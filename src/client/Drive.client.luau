-- Arcade driving. Runs on the driver's machine because the server gives them network
-- ownership of their car. Reads VehicleSeat input (WASD / arrows / gamepad / mobile
-- thumbstick all work) and the physics numbers the server wrote onto the car
-- (TopSpeed, Accel, TurnRate, Grip, OffroadFactor, TurboCharge, TurboPower).
--
-- DRIFT: hold Space / Shift (gamepad R1/L1, mobile "Drift") while turning. Sparks go
-- blue -> orange -> purple; let go to fire a Mini-Turbo boost.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local REVERSE_FACTOR = 0.4
local BRAKE_FACTOR = 2.5
local COAST_FACTOR = 0.5
local LAUNCH_AIR_TIME = 0.6
local SPINOUT_RATE = 10
local DRIFT = Config.Drift

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local driftHeld = false
local airborneUntil = 0

-- Per-car local state, reset whenever we get into a different car (or get teleported).
local state = {
	Car = nil,
	Heading = 0, -- yaw angle we're steering toward (radians)
	Up = Vector3.yAxis,
	Drifting = false,
	DriftDirection = 0,
	Charge = 0,
	TurboUntil = 0,
	PadUntil = 0,
	Sparks = nil,
	SpinBase = nil, -- heading before a spin-out, restored afterwards
	Kick = 0,
}

