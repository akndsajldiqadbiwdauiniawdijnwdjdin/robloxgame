-- Race HUD in the shared cream/mint style (see shared/UI.luau): place + lap card, timer,
-- map vote cards, level + coins, ability (Q) and item (E) slots, speed bar, key hints,
-- notifications, results with award ribbons, and the out-of-bounds rescue fade.
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cars = require(Shared:WaitForChild("Cars"))
local Config = require(Shared:WaitForChild("Config"))
local Items = require(Shared:WaitForChild("Items"))
local Progression = require(Shared:WaitForChild("Progression"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local UI = require(Shared:WaitForChild("UI"))

local C = UI.Colors
local new, text = UI.new, UI.text
local player = Players.LocalPlayer

local abilitiesById = {}
for _, car in Cars.List do
	abilitiesById[car.Ability.Id] = car.Ability
end

local gui = new("ScreenGui", { Name = "RaceHud", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

-- Top centre: place / lap card and the timer pill ------------------------------------

local scoreCard = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(250, 66), Parent = gui })
local placeLabel = text({ Position = UDim2.fromOffset(14, 6), Size = UDim2.fromOffset(110, 54), FontFace = UI.FontHeavy, Text = "", TextXAlignment = Enum.TextXAlignment.Left, Parent = scoreCard })
local divider = new("Frame", { Position = UDim2.fromOffset(124, 30), Size = UDim2.fromOffset(14, 4), BackgroundColor3 = Color3.fromRGB(215, 180, 150), BorderSizePixel = 0, Parent = scoreCard })
local lapLabel = text({ Position = UDim2.fromOffset(142, 10), Size = UDim2.fromOffset(96, 46), FontFace = UI.FontHeavy, Text = "", TextXAlignment = Enum.TextXAlignment.Right, Parent = scoreCard })
local banner = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, 2), Size = UDim2.fromOffset(110, 20), BackgroundTransparency = 0, BackgroundColor3 = C.Mint, FontFace = UI.FontHeavy, Text = "", Visible = false, Parent = scoreCard })
local timerPill = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 78), Size = UDim2.fromOffset(110, 32), BackgroundTransparency = 0, BackgroundColor3 = C.Bar, TextColor3 = Color3.fromRGB(255, 205, 150), FontFace = UI.FontHeavy, Text = "", Parent = gui })
UI.brackets(timerPill, Color3.fromRGB(120, 110, 100), 3)

local bigText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.33), Size = UDim2.fromOffset(620, 120), FontFace = UI.FontHeavy, TextColor3 = C.White, TextStrokeTransparency = 0, TextStrokeColor3 = C.Ink, Text = "", ZIndex = 10, Parent = gui })

-- Top right: level and coins ---------------------------------------------------------

local levelCard = UI.panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6), Size = UDim2.fromOffset(220, 86), Parent = gui })
local levelBadge = text({ Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(42, 42), BackgroundTransparency = 0, BackgroundColor3 = C.Bar, TextColor3 = C.White, FontFace = UI.FontHeavy, Text = "1", Parent = levelCard })
new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = levelBadge })
local levelLabel = text({ Position = UDim2.fromOffset(60, 8), Size = UDim2.fromOffset(150, 24), FontFace = UI.FontHeavy, Text = "Level 1", TextXAlignment = Enum.TextXAlignment.Left, Parent = levelCard })
local xpBar = new("Frame", { Position = UDim2.fromOffset(60, 36), Size = UDim2.fromOffset(148, 12), BackgroundColor3 = C.Bar, BorderSizePixel = 0, Parent = levelCard })
local xpFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Gold, BorderSizePixel = 0, Parent = xpBar })
local coinRow = new("Frame", { Position = UDim2.fromOffset(12, 58), Size = UDim2.fromOffset(200, 22), BackgroundTransparency = 1, Parent = levelCard })
UI.coin(coinRow, 22)
local coinLabel = text({ Position = UDim2.fromOffset(28, 0), Size = UDim2.fromOffset(170, 22), FontFace = UI.FontHeavy, Text = "0", TextXAlignment = Enum.TextXAlignment.Left, Parent = coinRow })

local function refreshLevel()
	local level, into, needed = Progression.levelFromXP(player:GetAttribute("XP") or 0)
	levelBadge.Text = tostring(level)
	levelLabel.Text = "Level " .. level
	xpFill.Size = UDim2.fromScale(into / needed, 1)
	coinLabel.Text = UI.formatNumber(player:GetAttribute("Cash") or 0)
