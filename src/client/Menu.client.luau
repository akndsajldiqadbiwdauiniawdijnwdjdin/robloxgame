-- Lobby menus: Shop (Daily Shop / Item Rolls / Loadout / Passes), the 7-day Daily Reward
-- and the emote wheel (B). All purchases go through Remotes.Shop and are checked by the
-- server (server/Shop.luau).
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Emotes = require(Shared:WaitForChild("Emotes"))
local Items = require(Shared:WaitForChild("Items"))
local Progression = require(Shared:WaitForChild("Progression"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))
local UI = require(Shared:WaitForChild("UI"))

local C = UI.Colors
local new, text = UI.new, UI.text
local player = Players.LocalPlayer

local WIDTH, HEIGHT = 1100, 600

local function decode(attribute: string, fallback)
	local raw = player:GetAttribute(attribute)
	if not raw then
		return fallback
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then value else fallback
end

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function duration(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return string.format("%dh %dm", seconds // 3600, seconds % 3600 // 60)
	end
	return string.format("%dm %ds", seconds // 60, seconds % 60)
end

local gui = new("ScreenGui", { Name = "Menus", ResetOnSpawn = false, DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

-- Toast for purchase results.
local toast = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.fromOffset(520, 40), BackgroundTransparency = 0, BackgroundColor3 = C.Bar, TextColor3 = C.White, FontFace = UI.FontHeavy, Text = "", Visible = false, ZIndex = 80, Parent = gui })
local toastToken = 0
local function showToast(message: string, ok: boolean?)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.BackgroundColor3 = if ok == false then C.Red else C.Bar
	toast.Visible = true
	task.delay(2.5, function()
		if token == toastToken then
			toast.Visible = false
		end
	end)
end

local function request(action: string, id: string)
	local ok, message, extra = Remotes.Shop:InvokeServer(action, id)
	showToast(tostring(message), ok)
	return ok, extra
end

local function promptProduct(item)
	if item.ProductId == 0 then
		showToast("This product isn't set up yet (Config.Store)", false)
		return
	end
	MarketplaceService:PromptProductPurchase(player, item.ProductId)
end

local function storeItem(kind: string, amount: number)
	for _, item in Config.Store do
		if item.Kind == kind and item.Amount == amount then
			return item
		end
	end
	return nil
end

-- Coin price button: cream with a coin, or mint for Robux.
local function priceButton(parent: Instance, props, coins: number?, robux: number?)
	local button = UI.button(props, if robux then "Mint" else "Cream")
	button.Text = ""
	local row = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Parent = button })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), Parent = row })
	if coins then
		UI.coin(row, 24)
	end
	text({ LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), TextScaled = false, TextSize = 26, FontFace = UI.FontHeavy, Text = if robux then "R$ " .. robux else UI.formatNumber(coins or 0), Parent = row })
	button.Parent = parent
	return button
end

-- Side menu buttons ---------------------------------------------------------------------

local shopButton, shopBadge = UI.sideButton(player, "SHOP", "🛒", 2)
local dailyButton, dailyBadge = UI.sideButton(player, "DAILY", "🎁", 3)
local emoteButton = UI.sideButton(player, "EMOTES", "🕺", 5)

-- Shop window -------------------------------------------------------------------------------

local window = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(WIDTH, HEIGHT), BackgroundColor3 = C.Cream, BorderSizePixel = 0, Visible = false, Parent = gui })
UI.exclusive(window)
UI.autoScale(window, WIDTH, HEIGHT)
local content = new("Frame", { Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 1, -70), BackgroundTransparency = 1, Parent = window })
new("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 18), PaddingBottom = UDim.new(0, 18), Parent = content })

local currentTab = "Daily Shop"
local renderTab -- forward declaration
local _, selectTab, tabBar = UI.tabBar(window, { "Daily Shop", "Item Rolls", "Loadout", "Passes" }, function(name)
	currentTab = name
	renderTab()
end)
local barCoins = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -86, 0.5, 0), Size = UDim2.fromOffset(180, 40), BackgroundTransparency = 1, Parent = tabBar })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), Parent = barCoins })
UI.coin(barCoins, 34)
local barCoinLabel = text({ LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 40), TextScaled = false, TextSize = 36, TextColor3 = C.White, FontFace = UI.FontHeavy, Text = "0", Parent = barCoins })
local closeButton = UI.button({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(56, 50), Text = "X", BackgroundColor3 = C.Red, TextColor3 = C.White, Parent = tabBar }, "Cream")