local function getCar(): (Model?, VehicleSeat?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") and seat.Parent and seat.Parent:GetAttribute("IsRaceCar") then
		return seat.Parent :: Model, seat
	end
	return nil, nil
end

local function headingOf(cf: CFrame): number
	local look = cf.LookVector
	return math.atan2(-look.X, -look.Z)
end

local function moveTowards(current: number, target: number, step: number): number
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

local function makeSparks(chassis: BasePart, halfHeight: number)
	local emitters = {}
	for _, side in { -1, 1 } do
		local attachment = Instance.new("Attachment")
		attachment.Name = "DriftSparks"
		attachment.Position = Vector3.new(side * (chassis.Size.X / 2 - 0.5), -halfHeight + 0.3, chassis.Size.Z / 2 - 1)
		attachment.Parent = chassis
		local emitter = Instance.new("ParticleEmitter")
		emitter.Rate = 60
		emitter.Lifetime = NumberRange.new(0.15, 0.35)
		emitter.Speed = NumberRange.new(8, 16)
		emitter.SpreadAngle = Vector2.new(40, 40)
		emitter.Size = NumberSequence.new(0.5, 0)
		emitter.LightEmission = 1
		emitter.Enabled = false
		emitter.Parent = attachment
		table.insert(emitters, emitter)
	end
	return emitters
end

local function setSparks(tier: number?)
	for _, emitter in state.Sparks or {} do
		emitter.Enabled = tier ~= nil
		if tier then
			local color = if tier == 0 then Color3.fromRGB(200, 200, 200) else DRIFT.TierColors[tier]
			emitter.Color = ColorSequence.new(color)
		end
	end
end

local function driftTier(): number
	local tier = 0
	for i, seconds in DRIFT.TierTimes do
		if state.Charge >= seconds then
			tier = i
		end
	end
	return tier
end

local function resetState(car: Model?)
	state.Car = car
	state.Drifting = false
	state.Charge = 0
	state.TurboUntil = 0
	state.PadUntil = 0
	state.Up = Vector3.yAxis
	state.Sparks = nil
	state.SpinBase = nil
	if car and car.PrimaryPart then
		state.Heading = headingOf(car.PrimaryPart.CFrame)
		state.Sparks = makeSparks(car.PrimaryPart, car:GetAttribute("HalfHeight") or 1.2)
	end
end

-- Drift button. Also swallows Space so it doesn't make you jump out of the car.
ContextActionService:BindActionAtPriority("Drift", function(_, inputState)
	if not getCar() then
		driftHeld = false
		return Enum.ContextActionResult.Pass
	end
	driftHeld = inputState == Enum.UserInputState.Begin or inputState == Enum.UserInputState.Change
	return Enum.ContextActionResult.Sink
end, true, Enum.ContextActionPriority.High.Value, Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1)
ContextActionService:SetTitle("Drift", "Drift")

local function setJetFlames(car: Model, on: boolean)
	local chassis = car.PrimaryPart
	local flames = chassis and chassis:FindFirstChild("JetFlames")
	if on and chassis and not flames then
		flames = Instance.new("Fire")
		flames.Name = "JetFlames"
		flames.Size = 8
		flames.Heat = 20
		flames.Color = Color3.fromRGB(255, 140, 30)
		flames.Parent = chassis
	elseif not on and flames then
		flames:Destroy()
	end
end

RunService.Heartbeat:Connect(function(dt)
	local car, seat = getCar()
	if car ~= state.Car then
		resetState(car)
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, car == nil)
	end
	if not car then
		camera.FieldOfView = 70
		if player:GetAttribute("DriftTier") ~= nil then
			player:SetAttribute("DriftTier", nil)
		end
		return
	end

	local chassis = car.PrimaryPart
	local drive = chassis and chassis:FindFirstChild("Drive")
	local align = chassis and chassis:FindFirstChild("Align")
	if not (drive and align) or chassis.Anchored then
		return
	end

	local now = workspace:GetServerTimeNow()
	local clock = os.clock()
	local locked = car:GetAttribute("Locked")
	local stunned = now < (car:GetAttribute("StunnedUntil") or 0)
	local topSpeed = car:GetAttribute("TopSpeed") * car:GetAttribute("SpeedFactor")
	local accel = car:GetAttribute("Accel")
	local turnRate = car:GetAttribute("TurnRate")
	local grip = car:GetAttribute("Grip")
	local offroad = car:GetAttribute("OffroadFactor")
	local halfHeight = car:GetAttribute("HalfHeight")

	-- Ground check: what are we driving on? Rays under the middle, front and back. The
	-- front/back pair gives the slope ahead, so the car tilts up as it reaches a ramp
	-- instead of slamming its nose into it.
	rayParams.FilterDescendantsInstances = { car, character }
	local headingForward = Vector3.new(-math.sin(state.Heading), 0, -math.cos(state.Heading))
	local reach = Vector3.new(0, -(halfHeight + 3), 0)
	local halfLength = chassis.Size.Z / 2 - 0.5
	local hit = workspace:Raycast(chassis.Position, Vector3.new(0, -(halfHeight + 1.5), 0), rayParams)
	local frontHit = workspace:Raycast(chassis.Position + headingForward * halfLength, reach, rayParams)
	local backHit = workspace:Raycast(chassis.Position - headingForward * halfLength, reach, rayParams)
	hit = hit or (frontHit and frontHit.Distance < halfHeight + 1.5 and frontHit) or (backHit and backHit.Distance < halfHeight + 1.5 and backHit) or nil
	local grounded = hit ~= nil and clock > airborneUntil
	local groundUp = Vector3.yAxis
	if frontHit and backHit then
		local slope = frontHit.Position - backHit.Position
		local headingRight = Vector3.new(-headingForward.Z, 0, headingForward.X)
		local up = headingRight:Cross(slope)
		if up.Magnitude > 1e-3 and up.Unit.Y > 0.6 then
			groundUp = up.Unit
		end
	elseif hit then
		groundUp = hit.Normal
	end

	local surfaceSpeed, surfaceGrip = 1, 1
	if hit then
		local surface = hit.Instance:GetAttribute("Surface")
		if surface == "Dirt" then
			surfaceSpeed = 1 - (1 - offroad) * 0.3
			surfaceGrip = 0.75
		elseif surface == "Mud" then
			surfaceSpeed = offroad * 0.75
			surfaceGrip = 0.6
		elseif surface == "Ice" then
			surfaceGrip = 0.2
		elseif surface ~= "Road" then
			surfaceSpeed = offroad
			surfaceGrip = 0.8
		end
		if hit.Instance:GetAttribute("BoostPad") then
			if clock > state.PadUntil then
				Sounds.play("Whoosh", 1.3)
			end
			state.PadUntil = clock + Config.BoostPad.Duration
		end
	end

	-- Jetpack: fly over everything at full speed.
	local flying = now < (car:GetAttribute("FlyUntil") or 0)
	if flying then
		surfaceSpeed, surfaceGrip = 1, 1
	end
	setJetFlames(car, flying)

	-- Boosts: items/abilities (server), boost pads and mini-turbos (local). Biggest wins.
	local boost = 1
	if now < (car:GetAttribute("BoostUntil") or 0) then
		boost = math.max(boost, car:GetAttribute("BoostPower") or Config.PowerUps.Nitro.SpeedBoost)
	end
	if clock < state.PadUntil then
		boost = math.max(boost, Config.BoostPad.SpeedBoost)
	end
	if clock < state.TurboUntil then
		boost = math.max(boost, car:GetAttribute("TurboPower"))
	end
	if boost > 1 then
		topSpeed *= boost
		accel *= 3
		surfaceSpeed = math.max(surfaceSpeed, 0.9) -- boosting powers through offroad
	end
	topSpeed *= surfaceSpeed
	-- Slowed by Freeze Ray, Siren, Jingle, Smoke...
	if now < (car:GetAttribute("SlowUntil") or 0) then
		topSpeed *= car:GetAttribute("SlowFactor") or 1
	end

	local forward = Vector3.new(-math.sin(state.Heading), 0, -math.cos(state.Heading))
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local velocity = chassis.AssemblyLinearVelocity
	local forwardSpeed = velocity:Dot(forward)
	local sideSpeed = velocity:Dot(right)

	local throttle, steerInput = seat.ThrottleFloat, seat.SteerFloat
	if locked then
		throttle, steerInput = 0, 0
	end
	if stunned then
		throttle = 0
	end

	-- Drift state machine.
	local baseTop = car:GetAttribute("TopSpeed")
	if not state.Drifting then
		if driftHeld and grounded and not stunned and math.abs(steerInput) > 0.3 and forwardSpeed > baseTop * DRIFT.MinSpeedFraction then
			state.Drifting = true
			state.DriftDirection = math.sign(steerInput)
			state.Charge = 0
		end
	elseif not driftHeld or stunned or forwardSpeed < baseTop * 0.25 then
		local tier = driftTier()
		if tier > 0 and not driftHeld and not stunned then
			state.TurboUntil = clock + DRIFT.BoostTimes[tier]
			state.Kick = DRIFT.Kick[tier]
			-- Tell the HUD (local-only attributes).
			player:SetAttribute("TurboTier", tier)
			player:SetAttribute("TurboCount", (player:GetAttribute("TurboCount") or 0) + 1)
		end
		state.Drifting = false
		state.Charge = 0
	end

	-- Speed along the heading.
	local targetSpeed = if throttle >= 0 then throttle * topSpeed else throttle * topSpeed * REVERSE_FACTOR
	local rate = accel
	if throttle == 0 then
		rate = accel * COAST_FACTOR
	elseif (forwardSpeed > 1 and throttle < 0) or (forwardSpeed < -1 and throttle > 0) then
		rate = accel * BRAKE_FACTOR
	end
	local newForward = moveTowards(forwardSpeed, targetSpeed, rate * dt)
	if state.Kick > 0 then
		newForward = math.max(newForward, forwardSpeed + state.Kick)
		state.Kick = 0
	end

	-- Sideways sliding and steering.
	local newSide, yawRate
	if stunned then
		state.SpinBase = state.SpinBase or state.Heading
		newSide = sideSpeed
		yawRate = SPINOUT_RATE
	elseif state.Drifting then
		-- into = +1 holding the drift direction, -1 counter-steering (the other key).
		local into = steerInput * state.DriftDirection
		if into >= -0.2 then
			-- Holding into the drift (or neutral): tighter turn, charges the Mini-Turbo.
			yawRate = -state.DriftDirection * turnRate * (0.55 + 0.65 * math.max(into, 0))
			local outward = -state.DriftDirection * newForward * 0.18
			newSide = moveTowards(sideSpeed, outward, grip * surfaceGrip * 20 * dt)
			local rush = if now < (car:GetAttribute("TurboRushUntil") or 0) then 3 else 1 -- Drift King
			state.Charge += dt * car:GetAttribute("TurboCharge") * rush
		else
			-- Counter-steering: straightens the car out (can even turn slightly the other
			-- way) without breaking the drift, but adds nothing to the Mini-Turbo.
			yawRate = -state.DriftDirection * turnRate * (0.2 + 0.45 * into)
			newSide = moveTowards(sideSpeed, -state.DriftDirection * newForward * 0.06, grip * surfaceGrip * 30 * dt)
		end
	else
		local speedScale = math.clamp(math.abs(forwardSpeed) / 25, 0, 1)
		local direction = if forwardSpeed >= 0 then 1 else -1
		-- Positive yaw turns left, and SteerFloat is +1 for right, hence the minus.
		yawRate = -steerInput * turnRate * speedScale * direction
		newSide = sideSpeed * math.max(0, 1 - grip * surfaceGrip * dt)
	end
	if not stunned and state.SpinBase then
		state.Heading = state.SpinBase -- spin-out over: face the way you were going
		state.SpinBase = nil
	end
	state.Heading += yawRate * dt
	local tier = if state.Drifting then driftTier() else nil
	setSparks(tier)
	if player:GetAttribute("DriftTier") ~= tier then
		player:SetAttribute("DriftTier", tier) -- read by the HUD (local only)
	end

	if grounded then
		drive.Enabled = true
		local planar = forward * newForward + right * newSide
		drive.PlaneVelocity = Vector2.new(planar.X, planar.Z)
	else
		drive.Enabled = false -- airborne: let physics fly the car
	end

	-- Orientation: face the heading, tilt to match the ground (level out in the air).
	local targetUp = if grounded then groundUp else Vector3.yAxis
	state.Up = state.Up:Lerp(targetUp, math.min(1, dt * 10)).Unit
	local look = (forward - state.Up * forward:Dot(state.Up)).Unit
	align.CFrame = CFrame.fromMatrix(Vector3.zero, look:Cross(state.Up), state.Up)

	-- Speed feel: widen the camera as you go faster.
	local speedRatio = math.clamp(velocity.Magnitude / 170, 0, 1)
	local targetFov = 70 + speedRatio * 18 + (if boost > 1 then 8 else 0)
	camera.FieldOfView += (targetFov - camera.FieldOfView) * math.min(1, dt * 5)
end)