end
player:GetAttributeChangedSignal("XP"):Connect(refreshLevel)
player:GetAttributeChangedSignal("Cash"):Connect(refreshLevel)
refreshLevel()

-- Map voting ---------------------------------------------------------------------------

local TRACK_COLORS = {
	Downtown = Color3.fromRGB(255, 120, 0),
	Canyon = Color3.fromRGB(190, 110, 60),
	NeonHighway = Color3.fromRGB(220, 0, 180),
	CoralCoast = Color3.fromRGB(0, 170, 220),
	Factory = Color3.fromRGB(220, 170, 0),
	Mansion = Color3.fromRGB(170, 30, 50),
	Bathroom = Color3.fromRGB(90, 180, 230),
}
local voteFrame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 122), Size = UDim2.fromOffset(640, 140), BackgroundTransparency = 1, Visible = false, Parent = gui }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local voteTitle = text({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 266), Size = UDim2.fromOffset(320, 26), FontFace = UI.FontHeavy, TextColor3 = C.White, TextStrokeTransparency = 0, Text = "", Parent = gui })
local myVote = nil

local function rebuildVotes()
	for _, child in voteFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	local options = workspace:GetAttribute("VoteOptions")
	local racing = player:GetAttribute("Place") ~= nil
	voteFrame.Visible = options ~= nil and not racing
	voteTitle.Text = if voteFrame.Visible then "VOTE FOR THE NEXT TRACK" else ""
	if not options then
		myVote = nil
		return
	end
	local counts = HttpService:JSONDecode(workspace:GetAttribute("VoteCounts") or "{}")
	for index, option in HttpService:JSONDecode(options) do
		local selected = option.Id == myVote
		local card = new("TextButton", { LayoutOrder = index, Size = UDim2.fromOffset(200, 132), BackgroundColor3 = if selected then C.Mint else C.Cream, BorderSizePixel = 0, Text = "", AutoButtonColor = true, Parent = voteFrame })
		UI.brackets(card)
		new("Frame", { Size = UDim2.new(1, 0, 0, 10), BackgroundColor3 = TRACK_COLORS[option.Id] or C.Gold, BorderSizePixel = 0, Parent = card })
		text({ Position = UDim2.fromOffset(12, 20), Size = UDim2.new(1, -24, 0, 56), Text = option.Name, FontFace = UI.FontHeavy, TextWrapped = true, Parent = card })
		local votes = counts[option.Id] or 0
		text({ Position = UDim2.new(0, 12, 1, -48), Size = UDim2.new(1, -24, 0, 36), Text = if selected then "✓ VOTED · " .. votes else votes .. (if votes == 1 then " vote" else " votes"), TextColor3 = if selected then C.Ink else C.Muted, Parent = card })
		card.Activated:Connect(function()
			myVote = option.Id
			Remotes.Vote:FireServer(option.Id)
			rebuildVotes()
		end)
	end
end
workspace:GetAttributeChangedSignal("VoteOptions"):Connect(function()
	myVote = nil
	rebuildVotes()
end)
workspace:GetAttributeChangedSignal("VoteCounts"):Connect(rebuildVotes)
player:GetAttributeChangedSignal("Place"):Connect(rebuildVotes)
rebuildVotes()

-- Bottom centre: ability (Q) + item (E) slots and the speed bar --------------------------

local slots = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(176, 84), BackgroundTransparency = 1, Visible = false, Parent = gui })
local function makeSlot(x: number, key: string)
	local slot = new("TextButton", { Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(80, 80), BackgroundColor3 = C.Cream, BackgroundTransparency = 0.05, BorderSizePixel = 0, Text = "", AutoButtonColor = true, Parent = slots })
	UI.brackets(slot, C.Ink, 3)
	local icon = text({ Position = UDim2.fromOffset(10, 6), Size = UDim2.fromOffset(60, 54), Text = "", Parent = slot })
	local cooldown = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = C.Bar, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 5, Parent = slot })
	local seconds = text({ Size = UDim2.fromScale(1, 1), Text = "", TextColor3 = C.White, FontFace = UI.FontHeavy, ZIndex = 6, Parent = slot })
	text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.fromOffset(24, 22), BackgroundTransparency = 0, BackgroundColor3 = C.Cream, Text = key, FontFace = UI.FontHeavy, ZIndex = 7, Parent = slot })
	return slot, icon, cooldown, seconds
end
local abilitySlot, abilityIcon, abilityCooldown, abilitySeconds = makeSlot(0, "Q")
local itemSlot, itemIcon, _, _ = makeSlot(96, "E")
local slotCaption = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -6), Size = UDim2.fromOffset(300, 22), TextColor3 = C.White, TextStrokeTransparency = 0.2, Text = "", Parent = slots })