local function header(parent: Instance, left: string, right: string?, order: number?)
	local bar = new("Frame", { LayoutOrder = order or 0, Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Parent = parent })
	text({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(0.5, -14, 0, 28), Text = left, TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Left, Parent = bar })
	if right then
		text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 8), Size = UDim2.new(0.5, -14, 0, 28), Text = right, TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Right, Parent = bar })
	end
	return bar
end

local function iconTile(parent: Instance, icon: string, tint: Color3, props)
	local tile = new("Frame", props, {})
	tile.BackgroundColor3 = tint:Lerp(C.Cream, 0.7)
	tile.BorderSizePixel = 0
	tile.Parent = parent
	UI.brackets(tile, tint, 6)
	text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), Text = icon, Parent = tile })
	return tile
end

-- Daily Shop tab.
local function renderDailyShop()
	local today = Progression.dayNumber(workspace:GetServerTimeNow())
	local offers = Progression.dailyOffers(today)
	local ownedItems = decode("OwnedItems", {})
	local ownedEmotes = decode("OwnedEmotes", {})
	local leaves = "Leaves in " .. duration(Progression.secondsUntilTomorrow(workspace:GetServerTimeNow()))

	local left = new("Frame", { Size = UDim2.new(0.68, -10, 1, 0), BackgroundTransparency = 1, Parent = content })
	header(left, "Today", leaves)
	local row = new("Frame", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 300), BackgroundTransparency = 1, Parent = left })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = row })

	local function offerCard(parent, index, offer, featured)
		local owned = if offer.Kind == "Item" then ownedItems[offer.Id] else ownedEmotes[offer.Id]
		local name, sub, icon, tint
		if offer.Kind == "Item" then
			local item = Items.ById[offer.Id]
			name, sub, icon, tint = item.Name, item.Rarity .. " Item", item.Icon, Items.Rarities[item.Rarity].Color
		else
			local emote = Emotes.ById[offer.Id]
			name, sub, icon, tint = emote.Name, "Emote", "🕺", Color3.fromRGB(120, 120, 130)
		end
		local card = new("Frame", { Size = if featured then UDim2.fromScale(1, 1) else UDim2.new(0.25, -8, 1, 0), BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Parent = parent })
		iconTile(card, icon, tint, { Position = UDim2.fromOffset(12, 12), Size = if featured then UDim2.new(1, -24, 0, 260) else UDim2.new(1, -24, 0, 140) })
		local top = if featured then 284 else 160
		text({ Position = UDim2.fromOffset(10, top), Size = UDim2.new(1, -20, 0, if featured then 40 else 30), Text = name, FontFace = UI.FontHeavy, Parent = card })
		text({ Position = UDim2.fromOffset(10, top + (if featured then 40 else 30)), Size = UDim2.new(1, -20, 0, 22), Text = if featured then sub .. "  ·  25% OFF" else sub, TextColor3 = C.Muted, FontFace = UI.FontRegular, Parent = card })
		local button
		if owned then
			button = UI.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 56), Text = "OWNED", Parent = card }, "Disabled")
		else
			button = priceButton(card, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.new(1, -24, 0, 56) }, offer.Price)
			button.Activated:Connect(function()
				if request("BuyOffer", tostring(index)) then
					renderTab()
				end
			end)
		end
		return card
	end
	for index = 1, 4 do
		offerCard(row, index, offers[index], false)
	end

	-- Coin packs (Robux).
	local packHeader = header(left, "Coin Packs", "Robux")
	packHeader.Position = UDim2.fromOffset(0, 372)
	local packs = new("Frame", { Position = UDim2.fromOffset(0, 426), Size = UDim2.new(1, 0, 0, 80), BackgroundTransparency = 1, Parent = left })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = packs })
	for _, item in Config.Store do
		if item.Kind == "Cash" then
			local pack = new("Frame", { Size = UDim2.new(1 / 3, -7, 1, 0), BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Parent = packs })
			text({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(0.5, -12, 1, -12), Text = item.Label, FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = pack })
			local buy = priceButton(pack, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0.45, 0, 0, 50) }, nil, item.Price)
			buy.Activated:Connect(function()
				promptProduct(item)
			end)
		end
	end

	local right = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.32, -10, 1, 0), BackgroundTransparency = 1, Parent = content })
	header(right, "Featured", leaves)
	local featuredHolder = new("Frame", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1, Parent = right })
	offerCard(featuredHolder, 5, offers[5], true)
