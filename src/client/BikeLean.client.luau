-- Motorcycles lean into turns (and lift the front for a Wheelie). Runs on every client
-- for every bike: the lean is worked out from how fast the bike is turning, which every
-- client already knows, and applied to the body's "Lean" Motor6D (see CarBuilder).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local BIKES = Config.Bikes

local current = {} -- [model] = { Lean, Pitch }

RunService.Stepped:Connect(function(_, dt)
	local now = workspace:GetServerTimeNow()
	for _, bike in CollectionService:GetTagged("Bike") do
		local chassis = bike.PrimaryPart
		local leanRoot = bike:FindFirstChild("LeanRoot")
		local motor = leanRoot and leanRoot:FindFirstChild("Lean")
		if chassis and motor then
			local state = current[bike]
			if not state then
				state = { Lean = 0, Pitch = 0 }
				current[bike] = state
			end
			local velocity = chassis.AssemblyLinearVelocity
			local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
			-- Turning left = positive yaw; lean right is positive here.
			local targetLean = math.clamp(-chassis.AssemblyAngularVelocity.Y * speed * BIKES.LeanPerTurn, -BIKES.MaxLean, BIKES.MaxLean)
			if bike:GetAttribute("DriftStyle") == "Inside" then
				targetLean *= 1.25 -- inside drifters hang off the bike
			end
			local targetPitch = if now < (bike:GetAttribute("WheelieUntil") or 0) then BIKES.WheelieAngle else 0
			local blend = math.min(1, dt * 8)
			state.Lean += (targetLean - state.Lean) * blend
			state.Pitch += (targetPitch - state.Pitch) * blend
			-- Wheelie pivots on the back wheel; lean pivots on the tyre contact line.
			local rear = bike:GetAttribute("RearZ") or 3
			motor.Transform = CFrame.new(0, 0, rear) * CFrame.Angles(state.Pitch, 0, 0) * CFrame.new(0, 0, -rear) * CFrame.Angles(0, 0, -state.Lean)
		end
	end
end)

CollectionService:GetInstanceRemovedSignal("Bike"):Connect(function(bike)
	current[bike] = nil
end)
