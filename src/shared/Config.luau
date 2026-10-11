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
	OffTrackRescue = 2.5, -- seconds lost off the road before you're put back
	StuckRescue = 4, -- seconds barely moving before you're put back
	DefaultWidth = 44,
}

-- Drifting (hold Space/Shift while turning) charges a Mini-Turbo.
Config.Drift = {
	MinSpeedFraction = 0.3, -- of top speed
	TierTimes = { 0.6, 1.3, 2.1 }, -- drift charge needed per tier (faster with Mini-Turbo stat)
	BoostTimes = { 0.9, 1.6, 2.5 }, -- boost length per tier
	Kick = { 12, 20, 30 }, -- instant speed added the moment you release
	Names = { "MINI-TURBO!", "SUPER MINI-TURBO!", "ULTRA MINI-TURBO!" },
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

-- Daily spin: one free spin every Cooldown seconds, plus extra spins from the store or
-- the wheel itself. Weights are relative chances.
Config.Spin = {
	Cooldown = 24 * 60 * 60,
	Prizes = {
		{ Kind = "Cash", Amount = 100, Weight = 30, Label = "$100", Color = Color3.fromRGB(90, 170, 255) },
		{ Kind = "Cash", Amount = 250, Weight = 25, Label = "$250", Color = Color3.fromRGB(80, 210, 120) },
		{ Kind = "Cash", Amount = 500, Weight = 18, Label = "$500", Color = Color3.fromRGB(255, 200, 40) },
		{ Kind = "Spin", Amount = 1, Weight = 8, Label = "+1 SPIN", Color = Color3.fromRGB(200, 90, 255) },
		{ Kind = "Cash", Amount = 1000, Weight = 10, Label = "$1,000", Color = Color3.fromRGB(255, 140, 40) },
		{ Kind = "Car", Amount = 1, Weight = 2, Label = "MYSTERY CAR", Color = Color3.fromRGB(255, 70, 90) },
		{ Kind = "Cash", Amount = 2500, Weight = 6, Label = "$2,500", Color = Color3.fromRGB(40, 200, 200) },
		{ Kind = "Cash", Amount = 10000, Weight = 1, Label = "JACKPOT", Color = Color3.fromRGB(255, 230, 0) },
	},
}

-- In-game purchases (Robux). Create each as a Developer Product on the Creator Dashboard
-- (Monetization -> Developer Products) and paste its ID here. 0 = not set up yet.
Config.Store = {
	{ ProductId = 0, Kind = "Cash", Amount = 2500, Label = "$2,500", Price = "R$ 25" },
	{ ProductId = 0, Kind = "Cash", Amount = 10000, Label = "$10,000", Price = "R$ 79" },
	{ ProductId = 0, Kind = "Cash", Amount = 50000, Label = "$50,000", Price = "R$ 299" },
	{ ProductId = 0, Kind = "Spins", Amount = 3, Label = "3 Spins", Price = "R$ 35" },
	{ ProductId = 0, Kind = "Spins", Amount = 10, Label = "10 Spins", Price = "R$ 99" },
}

-- 2x Cash game pass (Creator Dashboard -> Passes). 0 = disabled.
Config.Monetization = {
	DoubleCashPassId = 0,
}

return Config