end

-- Item Rolls tab.
local rollReveal -- forward declaration
local function renderRolls()
	local owned = decode("OwnedItems", {})
	local scroll = new("ScrollingFrame", { Size = UDim2.new(0.66, -10, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = content })
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })
	for order = #Items.RarityOrder, 1, -1 do
		local rarityName = Items.RarityOrder[order]
		local rarity = Items.Rarities[rarityName]
		local list = Items.ofRarity(rarityName)
		local ownedCount = 0
		for _, item in list do
			if owned[item.Id] then
				ownedCount += 1
			end
		end
		local section = new("Frame", { LayoutOrder = 10 - order, Size = UDim2.new(1, -10, 0, 210), BackgroundTransparency = 1, Parent = scroll })
		new("Frame", { Size = UDim2.new(0, 6, 0, 52), BackgroundColor3 = rarity.Color, BorderSizePixel = 0, Parent = section })
		text({ Position = UDim2.fromOffset(16, 0), Size = UDim2.fromOffset(300, 32), Text = rarityName, FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = section })
		text({ Position = UDim2.fromOffset(16, 32), Size = UDim2.fromOffset(400, 22), Text = string.format("%g%% of rolls  ·  %d/%d owned", rarity.Rate * 100, ownedCount, #list), TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Left, Parent = section })
		local tiles = new("Frame", { Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 140), BackgroundTransparency = 1, Parent = section })
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = tiles })
		for _, item in list do
			local tile = iconTile(tiles, item.Icon, rarity.Color, { Size = UDim2.fromOffset(150, 140) })
			text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -6), Size = UDim2.new(1, -12, 0, 22), Text = item.Name, FontFace = UI.FontHeavy, Parent = tile })
			text({ Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(90, 18), Text = if owned[item.Id] then "✓ Owned" else "Not owned", BackgroundTransparency = 0, BackgroundColor3 = C.Cream, TextColor3 = if owned[item.Id] then Color3.fromRGB(20, 150, 80) else C.Muted, Parent = tile })
		end
	end
	text({ LayoutOrder = 20, Size = UDim2.new(1, -10, 0, 24), Text = "Rolled items go into your Loadout pool. Duplicates refund coins.", TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Left, Parent = scroll })

	-- Right column: bundle with pity bars + single roll.
	local right = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.34, -10, 1, 0), BackgroundTransparency = 1, Parent = content })
	local bundle = new("Frame", { Size = UDim2.new(1, 0, 0, 290), BackgroundColor3 = C.Cream, BorderSizePixel = 0, Parent = right }, { UI.stroke(C.Ink, 2) })
	text({ Position = UDim2.fromOffset(14, -16), Size = UDim2.fromOffset(170, 32), BackgroundTransparency = 0, BackgroundColor3 = C.Bar, TextColor3 = C.White, FontFace = UI.FontHeavy, Text = "Bundle & Save", Parent = bundle })
	text({ Position = UDim2.fromOffset(16, 24), Size = UDim2.fromOffset(160, 36), Text = "10 Rolls", FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = bundle })
	text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 30), Size = UDim2.fromOffset(120, 24), Text = "Save 30%", TextColor3 = C.Muted, TextXAlignment = Enum.TextXAlignment.Right, Parent = bundle })
	local sinceEpic = player:GetAttribute("RollsSinceEpic") or 0
	local sinceMythic = player:GetAttribute("RollsSinceMythic") or 0
	for index, bar in {
		{ "Guaranteed Epic", Progression.Rolls.PityEpic - sinceEpic, sinceEpic / Progression.Rolls.PityEpic, Items.Rarities.Epic.Color },
		{ "Guaranteed Mythic", Progression.Rolls.PityMythic - sinceMythic, sinceMythic / Progression.Rolls.PityMythic, Items.Rarities.Mythic.Color },
	} do
		local y = 70 + (index - 1) * 64
		text({ Position = UDim2.fromOffset(16, y), Size = UDim2.new(0.6, -16, 0, 26), Text = bar[1], TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Left, Parent = bundle })
		text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, y), Size = UDim2.new(0.4, -16, 0, 26), Text = "in " .. bar[2] .. " rolls", TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Right, Parent = bundle })
		local track = new("Frame", { Position = UDim2.fromOffset(16, y + 30), Size = UDim2.new(1, -32, 0, 14), BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Parent = bundle })
		new("Frame", { Size = UDim2.fromScale(math.clamp(bar[3], 0, 1), 1), BackgroundColor3 = bar[4], BorderSizePixel = 0, Parent = track })
	end
	local tenRolls = storeItem("Rolls", 10)
	local tenButton = priceButton(bundle, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -32, 0, 64) }, nil, if tenRolls then tenRolls.Price else 0)
	tenButton.Activated:Connect(function()
		if tenRolls then
			promptProduct(tenRolls)
		end
	end)

	local single = new("Frame", { Position = UDim2.fromOffset(0, 306), Size = UDim2.new(1, 0, 0, 170), BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Parent = right })
	text({ Position = UDim2.fromOffset(16, 10), Size = UDim2.fromOffset(160, 36), Text = "1 Roll", FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = single })
	local tokens = player:GetAttribute("RollTokens") or 0
	local oneRoll = storeItem("Rolls", 1)
	local robuxButton = priceButton(single, { Position = UDim2.fromOffset(16, 56), Size = UDim2.new(0.5, -22, 0, 60) }, nil, if oneRoll then oneRoll.Price else 0)
	robuxButton.Activated:Connect(function()
		if oneRoll then
			promptProduct(oneRoll)
		end
	end)
	local coinButton
	if tokens > 0 then
		coinButton = UI.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 56), Size = UDim2.new(0.5, -22, 0, 60), Text = "ROLL (" .. tokens .. " free)" }, "Mint")
		coinButton.Parent = single
	else
		coinButton = priceButton(single, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 56), Size = UDim2.new(0.5, -22, 0, 60) }, Progression.Rolls.CoinPrice)
	end
	text({ Position = UDim2.fromOffset(16, 124), Size = UDim2.new(1, -32, 0, 24), Text = "You have " .. UI.formatNumber(player:GetAttribute("Cash") or 0) .. " coins", TextColor3 = C.Muted, FontFace = UI.FontRegular, Parent = single })
	coinButton.Activated:Connect(function()
		local ok, result = request("Roll", "1")
		if ok and result then
			rollReveal(result)
			renderTab()
		end
	end)
