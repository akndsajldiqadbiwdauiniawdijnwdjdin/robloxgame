-- The screens between races, Mario Kart style:
--   STANDINGS  after each race: cup points table with avatars (+points gained), and the
--              cup winners after the last race of a cup.
--   VOTE       in the lobby: pick one of 3 tracks; the board shows every player's pick
--              (a "?" until they vote) with their avatar. Close it with X, reopen with
--              the VOTE button.
--   SELECTING  a roulette runs over everyone's picks and lands on the chosen track.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))
local UI = require(Shared:WaitForChild("UI"))

local C = UI.Colors
local new, text = UI.new, UI.text
local player = Players.LocalPlayer

local TRACKS = {
	Downtown = { Color = Color3.fromRGB(255, 120, 0), Icon = "🏙️" },
	Canyon = { Color = Color3.fromRGB(190, 110, 60), Icon = "🏜️" },
	NeonHighway = { Color = Color3.fromRGB(200, 0, 180), Icon = "🌃" },
	CoralCoast = { Color = Color3.fromRGB(0, 170, 220), Icon = "🏝️" },
	Factory = { Color = Color3.fromRGB(220, 170, 0), Icon = "🏭" },
	Mansion = { Color = Color3.fromRGB(170, 30, 50), Icon = "🏰" },
	Bathroom = { Color = Color3.fromRGB(90, 180, 230), Icon = "🛁" },
}
local UNKNOWN = Color3.fromRGB(40, 90, 200)
local NAVY = Color3.fromRGB(16, 22, 40)

local gui = new("ScreenGui", { Name = "Intermission", ResetOnSpawn = false, DisplayOrder = 4, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

local function decode(name: string)
	local raw = workspace:GetAttribute(name)
	if not raw then
		return nil
	end
	local ok, value = pcall(HttpService.JSONDecode, HttpService, raw)
	return if ok then value else nil
end

local function clear(frame: Instance)
	for _, child in frame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function racing(): boolean
	return player:GetAttribute("Place") ~= nil
end

-- VOTE board ----------------------------------------------------------------------------

local board = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(900, 560), BackgroundColor3 = NAVY, BorderSizePixel = 0, Visible = false, Parent = gui })
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = board })
UI.autoScale(board, 920, 600)
UI.exclusive(board)
local header = new("Frame", { Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -86, 0, 46), BackgroundColor3 = C.Cream, BorderSizePixel = 0, Parent = board })
UI.brackets(header)
local headerText = text({ Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -120, 1, -12), FontFace = UI.FontHeavy, Text = "Vote for a course!", TextXAlignment = Enum.TextXAlignment.Left, Parent = header })
local headerTimer = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 6), Size = UDim2.fromOffset(90, 34), FontFace = UI.FontHeavy, Text = "", TextColor3 = C.Red, TextXAlignment = Enum.TextXAlignment.Right, Parent = header })
local closeX = UI.closeButton(board)
closeX.Position = UDim2.new(1, -14, 0, 15)

local optionRow = new("Frame", { Position = UDim2.fromOffset(16, 74), Size = UDim2.new(1, -32, 0, 170), BackgroundTransparency = 1, Parent = board }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }),
})
text({ Position = UDim2.fromOffset(20, 252), Size = UDim2.fromOffset(400, 24), FontFace = UI.FontHeavy, Text = "EVERYONE'S PICKS", TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left, Parent = board })
local ballotGrid = new("ScrollingFrame", { Position = UDim2.fromOffset(16, 282), Size = UDim2.new(1, -32, 1, -296), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = board }, {
	new("UIGridLayout", { CellSize = UDim2.fromOffset(134, 118), CellPadding = UDim2.fromOffset(10, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})

local voteButton = UI.sideButton(player, "VOTE", "🗳️", 1)
voteButton.Visible = false

local myVote = nil
local tiles = {} -- [userId] = tile frame (for the roulette)
local optionCards = {} -- [trackId] = card

local function trackCard(parent: Instance, trackId: string, name: string, order: number, size: UDim2)
	local info = TRACKS[trackId] or { Color = C.Gold, Icon = "🏁" }
	local card = new("TextButton", { LayoutOrder = order, Size = size, BackgroundColor3 = info.Color, BorderSizePixel = 0, Text = "", AutoButtonColor = true, Parent = parent })
	new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(150, 150, 150)), Parent = card })
	text({ Position = UDim2.fromScale(0.05, 0.06), Size = UDim2.fromScale(0.9, 0.5), Text = info.Icon, Parent = card })
	local nameLabel = text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0.32, 0), BackgroundTransparency = 0.25, BackgroundColor3 = NAVY, FontFace = UI.FontHeavy, TextColor3 = C.White, Text = name, Parent = card })
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = nameLabel })
	return card
