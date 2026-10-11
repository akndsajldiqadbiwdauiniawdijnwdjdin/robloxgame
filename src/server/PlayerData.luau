-- Loads/saves player progress and mirrors it into attributes + leaderstats for the UI.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cars = require(ReplicatedStorage.Shared.Cars)
local Config = require(ReplicatedStorage.Shared.Config)
local Emotes = require(ReplicatedStorage.Shared.Emotes)
local Items = require(ReplicatedStorage.Shared.Items)
local Progression = require(ReplicatedStorage.Shared.Progression)

local STORE_NAME = "IllegalRacing_v1"
local AUTOSAVE_INTERVAL = 120

local PlayerData = {}

local profiles = {} -- [Player] = { Data = table, CanSave = boolean }

local store
do
	local ok, result = pcall(DataStoreService.GetDataStore, DataStoreService, STORE_NAME)
	if ok then
		store = result
	else
		warn("[PlayerData] DataStores unavailable (enable Studio API access to save):", result)
	end
end

local function template()
	return {
		Cash = 0,
		Wins = 0,
		Races = 0,
		OwnedCars = { Beater = true },
		Equipped = "Beater",
		Upgrades = {},
		Purchases = {}, -- processed developer-product receipt ids
		Spins = 0, -- extra wheel spins (bought or won)
		LastFreeSpin = 0, -- unix time of the last free daily spin
		XP = 0,
		OwnedItems = { Nitro = true, Oil = true, Rocket = true },
		Loadout = table.clone(Items.Starter), -- item ids that item boxes can give you
		OwnedEmotes = { Wave = true, Point = true, Cheer = true },
		RollTokens = 0, -- item rolls bought with Robux / won from daily rewards
		RollsSinceEpic = 0, -- pity counters
		RollsSinceMythic = 0,
		DailyStreak = 0, -- days claimed in the current 7-day cycle
		LastDailyClaim = 0,
		ShopDay = 0, -- daily shop: offers bought today
		ShopBought = {},
		BikeDrift = {}, -- [bikeId] = "Inside" | "Outside" (only when changed from the default)
	}
end

local function reconcile(data)
	local defaults = template()
	for key, value in defaults do
		if data[key] == nil then
			data[key] = value
		end
	end
	local validLoadout = {}
	for _, id in data.Loadout do
		if Items.ById[id] and data.OwnedItems[id] and not table.find(validLoadout, id) then
			table.insert(validLoadout, id)
		end
	end
	data.Loadout = if #validLoadout > 0 then validLoadout else table.clone(Items.Starter)
	if not Cars.ById[data.Equipped] or not data.OwnedCars[data.Equipped] then
		data.Equipped = "Beater"
	end
	return data
end

local function key(player: Player)
	return "p_" .. player.UserId
end

local function publish(player: Player, data)
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("Equipped", data.Equipped)
	player:SetAttribute("BikeDrift", HttpService:JSONEncode(data.BikeDrift))
	player:SetAttribute("OwnedCars", HttpService:JSONEncode(data.OwnedCars))
	player:SetAttribute("Spins", data.Spins)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("Level", (Progression.levelFromXP(data.XP)))
	player:SetAttribute("OwnedItems", HttpService:JSONEncode(data.OwnedItems))
	player:SetAttribute("Loadout", HttpService:JSONEncode(data.Loadout))
	player:SetAttribute("OwnedEmotes", HttpService:JSONEncode(data.OwnedEmotes))
	player:SetAttribute("RollTokens", data.RollTokens)
	player:SetAttribute("RollsSinceEpic", data.RollsSinceEpic)
	player:SetAttribute("RollsSinceMythic", data.RollsSinceMythic)
	player:SetAttribute("DailyStreak", data.DailyStreak)
	player:SetAttribute("LastDailyClaim", data.LastDailyClaim)
	player:SetAttribute("ShopBought", HttpService:JSONEncode(if data.ShopDay == Progression.dayNumber(os.time()) then data.ShopBought else {}))
	player:SetAttribute("NextFreeSpin", data.LastFreeSpin + Config.Spin.Cooldown)
	for _, upgrade in Config.Upgrades do
		player:SetAttribute("Upg_" .. upgrade.Id, data.Upgrades[upgrade.Id] or 0)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Cash.Value = data.Cash
		leaderstats.Wins.Value = data.Wins
	end
end

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	for _, name in { "Cash", "Wins" } do
		local value = Instance.new("IntValue")
		value.Name = name
		value.Parent = leaderstats
	end
	leaderstats.Parent = player
end

function PlayerData.load(player: Player)
	local data
	local canSave = store ~= nil

	if store then
		local ok, result
		for attempt = 1, 3 do
			ok, result = pcall(store.GetAsync, store, key(player))
			if ok then
				break
			end
			task.wait(attempt)
		end
		if ok then
			data = result
		else
			-- Never overwrite real data we failed to read.
			canSave = false
			warn("[PlayerData] Failed to load", player.Name, result)
		end
	end

	if not player.Parent then
		return
	end

	data = reconcile(data or template())
	profiles[player] = { Data = data, CanSave = canSave }
	createLeaderstats(player)
	publish(player, data)
end

function PlayerData.save(player: Player)
	local profile = profiles[player]
	if not (profile and profile.CanSave and store) then
		return
	end
	local ok, err = pcall(store.SetAsync, store, key(player), profile.Data)
	if not ok then
		warn("[PlayerData] Failed to save", player.Name, err)
	end
end

function PlayerData.get(player: Player)
	local profile = profiles[player]
	return profile and profile.Data
end

-- Mutate a player's data and push the change to their UI.
function PlayerData.update(player: Player, mutate: (any) -> ())
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	mutate(data)
	publish(player, data)
	return true
end

-- Adds race earnings, applying the 2x cash game pass. Returns the amount actually given.
function PlayerData.addCash(player: Player, amount: number): number
	if player:GetAttribute("Pass_DoubleCoins") then
		amount *= 2
	end
	PlayerData.update(player, function(data)
		data.Cash += amount
	end)
	return amount
end

function PlayerData.init()
	Players.PlayerAdded:Connect(PlayerData.load)
	for _, player in Players:GetPlayers() do
		task.spawn(PlayerData.load, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		PlayerData.save(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				PlayerData.save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in profiles do
				task.spawn(PlayerData.save, player)
			end
		end
	end)
end

return PlayerData
