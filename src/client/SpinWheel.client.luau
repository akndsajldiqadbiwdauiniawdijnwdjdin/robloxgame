-- Daily spin wheel + store. The server picks the prize (server/Spin.luau); this script
-- only animates the wheel. Store buttons prompt Robux developer-product purchases.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local UI = require(Shared:WaitForChild("UI"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local WIDTH, HEIGHT = 680, 470
local NAVY = UI.Colors.Cream
local CARD = UI.Colors.CreamDark
local PINK = Color3.fromRGB(255, 60, 160)
local YELLOW = Color3.fromRGB(255, 214, 0)
local GREY = Color3.fromRGB(85, 90, 100)
local PRIZES = Config.Spin.Prizes

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

local function corner(radius)
	return create("UICorner", { CornerRadius = if typeof(radius) == "UDim" then radius else UDim.new(0, radius or 8) })
end

local function text(props, isButton: boolean?)
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = UI.FontHeavy,
		TextColor3 = UI.Colors.Ink,
		TextStrokeTransparency = 1,
		TextScaled = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return create(if isButton then "TextButton" else "TextLabel", defaults)
end

local gui = create("ScreenGui", { Name = "SpinWheel", ResetOnSpawn = false, Parent = player:WaitForChild("PlayerGui") })

local openButton, badge = UI.sideButton(player, "SPIN", "🎡", 4)

local window = create("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(WIDTH, HEIGHT),
	BackgroundColor3 = NAVY,
	Visible = false,
	Parent = gui,
})
UI.brackets(window)
local scale = create("UIScale", { Parent = window })
text({ Position = UDim2.fromOffset(18, 12), Size = UDim2.fromOffset(260, 38), Text = "DAILY SPIN", TextColor3 = PINK, TextXAlignment = Enum.TextXAlignment.Left, Parent = window })
local closeButton = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(38, 38), Text = "✕", BackgroundTransparency = 0, BackgroundColor3 = UI.Colors.CreamDark, Parent = window }, true)
corner().Parent = closeButton

-- The wheel: one coloured spoke per prize, rotated around the centre.
local wheelHolder = create("Frame", { Position = UDim2.fromOffset(24, 70), Size = UDim2.fromOffset(330, 330), BackgroundTransparency = 1, Parent = window })
local wheel = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(30, 30, 40), Parent = wheelHolder }, { corner(UDim.new(0.5, 0)), create("UIStroke", { Color = YELLOW, Thickness = 6 }) })
for index, prize in PRIZES do
	local spoke = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 112, 0.5, -6),
		Rotation = (index - 1) / #PRIZES * 360,
		BackgroundColor3 = prize.Color,
		BorderSizePixel = 0,
		Parent = wheel,
	}, { corner(10) })
	text({ Position = UDim2.fromOffset(6, 8), Size = UDim2.new(1, -12, 0, 36), Text = prize.Label, TextColor3 = UI.Colors.White, TextStrokeTransparency = 0.1, Parent = spoke })
end
create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(60, 60), BackgroundColor3 = YELLOW, Parent = wheel }, { corner(UDim.new(0.5, 0)) })
text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(44, 44), Text = "▼", TextColor3 = Color3.fromRGB(255, 255, 255), TextStrokeTransparency = 0, Parent = wheelHolder })

