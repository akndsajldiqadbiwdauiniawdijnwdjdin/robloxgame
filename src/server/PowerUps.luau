-- Item boxes and every item's effect. Item boxes give a random item from the racer's own
-- LOADOUT (chosen in the shop), so every player's race feels different.
-- The server decides everything; clients read car attributes (BoostUntil, BoostPower,
-- StunnedUntil, SlowUntil, SlowFactor, ShieldUntil, FlyUntil, BlindUntil) and Effect events.
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local Items = require(ReplicatedStorage.Shared.Items)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CarBuilder = require(script.Parent.CarBuilder)

local PowerUps = {}
local CFG = Config.PowerUps

local hazards = {} -- dropped things on the track: oil, spikes, smoke, tornadoes
local effectsFolder: Folder
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function now(): number
	return workspace:GetServerTimeNow()
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function flatDistance(a: Vector3, b: Vector3): number
	return flat(a - b).Magnitude
end
PowerUps.flatDistance = flatDistance

function PowerUps.notify(player: Player, text: string)
	if player.Parent then
		Remotes.Notify:FireClient(player, text, 2.5)
	end
end
local notify = PowerUps.notify

local function effectPart(props)
	local part = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	for key, value in props do
		part[key] = value
	end
	part.Parent = effectsFolder
	return part
end

local function explosion(position: Vector3)
	local blast = Instance.new("Explosion")
	blast.Position = position
	blast.BlastPressure = 0 -- visual only; knockback is handled by hit()
	blast.DestroyJointRadiusPercent = 0
	blast.Parent = workspace
end

-- Shared effect helpers (also used by car abilities) ------------------------------

local function consumeShield(victim): boolean
	if now() < (victim.Car:GetAttribute("ShieldUntil") or 0) then
		victim.Car:SetAttribute("ShieldUntil", 0)
		notify(victim.Player, "🛡️ Your shield blocked it!")
		return true
	end
	return false
end

-- Stuns and/or launches a racer. Heavy cars (Weight) are affected less. Returns true if
-- it landed (shields block it).
function PowerUps.hit(victim, attacker, stunTime: number?, launch: Vector3?, message: string?): boolean
	if not victim.Active or consumeShield(victim) then
		return false
	end
	local scale = victim.Car:GetAttribute("KnockbackScale") or 1
	if stunTime then
		local current = victim.Car:GetAttribute("StunnedUntil") or 0
		victim.Car:SetAttribute("StunnedUntil", math.max(current, now() + stunTime * scale))
	end
	if launch then
		Remotes.Effect:FireClient(victim.Player, "Launch", launch * scale)
	end
	if message then
		notify(victim.Player, message)
	end
	victim.TimesHit += 1
	if attacker and attacker ~= victim then
		attacker.Hits += 1
	end
	return true
end

function PowerUps.slow(victim, attacker, factor: number, duration: number, message: string?): boolean
	if not victim.Active or consumeShield(victim) then
		return false
	end
	local car = victim.Car
	local active = now() < (car:GetAttribute("SlowUntil") or 0)
	car:SetAttribute("SlowFactor", if active then math.min(factor, car:GetAttribute("SlowFactor") or 1) else factor)
	car:SetAttribute("SlowUntil", math.max(car:GetAttribute("SlowUntil") or 0, now() + duration))
	if message then
		notify(victim.Player, message)
	end
	if attacker and attacker ~= victim then
		attacker.Hits += 1
	end
	victim.TimesHit += 1
	return true
end

function PowerUps.boost(racer, power: number, duration: number)
	racer.Car:SetAttribute("BoostPower", power)
	racer.Car:SetAttribute("BoostUntil", now() + duration)
end

-- Racer directly ahead, else the next one behind.
local function adjacentTarget(race, racer)
	for _, place in { racer.Place - 1, racer.Place + 1 } do
		local other = race.Ordered[place]
		if other and other ~= racer and other.Active then
			return other
		end
	end
	return nil
end

local function targetAhead(race, racer, range: number)
	local other = race.Ordered[racer.Place - 1]
	if other and other.Active and flatDistance(other.Chassis.Position, racer.Chassis.Position) <= range then
		return other
	end
	return nil
end

