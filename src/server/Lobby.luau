-- The lobby players wait in between races: a compact round pit garage (Mario Kart
-- style). Logo floor with the spawn in the middle, numbered pit bays around the wall
-- with tire stacks, oil drums, tool carts and hose rigs, every vehicle on a pedestal,
-- a purple roll-up race door with the next-track screen above it, the garage counter
-- (walk up + E opens the garage), the daily spin wheel and a trophy case.
-- It sits far away from the tracks so it never overlaps one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBody = require(ReplicatedStorage.Shared.CarBody)
local Cars = require(ReplicatedStorage.Shared.Cars)
local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.Props)

local Lobby = {}

Lobby.Origin = Vector3.new(0, 0, 2600)
local R = 70 -- wall radius
local H = 32 -- wall height

local CONCRETE = Color3.fromRGB(150, 150, 156)
local DARK = Color3.fromRGB(58, 60, 68)
local FLOOR = Color3.fromRGB(78, 82, 96)
local PURPLE = Color3.fromRGB(140, 60, 230)
local PURPLE_DARK = Color3.fromRGB(95, 35, 170)
local RED = Color3.fromRGB(215, 40, 45)
local YELLOW = Color3.fromRGB(255, 200, 40)
local TIRE = Color3.fromRGB(28, 28, 30)
local SPONSORS = {
	{ "NITRO NATION", Color3.fromRGB(255, 120, 0) },
	{ "TURBO TIRES", Color3.fromRGB(80, 200, 255) },
	{ "DRIFT KINGS", Color3.fromRGB(255, 60, 160) },
	{ "SLICK OIL CO.", Color3.fromRGB(255, 220, 60) },
	{ "ILLEGAL MOTORS", Color3.fromRGB(120, 255, 140) },
	{ "BRICK BUILT", Color3.fromRGB(255, 80, 80) },
	{ "PIT STOP TV", Color3.fromRGB(180, 140, 255) },
}

local screens = {}

local function nameplate(adornee: BasePart, title: string, subtitle: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(180, 48)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
	gui.MaxDistance = 60
	for i, line in { title, subtitle } do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.5, 0)
		label.Position = UDim2.fromScale(0, (i - 1) * 0.5)
		label.BackgroundTransparency = 1
		label.Text = line
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = if i == 1 then Color3.new(1, 1, 1) else Color3.fromRGB(255, 210, 0)
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
	end
	gui.Parent = adornee
end

local function prompt(parent: BasePart, name: string, action: string, object: string)
	local proximity = Instance.new("ProximityPrompt")
	proximity.Name = name
	proximity.ActionText = action
	proximity.ObjectText = object
	proximity.HoldDuration = 0
	proximity.MaxActivationDistance = 16
	proximity.RequiresLineOfSight = false
	proximity.Parent = parent
end