end

-- Loadout tab.
local function renderLoadout()
	local owned = decode("OwnedItems", {})
	local loadout = decode("Loadout", {})
	local slotsCount = Items.LoadoutSlots + (if player:GetAttribute("Pass_VIP") then 1 else 0)

	header(content, "Your loadout: item boxes only give you these items", string.format("%d/%d slots", #loadout, slotsCount))
	local slotRow = new("Frame", { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1, Parent = content })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), Parent = slotRow })
	for index = 1, slotsCount do
		local item = Items.ById[loadout[index] or ""]
		local slot = new("TextButton", { Size = UDim2.fromOffset(150, 120), BackgroundColor3 = if item then Items.Rarities[item.Rarity].Color:Lerp(C.Cream, 0.6) else C.CreamDark, BorderSizePixel = 0, Text = "", Parent = slotRow })
		UI.brackets(slot, C.Ink, 6)
		text({ Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 60), Text = if item then item.Icon else "+", TextColor3 = C.Muted, Parent = slot })
		text({ Position = UDim2.fromOffset(8, 74), Size = UDim2.new(1, -16, 0, 26), Text = if item then item.Name else "Empty", FontFace = UI.FontHeavy, Parent = slot })
		if item then
			slot.Activated:Connect(function()
				table.remove(loadout, index)
				if #loadout == 0 then
					showToast("Keep at least one item in your loadout", false)
					return
				end
				if request("SetLoadout", HttpService:JSONEncode(loadout)) then
					renderTab()
				end
			end)
		end
	end
	text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 92), Size = UDim2.fromOffset(330, 24), Text = "Click a slot to remove · click an item to add", TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Right, Parent = content })

	local grid = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 1, -190), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = content })
	new("UIGridLayout", { CellSize = UDim2.fromOffset(250, 96), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = grid })
	for index, item in Items.List do
		local isOwned = owned[item.Id] == true
		local equipped = table.find(loadout, item.Id) ~= nil
		local card = new("TextButton", { LayoutOrder = index, BackgroundColor3 = if equipped then C.Mint else C.CreamDark, BorderSizePixel = 0, Text = "", AutoButtonColor = isOwned, Parent = grid })
		new("Frame", { Size = UDim2.new(0, 6, 1, 0), BackgroundColor3 = Items.Rarities[item.Rarity].Color, BorderSizePixel = 0, Parent = card })
		text({ Position = UDim2.fromOffset(14, 8), Size = UDim2.fromOffset(50, 50), Text = if isOwned then item.Icon else "🔒", Parent = card })
		text({ Position = UDim2.fromOffset(70, 6), Size = UDim2.new(1, -78, 0, 26), Text = item.Name, FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		text({ Position = UDim2.fromOffset(70, 32), Size = UDim2.new(1, -78, 0, 56), Text = item.Description, TextColor3 = C.Muted, FontFace = UI.FontRegular, TextScaled = false, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = card })
		card.Activated:Connect(function()
			if not isOwned then
				showToast("Get " .. item.Name .. " from Item Rolls or the Daily Shop", false)
				return
			end
			local position = table.find(loadout, item.Id)
			if position then
				table.remove(loadout, position)
			elseif #loadout >= slotsCount then
				showToast("Loadout full: remove an item first", false)
				return
			else
				table.insert(loadout, item.Id)
			end
			if #loadout == 0 then
				showToast("Keep at least one item in your loadout", false)
				return
			end
			if request("SetLoadout", HttpService:JSONEncode(loadout)) then
				renderTab()
			end
		end)
	end
end

-- Passes tab.
local function renderPasses()
	local row = new("Frame", { Size = UDim2.new(1, 0, 0, 380), BackgroundTransparency = 1, Parent = content })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), Parent = row })
	for _, pass in Config.Passes do
		local owned = player:GetAttribute("Pass_" .. pass.Key) == true
		local card = UI.panel({ Size = UDim2.fromOffset(300, 380), BackgroundColor3 = C.CreamDark, Parent = row })
		text({ Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -40, 0, 140), Text = pass.Icon, Parent = card })
		text({ Position = UDim2.fromOffset(20, 170), Size = UDim2.new(1, -40, 0, 44), Text = pass.Name, FontFace = UI.FontHeavy, Parent = card })
		text({ Position = UDim2.fromOffset(20, 216), Size = UDim2.new(1, -40, 0, 60), Text = pass.Description, TextColor3 = C.Muted, FontFace = UI.FontRegular, TextWrapped = true, TextScaled = false, TextSize = 20, Parent = card })
		if owned then
			UI.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(1, -40, 0, 60), Text = "OWNED", Parent = card }, "Disabled")
		else
			local buy = priceButton(card, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(1, -40, 0, 60) }, nil, pass.Price)
			buy.Activated:Connect(function()
				if pass.PassId == 0 then
					showToast("This pass isn't set up yet (Config.Passes)", false)
					return
				end
				MarketplaceService:PromptGamePassPurchase(player, pass.PassId)
			end)
		end
	end