local speedBar = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12), Size = UDim2.fromOffset(280, 14), BackgroundTransparency = 1, Visible = false, Parent = gui }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4) }),
})
local speedSegments = {}
for i = 1, 4 do
	local segment = new("Frame", { LayoutOrder = i, Size = UDim2.new(0.25, -3, 1, 0), BackgroundColor3 = C.Bar, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = speedBar })
	speedSegments[i] = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Mint, BorderSizePixel = 0, Parent = segment })
end

local driftLabel = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(280, 32), FontFace = UI.FontHeavy, TextStrokeTransparency = 0, Text = "", Parent = gui })
local statusLabel = text({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -184), Size = UDim2.fromOffset(360, 26), FontFace = UI.FontHeavy, TextColor3 = C.White, TextStrokeTransparency = 0, Text = "", Parent = gui })

-- Bottom right: key hints ----------------------------------------------------------------

local hints = new("Frame", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(200, 180), BackgroundTransparency = 1, Parent = gui }, {
	new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local raceHints = {
	(UI.keyHint(hints, "Use Item", "E", 1)),
	(UI.keyHint(hints, "Ability", "Q", 2)),
	(UI.keyHint(hints, "Drift", "SPACE", 3)),
	(UI.keyHint(hints, "Respawn", "R", 4)),
}
local lobbyHints = {
	(UI.keyHint(hints, "Emotes", "B", 5)),
}

-- Notifications ------------------------------------------------------------------------------

local feed = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -20), Size = UDim2.fromOffset(380, 260), BackgroundTransparency = 1, Parent = gui }, {
	new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 5) }),
})

local bigToken = 0
local function showBig(message: string, duration: number, color: Color3?)
	bigToken += 1
	local token = bigToken
	bigText.Text = message
	bigText.TextColor3 = color or C.White
	bigText.TextTransparency = 0
	bigText.TextStrokeTransparency = 0
	task.delay(duration, function()
		if token == bigToken then
			TweenService:Create(bigText, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

local function pushFeed(message: string, duration: number)
	local entry = text({
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0,
		BackgroundColor3 = C.Cream,
		TextScaled = false,
		TextSize = 19,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = message,
		Parent = feed,
	})
	new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5), Parent = entry })
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

-- Drift meter + mini-turbo callouts (local attributes set by Drive.client.luau).
player:GetAttributeChangedSignal("DriftTier"):Connect(function()
	local tier = player:GetAttribute("DriftTier")
	if tier == nil then
		driftLabel.Text = ""
	elseif tier == 0 then
		driftLabel.Text = "DRIFT"
		driftLabel.TextColor3 = C.White
	else
		driftLabel.Text = "DRIFT " .. string.rep("●", tier) .. string.rep("○", 3 - tier)
		driftLabel.TextColor3 = Config.Drift.TierColors[tier]
	end
end)
player:GetAttributeChangedSignal("TurboCount"):Connect(function()
	local tier = player:GetAttribute("TurboTier") or 1
	showBig(Config.Drift.Names[tier], 0.7, Config.Drift.TierColors[tier])
end)

-- Out-of-bounds rescue fade + smoke blindness ----------------------------------------------

local fade = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 50, Parent = gui })
local fadeText = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(600, 90), FontFace = UI.FontHeavy, TextColor3 = C.White, TextTransparency = 1, ZIndex = 51, Text = "", Parent = fade })
local fadeSub = text({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(500, 36), TextColor3 = C.Mint, TextTransparency = 1, ZIndex = 51, Text = "🚁 Rescue drone incoming...", Parent = fade })
local smoke = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(120, 120, 125), BackgroundTransparency = 1, ZIndex = 40, Parent = gui })

