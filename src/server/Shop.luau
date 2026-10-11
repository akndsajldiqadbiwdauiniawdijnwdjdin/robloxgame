-- Everything you can spend or claim, validated on the server (never trust the client):
-- cars, upgrades, the daily shop, item rolls (with pity), loadout, and the daily reward.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cars = require(ReplicatedStorage.Shared.Cars)
local Config = require(ReplicatedStorage.Shared.Config)
local Emotes = require(ReplicatedStorage.Shared.Emotes)
local Items = require(ReplicatedStorage.Shared.Items)
local Progression = require(ReplicatedStorage.Shared.Progression)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)

local Shop = {}

local lastRequest = {}
local random = Random.new()

local upgradesById = {}
for _, upgrade in Config.Upgrades do
	upgradesById[upgrade.Id] = upgrade
end

local function loadoutSlots(player: Player): number
	return Items.LoadoutSlots + (if player:GetAttribute("Pass_VIP") then 1 else 0)
end

-- One item roll. Returns a result table for the client's reveal animation.
local function rollOnce(data)
	local rarity = Progression.rollRarity(random, data.RollsSinceEpic, data.RollsSinceMythic)
	local pool = Items.ofRarity(rarity)
	local item = pool[random:NextInteger(1, #pool)]
	local order = Items.Rarities[rarity].Order
	data.RollsSinceEpic = if order >= Items.Rarities.Epic.Order then 0 else data.RollsSinceEpic + 1
	data.RollsSinceMythic = if rarity == "Mythic" then 0 else data.RollsSinceMythic + 1
	local duplicate = data.OwnedItems[item.Id] == true
	if duplicate then
		data.Cash += Items.Rarities[rarity].Refund
	else
		data.OwnedItems[item.Id] = true
	end
	return { Id = item.Id, Rarity = rarity, Duplicate = duplicate, Refund = if duplicate then Items.Rarities[rarity].Refund else 0 }
end
Shop.rollOnce = rollOnce

local actions = {}

function actions.BuyCar(_, data, id)
	local car = Cars.ById[id]
	if not car then
		return false, "Unknown car"
	end
	if data.OwnedCars[id] then
		return false, "You already own that"
	end
	if data.Cash < car.Price then
		return false, "Not enough coins"
	end
	data.Cash -= car.Price
	data.OwnedCars[id] = true
	data.Equipped = id
	return true, "Bought the " .. car.Name .. "!"
end

function actions.Equip(_, data, id)
	local car = Cars.ById[id]
	if not (car and data.OwnedCars[id]) then
		return false, "You don't own that car"
	end
	data.Equipped = id
	return true, car.Name .. " equipped (next race)"
end

-- Motorcycles: flip between inside and outside drift.
function actions.BikeDrift(_, data, id)
	local car = Cars.ById[id]
	if not (car and car.Bike) then
		return false, "Only motorcycles can change drift type"
	end
	local current = data.BikeDrift[id] or car.Drift
	local new = if current == "Inside" then "Outside" else "Inside"
	data.BikeDrift[id] = if new == car.Drift then nil else new
	return true, car.Name .. ": " .. string.upper(new) .. " drift"
end

function actions.Upgrade(_, data, id)
	local upgrade = upgradesById[id]
	if not upgrade then
		return false, "Unknown upgrade"
	end
	local level = data.Upgrades[id] or 0
	if level >= upgrade.MaxLevel then
		return false, "Already maxed"
	end
	local cost = Config.upgradeCost(upgrade, level)
	if data.Cash < cost then
		return false, "Not enough coins"
	end
	data.Cash -= cost
	data.Upgrades[id] = level + 1
	return true, string.format("%s upgraded to level %d", upgrade.Name, level + 1)
end

-- Daily shop: id is the offer index ("1".."5").
function actions.BuyOffer(_, data, id)
	local today = Progression.dayNumber(os.time())
	local index = tonumber(id)
	local offer = index and Progression.dailyOffers(today)[index]
	if not offer then
		return false, "That offer is gone"
	end
	if data.ShopDay ~= today then
		data.ShopDay = today
		data.ShopBought = {}
	end
	local owned = if offer.Kind == "Item" then data.OwnedItems[offer.Id] else data.OwnedEmotes[offer.Id]
	if owned then
		return false, "You already own that"
	end
	if data.Cash < offer.Price then
		return false, "Not enough coins"
	end
	data.Cash -= offer.Price
	if offer.Kind == "Item" then
		data.OwnedItems[offer.Id] = true
	else
		data.OwnedEmotes[offer.Id] = true
	end
	table.insert(data.ShopBought, offer.Id)
	local name = if offer.Kind == "Item" then Items.ById[offer.Id].Name else Emotes.ById[offer.Id].Name
	return true, "Bought " .. name .. "!"
end

-- One roll: uses a roll token if you have one, otherwise coins.
function actions.Roll(_, data, _id)
	if data.RollTokens > 0 then
		data.RollTokens -= 1
	elseif data.Cash >= Progression.Rolls.CoinPrice then
		data.Cash -= Progression.Rolls.CoinPrice
	else
		return false, "Not enough coins"
	end
	local result = rollOnce(data)
	local item = Items.ById[result.Id]
	local message = if result.Duplicate
		then string.format("Duplicate %s (+%d coins)", item.Name, result.Refund)
		else string.format("NEW %s: %s!", string.upper(result.Rarity), item.Name)
	return true, message, result
end

-- id is a JSON array of item ids.
function actions.SetLoadout(player, data, id)
	local ok, list = pcall(HttpService.JSONDecode, HttpService, id)
	if not ok or typeof(list) ~= "table" then
		return false, "Bad loadout"
	end
	local clean = {}
	for _, itemId in list do
		if typeof(itemId) == "string" and data.OwnedItems[itemId] and not table.find(clean, itemId) then
			table.insert(clean, itemId)
		end
	end
	if #clean == 0 then
		return false, "Pick at least one item"
	end
	if #clean > loadoutSlots(player) then
		return false, "Too many items (" .. loadoutSlots(player) .. " slots)"
	end
	data.Loadout = clean
	return true, "Loadout saved"
end

function actions.ClaimDaily(_, data, _id)
	local nowTime = os.time()
	if data.LastDailyClaim > 0 and nowTime - data.LastDailyClaim < Progression.Daily.Cooldown then
		return false, "Come back later!"
	end
	local day = Progression.nextDailyDay(data.DailyStreak, data.LastDailyClaim, nowTime)
	local reward = Progression.Daily.Rewards[day]
	data.DailyStreak = day
	data.LastDailyClaim = nowTime
	if reward.Kind == "Coins" then
		data.Cash += reward.Amount
		return true, string.format("Day %d: +%d coins!", day, reward.Amount)
	elseif reward.Kind == "Roll" then
		data.RollTokens += reward.Amount
		return true, string.format("Day %d: +%d free item roll!", day, reward.Amount)
	else
		local pool = Items.ofRarity(reward.Rarity)
		local unowned = {}
		for _, item in pool do
			if not data.OwnedItems[item.Id] then
				table.insert(unowned, item)
			end
		end
		if #unowned == 0 then
			data.Cash += Items.Rarities[reward.Rarity].Refund * 2
			return true, string.format("Day %d: you own every %s item, +%d coins!", day, reward.Rarity, Items.Rarities[reward.Rarity].Refund * 2)
		end
		local item = unowned[random:NextInteger(1, #unowned)]
		data.OwnedItems[item.Id] = true
		return true, string.format("Day %d: FREE %s item: %s!", day, string.upper(reward.Rarity), item.Name)
	end
end

function Shop.init()
	Remotes.Shop.OnServerInvoke = function(player, action, id)
		if typeof(action) ~= "string" or typeof(id) ~= "string" or not actions[action] then
			return false, "Bad request"
		end
		if os.clock() - (lastRequest[player] or 0) < 0.2 then
			return false, "Slow down"
		end
		lastRequest[player] = os.clock()

		local ok, message, extra = false, "Data not loaded yet", nil
		PlayerData.update(player, function(data)
			ok, message, extra = actions[action](player, data, id)
		end)
		return ok, message, extra
	end

	Players.PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return Shop