Remotes.Effect.OnClientEvent:Connect(function(kind, value, extra)
	local car = getCar()
	local chassis = car and car.PrimaryPart
	if not chassis then
		return
	end
	if kind == "Launch" then
		airborneUntil = os.clock() + LAUNCH_AIR_TIME
		chassis.AssemblyLinearVelocity += value
	elseif kind == "Hop" then -- Turbo Hop / Monster Stomp: value = upward speed, extra = kick
		airborneUntil = os.clock() + 0.35
		chassis.AssemblyLinearVelocity += Vector3.new(0, value, 0)
		if extra and extra > 0 then
			state.Kick = extra
			state.TurboUntil = os.clock() + 0.8
		end
	elseif kind == "Leap" or kind == "Dash" then -- Dune Jump / Magnet Hook
		airborneUntil = os.clock() + (if kind == "Leap" then 0.6 else 0.3)
		chassis.AssemblyLinearVelocity = Vector3.new(value.X, if kind == "Leap" then value.Y else chassis.AssemblyLinearVelocity.Y, value.Z)
		local flatValue = Vector3.new(value.X, 0, value.Z)
		if flatValue.Magnitude > 1 then
			state.Heading = math.atan2(-flatValue.X, -flatValue.Z)
		end
	elseif kind == "Blink" then -- Blink Drive: teleport ahead but keep your speed
		local speed = Vector3.new(chassis.AssemblyLinearVelocity.X, 0, chassis.AssemblyLinearVelocity.Z).Magnitude
		car:PivotTo(value)
		state.Heading = headingOf(value)
		chassis.AssemblyLinearVelocity = value.LookVector * speed
	elseif kind == "Teleport" then
		car:PivotTo(value)
		chassis.AssemblyLinearVelocity = Vector3.zero
		chassis.AssemblyAngularVelocity = Vector3.zero
		state.Heading = headingOf(value)
		state.Drifting = false
		state.Charge = 0
		state.SpinBase = nil
		state.Kick = 0
	elseif kind == "Stop" then
		chassis.AssemblyLinearVelocity = Vector3.zero
		task.defer(function()
			-- The server just teleported us: steer toward the new facing.
			if state.Car and state.Car.PrimaryPart then
				state.Heading = headingOf(state.Car.PrimaryPart.CFrame)
				state.Drifting = false
				state.Charge = 0
				state.SpinBase = nil
			end
		end)
	end
end)