end

local function rebuildBoard()
	clear(optionRow)
	clear(ballotGrid)
	table.clear(tiles)
	table.clear(optionCards)
	local options = decode("VoteOptions")
	if not options then
		return
	end
	local names = {}
	local counts = decode("VoteCounts") or {}
	local voting = workspace:GetAttribute("RaceState") == "Intermission"
	for index, option in options do
		names[option.Id] = option.Name
		local card = trackCard(optionRow, option.Id, option.Name, index, UDim2.fromOffset(270, 166))
		local votes = counts[option.Id] or 0
		text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(76, 28), BackgroundTransparency = 0, BackgroundColor3 = C.Cream, FontFace = UI.FontHeavy, Text = votes .. (if votes == 1 then " vote" else " votes"), Parent = card })
		if option.Id == myVote then
			new("UIStroke", { Color = C.Mint, Thickness = 5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
			text({ Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(90, 28), BackgroundTransparency = 0, BackgroundColor3 = C.Mint, FontFace = UI.FontHeavy, Text = "✓ YOUR PICK", Parent = card })
		end
		card.Activated:Connect(function()
			if not voting then
				return
			end
			Sounds.play("Click")
			myVote = option.Id
			Remotes.Vote:FireServer(option.Id)
			rebuildBoard()
		end)
		optionCards[option.Id] = card
	end

	for index, ballot in decode("PlayerVotes") or {} do
		local voted = ballot.Track ~= ""
		local info = TRACKS[ballot.Track]
		local tile = new("Frame", { LayoutOrder = if ballot.UserId == player.UserId then 0 else index, BackgroundColor3 = if voted and info then info.Color else UNKNOWN, BorderSizePixel = 0, Parent = ballotGrid })
		new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tile })
		local stroke = new("UIStroke", { Name = "Highlight", Color = C.Gold, Thickness = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tile })
		local picture = new("Frame", { Size = UDim2.new(1, 0, 0, 86), BackgroundTransparency = 1, Parent = tile })
		if voted then
			text({ Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -60, 0, 44), Text = if info then info.Icon else "🏁", Parent = picture })
			text({ Position = UDim2.fromOffset(6, 52), Size = UDim2.new(1, -12, 0, 26), FontFace = UI.FontHeavy, TextColor3 = C.White, TextStrokeTransparency = 0.3, Text = names[ballot.Track] or ballot.Track, TextXAlignment = Enum.TextXAlignment.Left, Parent = picture })
		else
			text({ Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -60, 1, -8), FontFace = UI.FontHeavy, TextColor3 = Color3.fromRGB(150, 190, 255), Text = "?", Parent = picture })
		end
		UI.avatar({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(48, 48), Parent = tile }, ballot.UserId)
		text({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0, BackgroundColor3 = if ballot.UserId == player.UserId then C.Mint else C.Cream, FontFace = UI.FontHeavy, Text = ballot.Name, Parent = tile })
		tiles[ballot.UserId] = { Tile = tile, Stroke = stroke }
	end
end

workspace:GetAttributeChangedSignal("VoteOptions"):Connect(function()
	myVote = nil
	if workspace:GetAttribute("VoteOptions") and not racing() then
		board.Visible = true -- a new vote: pop the board open (X closes it)
	end
	rebuildBoard()
end)
workspace:GetAttributeChangedSignal("VoteCounts"):Connect(rebuildBoard)
workspace:GetAttributeChangedSignal("PlayerVotes"):Connect(rebuildBoard)
voteButton.Activated:Connect(function()
	board.Visible = not board.Visible
end)

-- SELECTING: roulette over the picks ------------------------------------------------------

