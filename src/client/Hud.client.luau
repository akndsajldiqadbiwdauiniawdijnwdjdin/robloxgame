-- HUD, notifications and power-up/reset input. All built in code. (Garage: Garage.client.luau)
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer

local STUDS_TO_MPH = 0.63
local ORANGE = Color3.fromRGB(255, 120, 0)
local DARK = Color3.fromRGB(20, 20, 25)

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
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0.6,
		TextScaled = true,
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
	return "$" .. formatted
end

-- Layout -------------------------------------------------------------------------

local gui = create("ScreenGui", {
	Name = "RaceHud",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})

local status = text({
	Name = "Status",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 8),
	Size = UDim2.new(0, 420, 0, 36),
	BackgroundTransparency = 0.35,
	BackgroundColor3 = DARK,
	Parent = gui,
})
corner().Parent = status

local bigText = text({
	Name = "Big",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.3),
	Size = UDim2.new(0, 520, 0, 110),
	TextColor3 = ORANGE,
	TextStrokeTransparency = 0,
	Text = "",
	Parent = gui,
})

local cashLabel = text({
	Name = "Cash",
	Position = UDim2.new(0, 12, 0, 56),
	Size = UDim2.new(0, 220, 0, 40),
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Color3.fromRGB(120, 255, 120),
	Parent = gui,
})

local raceInfo = create("Frame", {
	Name = "RaceInfo",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, 56),
	Size = UDim2.new(0, 190, 0, 120),
	BackgroundTransparency = 0.35,
	BackgroundColor3 = DARK,
	Visible = false,
	Parent = gui,
}, { corner(), create("UIListLayout", { Padding = UDim.new(0, 4) }), create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingTop = UDim.new(0, 6) }) })
local placeLabel = text({ Size = UDim2.new(1, -10, 0, 44), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = ORANGE, Parent = raceInfo })
local lapLabel = text({ Size = UDim2.new(1, -10, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = raceInfo })
local speedLabel = text({ Size = UDim2.new(1, -10, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = raceInfo })

local powerSlot = text({
	Name = "PowerUp",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.new(0, 260, 0, 54),
	BackgroundTransparency = 0.25,
	BackgroundColor3 = DARK,
	Visible = false,
	Parent = gui,
})
corner().Parent = powerSlot

local feed = create("Frame", {
	Name = "Feed",
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -90),
	Size = UDim2.new(0, 380, 0, 300),
	BackgroundTransparency = 1,
	Parent = gui,
}, { create("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 4) }) })

-- Notifications ------------------------------------------------------------------

local bigToken = 0
local function showBig(message: string, duration: number)
	bigToken += 1
	local token = bigToken
	bigText.Text = message
	bigText.TextTransparency = 0
	task.delay(duration, function()
		if token == bigToken then
			TweenService:Create(bigText, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		end
	end)
end

local function pushFeed(message: string, duration: number)
	local entry = text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.35,
		BackgroundColor3 = DARK,
		TextScaled = false,
		TextSize = 18,
		TextWrapped = true,
		Font = Enum.Font.GothamBold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = message,
		Parent = feed,
	})
	create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = entry })
	corner(6).Parent = entry
	task.delay(duration, function()
		entry:Destroy()
	end)
end

Remotes.Notify.OnClientEvent:Connect(function(message, duration, big)
	if big then
		showBig(message, duration or 1.5)
	else
		pushFeed(message, duration or 2.5)
	end
end)

-- Input --------------------------------------------------------------------------

local function onAction(actionName: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if actionName == "UsePowerUp" then
		Remotes.UsePowerUp:FireServer()
	elseif actionName == "ResetCar" then
		Remotes.ResetCar:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

-- `true` also creates on-screen buttons for mobile players.
ContextActionService:BindAction("UsePowerUp", onAction, true, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("ResetCar", onAction, true, Enum.KeyCode.R, Enum.KeyCode.ButtonY)
ContextActionService:SetTitle("UsePowerUp", "Use")
ContextActionService:SetTitle("ResetCar", "Reset")
powerSlot.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Remotes.UsePowerUp:FireServer()
	end
end)

-- Cash ---------------------------------------------------------------------------

local function refreshCash()
	cashLabel.Text = formatCash(player:GetAttribute("Cash") or 0)
end
player:GetAttributeChangedSignal("Cash"):Connect(refreshCash)
refreshCash()

-- Per-frame HUD ------------------------------------------------------------------

local function ordinal(n: number): string
	local suffix = "th"
	if n % 100 < 11 or n % 100 > 13 then
		suffix = ({ "st", "nd", "rd" })[n % 10] or "th"
	end
	return n .. suffix
end

RunService.RenderStepped:Connect(function()
	local state = workspace:GetAttribute("RaceState") or "Intermission"
	local remaining = math.max(0, (workspace:GetAttribute("StateEndsAt") or 0) - workspace:GetServerTimeNow())

	if state == "Intermission" then
		status.Text = string.format("%s in %d", workspace:GetAttribute("TrackName") or "Next race", math.ceil(remaining))
	elseif state == "Countdown" then
		status.Text = "Get ready..."
		bigToken += 1
		bigText.TextTransparency = 0
		bigText.Text = tostring(math.max(1, math.ceil(remaining)))
	elseif state == "Racing" then
		status.Text = string.format("Race ends in %d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
	else
		status.Text = "Results"
	end

	local place = player:GetAttribute("Place")
	raceInfo.Visible = place ~= nil
	powerSlot.Visible = place ~= nil
	if place then
		placeLabel.Text = string.format("%s / %d", ordinal(place), workspace:GetAttribute("RacerCount") or 0)
		lapLabel.Text = string.format("LAP %d/%d", player:GetAttribute("Lap") or 1, workspace:GetAttribute("Laps") or Config.Race.Laps)

		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local seat = humanoid and humanoid.SeatPart
		local speed = if seat then seat.AssemblyLinearVelocity.Magnitude else 0
		speedLabel.Text = string.format("%d MPH", math.floor(speed * STUDS_TO_MPH))

		local powerUp = player:GetAttribute("PowerUp")
		local info = powerUp and Config.PowerUps[powerUp]
		if info then
			powerSlot.Text = string.format("[E] %s %s", info.Icon, info.Name)
			powerSlot.BackgroundColor3 = ORANGE
		else
			powerSlot.Text = "No power-up"
			powerSlot.BackgroundColor3 = DARK
		end
	end
end)