Remotes.Effect.OnClientEvent:Connect(function(kind, value)
	if kind ~= "Rescue" then
		return
	end
	fadeText.Text = tostring(value or "OUT OF BOUNDS")
	local fadeIn = TweenInfo.new(0.35)
	TweenService:Create(fade, fadeIn, { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(fadeText, fadeIn, { TextTransparency = 0 }):Play()
	TweenService:Create(fadeSub, fadeIn, { TextTransparency = 0 }):Play()
	task.delay(0.9, function()
		local fadeOut = TweenInfo.new(0.4)
		TweenService:Create(fade, fadeOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(fadeText, fadeOut, { TextTransparency = 1 }):Play()
		TweenService:Create(fadeSub, fadeOut, { TextTransparency = 1 }):Play()
	end)
end)

-- Results screen with award ribbons ----------------------------------------------------------

local resultsOverlay = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Visible = false, ZIndex = 30, Parent = gui })
local resultsPanel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromOffset(620, 400), ZIndex = 31, Parent = resultsOverlay })
UI.autoScale(resultsPanel, 640, 560)
local resultsTitle = text({ Position = UDim2.fromOffset(24, 16), Size = UDim2.new(1, -48, 0, 44), FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 32, Text = "Results", Parent = resultsPanel })
local resultsList = new("Frame", { Position = UDim2.fromOffset(24, 70), Size = UDim2.new(1, -48, 1, -90), BackgroundTransparency = 1, ZIndex = 32, Parent = resultsPanel }, {
	new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local ribbonRow = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -10), Size = UDim2.fromOffset(760, 66), BackgroundTransparency = 1, ZIndex = 32, Parent = resultsPanel }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }),
})

local function ordinal(n: number): string
	local suffix = "th"
	if n % 100 < 11 or n % 100 > 13 then
		suffix = ({ "st", "nd", "rd" })[n % 10] or "th"
	end
	return n .. suffix
end

