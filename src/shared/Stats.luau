-- The six Mario Kart-style stats (each 0-10) and how they turn into physics numbers.
local Stats = {}

Stats.Order = { "Speed", "Acceleration", "Weight", "Handling", "Traction", "MiniTurbo" }
Stats.Labels = {
	Speed = "Speed",
	Acceleration = "Acceleration",
	Weight = "Weight",
	Handling = "Handling",
	Traction = "Traction",
	MiniTurbo = "Mini-Turbo",
}
Stats.Max = 10

-- Base stats of a car plus upgrade bonuses, clamped to Stats.Max.
-- Returns (total, bonus) so the garage can draw the upgrade part of each bar separately.
function Stats.forCar(car, upgradeLevels, upgradeDefs)
	local total, bonus = {}, {}
	for _, name in Stats.Order do
		total[name] = car.Stats[name]
		bonus[name] = 0
	end
	if upgradeLevels and upgradeDefs then
		for _, upgrade in upgradeDefs do
			local level = upgradeLevels[upgrade.Id] or 0
			for statName, perLevel in upgrade.Boosts do
				local before = total[statName]
				total[statName] = math.min(Stats.Max, before + perLevel * level)
				bonus[statName] += total[statName] - before
			end
		end
	end
	return total, bonus
end

-- Stat bars -> physics. Speeds are studs/second.
function Stats.derive(s)
	return {
		TopSpeed = 70 + s.Speed * 10, -- 80 .. 170
		Accel = 25 + s.Acceleration * 8, -- how fast you reach top speed
		TurnRate = 1.4 + s.Handling * 0.22, -- radians/second at full lock
		Grip = 2.5 + s.Traction * 0.6, -- how fast sideways sliding stops
		OffroadFactor = 0.4 + s.Traction * 0.05, -- top-speed multiplier on grass/sand
		KnockbackScale = 1.3 - s.Weight * 0.06, -- heavy cars get thrown less
		Density = 0.4 + s.Weight * 0.15, -- heavy cars shove light ones
		TurboCharge = 0.7 + s.MiniTurbo * 0.1, -- drift charge speed
		TurboPower = 1.3 + s.MiniTurbo * 0.03, -- drift boost speed multiplier (1.33 .. 1.6)
	}
end

return Stats
