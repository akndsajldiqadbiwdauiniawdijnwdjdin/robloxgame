-- Garage: browse cars with a spinning 3D preview and Mario Kart-style stat bars, buy and
-- equip cars, and buy upgrades. Purchases are validated on the server (server/Shop).
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CarBody = require(Shared:WaitForChild("CarBody"))
local Cars = require(Shared:WaitForChild("Cars"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Stats = require(Shared:WaitForChild("Stats"))
local UI = require(Shared:WaitForChild("UI"))
local C = UI.Colors

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WIDTH, HEIGHT = 870, 510
local NAVY = C.Cream
local CARD = C.CreamDark
local TEAL = Color3.fromRGB(24, 104, 124)
local BAR_BG = Color3.fromRGB(9, 44, 56)
local YELLOW = Color3.fromRGB(255, 214, 0)
local BONUS = Color3.fromRGB(255, 140, 0)
local ORANGE = C.Mint
local GREEN = C.Mint
local GREY = C.Line

local function create(className: string, props, children: { Instance }?)
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			instance[key] = value
		end
	end
	for _, child in children or {} do
		child.Parent = instance
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

local function corner(radius: number?)
	return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) })
end

local function text(props, isButton: boolean?)
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = UI.FontHeavy,
		TextColor3 = C.Ink,
		TextStrokeTransparency = 1,
		TextScaled = true,
		AutoButtonColor = if isButton then true else nil,
	}
	for key, value in props do
		defaults[key] = value
	end
	return create(if isButton then "TextButton" else "TextLabel", defaults)
end

local function formatCash(amount: number): string
	local formatted = tostring(math.floor(amount))
	while true do
		local replaced, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = replaced
		if count == 0 then
			break
		end
	end
	return formatted .. " coins"
end

local function owned(): { [string]: boolean }
	return HttpService:JSONDecode(player:GetAttribute("OwnedCars") or "{}")
end

local function upgradeLevels(): { [string]: number }
	local levels = {}
	for _, upgrade in Config.Upgrades do
		levels[upgrade.Id] = player:GetAttribute("Upg_" .. upgrade.Id) or 0
	end
	return levels
end

-- Layout -------------------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "Garage",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local openButton = UI.sideButton(player, "GARAGE", "🛠", 1)

local window = create("Frame", {
	Name = "Window",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	BackgroundColor3 = NAVY,
	BackgroundTransparency = 0.04,
	Visible = false,
	Parent = gui,
})
UI.brackets(window)
local scale = create("UIScale", { Parent = window })

text({ Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(170, 38), Text = "GARAGE", TextColor3 = C.Ink, TextXAlignment = Enum.TextXAlignment.Left, Parent = window })
local carsTab = text({ Position = UDim2.fromOffset(200, 14), Size = UDim2.fromOffset(110, 34), Text = "CARS", BackgroundTransparency = 0, Parent = window }, true)
local upgradesTab = text({ Position = UDim2.fromOffset(318, 14), Size = UDim2.fromOffset(140, 34), Text = "UPGRADES", BackgroundTransparency = 0, Parent = window }, true)
corner().Parent = carsTab
corner().Parent = upgradesTab
local cashLabel = text({ Position = UDim2.fromOffset(480, 14), Size = UDim2.fromOffset(300, 34), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(200, 140, 0), Parent = window })
local closeButton = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(38, 38), Text = "✕", BackgroundTransparency = 0, BackgroundColor3 = C.CreamDark, Parent = window }, true)
corner().Parent = closeButton

local list = create("ScrollingFrame", {
	Position = UDim2.fromOffset(14, 64),
	Size = UDim2.new(0, 260, 1, -78),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 6,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = window,
}, { create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

-- Middle: preview + name + buy button.
local middle = create("Frame", { Position = UDim2.fromOffset(286, 64), Size = UDim2.new(0, 300, 1, -78), BackgroundTransparency = 1, Parent = window })
local viewport = create("ViewportFrame", {
	Size = UDim2.new(1, 0, 0, 250),
	BackgroundColor3 = Color3.fromRGB(8, 18, 30),
	Ambient = Color3.fromRGB(170, 170, 180),
	LightColor = Color3.new(1, 1, 1),
	LightDirection = Vector3.new(-1, -1.5, -0.8),
	Parent = middle,
}, { corner(10) })
local viewportCamera = create("Camera", { FieldOfView = 40, Parent = viewport })
viewport.CurrentCamera = viewportCamera
local nameLabel = text({ Position = UDim2.fromOffset(0, 258), Size = UDim2.new(1, 0, 0, 36), Parent = middle })
local descriptionLabel = text({
	Position = UDim2.fromOffset(0, 296),
	Size = UDim2.new(1, 0, 0, 74),
	FontFace = UI.FontRegular,
	TextScaled = false,
	TextSize = 16,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextColor3 = C.Muted,
	TextStrokeTransparency = 1,
	Parent = middle,
})
local actionButton = text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 54), BackgroundTransparency = 0, Parent = middle }, true)
corner(10).Parent = actionButton
local toast = text({ Position = UDim2.fromOffset(8, 6), Size = UDim2.new(1, -16, 0, 22), FontFace = UI.Font, Text = "", ZIndex = 5, Parent = middle })

