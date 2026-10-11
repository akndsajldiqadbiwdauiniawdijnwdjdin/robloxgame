-- Builds a drivable car. The invisible "Chassis" box (the car's hitbox) is the only
-- physical part; the brick body from CarBody is welded to it. Driving uses two
-- constraints the driver's client controls (see client/Drive.client.luau):
--   Drive (LinearVelocity, horizontal plane only, so gravity and jumps still work)
--   Align (AlignOrientation: steering + tilting to match hills)
--
-- Custom models: put a Model named after the car Id (e.g. "Muscle") inside
-- ReplicatedStorage.CarModels and it replaces the brick body. See README.
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBody = require(ReplicatedStorage.Shared.CarBody)
local Cars = require(ReplicatedStorage.Shared.Cars)
local Config = require(ReplicatedStorage.Shared.Config)
local Stats = require(ReplicatedStorage.Shared.Stats)

local CarBuilder = {}

local MAX_ACCELERATION = 400 -- studs/s² the drive force can apply (scales with mass)

local function weld(part: BasePart, chassis: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = chassis
	constraint.Part1 = part
	constraint.Parent = part
end
CarBuilder.weld = weld

-- Swaps in ReplicatedStorage.CarModels[carId] if it exists. The model must face -Z
-- (Roblox "front") and its pivot should sit at the centre of the car, on the ground.
local function applyCustomModel(model: Model, root: CFrame, carId: string)
	local folder = ReplicatedStorage:FindFirstChild("CarModels")
	local template = folder and folder:FindFirstChild(carId)
	if not (template and template:IsA("Model")) then
		return
	end

	local custom = template:Clone()
	custom.Name = "CustomBody"
	custom:PivotTo(root * CFrame.new(0, template:GetAttribute("YOffset") or 0, 0))
	for _, descendant in custom:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy() -- never run scripts that ride along in imported/free models
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		end
	end

	model.Body:Destroy()
	local customStealable = custom:FindFirstChild("Stealable")
	if customStealable then
		model.Stealable:Destroy()
		customStealable.Parent = model
	end
	custom.Parent = model
end

-- `ground` is a CFrame on the road surface where the car should sit, facing forward.
function CarBuilder.build(player: Player, carId: string, upgradeLevels, ground: CFrame, parent: Instance): Model
	local car = Cars.ById[carId] or Cars.ById[Cars.Default]
	local stats = Stats.forCar(car, upgradeLevels, Config.Upgrades)
	local physics = Stats.derive(stats)

	local root = ground * CFrame.new(0, 0.2, 0)
	local model, spec = CarBody.build(car, root, true)
	model.Name = player.Name .. "_Car"
	local hitbox = spec.Hitbox

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = hitbox
	chassis.CFrame = root * CFrame.new(0, hitbox.Y / 2, 0)
	chassis.Transparency = 1
	-- Zero friction: the Drive constraint does all the gripping. Weight sets density.
	chassis.CustomPhysicalProperties = PhysicalProperties.new(physics.Density, 0, 0, 100, 1)
	chassis.Parent = model
	model.PrimaryPart = chassis

	applyCustomModel(model, root, car.Id)

	-- Motorcycles: the body hangs off a "LeanRoot" on a Motor6D at ground level, so every
	-- client can tilt it into turns (client/BikeLean) while the hitbox stays upright.
	local bodyAnchor = chassis
	if car.Bike then
		local leanRoot = Instance.new("Part")
		leanRoot.Name = "LeanRoot"
		leanRoot.Size = Vector3.new(0.2, 0.2, 0.2)
		leanRoot.CFrame = root
		leanRoot.Transparency = 1
		leanRoot.CanCollide = false
		leanRoot.CanTouch = false
		leanRoot.CanQuery = false
		leanRoot.Massless = true
		leanRoot.Parent = model
		local motor = Instance.new("Motor6D")
		motor.Name = "Lean"
		motor.Part0 = chassis
		motor.Part1 = leanRoot
		motor.C0 = chassis.CFrame:ToObjectSpace(root)
		motor.Parent = leanRoot
		bodyAnchor = leanRoot
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") and descendant ~= chassis and descendant ~= bodyAnchor then
			weld(descendant, bodyAnchor)
		end
	end

	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriverSeat"
	seat.Size = Vector3.new(2, 0.4, 2)
	seat.CFrame = root * CFrame.new(spec.Seat)
	seat.Transparency = 1
	seat.CanCollide = false
	seat.CanTouch = false -- only the server seats players
	seat.Massless = true
	seat.MaxSpeed = 0
	seat.Torque = 0
	seat.TurnSpeed = 0
	seat.HeadsUpDisplay = false
	weld(seat, chassis)
	seat.Parent = model

	local attachment = Instance.new("Attachment")
	attachment.Name = "Root"
	attachment.Parent = chassis

	local drive = Instance.new("LinearVelocity")
	drive.Name = "Drive"
	drive.Attachment0 = attachment
	drive.RelativeTo = Enum.ActuatorRelativeTo.World
	drive.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	drive.PrimaryTangentAxis = Vector3.xAxis
	drive.SecondaryTangentAxis = Vector3.zAxis
	drive.PlaneVelocity = Vector2.zero
	-- Force scales with mass, so heavy cars shove light ones around.
	drive.MaxForce = (chassis:GetMass() + 20) * MAX_ACCELERATION
	drive.Parent = chassis

	local align = Instance.new("AlignOrientation")
	align.Name = "Align"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.CFrame = chassis.CFrame.Rotation
	align.MaxTorque = 1e8
	align.Responsiveness = 60
	align.Parent = chassis

	model:SetAttribute("IsRaceCar", true)
	model:SetAttribute("OwnerId", player.UserId)
	model:SetAttribute("CarId", car.Id)
	for key, value in physics do
		model:SetAttribute(key, value)
	end
	model:SetAttribute("HalfHeight", hitbox.Y / 2)
	model:SetAttribute("RoofY", spec.Roof)
	model:SetAttribute("SpeedFactor", 1)
	model:SetAttribute("BoostUntil", 0)
	model:SetAttribute("StunnedUntil", 0)
	model:SetAttribute("Locked", true)

	-- Drift type: cars always swing out; bikes use the player's choice or their default.
	local driftStyle = "Outside"
	if car.Bike then
		local ok, choices = pcall(HttpService.JSONDecode, HttpService, player:GetAttribute("BikeDrift") or "{}")
		local choice = ok and type(choices) == "table" and choices[car.Id]
		driftStyle = if choice == "Inside" or choice == "Outside" then choice else car.Drift
		model:SetAttribute("IsBike", true)
		model:SetAttribute("RearZ", hitbox.Z / 2 - 1)
		CollectionService:AddTag(model, "Bike")
	end
	model:SetAttribute("DriftStyle", driftStyle)

	model.Parent = parent
	return model
end

return CarBuilder