local function roulette()
	local selected = workspace:GetAttribute("SelectedTrack")
	local voter = workspace:GetAttribute("SelectedVoter") or 0
	if not selected or racing() then
		return
	end
	board.Visible = true
	headerText.Text = "Picking a course..."
	-- Spin over the ballots that voted (or the track cards if nobody did).
	local stops = {}
	local finalIndex = 1
	if voter ~= 0 then
		for userId, entry in tiles do
			if entry.Tile.BackgroundColor3 ~= UNKNOWN then
				table.insert(stops, { Frame = entry.Tile, Stroke = entry.Stroke })
				if userId == voter then
					finalIndex = #stops
				end
			end
		end
	end
	if #stops == 0 then
		for trackId, card in optionCards do
			table.insert(stops, { Frame = card, Stroke = new("UIStroke", { Color = C.Gold, Thickness = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card }) })
			if trackId == selected then
				finalIndex = #stops
			end
		end
	end
	if #stops == 0 then
		return
	end
	local steps = #stops * 3 + finalIndex
	local delay = 0.05
	for step = 1, steps do
		for i, stop in stops do
			stop.Stroke.Thickness = if i == (step - 1) % #stops + 1 then 6 else 0
		end
		Sounds.play("Beep", 1.4, 0.3)
		task.wait(delay)
		delay *= 1.07 -- slow down
	end
	Sounds.play("Victory", 1.3)
	local options = decode("VoteOptions") or {}
	local name = selected
	for _, option in options do
		if option.Id == selected then
			name = option.Name
		end
	end
	headerText.Text = "NEXT COURSE: " .. string.upper(name)
	headerText.TextColor3 = C.Red
end
workspace:GetAttributeChangedSignal("SelectedTrack"):Connect(function()
	if workspace:GetAttribute("SelectedTrack") then
		task.spawn(roulette)
	end
end)

-- STANDINGS: cup points between races ------------------------------------------------------

local standings = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = NAVY, BackgroundTransparency = 0.08, Visible = false, ZIndex = 40, Parent = gui })
local standingsBody = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(1000, 560), BackgroundTransparency = 1, ZIndex = 40, Parent = standings })
UI.autoScale(standingsBody, 1020, 600)
local standingsTitle = text({ Size = UDim2.fromOffset(640, 50), FontFace = UI.FontHeavy, TextColor3 = C.White, Text = "CUP STANDINGS", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41, Parent = standingsBody })
local standingsSub = text({ Position = UDim2.fromOffset(0, 50), Size = UDim2.fromOffset(640, 26), TextColor3 = Color3.fromRGB(170, 190, 230), Text = "", TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 41, Parent = standingsBody })
local rowsFrame = new("Frame", { Position = UDim2.fromOffset(0, 88), Size = UDim2.fromOffset(640, 470), BackgroundTransparency = 1, ZIndex = 41, Parent = standingsBody }, {
	new("UIGridLayout", { CellSize = UDim2.fromOffset(314, 50), CellPadding = UDim2.fromOffset(12, 8), FillDirection = Enum.FillDirection.Vertical, FillDirectionMaxCells = 8, SortOrder = Enum.SortOrder.LayoutOrder }),
})
-- Right side: trophy card.
local trophyCard = new("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 88), Size = UDim2.fromOffset(330, 420), BackgroundColor3 = C.Cream, BorderSizePixel = 0, ZIndex = 41, Parent = standingsBody })
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = trophyCard })
UI.brackets(trophyCard)
local trophyIcon = text({ Position = UDim2.fromOffset(20, 20), Size = UDim2.new(1, -40, 0, 150), Text = "🏁", ZIndex = 42, Parent = trophyCard })
local trophyTitle = text({ Position = UDim2.fromOffset(20, 180), Size = UDim2.new(1, -40, 0, 44), FontFace = UI.FontHeavy, Text = "", ZIndex = 42, Parent = trophyCard })
local trophyText = text({ Position = UDim2.fromOffset(20, 230), Size = UDim2.new(1, -40, 0, 170), FontFace = UI.FontRegular, TextScaled = false, TextSize = 22, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Text = "", ZIndex = 42, Parent = trophyCard })

