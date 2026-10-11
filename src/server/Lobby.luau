-- The lobby players wait in between races: a studded baseplate with every car on a
-- showroom pedestal. It sits far away from the tracks so it never overlaps one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBody = require(ReplicatedStorage.Shared.CarBody)
local Cars = require(ReplicatedStorage.Shared.Cars)

local Lobby = {}

Lobby.Origin = Vector3.new(0, 0, 2600)
local SIZE = 280

local function part(parent: Instance, props)
	local p = Instance.new("Part")
	p.Anchored = true
	for key, value in props do
		p[key] = value
	end
	p.Parent = parent
	return p
end

local function billboard(adornee: BasePart, title: string, subtitle: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 10, 0)
	gui.MaxDistance = 120
	gui.AlwaysOnTop = false
	for i, line in { title, subtitle } do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0.5, 0)
		label.Position = UDim2.fromScale(0, (i - 1) * 0.5)
		label.BackgroundTransparency = 1
		label.Text = line
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = if i == 1 then Color3.new(1, 1, 1) else Color3.fromRGB(255, 210, 0)
		label.TextStrokeTransparency = 0.3
		label.Parent = gui
	end
	gui.Parent = adornee
end

function Lobby.build()
	local existing = workspace:FindFirstChild("Lobby")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lobby"
	folder.Parent = workspace
	local origin = Lobby.Origin

	part(folder, {
		Name = "Floor",
		Size = Vector3.new(SIZE, 2, SIZE),
		CFrame = CFrame.new(origin + Vector3.new(0, -1, 0)),
		Material = Enum.Material.Plastic,
		Color = Color3.fromRGB(90, 90, 100),
		TopSurface = Enum.SurfaceType.Studs,
	})
	for _, side in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local along = Vector3.new(math.abs(side.Z), 0, math.abs(side.X))
		part(folder, {
			Name = "Fence",
			Size = along * SIZE + Vector3.new(2, 8, 2),
			CFrame = CFrame.new(origin + side * (SIZE / 2) + Vector3.new(0, 4, 0)),
			Material = Enum.Material.Plastic,
			Color = Color3.fromRGB(255, 120, 0),
			TopSurface = Enum.SurfaceType.Studs,
		})
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(origin + Vector3.new(0, 0.5, 0))
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(255, 80, 0)
	spawn.Parent = folder

	-- Showroom ring: every car on a pedestal, facing the spawn.
	local radius = 80
	for index, car in Cars.List do
		local angle = (index - 1) / #Cars.List * math.pi * 2
		local position = origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		local pedestal = part(folder, {
			Name = "Pedestal",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1, 20, 20),
			CFrame = CFrame.new(position + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Material = Enum.Material.Neon,
			Color = car.Colors.Primary,
		})
		local facing = CFrame.lookAt(position + Vector3.new(0, 1, 0), origin + Vector3.new(0, 1, 0)) * CFrame.Angles(0, math.rad(35), 0)
		local model = CarBody.build(car, facing, false)
		model.Name = "Showroom_" .. car.Id
		model.Parent = folder
		billboard(pedestal, car.Name, if car.Price == 0 then "FREE" else "$" .. car.Price)
	end

	return spawn
end

return Lobby