function Lobby.build()
	local existing = workspace:FindFirstChild("Lobby")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	local O = Lobby.Origin
	local function part(props)
		return Props.part(folder, props)
	end
	-- Angles: 0 = north (the race door), measured clockwise seen from above.
	local function ring(angle: number, radius: number, y: number): Vector3
		return O + Vector3.new(math.sin(angle) * radius, y, -math.cos(angle) * radius)
	end
	-- Placed on the ring, front face looking at the centre of the room.
	local function facingIn(angle: number, radius: number, y: number): CFrame
		return CFrame.lookAt(ring(angle, radius, y), O + Vector3.new(0, y, 0))
	end
	local function disc(name, radius, top, thickness, color, material)
		return part({
			Name = name,
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(thickness, radius * 2, radius * 2),
			CFrame = CFrame.new(O + Vector3.new(0, top - thickness / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Material = material or Enum.Material.SmoothPlastic,
			Color = color,
		})
	end
	local function light(target: BasePart, range: number, brightness: number)
		local pointLight = Instance.new("PointLight")
		pointLight.Range = range
		pointLight.Brightness = brightness
		pointLight.Color = Color3.fromRGB(255, 245, 230)
		pointLight.Parent = target
	end
	local function tireStack(position: Vector3, count: number)
		for i = 0, count - 1 do
			part({ Name = "Tire", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 4.2, 4.2), CFrame = CFrame.new(position + Vector3.new(0, 0.7 + i * 1.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = TIRE })
		end
	end
	local function barrel(position: Vector3)
		part({ Name = "OilDrum", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 3.4, 3.4), CFrame = CFrame.new(position + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = PURPLE })
		part({ Name = "DrumBand", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.5, 3.5), CFrame = CFrame.new(position + Vector3.new(0, 2.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(245, 245, 245) })
	end
	local function toolCart(cf: CFrame)
		part({ Name = "ToolCart", Size = Vector3.new(5, 4, 2.6), CFrame = cf * CFrame.new(0, 2.4, 0), Material = Enum.Material.SmoothPlastic, Color = RED })
		for drawer = 0, 2 do
			part({ Name = "Drawer", Size = Vector3.new(4.4, 0.15, 0.1), CFrame = cf * CFrame.new(0, 1.3 + drawer * 1.1, -1.32), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205) })
		end
		part({ Name = "CartTop", Size = Vector3.new(5.2, 0.3, 2.8), CFrame = cf * CFrame.new(0, 4.55, 0), Material = Enum.Material.Metal, Color = DARK })
		part({ Name = "OilCan", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 0.8, 0.8), CFrame = cf * CFrame.new(1.4, 5.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = YELLOW })
		part({ Name = "Toolbox", Size = Vector3.new(1.8, 0.8, 1), CFrame = cf * CFrame.new(-1.2, 5.1, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 120, 220) })
		for _, x in { -2.2, 2.2 } do
			part({ Name = "Caster", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 0.8, 0.8), CFrame = cf * CFrame.new(x, 0.4, 0), Material = Enum.Material.SmoothPlastic, Color = TIRE })
		end
	end
	local function hoseRig(cf: CFrame)
		-- An air-hose pole with an arm reaching over the bay and a hose hanging down.
		part({ Name = "HosePole", Size = Vector3.new(1, 12, 1), CFrame = cf * CFrame.new(0, 6, 0), Material = Enum.Material.Metal, Color = DARK })
		part({ Name = "HoseArm", Size = Vector3.new(0.8, 0.8, 8), CFrame = cf * CFrame.new(0, 11.6, -4), Material = Enum.Material.Metal, Color = DARK })
		part({ Name = "HoseReel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 1.6, 1.6), CFrame = cf * CFrame.new(0, 11.6, -8) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205) })
		part({ Name = "Hose", Size = Vector3.new(0.35, 9, 0.35), CFrame = cf * CFrame.new(0, 6.8, -8.2) * CFrame.Angles(math.rad(6), 0, 0), Material = Enum.Material.SmoothPlastic, Color = TIRE })
		part({ Name = "HoseNozzle", Size = Vector3.new(0.6, 1, 0.6), CFrame = cf * CFrame.new(0, 2, -8.7), Material = Enum.Material.Neon, Color = Color3.fromRGB(160, 60, 255) })
	end

	-- Floor: dark disc, purple logo ring, name, inner ring and the spawn ------------------
	disc("Floor", R + 4, 0, 2, FLOOR, Enum.Material.Slate)
	disc("LogoRing", 40, 0.06, 0.1, PURPLE)
	disc("LogoInner", 37.5, 0.12, 0.1, Color3.fromRGB(88, 92, 108), Enum.Material.Slate)
	disc("InnerRing", 14, 0.18, 0.1, PURPLE)
	disc("InnerDisc", 12, 0.24, 0.1, Color3.fromRGB(70, 74, 88), Enum.Material.Slate)
	for _, z in { 24, -24 } do
		local plate = part({ Name = "FloorLogo", Size = Vector3.new(50, 0.1, 9), CFrame = CFrame.new(O + Vector3.new(0, 0.15, z)) * CFrame.Angles(0, if z < 0 then math.pi else 0, 0), Transparency = 1, CanCollide = false })
		Props.sign(plate, "ILLEGAL RACING", Color3.fromRGB(230, 230, 240), Enum.NormalId.Top)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Shape = Enum.PartType.Cylinder
	spawn.Size = Vector3.new(0.4, 16, 16)
	spawn.CFrame = CFrame.new(O + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90))
	spawn.Material = Enum.Material.Neon
	spawn.Color = PURPLE_DARK
	spawn.Transparency = 0.3
	spawn.Parent = folder

	-- Round wall, stripes, pillars, ledge with sponsor boards, ceiling and lights ------------
	local segments = 32
	local segmentWidth = 2 * math.pi * R / segments + 0.6
	for i = 0, segments - 1 do
		local angle = (i + 0.5) / segments * math.pi * 2
		part({ Name = "Wall", Size = Vector3.new(segmentWidth, H, 3), CFrame = facingIn(angle, R + 1.5, H / 2), Material = Enum.Material.Concrete, Color = CONCRETE })
		part({ Name = "WallStripe", Size = Vector3.new(segmentWidth, 1.6, 0.4), CFrame = facingIn(angle, R - 0.2, 5), Material = Enum.Material.SmoothPlastic, Color = RED })
		part({ Name = "WallBase", Size = Vector3.new(segmentWidth, 3, 0.4), CFrame = facingIn(angle, R - 0.2, 1.5), Material = Enum.Material.SmoothPlastic, Color = TIRE })
		part({ Name = "Ledge", Size = Vector3.new(segmentWidth, 1.4, 6), CFrame = facingIn(angle, R - 3, H - 6), Material = Enum.Material.Concrete, Color = DARK })
		if i % 2 == 0 then
			local lamp = part({ Name = "CeilingLight", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 2.4, 2.4), CFrame = CFrame.new(ring(angle, R - 14, H - 0.15)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 250, 235) })
			if i % 4 == 0 then
				light(lamp, 36, 1.4)
			end
		end
	end
	disc("Ceiling", R + 4, H + 2, 2, Color3.fromRGB(205, 205, 210), Enum.Material.Concrete)
	disc("CeilingRing", R - 6, H + 0.2, 0.4, Color3.fromRGB(180, 180, 188), Enum.Material.Concrete)
	local skylight = disc("Skylight", 20, H, 0.3, Color3.fromRGB(255, 252, 240), Enum.Material.Neon)
	light(skylight, 60, 2)
	for i = 0, 7 do
		local angle = (i + 0.5) / 8 * math.pi * 2
		part({ Name = "Pillar", Size = Vector3.new(6, H, 5), CFrame = facingIn(angle, R - 1.5, H / 2), Material = Enum.Material.Concrete, Color = Color3.fromRGB(170, 170, 176) })
		part({ Name = "PillarBase", Size = Vector3.new(6.6, 2, 5.6), CFrame = facingIn(angle, R - 1.5, 1), Material = Enum.Material.SmoothPlastic, Color = YELLOW })
	end
	local sponsorIndex = 0
	for i = 1, 7 do
		local angle = i / 8 * math.pi * 2
		if i ~= 1 then -- bay 1 has the spin wheel sign instead
			sponsorIndex += 1
			local sponsor = SPONSORS[sponsorIndex]
			local board = part({ Name = "SponsorBoard", Size = Vector3.new(22, 4, 0.6), CFrame = facingIn(angle, R - 5.8, H - 3), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 32, 40) })
			Props.sign(board, sponsor[1], sponsor[2], Enum.NormalId.Front)
		end
		-- Bay number on a purple plate below the ledge.
		local plate = part({ Name = "BayNumber", Size = Vector3.new(5, 4, 0.5), CFrame = facingIn(angle + math.rad(9), R - 0.5, H - 11), Material = Enum.Material.SmoothPlastic, Color = PURPLE })
		Props.sign(plate, tostring(i), Color3.new(1, 1, 1), Enum.NormalId.Front)
	end

	-- North: the purple roll-up race door with the next-track screen above it ----------------
	local doorCf = facingIn(0, R - 0.6, 0)
	for slat = 0, 11 do
		part({ Name = "DoorSlat", Size = Vector3.new(24, 1.45, 0.4), CFrame = doorCf * CFrame.new(0, 0.8 + slat * 1.5, 0), Material = Enum.Material.Metal, Color = if slat % 2 == 0 then PURPLE else PURPLE_DARK })
	end
	part({ Name = "DoorEmblem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 11, 11), CFrame = doorCf * CFrame.new(0, 9, -0.35) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(190, 140, 255), Transparency = 0.45 })
	for _, x in { -13, 13 } do
		part({ Name = "DoorPost", Size = Vector3.new(2, 19, 1.4), CFrame = doorCf * CFrame.new(x, 9.5, 0), Material = Enum.Material.SmoothPlastic, Color = YELLOW })
	end
	part({ Name = "DoorHeader", Size = Vector3.new(28, 2, 1.6), CFrame = doorCf * CFrame.new(0, 19, 0), Material = Enum.Material.Concrete, Color = DARK })
	local screen = part({ Name = "Screen", Size = Vector3.new(16, 5, 0.6), CFrame = doorCf * CFrame.new(0, 22.4, -0.6), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(15, 15, 20) })
	Props.sign(screen, "", Color3.fromRGB(120, 255, 160), Enum.NormalId.Front)
	table.insert(screens, screen:FindFirstChildOfClass("SurfaceGui").Text)
	for _, side in { -1, 1 } do
		hoseRig(facingIn(math.rad(side * 21), R - 7, 0))
		part({ Name = "Extinguisher", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 1, 1), CFrame = CFrame.new(ring(math.rad(side * 13), R - 2, 1.2)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = RED })
	end
	barrel(ring(math.rad(-30), R - 6, 0))
	tireStack(ring(math.rad(30), R - 6, 0), 4)

	-- Bay 7 (north-west): the garage counter --------------------------------------------------
	local garageAngle = math.rad(-45)
	local counterCf = facingIn(garageAngle, R - 14, 0)
	local counter = part({ Name = "Counter", Size = Vector3.new(20, 4, 3), CFrame = counterCf * CFrame.new(0, 2, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 100, 60) })
	part({ Name = "CounterTop", Size = Vector3.new(21, 0.5, 3.6), CFrame = counterCf * CFrame.new(0, 4.25, 0), Material = Enum.Material.Metal, Color = DARK })
	part({ Name = "Register", Size = Vector3.new(2, 1.4, 1.6), CFrame = counterCf * CFrame.new(6, 5.2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 40, 46) })
	prompt(counter, "OpenGarage", "Open Garage", "Car Shop")
	local garageSign = part({ Name = "GarageSign", Size = Vector3.new(16, 4, 0.5), CFrame = facingIn(garageAngle, R - 0.6, 14), Material = Enum.Material.Neon, Color = Color3.fromRGB(40, 130, 230) })
	Props.sign(garageSign, "GARAGE", Color3.new(1, 1, 1), Enum.NormalId.Front)
	toolCart(facingIn(garageAngle - math.rad(9), R - 5, 0))
	toolCart(facingIn(garageAngle + math.rad(9), R - 5, 0))
	-- Car lift with a car up on it.
	local liftCf = facingIn(garageAngle, R - 6, 0)
	for _, x in { -5, 5 } do
		part({ Name = "LiftPost", Size = Vector3.new(1, 10, 1), CFrame = liftCf * CFrame.new(x, 5, 1.5), Material = Enum.Material.Metal, Color = YELLOW })
	end
	part({ Name = "LiftArm", Size = Vector3.new(11, 0.6, 7), CFrame = liftCf * CFrame.new(0, 4.5, 0), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(120, 120, 125) })
	local liftCar = Cars.ById.Tuner or Cars.List[1]
	CarBody.build(liftCar, liftCf * CFrame.new(0, 4.8, 0) * CFrame.Angles(0, math.rad(90), 0), false).Parent = folder

	-- Bay 1 (north-east): the daily spin wheel on the wall -------------------------------------
	local spinAngle = math.rad(45)
	local hub = facingIn(spinAngle, R - 3.5, 12)
	local prizes = Config.Spin.Prizes
	for i, prize in prizes do
		part({ Name = "SpinSlice", Size = Vector3.new(3.6, 8, 0.6), CFrame = hub * CFrame.Angles(0, 0, (i - 1) / #prizes * math.pi * 2) * CFrame.new(0, 4.2, 0), Material = Enum.Material.SmoothPlastic, Color = prize.Color })
	end
	part({ Name = "SpinHub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 3.6, 3.6), CFrame = hub * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Metal, Color = YELLOW })
	part({ ClassName = "WedgePart", Name = "SpinPointer", Size = Vector3.new(0.6, 2, 1.6), CFrame = hub * CFrame.new(0, 8.6, -0.6) * CFrame.Angles(math.rad(180), 0, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.new(1, 1, 1) })
	local spinSign = part({ Name = "SpinSign", Size = Vector3.new(14, 2.4, 0.5), CFrame = facingIn(spinAngle, R - 0.6, 23), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 60, 160) })
	Props.sign(spinSign, "DAILY SPIN", Color3.new(1, 1, 1), Enum.NormalId.Front)
	local podium = part({ Name = "SpinPodium", Size = Vector3.new(10, 1, 6), CFrame = facingIn(spinAngle, R - 10, 0.5), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(255, 60, 160) })
	prompt(podium, "OpenSpin", "Spin the Wheel", "Daily Spin")

	-- South: trophy case -----------------------------------------------------------------------
	local caseCf = facingIn(math.pi, R - 7, 0)
	part({ Name = "TrophyStand", Size = Vector3.new(14, 4, 5), CFrame = caseCf * CFrame.new(0, 2, 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 70, 40) })
	part({ Name = "TrophyGlass", Size = Vector3.new(14, 8, 5), CFrame = caseCf * CFrame.new(0, 8, 0), Material = Enum.Material.Glass, Color = Color3.fromRGB(200, 230, 255), Transparency = 0.7, CanCollide = false })
	for index, x in { -4.5, 0, 4.5 } do
		local scale = if index == 2 then 1.3 else 1
		local color = ({ Color3.fromRGB(200, 200, 210), Color3.fromRGB(255, 205, 40), Color3.fromRGB(205, 130, 60) })[index]
		part({ Name = "TrophyBase", Size = Vector3.new(2, 1, 2) * scale, CFrame = caseCf * CFrame.new(x, 4.5, 0), Material = Enum.Material.Marble, Color = Color3.fromRGB(40, 40, 45) })
		part({ Name = "TrophyStem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4 * scale, 0.6 * scale, 0.6 * scale), CFrame = caseCf * CFrame.new(x, 5 + 1.2 * scale, 0) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = color })
		part({ Name = "TrophyCup", Shape = Enum.PartType.Ball, Size = Vector3.one * 2.4 * scale, CFrame = caseCf * CFrame.new(x, 5 + 3 * scale, 0), Material = Enum.Material.Metal, Color = color })
	end
	local caseSign = part({ Name = "TrophySign", Size = Vector3.new(14, 2.4, 0.4), CFrame = caseCf * CFrame.new(0, 13.4, 0), Material = Enum.Material.SmoothPlastic, Color = DARK })
	Props.sign(caseSign, "CUP CHAMPIONS", YELLOW, Enum.NormalId.Front)
	tireStack(ring(math.pi - math.rad(14), R - 6, 0), 3)
	tireStack(ring(math.pi + math.rad(14), R - 6, 0), 5)

	-- East + west bays: tire stacks, drums and carts behind the vehicles ----------------------
	for _, centre in { 90, 135, 225, 270 } do
		local angle = math.rad(centre)
		tireStack(ring(angle - math.rad(11), R - 6, 0), 3 + centre % 3)
		barrel(ring(angle + math.rad(10), R - 6, 0))
		barrel(ring(angle + math.rad(14), R - 9, 0))
		toolCart(facingIn(angle, R - 5, 0))
	end

	-- Every vehicle on a pedestal, in two arcs facing the middle ------------------------------
	local perSide = math.ceil(#Cars.List / 2)
	for index, car in Cars.List do
		local side = if index <= perSide then 1 else -1
		local slot = if side == 1 then index else index - perSide
		local degrees = 68 + (slot - 1) * (100 / math.max(perSide - 1, 1))
		local angle = math.rad(side * degrees)
		local base = ring(angle, 50, 0)
		local pedestal = part({ Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 11, 11), CFrame = CFrame.new(base + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = car.Colors.Primary })
		part({ Name = "PedestalTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 10, 10), CFrame = CFrame.new(base + Vector3.new(0, 0.95, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 42, 50) })
		local model = CarBody.build(car, CFrame.lookAt(base + Vector3.new(0, 1.1, 0), O + Vector3.new(0, 1.1, 0)), false)
		model.Name = "Showroom_" .. car.Id
		model.Parent = folder
		nameplate(pedestal, car.Name, if car.Price == 0 then "FREE" else "$" .. car.Price)
	end

	return spawn
end

-- Keeps the screen above the race door showing the next track and countdown.
function Lobby.startScreens()
	task.spawn(function()
		while true do
			local state = workspace:GetAttribute("RaceState")
			local trackName = workspace:GetAttribute("TrackName") or "..."
			local remaining = math.max(0, math.ceil((workspace:GetAttribute("StateEndsAt") or 0) - workspace:GetServerTimeNow()))
			local message
			if state == "Intermission" then
				message = string.format("VOTE NOW!  %ds", remaining)
			elseif state == "Selecting" then
				message = "PICKING THE TRACK..."
			elseif state == "Racing" or state == "Countdown" then
				message = "RACE LIVE\n" .. trackName
			else
				message = "RESULTS\n" .. trackName
			end
			for _, label in screens do
				label.Text = message
			end
			task.wait(0.5)
		end
	end)
end

return Lobby