-- Right: Mario Kart-style stat panel.
local statPanel = create("Frame", {
	Position = UDim2.fromOffset(600, 64),
	Size = UDim2.new(0, 256, 1, -78),
	BackgroundColor3 = TEAL,
	BackgroundTransparency = 0.1,
	Parent = window,
}, {
	corner(10),
	create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 10) }),
	create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
})

local statBars = {}
for index, statName in Stats.Order do
	text({ LayoutOrder = index * 2, Size = UDim2.new(1, 0, 0, 26), Text = Stats.Labels[statName], TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0, Parent = statPanel })
	local bar = create("Frame", { LayoutOrder = index * 2 + 1, Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = BAR_BG, ClipsDescendants = true, Parent = statPanel }, { corner(4) })
	local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = YELLOW, BorderSizePixel = 0, Parent = bar })
	local bonus = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = BONUS, BorderSizePixel = 0, Parent = bar })
	for segment = 1, Stats.Max - 1 do
		create("Frame", {
			Position = UDim2.new(segment / Stats.Max, -1, 0, 0),
			Size = UDim2.new(0, 2, 1, 0),
			BackgroundColor3 = BAR_BG,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = bar,
		})
	end
	statBars[statName] = { Fill = fill, Bonus = bonus }
end
text({ LayoutOrder = 100, Size = UDim2.new(1, 0, 0, 18), Text = "orange = your upgrades", FontFace = UI.Font, TextColor3 = BONUS, TextStrokeTransparency = 1, Parent = statPanel })

-- State + rendering --------------------------------------------------------------

local tab = "Cars"
local selectedId = player:GetAttribute("Equipped") or Cars.Default
local previewId = nil
local previewAngle = 0
local listItems = {}

local function showToast(message: string, ok: boolean)
	toast.Text = message
	toast.TextColor3 = if ok then Color3.fromRGB(20, 150, 80) else C.Red
	task.delay(2.5, function()
		if toast.Text == message then
			toast.Text = ""
		end
	end)
end

local function request(action: string, id: string)
	local ok, message = Remotes.Shop:InvokeServer(action, id)
	showToast(tostring(message), ok)
end

local function setPreview(car)
	if previewId == car.Id then
		return
	end
	previewId = car.Id
	viewport:ClearAllChildren()
	corner(10).Parent = viewport
	viewportCamera = create("Camera", { FieldOfView = 40, Parent = viewport })
	viewport.CurrentCamera = viewportCamera
	local model = CarBody.build(car, CFrame.new(), false)
	model.Parent = viewport
end

local function updateStats(car)
	local total, bonus = Stats.forCar(car, upgradeLevels(), Config.Upgrades)
	for statName, bar in statBars do
		local base = total[statName] - bonus[statName]
		bar.Fill.Size = UDim2.fromScale(base / Stats.Max, 1)
		bar.Bonus.Position = UDim2.fromScale(base / Stats.Max, 0)
		bar.Bonus.Size = UDim2.fromScale(bonus[statName] / Stats.Max, 1)
	end
end

local function clearList()
	for _, item in listItems do
		item:Destroy()
	end
	table.clear(listItems)
end

local refresh -- defined below; card clicks call it