local function behindPosition(racer, distance: number): Vector3
	local cf = racer.Chassis.CFrame
	local back = flat(cf.LookVector)
	back = if back.Magnitude > 0.01 then back.Unit else Vector3.zAxis
	local position = cf.Position - back * distance
	local hit = workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -30, 0), rayParams)
	return if hit then hit.Position else position - Vector3.new(0, 1.2, 0)
end

local function dropHazard(kind: string, racer, part: BasePart, lifetime: number, radius: number)
	table.insert(hazards, {
		Kind = kind,
		Part = part,
		Owner = racer,
		SafeUntil = now() + 1.5, -- don't instantly hit the person who dropped it
		Expires = now() + lifetime,
		Radius = radius,
		HitRacers = {},
	})
end

-- Item boxes -----------------------------------------------------------------------------

function PowerUps.init(carsFolder: Folder)
	effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Effects"
	effectsFolder.Parent = workspace
	rayParams.FilterDescendantsInstances = { carsFolder, effectsFolder }
end

function PowerUps.give(racer, id: string?)
	racer.PowerUp = id
	if racer.Player.Parent then
		racer.Player:SetAttribute("PowerUp", id)
	end
end

-- Picks from the racer's loadout. Racers in the back half get rarer items more often.
function PowerUps.roll(race, racer): string
	local loadout = racer.Loadout
	if #loadout == 0 then
		return "Nitro"
	end
	local behind = race.Count > 1 and racer.Place > race.Count / 2
	local weights, total = {}, 0
	for index, id in loadout do
		local rarity = Items.Rarities[Items.ById[id].Rarity]
		local weight = if behind then Config.CatchUpRarityBonus ^ (rarity.Order - 1) else 1
		weights[index] = weight
		total += weight
	end
	local roll = math.random() * total
	for index, id in loadout do
		roll -= weights[index]
		if roll <= 0 then
			return id
		end
	end
	return loadout[1]
end

-- Items ----------------------------------------------------------------------------------

local handlers = {}

function handlers.Nitro(_, racer)
	PowerUps.boost(racer, CFG.Nitro.SpeedBoost, CFG.Nitro.Duration)
end

function handlers.Oil(_, racer)
	local position = behindPosition(racer, 10)
	local puddle = effectPart({
		Name = "OilSlick",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 12, 12),
		CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(15, 15, 20),
		Reflectance = 0.4,
	})
	dropHazard("Oil", racer, puddle, CFG.Oil.Lifetime, 7)
end

function handlers.Spikes(_, racer)
	local position = behindPosition(racer, 10)
	local look = flat(racer.Chassis.CFrame.LookVector)
	local strip = effectPart({
		Name = "SpikeStrip",
		Size = Vector3.new(12, 0.5, 3),
		CFrame = CFrame.lookAt(position + Vector3.new(0, 0.25, 0), position + Vector3.new(0, 0.25, 0) + (if look.Magnitude > 0 then look else Vector3.zAxis)),
		Material = Enum.Material.DiamondPlate,
		Color = Color3.fromRGB(60, 60, 65),
	})
	for k = -2, 2 do
		local spike = effectPart({ ClassName = "WedgePart", Name = "Spike", Size = Vector3.new(0.6, 1, 1), CFrame = strip.CFrame * CFrame.new(k * 2.4, 0.75, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205) })
		spike.Parent = strip -- removed together with the strip
	end
	dropHazard("Spikes", racer, strip, CFG.Spikes.Lifetime, 7)
end

function handlers.Smoke(_, racer)
	local position = behindPosition(racer, 14)
	local cloud = effectPart({
		Name = "SmokeCloud",
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * CFG.Smoke.Radius * 2,
		CFrame = CFrame.new(position + Vector3.new(0, 4, 0)),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(150, 150, 155),
		Transparency = 0.35,
	})
	dropHazard("Smoke", racer, cloud, CFG.Smoke.Lifetime, CFG.Smoke.Radius)
end