-- Right side: spin button, spin info and the store.
local right = create("Frame", { Position = UDim2.fromOffset(376, 66), Size = UDim2.new(1, -392, 1, -80), BackgroundTransparency = 1, Parent = window })
local spinButton = text({ Size = UDim2.new(1, 0, 0, 58), BackgroundTransparency = 0, BackgroundColor3 = PINK, Text = "SPIN!", Parent = right }, true)
corner(10).Parent = spinButton
local infoLabel = text({ Position = UDim2.fromOffset(0, 64), Size = UDim2.new(1, 0, 0, 22), FontFace = UI.Font, Text = "", Parent = right })
local resultLabel = text({ Position = UDim2.fromOffset(0, 90), Size = UDim2.new(1, 0, 0, 28), TextColor3 = Color3.fromRGB(200, 140, 0), Text = "", Parent = right })
text({ Position = UDim2.fromOffset(0, 126), Size = UDim2.new(1, 0, 0, 24), Text = "STORE", TextColor3 = UI.Colors.Ink, TextXAlignment = Enum.TextXAlignment.Left, Parent = right })
local storeList = create("Frame", { Position = UDim2.fromOffset(0, 154), Size = UDim2.new(1, 0, 1, -154), BackgroundTransparency = 1, Parent = right }, {
	create("UIListLayout", { Padding = UDim.new(0, 6) }),
})
for _, item in Config.Store do
	local row = text({ Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 0, BackgroundColor3 = CARD, Text = "", Parent = storeList }, true)
	corner().Parent = row
	text({ Position = UDim2.fromOffset(10, 4), Size = UDim2.new(0.6, -10, 1, -8), Text = (if item.Kind == "Spins" then "🎡 " elseif item.Kind == "Rolls" then "🎲 " else "🪙 ") .. item.Label, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 4), Size = UDim2.new(0.4, -10, 1, -8), Text = "R$ " .. item.Price, TextColor3 = Color3.fromRGB(20, 150, 80), TextXAlignment = Enum.TextXAlignment.Right, Parent = row })
	row.Activated:Connect(function()
		if item.ProductId == 0 then
			resultLabel.Text = "Store not set up yet (Config.Store)"
			return
		end
		MarketplaceService:PromptProductPurchase(player, item.ProductId)
	end)
end

-- Logic --------------------------------------------------------------------------------

local spinning = false

local function freeSpinIn(): number
	return math.max(0, (player:GetAttribute("NextFreeSpin") or 0) - workspace:GetServerTimeNow())
end

local function clock(seconds: number): string
	seconds = math.floor(seconds)
	return string.format("%02d:%02d:%02d", seconds // 3600, seconds % 3600 // 60, seconds % 60)
end

local function refresh()
	local wait = freeSpinIn()
	local spins = player:GetAttribute("Spins") or 0
	badge.Visible = wait <= 0 or spins > 0
	if spinning then
		return
	end
	if wait <= 0 then
		spinButton.Text, spinButton.BackgroundColor3 = "FREE SPIN!", PINK
		infoLabel.Text = string.format("Extra spins: %d", spins)
	elseif spins > 0 then
		spinButton.Text, spinButton.BackgroundColor3 = "SPIN (" .. spins .. " left)", PINK
		infoLabel.Text = "Free spin in " .. clock(wait)
	else
		spinButton.Text, spinButton.BackgroundColor3 = "NO SPINS", GREY
		infoLabel.Text = "Free spin in " .. clock(wait)
	end
end

spinButton.Activated:Connect(function()
	if spinning then
		return
	end
	local ok, result = Remotes.Spin:InvokeServer()
	if not ok then
		resultLabel.Text = tostring(result)
		return
	end
	spinning = true
	resultLabel.Text = ""
	spinButton.Text, spinButton.BackgroundColor3 = "SPINNING...", GREY
	-- Land the winning spoke under the pointer at the top: a spoke drawn at angle A shows
	-- at A + Rotation, so we need Rotation = -A (mod 360), plus six full turns for drama.
	local spokeAngle = (result - 1) / #PRIZES * 360
	local start = wheel.Rotation % 360
	wheel.Rotation = start
	local target = start + 360 * 6 + ((360 - spokeAngle) - start) % 360
	local tween = TweenService:Create(wheel, TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Rotation = target })
	tween:Play()
	tween.Completed:Wait()
	resultLabel.Text = "🎉 " .. PRIZES[result].Label .. " 🎉"
	spinning = false
	refresh()
end)

openButton.Activated:Connect(function()
	window.Visible = not window.Visible
	refresh()
end)
closeButton.Activated:Connect(function()
	window.Visible = false
end)
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt.Name == "OpenSpin" then
		window.Visible = true
		refresh()
	end
end)

local accumulator = 0
RunService.RenderStepped:Connect(function(dt)
	local racing = player:GetAttribute("Place") ~= nil
	openButton.Visible = not racing
	if racing then
		window.Visible = false
	end
	local viewportSize = camera.ViewportSize
	scale.Scale = math.min(1, (viewportSize.X - 20) / WIDTH, (viewportSize.Y - 40) / HEIGHT)
	accumulator += dt
	if accumulator >= 1 then
		accumulator = 0
		refresh()
	end
end)
refresh()
