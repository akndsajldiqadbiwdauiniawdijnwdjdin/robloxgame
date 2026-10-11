-- All tunable game numbers live here. Speeds are in studs/second.
local Config = {}

Config.Race = {
	Laps = 3, -- default; a track can override it
	MinPlayers = 1, -- set to 2+ for live servers; 1 lets you test solo
	MaxPlayers = 16,
	IntermissionTime = 15,
	CountdownTime = 3,
	MaxRaceTime = 300,
	FinishGraceTime = 30, -- everyone else gets this long after the winner crosses the line
	ResultsTime = 7,
	ResetCooldown = 3,
}

Config.Rewards = {
	Placement = { 600, 400, 250, 150 }, -- 1st, 2nd, 3rd, 4th
	Finish = 100, -- finished, but 5th or worse
	DNF = 25,
	PerSteal = 50,
}

Config.Track = {
	SampleSpacing = 10, -- studs between track samples
	ProgressSearch = 80, -- how many samples ahead progress can jump (allows shortcuts)
	FallDistance = 18, -- reset if this far below the track
	DefaultWidth = 44,
}

-- Drifting (hold Space/Shift while turning) charges a Mini-Turbo.
Config.Drift = {
	MinSpeedFraction = 0.35, -- of top speed
	TierTimes = { 0.9, 1.8, 2.8 }, -- seconds of drifting (scaled by Mini-Turbo stat)
	BoostTimes = { 0.6, 1.1, 1.7 }, -- boost length per tier
	TierColors = {
		Color3.fromRGB(80, 170, 255), -- blue
		Color3.fromRGB(255, 150, 30), -- orange
		Color3.fromRGB(200, 80, 255), -- purple
	},
}

Config.BoostPad = { Duration = 1.2, SpeedBoost = 1.5 }

-- Upgrades are global (they apply to whichever car is equipped) and add stat points.
Config.Upgrades = {
	{ Id = "Engine", Name = "Engine", Boosts = { Speed = 0.4 }, MaxLevel = 5, BaseCost = 500 },
	{ Id = "Turbo", Name = "Turbo", Boosts = { Acceleration = 0.4, MiniTurbo = 0.3 }, MaxLevel = 5, BaseCost = 400 },
	{ Id = "Tires", Name = "Tires", Boosts = { Handling = 0.3, Traction = 0.4 }, MaxLevel = 5, BaseCost = 400 },
}

function Config.upgradeCost(upgrade, currentLevel: number): number
	return math.floor(upgrade.BaseCost * 2 ^ currentLevel)
end

Config.PowerUps = {
	Nitro = { Name = "Nitro", Icon = "🔥", Weight = 30, Duration = 2.5, SpeedBoost = 1.6 },
	Oil = { Name = "Oil Slick", Icon = "🛢️", Weight = 25, Lifetime = 20, StunTime = 1.5 },
	Rocket = { Name = "Rocket", Icon = "🚀", Weight = 20, StunTime = 1.5, Speed = 260 },
	EMP = { Name = "EMP Blast", Icon = "⚡", Weight = 15, Radius = 70, StunTime = 1.2 },
	Steal = {
		Name = "Steal Part",
		Icon = "💰",
		Weight = 20,
		Range = 120,
		VictimFactor = 0.88, -- victim keeps 88% of their speed for the rest of the race
		ThiefFactor = 1.08,
		MinFactor = 0.6,
		MaxFactor = 1.4,
	},
}
Config.PowerUpOrder = { "Nitro", "Oil", "Rocket", "EMP", "Steal" }
-- Racers in the back half of the pack get these weights multiplied (rubber-banding).
Config.CatchUpPowerUps = { Rocket = 2, Steal = 2 }
Config.PickupRespawn = 6

-- Fill these in after creating the passes/products on the Creator Dashboard. 0 = disabled.
Config.Monetization = {
	DoubleCashPassId = 0,
	CashProducts = {
		-- [productId] = cash amount, e.g. [123456789] = 5000,
	},
}

return Config