function handlers.Rocket(race, racer)
	local target = adjacentTarget(race, racer)
	if not target then
		notify(racer.Player, "No target for your rocket!")
		return
	end
	local rocket = effectPart({ Name = "Rocket", Size = Vector3.new(1, 1, 3), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 60, 30), CFrame = racer.Chassis.CFrame * CFrame.new(0, 3, 0) })
	notify(target.Player, "🚀 Incoming rocket from " .. racer.Player.DisplayName .. "!")
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < 3 and target.Active do
			local dt = RunService.Heartbeat:Wait()
			local goal = target.Chassis.Position + Vector3.new(0, 2, 0)
			local delta = goal - rocket.Position
			if delta.Magnitude < 6 then
				break
			end
			rocket.CFrame = CFrame.lookAt(rocket.Position + delta.Unit * math.min(delta.Magnitude, CFG.Rocket.Speed * dt), goal)
		end
		local position = rocket.Position
		rocket:Destroy()
		if target.Active then
			explosion(position)
			PowerUps.hit(target, racer, CFG.Rocket.StunTime, Vector3.new(math.random(-25, 25), 70, math.random(-25, 25)))
		end
	end)
end

function handlers.EMP(race, racer)
	local origin = racer.Chassis.Position
	local wave = effectPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, CFrame = CFrame.new(origin), Material = Enum.Material.ForceField, Color = Color3.fromRGB(80, 180, 255) })
	TweenService:Create(wave, TweenInfo.new(0.5), { Size = Vector3.one * CFG.EMP.Radius * 2, Transparency = 1 }):Play()
	Debris:AddItem(wave, 0.6)
	local hits = 0
	for _, other in race.Ordered do
		if other ~= racer and other.Active and flatDistance(other.Chassis.Position, origin) <= CFG.EMP.Radius then
			local away = flat(other.Chassis.Position - origin)
			away = if away.Magnitude > 0.1 then away.Unit else Vector3.zAxis
			if PowerUps.hit(other, racer, CFG.EMP.StunTime, away * 45 + Vector3.new(0, 30, 0), "⚡ EMP'd by " .. racer.Player.DisplayName .. "!") then
				hits += 1
			end
		end
	end
	notify(racer.Player, if hits > 0 then string.format("⚡ EMP hit %d racer(s)!", hits) else "⚡ EMP hit nobody...")
end

-- Rips a random stealable part off `from` and stacks it on `to`'s roof as a trophy.
local function moveStealablePart(from, to): string?
	local source = from.Car:FindFirstChild("Stealable")
	local destination = to.Car:FindFirstChild("Stealable")
	if not (source and destination) then
		return nil
	end
	local candidates = {}
	for _, child in source:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(candidates, child)
		end
	end
	if #candidates == 0 then
		return nil
	end
	local part = candidates[math.random(#candidates)]
	for _, child in part:GetChildren() do
		if child:IsA("WeldConstraint") then
			child:Destroy()
		end
	end
	local trophies = to.Car:GetAttribute("Trophies") or 0
	to.Car:SetAttribute("Trophies", trophies + 1)
	local roof = to.Car:GetAttribute("RoofY") - to.Car:GetAttribute("HalfHeight")
	part.CFrame = to.Chassis.CFrame * CFrame.new(0, roof + trophies * 0.7, 1) * CFrame.Angles(0, math.rad(trophies * 35), 0)
	CarBuilder.weld(part, to.Chassis)
	part.Parent = destination
	return part.Name
end

function handlers.Steal(race, racer)
	local cfg = CFG.Steal
	local target = targetAhead(race, racer, cfg.Range)
	if not target then
		local best = cfg.Range
		for _, other in race.Ordered do
			if other ~= racer and other.Active then
				local distance = flatDistance(other.Chassis.Position, racer.Chassis.Position)
				if distance <= best then
					best, target = distance, other
				end
			end
		end
	end
	if not target then
		notify(racer.Player, "Nobody close enough to rob!")
		return
	end
	if consumeShield(target) then
		return
	end
	target.Car:SetAttribute("SpeedFactor", math.max(cfg.MinFactor, target.Car:GetAttribute("SpeedFactor") * cfg.VictimFactor))
	racer.Car:SetAttribute("SpeedFactor", math.min(cfg.MaxFactor, racer.Car:GetAttribute("SpeedFactor") * cfg.ThiefFactor))
	racer.Steals += 1
	racer.Hits += 1
	target.TimesHit += 1
	local stolen = moveStealablePart(target, racer) or "horsepower"
	notify(racer.Player, "💰 You stole " .. target.Player.DisplayName .. "'s " .. stolen .. "!")
	notify(target.Player, "😡 " .. racer.Player.DisplayName .. " stole your " .. stolen .. "!")
end

function handlers.Shield(_, racer)
	racer.Car:SetAttribute("ShieldUntil", now() + CFG.Shield.Duration)
	local bubble = effectPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 16, CFrame = racer.Chassis.CFrame, Material = Enum.Material.ForceField, Color = Color3.fromRGB(90, 200, 255), Anchored = false, Massless = true })
	CarBuilder.weld(bubble, racer.Chassis)
	bubble.Parent = racer.Car
	task.spawn(function()
		while bubble.Parent and now() < (racer.Car:GetAttribute("ShieldUntil") or 0) do
			task.wait(0.1)
		end
		bubble:Destroy()
	end)
