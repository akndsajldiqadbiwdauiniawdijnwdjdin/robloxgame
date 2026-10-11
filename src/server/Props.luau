-- Reusable scenery pieces for the lobby and the tracks. Every function takes the folder
-- to build into and returns the main part (or model).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBody = require(ReplicatedStorage.Shared.CarBody)
local Cars = require(ReplicatedStorage.Shared.Cars)

local Props = {}

function Props.part(parent: Instance, props)
	local part = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local attributes = props.Attributes
	props.Attributes = nil
	for key, value in props do
		part[key] = value
	end
	for key, value in attributes or {} do
		part:SetAttribute(key, value)
	end
	part.Parent = parent
	return part
end
local part = Props.part

function Props.sign(target: BasePart, text: string, color: Color3?, face: Enum.NormalId?)
	for _, f in if face then { face } else { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = f
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = color or Color3.new(1, 1, 1)
		label.Parent = gui
		gui.Parent = target
	end
end

-- Trees. style: "round" (park tree), "pine", "palm", "dead" (desert).
function Props.tree(parent: Instance, position: Vector3, size: number, style: string?)
	style = style or "round"
	local trunkColor = if style == "dead" then Color3.fromRGB(120, 90, 60) else Color3.fromRGB(105, 70, 40)
	local height = 10 * size
	local trunk = part(parent, {
		Name = "Trunk",
		Size = Vector3.new(1.6 * size, height, 1.6 * size),
		CFrame = CFrame.new(position + Vector3.new(0, height / 2, 0)),
		Material = Enum.Material.Wood,
		Color = trunkColor,
	})
	if style == "round" then
		for i, offset in { Vector3.new(0, 0, 0), Vector3.new(2.5, -1.5, 1), Vector3.new(-2, -1, -2) } do
			part(parent, {
				Name = "Leaves",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * (8 - i) * size,
				CFrame = CFrame.new(position + Vector3.new(0, height, 0) + offset * size),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(60, 150 - i * 10, 55),
			})
		end
	elseif style == "pine" then
		for i = 0, 2 do
			part(parent, {
				Name = "Needles",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3 * size, (9 - i * 2.5) * size, (9 - i * 2.5) * size),
				CFrame = CFrame.new(position + Vector3.new(0, height * 0.6 + i * 3 * size, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(40, 110, 60),
			})
		end
	elseif style == "palm" then
		trunk.Size = Vector3.new(1.2 * size, height * 1.3, 1.2 * size)
		trunk.CFrame = CFrame.new(position + Vector3.new(0, height * 0.65, 0)) * CFrame.Angles(0, 0, math.rad(6))
		for i = 0, 4 do
			part(parent, {
				Name = "Frond",
				Size = Vector3.new(1.2 * size, 0.3 * size, 7 * size),
				CFrame = CFrame.new(position + Vector3.new(0, height * 1.3, 0)) * CFrame.Angles(0, i * math.pi * 2 / 5, 0) * CFrame.new(0, -0.8 * size, 3 * size) * CFrame.Angles(math.rad(-20), 0, 0),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(60, 160, 60),
			})
		end
	elseif style == "dead" then
		for i, angle in { 35, -40 } do
			part(parent, {
				Name = "Branch",
				Size = Vector3.new(0.8 * size, 5 * size, 0.8 * size),
				CFrame = CFrame.new(position + Vector3.new(0, height * (0.55 + i * 0.15), 0)) * CFrame.Angles(0, i * 2, math.rad(angle)) * CFrame.new(0, 2 * size, 0),
				Material = Enum.Material.Wood,
				Color = trunkColor,
			})
		end
	end
	return trunk
end

-- Two posts and a board with text facing `cframe.LookVector`.
function Props.billboard(parent: Instance, cframe: CFrame, text: string, boardColor: Color3, textColor: Color3?, neon: boolean?)
	local width, height, lift = 28, 10, 14
	for _, side in { -1, 1 } do
		part(parent, {
			Name = "Post",
			Size = Vector3.new(1, lift, 1),
			CFrame = cframe * CFrame.new(side * width * 0.35, lift / 2, 0),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(60, 60, 65),
		})
	end
	local board = part(parent, {
		Name = "Billboard",
		Size = Vector3.new(width, height, 1),
		CFrame = cframe * CFrame.new(0, lift + height / 2, 0),
		Material = if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic,
		Color = boardColor,
	})
	Props.sign(board, text, textColor)
	return board
end

-- A parked, non-colliding display car (any car Id from Cars.luau).
function Props.parkedCar(parent: Instance, cframe: CFrame, carId: string?)
	local car = Cars.ById[carId or ""] or Cars.List[math.random(1, #Cars.List)]
	local model = CarBody.build(car, cframe, false)
	model.Name = "Parked_" .. car.Id
	model.Parent = parent
	return model
end

-- Calls fn(position, angle, index) for `count` points on a circle (a "skyline ring" that
-- hides the edge of the world).
function Props.ring(center: Vector3, radius: number, count: number, fn)
	for i = 1, count do
		local angle = (i - 1) / count * math.pi * 2
		fn(center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), angle, i)
	end
end

return Props