end

function renderTab()
	clear(content)
	barCoinLabel.Text = UI.formatNumber(player:GetAttribute("Cash") or 0)
	if currentTab == "Daily Shop" then
		renderDailyShop()
	elseif currentTab == "Item Rolls" then
		renderRolls()
	elseif currentTab == "Loadout" then
		renderLoadout()
	else
		renderPasses()
	end
end

-- Roll reveal popup.
local reveal = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4, Visible = false, ZIndex = 60, Parent = gui })
local revealCard = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, 420), ZIndex = 61, Parent = reveal })
local revealRarity = text({ Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -40, 0, 34), FontFace = UI.FontHeavy, ZIndex = 62, Text = "", Parent = revealCard })
local revealIcon = text({ Position = UDim2.fromOffset(20, 64), Size = UDim2.new(1, -40, 0, 190), ZIndex = 62, Text = "", Parent = revealCard })
local revealName = text({ Position = UDim2.fromOffset(20, 262), Size = UDim2.new(1, -40, 0, 44), FontFace = UI.FontHeavy, ZIndex = 62, Text = "", Parent = revealCard })
local revealNote = text({ Position = UDim2.fromOffset(20, 308), Size = UDim2.new(1, -40, 0, 26), TextColor3 = C.Muted, ZIndex = 62, Text = "", Parent = revealCard })
local revealOk = UI.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(1, -40, 0, 56), Text = "Nice!", ZIndex = 62, Parent = revealCard }, "Mint")
revealOk.Activated:Connect(function()
	reveal.Visible = false
end)
function rollReveal(result)
	local item = Items.ById[result.Id]
	local rarity = Items.Rarities[result.Rarity]
	revealCard.BackgroundColor3 = rarity.Color:Lerp(C.Cream, 0.75)
	revealRarity.Text = string.upper(result.Rarity)
	revealRarity.TextColor3 = rarity.Color
	revealIcon.Text = item.Icon
	revealName.Text = item.Name
	revealNote.Text = if result.Duplicate then "Duplicate: +" .. result.Refund .. " coins" else "NEW! Added to your items"
	reveal.Visible = true
	if rarity.Order >= Items.Rarities.Epic.Order then
		Sounds.play("Victory", 1 + rarity.Order * 0.05)
	else
		Sounds.play("Beep", 1 + rarity.Order * 0.2)
	end
	revealIcon.Size = UDim2.new(1, -40, 0, 20)
	TweenService:Create(revealIcon, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(1, -40, 0, 190) }):Play()