end

function handlers.Freeze(race, racer)
	local cfg = CFG.Freeze
	local target = targetAhead(race, racer, cfg.Range)
	if not target then
		notify(racer.Player, "Nobody ahead in range to freeze!")
		return
	end
	local beam = effectPart({ Size = Vector3.new(0.6, 0.6, (target.Chassis.Position - racer.Chassis.Position).Magnitude), CFrame = CFrame.lookAt((racer.Chassis.Position + target.Chassis.Position) / 2, target.Chassis.Position), Material = Enum.Material.Neon, Color = Color3.fromRGB(150, 230, 255) })
	Debris:AddItem(beam, 0.25)
	if PowerUps.slow(target, racer, cfg.Slow, cfg.Time, "❄️ Frozen by " .. racer.Player.DisplayName .. "!") then
		local ice = effectPart({ Size = target.Chassis.Size + Vector3.new(2, 2, 2), CFrame = target.Chassis.CFrame, Material = Enum.Material.Ice, Color = Color3.fromRGB(170, 225, 255), Transparency = 0.35, Anchored = false, Massless = true })
		CarBuilder.weld(ice, target.Chassis)
		ice.Parent = target.Car
		Debris:AddItem(ice, cfg.Time)
	end
end

function handlers.Hook(race, racer)
	local cfg = CFG.Hook
	local target = targetAhead(race, racer, cfg.Range)
	if not target then
		notify(racer.Player, "Nobody ahead in range to hook!")
		return
	end
	local direction = flat(target.Chassis.Position - racer.Chassis.Position)
	direction = if direction.Magnitude > 0.1 then direction.Unit else flat(racer.Chassis.CFrame.LookVector).Unit
	local chain = effectPart({ Size = Vector3.new(0.4, 0.4, (target.Chassis.Position - racer.Chassis.Position).Magnitude), CFrame = CFrame.lookAt((racer.Chassis.Position + target.Chassis.Position) / 2, target.Chassis.Position), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 60, 60) })
	Debris:AddItem(chain, 0.4)
	Remotes.Effect:FireClient(racer.Player, "Dash", direction * cfg.Speed)
	PowerUps.boost(racer, cfg.Boost, cfg.BoostTime)
	notify(target.Player, "🧲 " .. racer.Player.DisplayName .. " hooked onto you!")
end

function handlers.Tornado(_, racer)
	local position = behindPosition(racer, 16)
	local funnel = effectPart({
		Name = "Tornado",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(30, CFG.Tornado.Radius * 2, CFG.Tornado.Radius * 2),
		CFrame = CFrame.new(position + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Material = Enum.Material.ForceField,
		Color = Color3.fromRGB(180, 180, 190),
	})
	dropHazard("Tornado", racer, funnel, CFG.Tornado.Lifetime, CFG.Tornado.Radius)
end

function handlers.Jetpack(_, racer)
	local cfg = CFG.Jetpack
	PowerUps.boost(racer, cfg.SpeedBoost, cfg.Duration)
	racer.Car:SetAttribute("ShieldUntil", now() + cfg.Duration)
	racer.Car:SetAttribute("FlyUntil", now() + cfg.Duration)
end

function handlers.Laser(race, racer)
	local cfg = CFG.Laser
	local target = race.Ordered[1]
	if target == racer then
		target = race.Ordered[2]
	end
	if not (target and target.Active) then
		notify(racer.Player, "No one to laser!")
		return
	end
	notify(target.Player, "🛰️ ORBITAL LASER LOCKED ON YOU!")
	local beam = effectPart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(300, 3, 3), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 60), Transparency = 0.4 })
	task.spawn(function()
		local started = os.clock()
		while os.clock() - started < cfg.Warning and target.Active do
			beam.CFrame = CFrame.new(target.Chassis.Position + Vector3.new(0, 150, 0)) * CFrame.Angles(0, 0, math.rad(90))
			RunService.Heartbeat:Wait()
		end
		beam.Size = Vector3.new(300, 12, 12)
		beam.Transparency = 0
		Debris:AddItem(beam, 0.3)
		if target.Active then
			explosion(target.Chassis.Position)
			PowerUps.hit(target, racer, cfg.StunTime, Vector3.new(0, 60, 0))
		end
	end)
