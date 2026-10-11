-- The lobby players wait in between races: a sandy plaza with stone walls, wooden
-- boardwalks, a tiered centre with the spawn, a car shop (walk up + E opens the garage),
-- two towers whose screens show the next track, and two showroom halls with every car.
-- It sits far away from the tracks so it never overlaps one.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CarBody = require(ReplicatedStorage.Shared.CarBody)
local Cars = require(ReplicatedStorage.Shared.Cars)
local Props = require(script.Parent.Props)

local Lobby = {}

Lobby.Origin = Vector3.new(0, 0, 2600)
local HALF = 150 -- floor is 300 x 300

local SAND = Color3.fromRGB(226, 202, 152)
local STONE = Color3.fromRGB(176, 166, 146)
local WOOD = Color3.fromRGB(168, 118, 70)
local BRICK = Color3.fromRGB(200, 125, 92)
local CREAM = Color3.fromRGB(232, 214, 176)
local BRIGHTS = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(60, 200, 90),
	Color3.fromRGB(60, 150, 255),
	Color3.fromRGB(255, 210, 40),
	Color3.fromRGB(255, 120, 200),
	Color3.fromRGB(120, 220, 255),
	Color3.fromRGB(40, 60, 200),
}

local screens = {}

local function nameplate(adornee: BasePart, title: string, subtitle: string)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(200, 54)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	gui.MaxDistance = 90
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
	local O = Lobby.Origin
	local function at(x, y, z)
		return CFrame.new(O + Vector3.new(x, y, z))
	end
	local function part(props)
		return Props.part(folder, props)
	end
	local random = Random.new(7)

	-- Floor and walls ---------------------------------------------------------------
	part({ Name = "Floor", Size = Vector3.new(HALF * 2, 2, HALF * 2), CFrame = at(0, -1, 0), Material = Enum.Material.Sand, Color = SAND })
	for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
		local along = Vector3.new(math.abs(side.Z), 0, math.abs(side.X))
		local base = O + side * (HALF - 2)
		part({ Name = "Wall", Size = along * (HALF * 2) + Vector3.new(4, 22, 4), CFrame = CFrame.new(base + Vector3.new(0, 11, 0)), Material = Enum.Material.Cobblestone, Color = STONE })
		part({ Name = "WallTrim", Size = along * (HALF * 2) + Vector3.new(6, 2, 6), CFrame = CFrame.new(base + Vector3.new(0, 23, 0)), Material = Enum.Material.WoodPlanks, Color = WOOD })
	end

	-- Boardwalks ---------------------------------------------------------------------
	local plank = { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(176, 124, 74) }
	for _, walk in {
		{ Vector3.new(20, 0.4, 90), Vector3.new(0, 0.2, -50) }, -- to the shop
		{ Vector3.new(20, 0.4, 80), Vector3.new(0, 0.2, 100) }, -- to the south gate
		{ Vector3.new(60, 0.4, 18), Vector3.new(-68, 0.2, 20) }, -- to the west showroom
		{ Vector3.new(60, 0.4, 18), Vector3.new(68, 0.2, 20) }, -- to the east showroom
	} do
		part({ Name = "Boardwalk", Size = walk[1], CFrame = at(walk[2].X, walk[2].Y, walk[2].Z), Material = plank.Material, Color = plank.Color })
	end

	-- Central tiers + spawn ----------------------------------------------------------
	for _, tier in {
		{ 84, 1.5, Enum.Material.Slate, Color3.fromRGB(165, 160, 155) },
		{ 66, 3, Enum.Material.Grass, Color3.fromRGB(90, 170, 70) },
		{ 46, 4.5, Enum.Material.Concrete, Color3.fromRGB(210, 200, 185) },
	} do
		part({
			Name = "Tier",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(tier[2], tier[1], tier[1]),
			CFrame = at(0, tier[2] / 2, 20) * CFrame.Angles(0, 0, math.rad(90)),
			Material = tier[3],
			Color = tier[4],
		})
	end
	for i = 1, 8 do
		local angle = (i - 0.5) / 8 * math.pi * 2
		local position = Vector3.new(math.cos(angle) * 38, 0, 20 + math.sin(angle) * 38)
		part({ Name = "Hedge", Size = Vector3.new(10, 3, 4), CFrame = at(position.X, 3, position.Z) * CFrame.Angles(0, -angle + math.pi / 2, 0), Material = Enum.Material.Grass, Color = Color3.fromRGB(70, 150, 60) })
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = at(0, 5, 20)
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(255, 120, 0)
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = folder

	-- Car shop (opens the garage) ----------------------------------------------------
	part({ Name = "ShopBack", Size = Vector3.new(64, 26, 2), CFrame = at(0, 13, -124), Material = Enum.Material.Brick, Color = BRICK })
	for _, x in { -31, 31 } do
		part({ Name = "ShopSide", Size = Vector3.new(2, 26, 30), CFrame = at(x, 13, -110), Material = Enum.Material.Brick, Color = BRICK })
	end
	part({ Name = "ShopRoof", Size = Vector3.new(68, 1.5, 34), CFrame = at(0, 26.75, -110), Material = Enum.Material.WoodPlanks, Color = WOOD })
	part({ Name = "ShopHeader", Size = Vector3.new(64, 6, 2), CFrame = at(0, 23, -96), Material = Enum.Material.Brick, Color = BRICK })
	part({ Name = "ShopFloor", Size = Vector3.new(60, 0.3, 26), CFrame = at(0, 0.15, -110), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 95, 60) })
	local counter = part({ Name = "Counter", Size = Vector3.new(64, 7, 2), CFrame = at(0, 3.5, -96), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(196, 146, 94) })
	part({ Name = "CounterTop", Size = Vector3.new(64, 0.6, 4), CFrame = at(0, 7.3, -95.5), Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 80, 50) })
	for i = 0, 7 do
		part({
			Name = "Awning",
			Size = Vector3.new(8, 0.4, 10),
			CFrame = at(-28 + i * 8, 18.5, -91.5) * CFrame.Angles(math.rad(-22), 0, 0),
			Material = Enum.Material.Fabric,
			Color = if i % 2 == 0 then Color3.fromRGB(220, 50, 60) else Color3.fromRGB(245, 245, 245),
		})
	end
	local shopSign = part({ Name = "ShopSign", Size = Vector3.new(40, 8, 1), CFrame = at(0, 32, -97), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 130, 230) })
	Props.sign(shopSign, "🛠 GARAGE", Color3.new(1, 1, 1))
	for i = 0, 5 do -- stacked tires inside
		part({ Name = "Tire", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 4, 4), CFrame = at(-22 + (i // 3) * 6, 0.75 + (i % 3) * 1.6, -118) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 30, 32) })
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenGarage"
	prompt.ActionText = "Open Garage"
	prompt.ObjectText = "Car Shop"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter

	-- Towers with screens --------------------------------------------------------------
	for _, tower in { { -52, Color3.fromRGB(240, 200, 40) }, { 52, Color3.fromRGB(220, 60, 60) } } do
		local x = tower[1]
		part({ Name = "Tower", Size = Vector3.new(18, 44, 18), CFrame = at(x, 22, -112), Material = Enum.Material.Brick, Color = CREAM })
		part({ Name = "TowerBand", Size = Vector3.new(19, 2, 19), CFrame = at(x, 36, -112), Material = Enum.Material.WoodPlanks, Color = WOOD })
		for _, side in { -1, 1 } do
			part({
				ClassName = "WedgePart",
				Name = "TowerRoof",
				Size = Vector3.new(22, 8, 11),
				CFrame = at(x, 48, -112 + side * 5.5) * CFrame.Angles(0, if side < 0 then 0 else math.pi, 0),
				Material = Enum.Material.SmoothPlastic,
				Color = tower[2],
			})
		end
		local screen = part({
			Name = "Screen",
			Size = Vector3.new(15, 10, 0.6),
			CFrame = CFrame.lookAt(O + Vector3.new(x, 26, -102.8), O + Vector3.new(x, 26, 0)),
			Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(15, 15, 20),
		})
		Props.sign(screen, "", Color3.fromRGB(120, 255, 160), Enum.NormalId.Front)
		table.insert(screens, screen:FindFirstChildOfClass("SurfaceGui").Text)
	end

	-- Showroom halls with every car ------------------------------------------------------
	local perHall = math.ceil(#Cars.List / 2)
	for hall, side in { -1, 1 } do
		local cx = side * 117
		part({ Name = "HallBack", Size = Vector3.new(2, 22, 120), CFrame = at(side * 137, 11, 20), Material = Enum.Material.Brick, Color = CREAM })
		for _, z in { -40, 80 } do
			part({ Name = "HallEnd", Size = Vector3.new(40, 22, 2), CFrame = at(cx, 11, z), Material = Enum.Material.Brick, Color = CREAM })
		end
		part({ Name = "HallRoof", Size = Vector3.new(44, 1.5, 124), CFrame = at(cx, 22.75, 20), Material = Enum.Material.WoodPlanks, Color = WOOD })
		local header = part({ Name = "HallHeader", Size = Vector3.new(2, 6, 120), CFrame = at(side * 98, 19, 20), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 130, 230) })
		Props.sign(header, "SHOWROOM", Color3.new(1, 1, 1), if side < 0 then Enum.NormalId.Right else Enum.NormalId.Left)
		part({ Name = "HallFloor", Size = Vector3.new(38, 0.3, 118), CFrame = at(cx, 0.15, 20), Material = Enum.Material.Marble, Color = Color3.fromRGB(235, 235, 240) })

		for slot = 1, perHall do
			local car = Cars.List[(hall - 1) * perHall + slot]
			if car then
				local z = -22 + (slot - 1) * 23
				local position = O + Vector3.new(cx - side * 4, 0, z)
				local pedestal = part({
					Name = "Pedestal",
					Shape = Enum.PartType.Cylinder,
					Size = Vector3.new(0.6, 18, 18),
					CFrame = CFrame.new(position + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)),
					Material = Enum.Material.Neon,
					Color = car.Colors.Primary,
				})
				local facing = CFrame.lookAt(position + Vector3.new(0, 0.9, 0), position + Vector3.new(-side, 0.9, 0)) * CFrame.Angles(0, math.rad(side * 30), 0)
				local model = CarBody.build(car, facing, false)
				model.Name = "Showroom_" .. car.Id
				model.Parent = folder
				nameplate(pedestal, car.Name, if car.Price == 0 then "FREE" else "$" .. car.Price)
			end
		end
	end

	-- Entrance arch ------------------------------------------------------------------------
	for _, x in { -14, 14 } do
		part({ Name = "ArchPost", Size = Vector3.new(4, 28, 4), CFrame = at(x, 14, 140), Material = Enum.Material.Brick, Color = BRICK })
	end
	local arch = part({ Name = "ArchSign", Size = Vector3.new(40, 8, 2), CFrame = at(0, 30, 140), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 100, 0) })
	Props.sign(arch, "ILLEGAL RACING")

	-- Trees and lamps ------------------------------------------------------------------------
	for _, spot in { { -80, -70 }, { 80, -70 }, { -80, 110 }, { 80, 110 }, { -40, 125 }, { 40, 125 }, { -60, -20 }, { 60, -20 } } do
		Props.tree(folder, O + Vector3.new(spot[1], 0, spot[2]), 1 + random:NextNumber() * 0.4, "round")
	end
	for _, spot in { { -14, -30 }, { 14, -30 }, { -14, 80 }, { 14, 80 } } do
		part({ Name = "LampPost", Size = Vector3.new(0.8, 14, 0.8), CFrame = at(spot[1], 7, spot[2]), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 45) })
		local lamp = part({ Name = "Lamp", Size = Vector3.new(2, 2, 2), CFrame = at(spot[1], 14.5, spot[2]), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200) })
		local light = Instance.new("PointLight")
		light.Range = 30
		light.Parent = lamp
	end

	-- Daily spin booth: a big prize wheel on a stand (walk up + E to spin).
	local booth = Vector3.new(40, 0, 78)
	part({ Name = "SpinStage", Size = Vector3.new(24, 1, 14), CFrame = at(booth.X, 0.5, booth.Z), Material = Enum.Material.WoodPlanks, Color = WOOD })
	for _, x in { -6, 6 } do
		part({ Name = "SpinStand", Size = Vector3.new(1.5, 16, 1.5), CFrame = at(booth.X + x, 8, booth.Z), Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 70, 75) })
	end
	local hub = at(booth.X, 15, booth.Z + 0.8)
	local prizes = require(ReplicatedStorage.Shared.Config).Spin.Prizes
	for i, prize in prizes do
		part({
			Name = "SpinSlice",
			Size = Vector3.new(4.4, 9, 0.6),
			CFrame = hub * CFrame.Angles(0, 0, (i - 1) / #prizes * math.pi * 2) * CFrame.new(0, 4.5, 0),
			Material = Enum.Material.SmoothPlastic,
			Color = prize.Color,
		})
	end
	part({ Name = "SpinHub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 4, 4), CFrame = hub * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(255, 220, 60) })
	local spinSign = part({ Name = "SpinSign", Size = Vector3.new(18, 4, 0.6), CFrame = at(booth.X, 26.5, booth.Z), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 60, 160) })
	Props.sign(spinSign, "🎡 DAILY SPIN")
	local spinPrompt = Instance.new("ProximityPrompt")
	spinPrompt.Name = "OpenSpin"
	spinPrompt.ActionText = "Spin the Wheel"
	spinPrompt.ObjectText = "Daily Spin"
	spinPrompt.HoldDuration = 0
	spinPrompt.MaxActivationDistance = 16
	spinPrompt.RequiresLineOfSight = false
	spinPrompt.Parent = spinSign

	-- Colourful cubes you can push around --------------------------------------------------
	local placed = 0
	while placed < 26 do
		local x, z = random:NextInteger(-HALF + 15, HALF - 15), random:NextInteger(-85, HALF - 20)
		local clearOfPlaza = Vector2.new(x, z - 20).Magnitude > 50
		local clearOfPaths = math.abs(x) > 14 and math.abs(z - 20) > 12
		local clearOfHalls = math.abs(x) < 90
		local clearOfBooth = Vector2.new(x - 40, z - 78).Magnitude > 20
		if clearOfPlaza and clearOfPaths and clearOfHalls and clearOfBooth then
			local size = random:NextInteger(4, 7)
			part({
				Name = "Cube",
				Anchored = false,
				Size = Vector3.one * size,
				CFrame = at(x, size / 2, z) * CFrame.Angles(0, random:NextNumber() * math.pi, 0),
				Material = Enum.Material.Plastic,
				Color = BRIGHTS[random:NextInteger(1, #BRIGHTS)],
				TopSurface = Enum.SurfaceType.Studs,
				BottomSurface = Enum.SurfaceType.Inlet,
			})
			placed += 1
		end
	end

	return spawn
end

-- Keeps the tower screens showing the next track and countdown.
function Lobby.startScreens()
	task.spawn(function()
		while true do
			local state = workspace:GetAttribute("RaceState")
			local trackName = workspace:GetAttribute("TrackName") or "..."
			local remaining = math.max(0, math.ceil((workspace:GetAttribute("StateEndsAt") or 0) - workspace:GetServerTimeNow()))
			local message
			if state == "Intermission" then
				message = string.format("NEXT RACE\n%s\n%ds", trackName, remaining)
			elseif state == "Racing" or state == "Countdown" then
				message = "RACE LIVE\n" .. trackName
			else
				message = "RESULTS\n" .. trackName
			end
			for _, label in screens do
				label.Text = message
			end
			task.wait(0.5)
		end
	end)
end

return Lobby
