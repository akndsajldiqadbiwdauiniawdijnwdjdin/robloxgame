-- Shared UI kit (client side) in the "Illegal Soccer" style: cream cards with corner
-- brackets, bold condensed text, mint action buttons and dark tab bars.
local Sounds = require(script.Parent.Sounds)

local UI = {}

UI.Font = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Bold)
UI.FontHeavy = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Heavy)
UI.FontRegular = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Medium)

UI.Colors = {
	Cream = Color3.fromRGB(248, 244, 235),
	CreamDark = Color3.fromRGB(234, 229, 218),
	Line = Color3.fromRGB(205, 198, 185),
	Ink = Color3.fromRGB(28, 28, 30),
	Muted = Color3.fromRGB(135, 128, 120),
	Mint = Color3.fromRGB(46, 255, 166),
	Bar = Color3.fromRGB(22, 22, 24),
	Red = Color3.fromRGB(255, 50, 90),
	Gold = Color3.fromRGB(255, 196, 40),
	Blue = Color3.fromRGB(50, 140, 255),
	White = Color3.new(1, 1, 1),
}
local C = UI.Colors

function UI.new(className: string, props, children: { Instance }?)
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
local new = UI.new

function UI.corner(radius: number?)
	return new("UICorner", { CornerRadius = UDim.new(0, radius or 4) })
end

function UI.stroke(color: Color3?, thickness: number?, transparency: number?)
	return new("UIStroke", { Color = color or C.Ink, Thickness = thickness or 2, Transparency = transparency or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

-- The little L-shaped corner marks on every card.
function UI.brackets(frame: GuiObject, color: Color3?, inset: number?)
	color = color or C.Line
	inset = inset or 6
	local length, thick = 10, 2
	for _, corner in { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) } do
		local holder = new("Frame", {
			Name = "Bracket",
			AnchorPoint = corner,
			Position = UDim2.new(corner.X, if corner.X == 0 then inset else -inset, corner.Y, if corner.Y == 0 then inset else -inset),
			Size = UDim2.fromOffset(length, length),
			BackgroundTransparency = 1,
			ZIndex = 20,
			Parent = frame,
		})
		new("Frame", { AnchorPoint = Vector2.new(corner.X, 0), Position = UDim2.fromScale(corner.X, corner.Y), Size = UDim2.new(1, 0, 0, thick), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 20, Parent = holder })
		new("Frame", { AnchorPoint = Vector2.new(0, corner.Y), Position = UDim2.fromScale(corner.X, corner.Y), Size = UDim2.new(0, thick, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 20, Parent = holder })
	end
end

function UI.text(props)
	local defaults = {
		BackgroundTransparency = 1,
		FontFace = UI.Font,
		TextColor3 = C.Ink,
		TextScaled = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	return new("TextLabel", defaults)
end

-- style: "Mint" (main action), "Dark", "Cream", "Red", "Disabled"
function UI.button(props, style: string?)
	style = style or "Mint"
	local looks = {
		Mint = { C.Mint, C.Ink },
		Dark = { C.Bar, C.White },
		Cream = { C.CreamDark, C.Ink },
		Red = { C.Red, C.White },
		Disabled = { C.CreamDark, C.Muted },
	}
	local look = looks[style]
	local defaults = {
		BackgroundColor3 = look[1],
		TextColor3 = look[2],
		FontFace = UI.FontHeavy,
		TextScaled = true,
		AutoButtonColor = style ~= "Disabled",
		BorderSizePixel = 0,
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = new("TextButton", defaults)
	button.Activated:Connect(function()
		Sounds.play("Click")
	end)
	new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = button })
	return button
end

function UI.setButtonStyle(button: TextButton, style: string)
	local looks = { Mint = { C.Mint, C.Ink }, Dark = { C.Bar, C.White }, Cream = { C.CreamDark, C.Ink }, Red = { C.Red, C.White }, Disabled = { C.CreamDark, C.Muted } }
	button.BackgroundColor3 = looks[style][1]
	button.TextColor3 = looks[style][2]
	button.AutoButtonColor = style ~= "Disabled"
end

-- A cream card with corner brackets.
function UI.panel(props)
	local defaults = { BackgroundColor3 = C.Cream, BorderSizePixel = 0 }
	for key, value in props do
		defaults[key] = value
	end
	local frame = new("Frame", defaults)
	UI.brackets(frame)
	return frame
end

-- Gold coin icon + amount, laid out horizontally.
function UI.coin(parent: Instance, size: number)
	local coin = new("Frame", { Name = "Coin", Size = UDim2.fromOffset(size, size), BackgroundColor3 = C.Gold, Parent = parent }, {
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		new("UIStroke", { Color = Color3.fromRGB(210, 140, 20), Thickness = math.max(1, size / 12) }),
	})
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.45, 0.45), BackgroundColor3 = Color3.fromRGB(255, 225, 120), Parent = coin }, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	return coin
end

