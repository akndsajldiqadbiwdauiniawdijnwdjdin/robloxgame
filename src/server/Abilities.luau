-- Car signature abilities (key Q / slot 1). Every car has its own (see Cars.luau
-- Ability); tuning numbers are in Config.Abilities.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cars = require(ReplicatedStorage.Shared.Cars)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PowerUps = require(script.Parent.PowerUps)

local Abilities = {}
local CFG = Config.Abilities

local function now(): number
	return workspace:GetServerTimeNow()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function forwardOf(racer): Vector3
	local look = flat(racer.Chassis.CFrame.LookVector)
	return if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis
end

local function othersWithin(race, racer, radius: number)
	local list = {}
	for _, other in race.Ordered do
		if other ~= racer and other.Active and PowerUps.flatDistance(other.Chassis.Position, racer.Chassis.Position) <= radius then
			table.insert(list, other)
		end
	end
	return list
end

local handlers = {}

function handlers.DuctTape(_, racer)
	racer.Car:SetAttribute("SpeedFactor", math.max(1, racer.Car:GetAttribute("SpeedFactor")))
	PowerUps.boost(racer, CFG.DuctTape.Boost, CFG.DuctTape.BoostTime)
	PowerUps.notify(racer.Player, "🩹 Patched up!")
end

function handlers.Hop(_, racer)
	Remotes.Effect:FireClient(racer.Player, "Hop", CFG.Hop.Up, CFG.Hop.Kick)
end

function handlers.DriftKing(_, racer)
	racer.Car:SetAttribute("TurboRushUntil", now() + CFG.DriftKing.Duration)
	PowerUps.notify(racer.Player, "🌀 Drift King! Drifts charge 3x faster")
end

function handlers.DuneJump(_, racer)
	Remotes.Effect:FireClient(racer.Player, "Leap", forwardOf(racer) * CFG.DuneJump.Forward + Vector3.new(0, CFG.DuneJump.Up, 0))
end

function handlers.Ram(_, racer)
	PowerUps.boost(racer, CFG.Ram.Boost, CFG.Ram.Duration)
	racer.RamUntil = os.clock() + CFG.Ram.Duration
	racer.RamHit = {}
end

function handlers.Jingle(race, racer)
	for _, other in othersWithin(race, racer, CFG.Jingle.Radius) do
		PowerUps.slow(other, racer, CFG.Jingle.Slow, CFG.Jingle.Time, "🍦 Brain freeze! (" .. racer.Player.DisplayName .. ")")
	end
end

function handlers.Siren(race, racer)
	for place = 1, racer.Place - 1 do
		local other = race.Ordered[place]
		if other and other.Active and PowerUps.flatDistance(other.Chassis.Position, racer.Chassis.Position) <= CFG.Siren.Range then
			PowerUps.slow(other, racer, CFG.Siren.Slow, CFG.Siren.Time, "🚨 PULL OVER! (" .. racer.Player.DisplayName .. ")")
		end
	end
end

function handlers.Stomp(race, racer)
	Remotes.Effect:FireClient(racer.Player, "Hop", 25, 0)
	for _, other in othersWithin(race, racer, CFG.Stomp.Radius) do
		local away = flat(other.Chassis.Position - racer.Chassis.Position)
		away = if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis
		PowerUps.hit(other, racer, CFG.Stomp.StunTime, away * 45 + Vector3.new(0, 40, 0), "💥 Monster stomp!")
	end
end

function handlers.Afterburner(_, racer)
	PowerUps.boost(racer, CFG.Afterburner.Boost, CFG.Afterburner.Time)
end

function handlers.Blink(race, racer)
	local samples = race.Track.Samples
	-- Never blink across the finish line (no free laps).
	local index = math.min(racer.Sample + CFG.Blink.Samples, #samples)
	local sample = samples[index]
	local position = sample.Position + Vector3.new(0, racer.Car:GetAttribute("HalfHeight") + 1.2, 0)
	local target = CFrame.lookAt(position, position + sample.Forward)
	racer.Car:PivotTo(target)
	racer.Sample = index
	Remotes.Effect:FireClient(racer.Player, "Blink", target)
end

function handlers.PizzaToss(race, racer)
	local target = race.Ordered[racer.Place - 1]
	if not (target and target.Active and PowerUps.flatDistance(target.Chassis.Position, racer.Chassis.Position) <= CFG.PizzaToss.Range) then
		PowerUps.notify(racer.Player, "🍕 Nobody close enough ahead!")
		racer.AbilityReadyAt = now() + 2 -- quick retry instead of the full cooldown
		racer.Player:SetAttribute("AbilityReadyAt", racer.AbilityReadyAt)
		return
	end
	PowerUps.slow(target, racer, CFG.PizzaToss.Slow, CFG.PizzaToss.Time, "🍕 Pizza to the face! (" .. racer.Player.DisplayName .. ")")
end

function handlers.Wheelie(_, racer)
	PowerUps.boost(racer, CFG.Wheelie.Boost, CFG.Wheelie.Time)
	racer.Car:SetAttribute("WheelieUntil", now() + CFG.Wheelie.Time)
end

function handlers.ChainWhip(race, racer)
	local right = forwardOf(racer):Cross(Vector3.yAxis)
	for _, other in othersWithin(race, racer, CFG.ChainWhip.Radius) do
		local offset = flat(other.Chassis.Position - racer.Chassis.Position)
		local side = if offset:Dot(right) >= 0 then right else -right
		PowerUps.hit(other, racer, CFG.ChainWhip.StunTime, side * 40 + Vector3.new(0, 20, 0), "⛓️ Chain whipped by " .. racer.Player.DisplayName .. "!")
	end
end

function handlers.LaneSplit(_, racer)
	PowerUps.boost(racer, CFG.LaneSplit.Boost, CFG.LaneSplit.Time)
	racer.Car:SetAttribute("ShieldUntil", math.max(racer.Car:GetAttribute("ShieldUntil") or 0, now() + CFG.LaneSplit.Time))
	PowerUps.notify(racer.Player, "⚡ Lane split!")
end

-- Starts a race with the ability ready.
function Abilities.setup(racer, carId: string)
	local car = Cars.ById[carId] or Cars.List[1]
	racer.Ability = car.Ability
	racer.AbilityReadyAt = 0
	racer.Player:SetAttribute("AbilityId", car.Ability.Id)
	racer.Player:SetAttribute("AbilityReadyAt", 0)
end

function Abilities.use(race, racer)
	local ability = racer.Ability
	if not ability or now() < racer.AbilityReadyAt then
		return
	end
	racer.AbilityReadyAt = now() + ability.Cooldown
	racer.Player:SetAttribute("AbilityReadyAt", racer.AbilityReadyAt)
	handlers[ability.Id](race, racer)
end

-- Called ~10x per second: the Ram ability hits whoever it touches.
function Abilities.update(race)
	for _, racer in race.Ordered do
		if racer.Active and racer.RamUntil and os.clock() < racer.RamUntil then
			for _, other in othersWithin(race, racer, CFG.Ram.Radius) do
				if not racer.RamHit[other] then
					racer.RamHit[other] = true
					local side = flat(other.Chassis.Position - racer.Chassis.Position)
					side = if side.Magnitude > 0.1 then side.Unit else Vector3.xAxis
					PowerUps.hit(other, racer, CFG.Ram.StunTime, side * 50 + Vector3.new(0, 35, 0), "🐂 Rammed by " .. racer.Player.DisplayName .. "!")
				end
			end
		end
	end
end

return Abilities