end

shopButton.Activated:Connect(function()
	window.Visible = not window.Visible
	if window.Visible then
		selectTab(currentTab)
	end
end)
closeButton.Activated:Connect(function()
	window.Visible = false
end)
for _, attribute in { "Cash", "OwnedItems", "Loadout", "OwnedEmotes", "RollTokens", "RollsSinceEpic" } do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if window.Visible then
			renderTab()
		end
	end)
end

-- Daily reward popup ---------------------------------------------------------------------

local daily = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(940, 600), Visible = false, Parent = gui })
UI.exclusive(daily)
UI.autoScale(daily, 940, 600)
text({ Position = UDim2.fromOffset(32, 26), Size = UDim2.fromOffset(500, 64), Text = "Daily Reward", FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = daily })
local dailyClose = UI.button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 20), Size = UDim2.fromOffset(50, 46), Text = "X", BackgroundColor3 = C.Red, TextColor3 = C.White }, "Cream")
dailyClose.Parent = daily
text({ Position = UDim2.fromOffset(32, 110), Size = UDim2.fromOffset(500, 34), Text = "Play every day for the best rewards!", TextColor3 = C.Muted, FontFace = UI.FontRegular, TextXAlignment = Enum.TextXAlignment.Left, Parent = daily })
local daysLabel = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -32, 0, 110), Size = UDim2.fromOffset(200, 34), Text = "0/7 Days", FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Right, Parent = daily })
local streakTrack = new("Frame", { Position = UDim2.fromOffset(32, 152), Size = UDim2.new(1, -64, 0, 12), BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Parent = daily })
local streakFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Mint, BorderSizePixel = 0, Parent = streakTrack })
local dayRow = new("Frame", { Position = UDim2.fromOffset(32, 190), Size = UDim2.new(1, -64, 0, 270), BackgroundTransparency = 1, Parent = daily })
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), Parent = dayRow })
local claimButton = UI.button({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.new(1, -64, 0, 76), Text = "Claim" }, "Mint")
claimButton.Parent = daily