end

function handlers.BlackHole(race, racer)
	local cfg = CFG.BlackHole
	local origin = racer.Chassis.Position
	local hole = effectPart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 6, CFrame = CFrame.new(origin + Vector3.new(0, 10, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(40, 0, 70) })
	TweenService:Create(hole, TweenInfo.new(1), { Size = Vector3.one * 40, Transparency = 0.6 }):Play()
	Debris:AddItem(hole, 1.2)
	local hits = 0
	for place = 1, racer.Place - 1 do
		local other = race.Ordered[place]
		if other and other.Active and flatDistance(other.Chassis.Position, origin) <= cfg.Range then
			if PowerUps.hit(other, racer, cfg.StunTime, nil, "🕳️ Sucked into " .. racer.Player.DisplayName .. "'s black hole!") then
				PowerUps.slow(other, nil, cfg.Slow, cfg.SlowTime)
				hits += 1
			end
		end
	end
	notify(racer.Player, string.format("🕳️ Black hole caught %d racer(s)!", hits))
end

function PowerUps.use(race, racer)
	local id = racer.PowerUp
	if not id or not handlers[id] then
		return
	end
	PowerUps.give(racer, nil)
	handlers[id](race, racer)
end

-- Called ~10x per second by the race loop.
function PowerUps.update(race)
	local t = now()

	for _, pickup in race.Track.Pickups do
		if t >= pickup.ReadyAt then
			pickup.Part.Transparency = 0.15
			for _, racer in race.Ordered do
				if racer.Active and not racer.PowerUp and (racer.Chassis.Position - pickup.Position).Magnitude < 10 then
					local id = PowerUps.roll(race, racer)
					PowerUps.give(racer, id)
					local item = Items.ById[id]
					notify(racer.Player, item.Icon .. " Got " .. item.Name .. "! Press E to use")
					pickup.ReadyAt = t + Config.PickupRespawn
					pickup.Part.Transparency = 1
					break
				end
			end
		end
	end

	for i = #hazards, 1, -1 do
		local hazard = hazards[i]
		local remove = t > hazard.Expires
		if hazard.Kind == "Tornado" and not remove then
			hazard.Part.CFrame *= CFrame.Angles(0.5, 0, 0) -- spin
		end
		if not remove then
			for _, racer in race.Ordered do
				local safe = racer == hazard.Owner and t < hazard.SafeUntil
				if racer.Active and not safe and not hazard.HitRacers[racer] and flatDistance(racer.Chassis.Position, hazard.Part.Position) < hazard.Radius then
					hazard.HitRacers[racer] = true
					if hazard.Kind == "Oil" then
						PowerUps.hit(racer, hazard.Owner, CFG.Oil.StunTime, nil, "🛢️ You hit an oil slick!")
						remove = true
					elseif hazard.Kind == "Spikes" then
						PowerUps.hit(racer, hazard.Owner, CFG.Spikes.StunTime, Vector3.new(0, CFG.Spikes.Pop, 0), "📌 Spikes!")
						remove = true
					elseif hazard.Kind == "Smoke" then
						racer.Car:SetAttribute("BlindUntil", t + CFG.Smoke.BlindTime)
						PowerUps.slow(racer, hazard.Owner, CFG.Smoke.Slow, CFG.Smoke.SlowTime, "💨 Can't see!")
					elseif hazard.Kind == "Tornado" then
						PowerUps.hit(racer, hazard.Owner, CFG.Tornado.StunTime, Vector3.new(math.random(-20, 20), 75, math.random(-20, 20)), "🌪️ Caught in a tornado!")
					end
					if remove then
						break
					end
				end
			end
		end
		if remove then
			hazard.Part:Destroy()
			table.remove(hazards, i)
		end
	end
end

function PowerUps.reset(track)
	table.clear(hazards)
	effectsFolder:ClearAllChildren()
	for _, pickup in track.Pickups do
		pickup.ReadyAt = 0
		pickup.Part.Transparency = 0.15
	end
end

return PowerUps
