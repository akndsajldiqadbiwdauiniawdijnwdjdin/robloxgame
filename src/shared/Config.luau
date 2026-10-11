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
	CheckpointEvery = 8, -- invisible system checkpoint every N samples (~80 studs)
	OutOfBoundsMargin = 6, -- studs past the barrier before you're out of bounds
	OutOfBoundsDelay = 0.3, -- seconds out of bounds before the rescue
	OffTrackRescue = 1.5, -- seconds on the wrong part of the map before you're put back
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

-- Tuning for every item (see shared/Items.luau for names/rarities and
-- server/PowerUps.luau for what they do).
Config.PowerUps = {
	Nitro = { Duration = 2.5, SpeedBoost = 1.6 },
	Oil = { Lifetime = 20, StunTime = 1.5 },
	Spikes = { Lifetime = 20, StunTime = 1.0, Pop = 30 },
	Smoke = { Lifetime = 10, Radius = 16, BlindTime = 2.5, Slow = 0.8, SlowTime = 1.5 },
	Rocket = { StunTime = 1.5, Speed = 260 },
	EMP = { Radius = 60, StunTime = 1.2 },
	Steal = { Range = 120, VictimFactor = 0.88, ThiefFactor = 1.08, MinFactor = 0.6, MaxFactor = 1.4 },
	Shield = { Duration = 8 },
	Freeze = { Range = 220, Time = 1.8, Slow = 0.15 },
	Hook = { Range = 260, Speed = 150, Boost = 1.4, BoostTime = 1.5 },
	Tornado = { Lifetime = 7, Radius = 14, StunTime = 1.4 },
	Jetpack = { Duration = 3, SpeedBoost = 1.9 },
	Laser = { Warning = 1.2, StunTime = 2 },
	BlackHole = { Range = 320, StunTime = 1.5, Slow = 0.5, SlowTime = 2 },
}
-- Racers in the back half get rarer items from their loadout more often.
Config.CatchUpRarityBonus = 2
Config.PickupRespawn = 6

-- Car signature abilities (each car's Ability in Cars.luau). Tuning:
Config.Abilities = {
	DuctTape = { Boost = 1.35, BoostTime = 1.2 },
	Hop = { Up = 45, Kick = 12 },
	DriftKing = { Duration = 6, ChargeMultiplier = 3 },
	DuneJump = { Up = 55, Forward = 70 },
	Ram = { Duration = 1.6, Boost = 1.5, Radius = 10, StunTime = 1 },
	Jingle = { Radius = 45, Slow = 0.6, Time = 2.5 },
	Siren = { Range = 140, Slow = 0.75, Time = 3 },
	Stomp = { Radius = 35, StunTime = 1 },
	Afterburner = { Boost = 1.75, Time = 2.2 },
	Blink = { Samples = 6 },
}

-- Racing XP (levels) per race.
Config.XP = { Finish = 50, PerPlaceAhead = 15, PerHit = 10, PerSteal = 10, VIPMultiplier = 1.5 }

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
	{ ProductId = 0, Kind = "Cash", Amount = 2500, Label = "2,500 Coins", Price = 25 },
	{ ProductId = 0, Kind = "Cash", Amount = 10000, Label = "10,000 Coins", Price = 79 },
	{ ProductId = 0, Kind = "Cash", Amount = 50000, Label = "50,000 Coins", Price = 299 },
	{ ProductId = 0, Kind = "Spins", Amount = 3, Label = "3 Spins", Price = 35 },
	{ ProductId = 0, Kind = "Rolls", Amount = 1, Label = "1 Item Roll", Price = 35, Was = 59 },
	{ ProductId = 0, Kind = "Rolls", Amount = 10, Label = "10 Item Rolls", Price = 415, Was = 590 },
}

-- Game passes (Creator Dashboard -> Passes). 0 = not set up yet.
Config.Passes = {
	{ Key = "DoubleCoins", Name = "2x Coins", Icon = "💰", Description = "Double coins from every race.", PassId = 0, Price = 199 },
	{ Key = "VIP", Name = "VIP", Icon = "👑", Description = "+1 loadout slot and 1.5x XP.", PassId = 0, Price = 299 },
}

-- Music + engine sound. Find tracks in the Creator Store (Audio, filter to Roblox/APM's
-- free licensed library), copy the number from the asset URL and paste it here.
-- 0 = off. Sound effects use built-in Roblox sounds and need no ids (shared/Sounds).
Config.Audio = {
	LobbyMusic = 0,
	RaceMusic = { 0 }, -- one is picked at random each race; add as many as you like
	ResultsMusic = 0,
	EngineLoop = 0, -- a looping engine/motor sound; pitch follows your speed
	MusicVolume = 0.3,
	EngineVolume = 0.35,
}

return Config