function UI.formatNumber(amount: number): string
	local formatted = tostring(math.floor(amount))
	while true do
		local replaced, count = formatted:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		formatted = replaced
		if count == 0 then
			break
		end
	end
	return formatted
end

-- "Label [KEY]" hint like the ones in the bottom right corner.
function UI.keyHint(parent: Instance, label: string, key: string, order: number)
	local row = new("Frame", { LayoutOrder = order, Size = UDim2.fromOffset(170, 30), BackgroundTransparency = 1, Parent = parent })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 0), Parent = row })
	local name = UI.text({ Name = "Label", LayoutOrder = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), TextScaled = false, TextSize = 19, Text = "  " .. label .. "  ", BackgroundTransparency = 0, BackgroundColor3 = C.Cream, Parent = row })
	local keyBox = UI.text({ Name = "Key", LayoutOrder = 2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(30, 30), TextScaled = false, TextSize = 16, Text = " " .. key .. " ", BackgroundTransparency = 0, BackgroundColor3 = C.Bar, TextColor3 = C.White, FontFace = UI.FontHeavy, Parent = row })
	new("UISizeConstraint", { MinSize = Vector2.new(30, 30), Parent = keyBox })
	return row, name
end

-- Award banner ("MVP / Highest score") with arrow tails.
function UI.ribbon(parent: Instance, title: string, subtitle: string)
	local holder = new("Frame", { Size = UDim2.fromOffset(240, 62), BackgroundTransparency = 1, Parent = parent })
	for _, side in { 0, 1 } do
		UI.text({ AnchorPoint = Vector2.new(side, 0.5), Position = UDim2.fromScale(side, 0.5), Size = UDim2.fromOffset(24, 30), Text = if side == 0 then "▶" else "◀", TextColor3 = C.Cream, Parent = holder })
	end
	local card = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -40, 1, 0), Parent = holder })
	UI.text({ Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 0.55, -6), Text = title, FontFace = UI.FontHeavy, Parent = card })
	UI.text({ Position = UDim2.new(0, 8, 0.55, 0), Size = UDim2.new(1, -16, 0.45, -6), Text = subtitle, TextColor3 = C.Muted, FontFace = UI.FontRegular, Parent = card })
	return holder
end

-- Dark tab bar. tabs = { "Daily Shop", ... }. Returns { [name] = button } and a select fn.
function UI.tabBar(parent: Instance, tabs: { string }, onSelect: (string) -> ())
	local bar = new("Frame", { Name = "TabBar", Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = C.Bar, BorderSizePixel = 0, Parent = parent })
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 12), Parent = bar })
	new("UIPadding", { PaddingLeft = UDim.new(0, 16), Parent = bar })
	local buttons = {}
	local function select(name: string)
		for tabName, button in buttons do
			local active = tabName == name
			button.BackgroundTransparency = if active then 0 else 1
			button.TextColor3 = if active then C.Ink else C.White
		end
		onSelect(name)
	end
	for index, name in tabs do
		local button = new("TextButton", {
			LayoutOrder = index,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 46),
			BackgroundColor3 = C.Cream,
			BackgroundTransparency = 1,
			Text = "  " .. name .. "  ",
			FontFace = UI.FontHeavy,
			TextSize = 26,
			TextColor3 = C.White,
			BorderSizePixel = 0,
			Parent = bar,
		})
		new("UIStroke", { Color = C.White, Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = button })
		button.Activated:Connect(function()
			Sounds.play("Click")
			select(name)
		end)
		buttons[name] = button
	end
	return buttons, select, bar