local function claimState()
	local serverNow = workspace:GetServerTimeNow()
	local streak = player:GetAttribute("DailyStreak") or 0
	local last = player:GetAttribute("LastDailyClaim") or 0
	local nextDay = Progression.nextDailyDay(streak, last, serverNow)
	local wait = if last == 0 then 0 else math.max(0, last + Progression.Daily.Cooldown - serverNow)
	local claimedThisCycle = if nextDay == 1 and wait <= 0 then 0 else streak
	return nextDay, wait, claimedThisCycle
end

local function renderDaily()
	clear(dayRow)
	local nextDay, wait, claimed = claimState()
	daysLabel.Text = string.format("%d/7 Days", claimed)
	streakFill.Size = UDim2.fromScale(claimed / 7, 1)
	for day, reward in Progression.Daily.Rewards do
		local isNext = day == nextDay
		local done = day <= claimed and not (isNext and wait <= 0)
		local card = new("Frame", { Size = UDim2.new(1 / 7, -9, 1, 0), BackgroundColor3 = if isNext and wait <= 0 then Color3.fromRGB(215, 255, 235) else C.CreamDark, BorderSizePixel = 0, Parent = dayRow })
		if isNext and wait <= 0 then
			new("UIStroke", { Color = C.Mint, Thickness = 2, Parent = card })
		end
		local tag = if done then "Claimed" elseif isNext and wait <= 0 then "Today" elseif isNext then "Next" else "Soon"
		text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(84, 30), BackgroundTransparency = 0, BackgroundColor3 = if tag == "Today" then C.Mint else C.Cream, Text = tag, FontFace = UI.FontHeavy, Parent = card })
		text({ Position = UDim2.fromOffset(6, 26), Size = UDim2.new(1, -12, 0, 34), Text = "Day " .. day, FontFace = UI.FontHeavy, Parent = card })
		local kind = if reward.Kind == "Coins" then "Coins" elseif reward.Kind == "Roll" then "Item Roll" else "Free " .. reward.Rarity
		text({ Position = UDim2.fromOffset(6, 60), Size = UDim2.new(1, -12, 0, 24), Text = kind, TextColor3 = C.Muted, FontFace = UI.FontRegular, Parent = card })
		local iconHolder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(70, 70), BackgroundTransparency = 1, Parent = card })
		if reward.Kind == "Coins" then
			UI.coin(iconHolder, 70)
		else
			text({ Size = UDim2.fromScale(1, 1), Text = if reward.Kind == "Roll" then "🎲" else "🎁", Parent = iconHolder })
		end
		text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.new(1, -24, 0, 46), BackgroundTransparency = 0, BackgroundColor3 = C.Cream, Text = (if done then "✓" else "+" .. reward.Amount), FontFace = UI.FontHeavy, Parent = card })
	end
	if wait <= 0 then
		claimButton.Text = "Claim"
		UI.setButtonStyle(claimButton, "Mint")
	else
		claimButton.Text = "Come back in " .. duration(wait)
		UI.setButtonStyle(claimButton, "Disabled")
	end
	dailyBadge.Visible = wait <= 0
end

claimButton.Activated:Connect(function()
	local _, wait = claimState()
	if wait > 0 then
		return
	end
	if request("ClaimDaily", "") then
		task.wait(0.2)
		renderDaily()
	end
end)
dailyButton.Activated:Connect(function()
	daily.Visible = not daily.Visible
	renderDaily()
end)
dailyClose.Activated:Connect(function()
	daily.Visible = false
end)
player:GetAttributeChangedSignal("LastDailyClaim"):Connect(renderDaily)
-- Pop the daily reward up when you join and it's ready.
task.delay(4, function()
	local _, wait = claimState()
	if wait <= 0 and player:GetAttribute("Place") == nil then
		daily.Visible = true
	end
	renderDaily()
end)

