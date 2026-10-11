-- Levels, the 7-day daily reward, item rolls and the rotating daily shop. Shared so the
-- server (which decides) and the client (which displays) always agree.
local Emotes = require(script.Parent.Emotes)
local Items = require(script.Parent.Items)

local Progression = {}

-- Levels ---------------------------------------------------------------------------

function Progression.xpForLevel(level: number): number
	return 100 + (level - 1) * 50
end

-- Returns level, xp into this level, xp needed for the next level.
function Progression.levelFromXP(xp: number): (number, number, number)
	local level = 1
	while xp >= Progression.xpForLevel(level) do
		xp -= Progression.xpForLevel(level)
		level += 1
	end
	return level, xp, Progression.xpForLevel(level)
end

-- Daily reward -----------------------------------------------------------------------

Progression.Daily = {
	Cooldown = 20 * 60 * 60, -- can claim again 20h after the last claim
	StreakReset = 48 * 60 * 60, -- miss more than 48h and the streak restarts at day 1
	Rewards = {
		{ Kind = "Coins", Amount = 50 },
		{ Kind = "Coins", Amount = 100 },
		{ Kind = "Coins", Amount = 150 },
		{ Kind = "Roll", Amount = 1 },
		{ Kind = "Coins", Amount = 150 },
		{ Kind = "Coins", Amount = 200 },
		{ Kind = "Item", Rarity = "Epic", Amount = 1 },
	},
}

-- Which day (1..7) the next claim is, given the saved streak and last claim time.
function Progression.nextDailyDay(streak: number, lastClaim: number, now: number): number
	if lastClaim > 0 and now - lastClaim > Progression.Daily.StreakReset then
		return 1
	end
	return streak % #Progression.Daily.Rewards + 1
end

-- Item rolls -------------------------------------------------------------------------

Progression.Rolls = {
	CoinPrice = 1000,
	PityEpic = 20, -- an Epic or better within this many rolls
	PityMythic = 60, -- a Mythic within this many rolls
}

-- Picks a rarity. `random` is a Random object; counters are rolls since the last Epic+
-- and since the last Mythic (before this roll).
function Progression.rollRarity(random: Random, sinceEpic: number, sinceMythic: number): string
	if sinceMythic + 1 >= Progression.Rolls.PityMythic then
		return "Mythic"
	end
	local roll = random:NextNumber()
	local rarity = "Common"
	local cumulative = 0
	for index = #Items.RarityOrder, 1, -1 do -- check the rarest first
		local name = Items.RarityOrder[index]
		cumulative += Items.Rarities[name].Rate
		if roll < cumulative then
			rarity = name
			break
		end
	end
	if sinceEpic + 1 >= Progression.Rolls.PityEpic and Items.Rarities[rarity].Order < Items.Rarities.Epic.Order then
		rarity = "Epic"
	end
	return rarity
end

-- Daily shop -------------------------------------------------------------------------

function Progression.dayNumber(unixTime: number): number
	return math.floor(unixTime / 86400)
end

function Progression.secondsUntilTomorrow(unixTime: number): number
	return 86400 - unixTime % 86400
end

-- Today's offers: four regular slots (items + an emote) and one discounted featured
-- Epic/Mythic. The same day always gives the same offers on server and client.
function Progression.dailyOffers(day: number)
	local random = Random.new(day * 7919 + 17)
	local offers = {}
	local pool = {}
	for _, item in Items.List do
		if not table.find(Items.Starter, item.Id) and item.Rarity ~= "Mythic" then
			table.insert(pool, item)
		end
	end
	for _ = 1, 3 do
		local item = table.remove(pool, random:NextInteger(1, #pool))
		table.insert(offers, { Kind = "Item", Id = item.Id, Price = Items.Rarities[item.Rarity].Price })
	end
	local emotePool = {}
	for _, emote in Emotes.List do
		if emote.Price > 0 then
			table.insert(emotePool, emote)
		end
	end
	local emote = emotePool[random:NextInteger(1, #emotePool)]
	table.insert(offers, { Kind = "Emote", Id = emote.Id, Price = emote.Price })

	local featuredPool = {}
	for _, item in Items.List do
		if item.Rarity == "Mythic" or item.Rarity == "Epic" then
			table.insert(featuredPool, item)
		end
	end
	local featured = featuredPool[random:NextInteger(1, #featuredPool)]
	table.insert(offers, { Kind = "Item", Id = featured.Id, Price = math.floor(Items.Rarities[featured.Rarity].Price * 0.75), Featured = true })
	return offers
end

return Progression