end

-- The left-side lobby menu column. Every menu script adds its button here.
function UI.sideButton(player: Player, label: string, icon: string, order: number)
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:FindFirstChild("SideMenu")
	if not gui then
		gui = new("ScreenGui", { Name = "SideMenu", ResetOnSpawn = false, DisplayOrder = 2, Parent = playerGui })
		local column = new("Frame", { Name = "Column", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0), Size = UDim2.fromOffset(150, 400), BackgroundTransparency = 1, Parent = gui })
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Parent = column })
	end
	local button = new("TextButton", {
		LayoutOrder = order,
		Size = UDim2.fromOffset(150, 52),
		BackgroundColor3 = C.Cream,
		BorderSizePixel = 0,
		Text = "",
		Parent = gui.Column,
	})
	UI.brackets(button, C.Line, 4)
	button.Activated:Connect(function()
		Sounds.play("Click")
	end)
	UI.text({ Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(40, 40), Text = icon, Parent = button })
	UI.text({ Position = UDim2.fromOffset(52, 10), Size = UDim2.new(1, -60, 0, 32), Text = label, FontFace = UI.FontHeavy, TextXAlignment = Enum.TextXAlignment.Left, Parent = button })
	local badge = UI.text({ Name = "Badge", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 0, BackgroundColor3 = C.Red, TextColor3 = C.White, Text = "!", FontFace = UI.FontHeavy, Visible = false, ZIndex = 30, Parent = button })
	return button, badge, gui
end

-- Round avatar headshot (loads in the background).
function UI.avatar(props, userId: number)
	local defaults = { BackgroundColor3 = C.CreamDark, BorderSizePixel = 0, Image = "" }
	for key, value in props do
		defaults[key] = value
	end
	local image = new("ImageLabel", defaults, { new("UICorner", { CornerRadius = UDim.new(0.5, 0) }) })
	task.spawn(function()
		local Players = game:GetService("Players")
		local ok, url = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		if ok and image.Parent then
			image.Image = url
		end
	end)
	return image
end

-- Only one menu window open at a time: opening a registered window closes the others.
local exclusiveWindows = {}
function UI.exclusive(window: GuiObject)
	table.insert(exclusiveWindows, window)
	window:GetPropertyChangedSignal("Visible"):Connect(function()
		if window.Visible then
			for _, other in exclusiveWindows do
				if other ~= window and other.Visible then
					other.Visible = false
				end
			end
		end
	end)
end

-- Big red X close button in a window's top-right corner.
function UI.closeButton(window: GuiObject, onClose: (() -> ())?)
	local button = new("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = C.Red,
		BorderSizePixel = 0,
		Text = "X",
		TextColor3 = C.White,
		TextScaled = true,
		FontFace = UI.FontHeavy,
		ZIndex = 20,
		Parent = window,
	}, {
		new("UICorner", { CornerRadius = UDim.new(0, 8) }),
		new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
	})
	button.Activated:Connect(function()
		Sounds.play("Click")
		window.Visible = false
		if onClose then
			onClose()
		end
	end)
	return button
end

-- Scales a fixed-size window down on small screens.
function UI.autoScale(window: GuiObject, width: number, height: number)
	local scale = new("UIScale", { Parent = window })
	local camera = workspace.CurrentCamera
	local function update()
		local size = camera.ViewportSize
		scale.Scale = math.min(1, (size.X - 20) / width, (size.Y - 40) / height)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(update)
	update()
	return scale
end

return UI