-- Emote wheel (B) ---------------------------------------------------------------------------

local wheel = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 440), BackgroundTransparency = 1, Visible = false, Parent = gui })
local wheelCenter = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(150, 150), BackgroundTransparency = 0.3, BackgroundColor3 = C.Bar, TextColor3 = C.White, FontFace = UI.FontHeavy, Text = "Emotes", Parent = wheel })
new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = wheelCenter })
UI.closeButton(wheel).Position = UDim2.new(1, 0, 0, 0)
UI.exclusive(wheel)
local currentTrack: AnimationTrack? = nil

local function playEmote(emoteId: string)
	local emote = Emotes.ById[emoteId]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not (emote and animator) or player:GetAttribute("Place") ~= nil then
		return
	end
	if currentTrack then
		currentTrack:Stop()
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = emote.Animation
	currentTrack = animator:LoadAnimation(animation)
	currentTrack:Play()
	wheel.Visible = false
end

local function ownedEmoteList(): { string }
	local owned = decode("OwnedEmotes", {})
	local list = {}
	for _, emote in Emotes.List do
		if owned[emote.Id] and #list < 8 then
			table.insert(list, emote.Id)
		end
	end
	return list
end

local function renderWheel()
	for _, child in wheel:GetChildren() do
		if child ~= wheelCenter and child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local list = ownedEmoteList()
	for slot = 1, 8 do
		local angle = (slot - 1) / 8 * math.pi * 2
		local position = UDim2.new(0.5, math.sin(angle) * 170, 0.5, -math.cos(angle) * 170)
		local emoteId = list[slot]
		local emote = emoteId and Emotes.ById[emoteId]
		local button = new("TextButton", { AnchorPoint = Vector2.new(0.5, 0.5), Position = position, Size = UDim2.fromOffset(110, 70), BackgroundColor3 = if emote then C.Cream else C.CreamDark, BackgroundTransparency = if emote then 0 else 0.4, BorderSizePixel = 0, Text = "", Parent = wheel })
		UI.brackets(button, C.Line, 4)
		text({ Position = UDim2.fromOffset(6, 4), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 0, BackgroundColor3 = C.Bar, TextColor3 = C.White, Text = tostring(slot), FontFace = UI.FontHeavy, Parent = button })
		text({ Position = UDim2.fromOffset(6, 28), Size = UDim2.new(1, -12, 0, 34), Text = if emote then emote.Name else "None", FontFace = UI.FontHeavy, TextColor3 = if emote then C.Ink else C.Muted, Parent = button })
		if emote then
			button.Activated:Connect(function()
				playEmote(emote.Id)
			end)
		end
	end
end

local function toggleWheel()
	if player:GetAttribute("Place") ~= nil then
		return
	end
	wheel.Visible = not wheel.Visible
	if wheel.Visible then
		renderWheel()
	end
end
emoteButton.Activated:Connect(toggleWheel)
ContextActionService:BindAction("EmoteWheel", function(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		toggleWheel()
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.B)
ContextActionService:BindAction("EmoteSlot", function(_, inputState, input)
	if inputState ~= Enum.UserInputState.Begin or not wheel.Visible then
		return Enum.ContextActionResult.Pass
	end
	local slot = input.KeyCode.Value - Enum.KeyCode.One.Value + 1
	local emoteId = ownedEmoteList()[slot]
	if emoteId then
		playEmote(emoteId)
	end
	return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight)

-- Hide lobby menus while racing; keep badges fresh ------------------------------------------

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
	local racing = player:GetAttribute("Place") ~= nil
	local side = player.PlayerGui:FindFirstChild("SideMenu")
	if side then
		side.Enabled = not racing
	end
	if racing then
		window.Visible = false
		daily.Visible = false
		wheel.Visible = false
	end
	accumulator += dt
	if accumulator > 1 then
		accumulator = 0
		local _, wait = claimState()
		dailyBadge.Visible = wait <= 0
		shopBadge.Visible = (player:GetAttribute("RollTokens") or 0) > 0
		if daily.Visible then
			renderDaily()
		end
	end
end)