local function clearChildren(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

Remotes.Results.OnClientEvent:Connect(function(payload)
	clearChildren(resultsList)
	clearChildren(ribbonRow)
	resultsTitle.Text = "Results  ·  " .. payload.Track
	for _, result in payload.Results do
		local mine = result.UserId == player.UserId
		local row = new("Frame", { LayoutOrder = result.Place, Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = if mine then C.Mint else C.CreamDark, BorderSizePixel = 0, ZIndex = 33, Parent = resultsList })
		text({ Position = UDim2.fromOffset(10, 4), Size = UDim2.fromOffset(60, 32), Text = ordinal(result.Place), FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 34, Parent = row })
		-- Avatar headshot next to the name (loaded in the background).
		local avatar = new("ImageLabel", { Position = UDim2.fromOffset(72, 3), Size = UDim2.fromOffset(34, 34), BackgroundColor3 = C.Cream, BorderSizePixel = 0, Image = "", ZIndex = 34, Parent = row })
		new("UICorner", { CornerRadius = UDim.new(0.5, 0), Parent = avatar })
		task.spawn(function()
			local ok, image = pcall(Players.GetUserThumbnailAsync, Players, result.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			if ok and avatar.Parent then
				avatar.Image = image
			end
		end)
		text({ Position = UDim2.fromOffset(112, 6), Size = UDim2.fromOffset(144, 28), Text = result.Name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 34, Parent = row })
		local tags = {}
		for _, award in result.Awards do
			table.insert(tags, award.Title)
		end
		text({ Position = UDim2.fromOffset(258, 9), Size = UDim2.fromOffset(160, 22), Text = table.concat(tags, " · "), TextColor3 = Color3.fromRGB(150, 70, 200), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 34, Parent = row })
		text({ Position = UDim2.fromOffset(420, 6), Size = UDim2.fromOffset(60, 28), Text = result.Time, TextColor3 = C.Muted, ZIndex = 34, Parent = row })
		text({ Position = UDim2.fromOffset(486, 6), Size = UDim2.fromOffset(80, 28), Text = "+" .. UI.formatNumber(result.Coins) .. " coins", TextColor3 = Color3.fromRGB(200, 140, 0), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 34, Parent = row })
		if mine then
			for _, award in result.Awards do
				UI.ribbon(ribbonRow, award.Title, award.Subtitle)
			end
			pushFeed(string.format("+%d XP", result.XP), 5)
		end
	end
	resultsOverlay.Visible = true
	task.delay(payload.Duration or 6, function()
		resultsOverlay.Visible = false
	end)
end)

-- Input ------------------------------------------------------------------------------------------

local function onAction(actionName: string, inputState: Enum.UserInputState)
	-- Only while racing, so the lobby keeps E/Q/1/2 for prompts and the emote wheel.
	if inputState ~= Enum.UserInputState.Begin or player:GetAttribute("Place") == nil then
		return Enum.ContextActionResult.Pass
	end
	if actionName == "UsePowerUp" then
		Remotes.UsePowerUp:FireServer()
	elseif actionName == "UseAbility" then
		Remotes.UseAbility:FireServer()
	elseif actionName == "ResetCar" then
		Remotes.ResetCar:FireServer()
	end
	return Enum.ContextActionResult.Sink
end

-- `true` also creates on-screen buttons for mobile players.
ContextActionService:BindAction("UsePowerUp", onAction, true, Enum.KeyCode.E, Enum.KeyCode.Two, Enum.KeyCode.ButtonX)
ContextActionService:BindAction("UseAbility", onAction, true, Enum.KeyCode.Q, Enum.KeyCode.One, Enum.KeyCode.ButtonY)
ContextActionService:BindAction("ResetCar", onAction, true, Enum.KeyCode.R, Enum.KeyCode.DPadDown)
ContextActionService:SetTitle("UsePowerUp", "Item")
ContextActionService:SetTitle("UseAbility", "Ability")
ContextActionService:SetTitle("ResetCar", "Reset")
itemSlot.Activated:Connect(function()
	Remotes.UsePowerUp:FireServer()
end)
abilitySlot.Activated:Connect(function()
	Remotes.UseAbility:FireServer()
end)

-- Per-frame updates -------------------------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	local state = workspace:GetAttribute("RaceState") or "Intermission"
	local serverNow = workspace:GetServerTimeNow()
	local remaining = math.max(0, (workspace:GetAttribute("StateEndsAt") or 0) - serverNow)
	local place = player:GetAttribute("Place")
	local racing = place ~= nil
	local laps = workspace:GetAttribute("Laps") or Config.Race.Laps
	local lap = player:GetAttribute("Lap") or 1

	timerPill.Text = string.format("⏱ %d:%02d", math.floor(remaining / 60), math.floor(remaining % 60))
	if racing then
		placeLabel.Text = ordinal(place)
		lapLabel.Text = string.format("LAP %d/%d", lap, laps)
		divider.Visible = true
		banner.Visible = lap == laps and state == "Racing"
		banner.Text = "FINAL LAP"
	else
		placeLabel.Text = if state == "Intermission" then "NEXT" else "RACE"
		lapLabel.Text = if state == "Intermission" then "RACE" else "LIVE"
		divider.Visible = false
		banner.Visible = false
	end
	if state == "Countdown" then
		bigToken += 1
		bigText.TextTransparency = 0
		bigText.TextStrokeTransparency = 0
		bigText.TextColor3 = C.White
		bigText.Text = tostring(math.max(1, math.ceil(remaining)))
	end

	slots.Visible = racing
	speedBar.Visible = racing
	for _, hint in raceHints do
		hint.Visible = racing
	end
	for _, hint in lobbyHints do
		hint.Visible = not racing
	end
	if not racing then
		statusLabel.Text = ""
		smoke.BackgroundTransparency = 1
		return
	end

	-- Ability slot with cooldown sweep.
	local ability = abilitiesById[player:GetAttribute("AbilityId") or ""]
	abilityIcon.Text = if ability then ability.Icon else ""
	local readyAt = player:GetAttribute("AbilityReadyAt") or 0
	local cooldownLeft = math.max(0, readyAt - serverNow)
	abilityCooldown.Size = UDim2.fromScale(1, if ability and cooldownLeft > 0 then cooldownLeft / ability.Cooldown else 0)
	abilitySeconds.Text = if cooldownLeft > 0 then tostring(math.ceil(cooldownLeft)) else ""

	-- Item slot.
	local itemId = player:GetAttribute("PowerUp")
	local item = itemId and Items.ById[itemId]
	itemIcon.Text = if item then item.Icon else ""
	itemSlot.BackgroundColor3 = if item then Items.Rarities[item.Rarity].Color:Lerp(C.Cream, 0.55) else C.Cream
	slotCaption.Text = if item then item.Name elseif ability and cooldownLeft <= 0 then ability.Name .. " ready!" else ""

	-- Speed bar + car status effects.
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local car = seat and seat.Parent
	if seat and car then
		local top = (car:GetAttribute("TopSpeed") or 100) * 1.3
		local fraction = math.clamp(seat.AssemblyLinearVelocity.Magnitude / top, 0, 1)
		for i, fill in speedSegments do
			fill.Size = UDim2.fromScale(math.clamp(fraction * 4 - (i - 1), 0, 1), 1)
		end
		local status = {}
		if serverNow < (car:GetAttribute("ShieldUntil") or 0) then
			table.insert(status, "🛡️ SHIELD")
		end
		if serverNow < (car:GetAttribute("SlowUntil") or 0) then
			table.insert(status, "🐌 SLOWED")
		end
		if serverNow < (car:GetAttribute("TurboRushUntil") or 0) then
			table.insert(status, "🌀 DRIFT KING")
		end
		statusLabel.Text = table.concat(status, "   ")
		local blind = serverNow < (car:GetAttribute("BlindUntil") or 0)
		smoke.BackgroundTransparency = if blind then 0.2 else 1
	end
end)