local function buildCarList()
	clearList()
	local ownedCars = owned()
	local equipped = player:GetAttribute("Equipped")
	for index, car in Cars.List do
		local card = text({ LayoutOrder = index, Size = UDim2.new(1, -8, 0, 56), BackgroundTransparency = 0, BackgroundColor3 = CARD, Text = "", Parent = list }, true)
		corner().Parent = card
		if car.Id == selectedId then
			create("UIStroke", { Color = C.Ink, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
		end
		create("Frame", { Position = UDim2.fromOffset(6, 8), Size = UDim2.fromOffset(8, 40), BackgroundColor3 = car.Colors.Primary, Parent = card }, { corner(3) })
		text({ Position = UDim2.fromOffset(22, 6), Size = UDim2.new(1, -30, 0, 24), Text = car.Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		local status, color
		if car.Id == equipped then
			status, color = "EQUIPPED", Color3.fromRGB(20, 150, 80)
		elseif ownedCars[car.Id] then
			status, color = "OWNED", C.Blue
		else
			status, color = formatCash(car.Price), Color3.fromRGB(200, 140, 0)
		end
		text({ Position = UDim2.fromOffset(22, 31), Size = UDim2.new(1, -30, 0, 18), Text = status, TextColor3 = color, FontFace = UI.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = card })
		card.Activated:Connect(function()
			selectedId = car.Id
			refresh() -- updates the list, preview, name and stat bars
		end)
		table.insert(listItems, card)
	end

	local car = Cars.ById[selectedId] or Cars.List[1]
	local cash = player:GetAttribute("Cash") or 0
	if car.Id == equipped then
		actionButton.Text, actionButton.BackgroundColor3 = "EQUIPPED", GREY
	elseif ownedCars[car.Id] then
		actionButton.Text, actionButton.BackgroundColor3 = "EQUIP", GREEN
	else
		actionButton.Text = "BUY  " .. formatCash(car.Price)
		actionButton.BackgroundColor3 = if cash >= car.Price then ORANGE else GREY
	end
end

local function buildUpgradeList()
	clearList()
	local cash = player:GetAttribute("Cash") or 0
	local levels = upgradeLevels()
	for index, upgrade in Config.Upgrades do
		local row = create("Frame", { LayoutOrder = index, Size = UDim2.new(1, -8, 0, 96), BackgroundColor3 = CARD, Parent = list }, { corner() })
		text({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 24), Text = upgrade.Name, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local boosts = {}
		for statName, perLevel in upgrade.Boosts do
			table.insert(boosts, string.format("+%.1f %s", perLevel, Stats.Labels[statName]))
		end
		text({ Position = UDim2.fromOffset(12, 30), Size = UDim2.new(1, -24, 0, 16), Text = table.concat(boosts, "  ") .. " per level", FontFace = UI.Font, TextColor3 = BONUS, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 1, Parent = row })
		local level = levels[upgrade.Id]
		text({ Position = UDim2.fromOffset(12, 52), Size = UDim2.fromOffset(110, 34), Text = string.rep("■", level) .. string.rep("□", upgrade.MaxLevel - level), TextColor3 = Color3.fromRGB(200, 140, 0), TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local button = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 52), Size = UDim2.fromOffset(110, 36), BackgroundTransparency = 0, Parent = row }, true)
		corner().Parent = button
		if level >= upgrade.MaxLevel then
			button.Text, button.BackgroundColor3 = "MAX", GREY
		else
			local cost = Config.upgradeCost(upgrade, level)
			button.Text = formatCash(cost)
			button.BackgroundColor3 = if cash >= cost then ORANGE else GREY
		end
		button.Activated:Connect(function()
			request("Upgrade", upgrade.Id)
		end)
		table.insert(listItems, row)
	end
	actionButton.Text, actionButton.BackgroundColor3 = "UPGRADES APPLY TO EVERY CAR", GREY
end

function refresh()
	cashLabel.Text = formatCash(player:GetAttribute("Cash") or 0)
	carsTab.BackgroundColor3 = if tab == "Cars" then ORANGE else CARD
	upgradesTab.BackgroundColor3 = if tab == "Upgrades" then ORANGE else CARD
	if tab == "Upgrades" then
		selectedId = player:GetAttribute("Equipped") or Cars.Default
		buildUpgradeList()
	else
		buildCarList()
	end
	local car = Cars.ById[selectedId] or Cars.List[1]
	nameLabel.Text = car.Name
	local ability = car.Ability
	descriptionLabel.Text = string.format("%s\n%s %s (%ds cooldown): %s", car.Description, ability.Icon, ability.Name, ability.Cooldown, ability.Description)
	setPreview(car)
	updateStats(car)
end

-- Wiring -------------------------------------------------------------------------

actionButton.Activated:Connect(function()
	if tab ~= "Cars" then
		return
	end
	local car = Cars.ById[selectedId]
	if not car or car.Id == player:GetAttribute("Equipped") then
		return
	end
	request(if owned()[car.Id] then "Equip" else "BuyCar", car.Id)
end)
carsTab.Activated:Connect(function()
	tab = "Cars"
	refresh()
end)
upgradesTab.Activated:Connect(function()
	tab = "Upgrades"
	refresh()
end)
openButton.Activated:Connect(function()
	window.Visible = not window.Visible
	if window.Visible then
		refresh()
	end
end)
closeButton.Activated:Connect(function()
	window.Visible = false
end)
-- Walking up to the lobby car shop and pressing E opens the garage too.
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenGarage" then
		window.Visible = true
		refresh()
	end
end)

player.AttributeChanged:Connect(function(name)
	if window.Visible and (name == "Cash" or name == "Equipped" or name == "OwnedCars" or name:sub(1, 4) == "Upg_") then
		refresh()
	end
end)

-- Hide the garage button while racing.
RunService.RenderStepped:Connect(function(dt)
	local racing = player:GetAttribute("Place") ~= nil
	openButton.Visible = not racing
	if racing then
		window.Visible = false
	end
	if not window.Visible then
		return
	end

	local viewportSize = camera.ViewportSize
	scale.Scale = math.min(1, (viewportSize.X - 20) / WIDTH, (viewportSize.Y - 40) / HEIGHT)

	-- Spin the preview car.
	local car = Cars.ById[previewId]
	if car then
		local hitbox = CarBody.spec(car).Hitbox
		local target = Vector3.new(0, hitbox.Y / 2 + 0.5, 0)
		local distance = math.max(hitbox.Z, hitbox.X * 1.6) * 1.35 + 4
		previewAngle += dt * 0.6
		viewportCamera.CFrame = CFrame.lookAt(target + Vector3.new(math.sin(previewAngle) * distance, distance * 0.35, math.cos(previewAngle) * distance), target)
	end
end)