Remotes.Standings.OnClientEvent:Connect(function(payload)
	clear(rowsFrame)
	standingsTitle.Text = if payload.Final then "CUP RESULTS" else "CUP STANDINGS"
	standingsSub.Text = string.format("After race %d of %d", payload.Race, payload.Races)
	local counters = {}
	for rank, row in payload.Rows do
		if rank > 16 then
			break
		end
		local mine = row.UserId == player.UserId
		local frame = new("Frame", { LayoutOrder = rank, BackgroundColor3 = if mine then Color3.fromRGB(60, 80, 130) else Color3.fromRGB(38, 46, 70), BorderSizePixel = 0, ZIndex = 42, Parent = rowsFrame })
		new("UICorner", { CornerRadius = UDim.new(0, 10), Parent = frame })
		text({ Position = UDim2.fromOffset(8, 10), Size = UDim2.fromOffset(28, 30), FontFace = UI.FontHeavy, TextColor3 = if rank <= 3 then C.Gold else C.White, Text = tostring(rank), ZIndex = 43, Parent = frame })
		UI.avatar({ Position = UDim2.fromOffset(40, 5), Size = UDim2.fromOffset(40, 40), ZIndex = 43, Parent = frame }, row.UserId)
		text({ Position = UDim2.fromOffset(88, 10), Size = UDim2.fromOffset(140, 30), FontFace = UI.FontHeavy, TextColor3 = C.White, Text = row.Name, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43, Parent = frame })
		local points = text({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(60, 34), FontFace = UI.FontHeavy, TextColor3 = C.White, Text = tostring(row.Points - row.Gained), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 43, Parent = frame })
		if row.Gained > 0 then
			text({ AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -74, 0.5, 0), Size = UDim2.fromOffset(44, 26), BackgroundTransparency = 0, BackgroundColor3 = C.Mint, FontFace = UI.FontHeavy, Text = "+" .. row.Gained, ZIndex = 43, Parent = frame })
		end
		table.insert(counters, { Label = points, From = row.Points - row.Gained, To = row.Points })
	end

	local leader = payload.Rows[1]
	if payload.Final and leader then
		trophyIcon.Text = "🏆"
		trophyTitle.Text = leader.Name .. " WINS THE CUP!"
		local lines = {}
		for rank = 1, math.min(3, #payload.Rows) do
			local row = payload.Rows[rank]
			table.insert(lines, string.format("%s  %s  %d pts%s", ({ "🥇", "🥈", "🥉" })[rank], row.Name, row.Points, if row.Bonus then "  (+" .. UI.formatNumber(row.Bonus) .. " coins)" else ""))
		end
		trophyText.Text = table.concat(lines, "\n") .. "\n\nA new cup starts next race!"
	else
		trophyIcon.Text = "🏁"
		trophyTitle.Text = string.format("RACE %d / %d", payload.Race, payload.Races)
		trophyText.Text = "Points: 1st 15 · 2nd 12 · 3rd 10 · 4th 9 ...\n\nTop 3 after the last race win bonus coins."
	end

	standings.Visible = true
	-- Count the totals up after a beat.
	task.delay(1, function()
		local start = os.clock()
		while os.clock() - start < 1.2 and standings.Visible do
			local t = (os.clock() - start) / 1.2
			for _, counter in counters do
				counter.Label.Text = tostring(math.floor(counter.From + (counter.To - counter.From) * t + 0.5))
			end
			task.wait()
		end
		for _, counter in counters do
			counter.Label.Text = tostring(counter.To)
		end
	end)
	task.delay(payload.Duration or 8, function()
		standings.Visible = false
	end)
end)

-- Per-frame: timer, visibility -------------------------------------------------------------

RunService.RenderStepped:Connect(function()
	local state = workspace:GetAttribute("RaceState")
	local hasVote = workspace:GetAttribute("VoteOptions") ~= nil
	local inLobby = not racing()
	voteButton.Visible = hasVote and inLobby and state == "Intermission"
	if not (hasVote and inLobby) then
		board.Visible = false
	end
	if state == "Intermission" then
		local remaining = math.max(0, (workspace:GetAttribute("StateEndsAt") or 0) - workspace:GetServerTimeNow())
		headerTimer.Text = string.format("%d:%02d", remaining // 60, math.floor(remaining % 60))
		headerText.Text = if myVote then "Waiting for everyone to vote for a course..." else "Vote for a course!"
		headerText.TextColor3 = C.Ink
	elseif state ~= "Selecting" then
		headerTimer.Text = ""
	end
	if state ~= "Standings" and standings.Visible and state ~= "Results" then
		standings.Visible = false
	end
end)

-- Fade the board in when it opens.
board:GetPropertyChangedSignal("Visible"):Connect(function()
	if board.Visible then
		board.BackgroundTransparency = 0.3
		TweenService:Create(board, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
	end
end)
