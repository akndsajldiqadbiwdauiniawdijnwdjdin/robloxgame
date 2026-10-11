-- Coral Coast: a wooden boardwalk on a sandy causeway across a tropical sea. Race past the
-- pier grandstand, around Lighthouse Point, jump between islands (or take the reef
-- sandbar), through the sea cave and cut the west sandbar home. Fall in = rescue.
return {
	Name = "Coral Coast",
	Laps = 3,
	Seed = 44,
	Width = 32,
	Surface = "Road",
	Curbs = false,
	RoadMaterial = Enum.Material.WoodPlanks,
	RoadColor = Color3.fromRGB(176, 128, 82),
	BannerColor = Color3.fromRGB(0, 170, 220),
	Ground = { Y = -14, Material = Enum.Material.Sand, Color = Color3.fromRGB(205, 185, 135), Surface = "Offroad", Margin = 350 },
	Water = { Level = 0.6, Color = Color3.fromRGB(20, 150, 200), Transparency = 0.3 },
	KillY = -3, -- fell in the sea
	Border = { Width = 8, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(240, 220, 165) },
	Barrier = { Height = 2.5, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 95, 60) },
	Support = "Fill",
	FillMaterial = Enum.Material.Sand,
	FillColor = Color3.fromRGB(225, 200, 145),
	Lighting = {
		ClockTime = 14,
		Brightness = 2.8,
		Ambient = Color3.fromRGB(120, 130, 140),
		OutdoorAmbient = Color3.fromRGB(140, 150, 160),
		FogEnd = 2600,
		FogColor = Color3.fromRGB(180, 220, 240),
		ExposureCompensation = 0,
	},
	Atmosphere = { Density = 0.25, Haze = 0.5, Color = Color3.fromRGB(190, 230, 255) },

	Points = {
		Vector3.new(0, 3, 300), -- 1 start / finish on the pier
		Vector3.new(220, 3, 300),
		Vector3.new(330, 3, 220),
		Vector3.new(300, 3, 120),
		Vector3.new(380, 6, 40), -- 5 Lighthouse Point
		Vector3.new(360, 12, -80),
		Vector3.new(240, 12, -130),
		Vector3.new(160, 10, -60), -- 8 island jump (or the reef sandbar)
		Vector3.new(60, 6, -120),
		Vector3.new(-60, 3, -220), -- 10 sea cave
		Vector3.new(-220, 3, -200),
		Vector3.new(-300, 3, -90), -- 12 west loop (sandbar shortcut)
		Vector3.new(-230, 3, 10),
		Vector3.new(-340, 3, 120),
		Vector3.new(-260, 3, 230),
		Vector3.new(-120, 3, 290),
	},

	Gaps = {
		{ From = 8.45, To = 8.6 },
	},
	Shortcuts = {
		{ Width = 16, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(240, 220, 165), Points = { Vector3.new(-285, 3, -80), Vector3.new(-330, 3, 15), Vector3.new(-345, 3, 105) } },
		{ Width = 14, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(250, 190, 170), Points = { Vector3.new(175, 10, -75), Vector3.new(110, 8, -20), Vector3.new(50, 6, -110) } }, -- coral reef
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 4.5, Offset = 6 },
		{ At = 8.2, Offset = 0, Width = 18 }, -- before the island jump
		{ At = 11.5, Offset = -6 },
		{ At = 15.0, Offset = 0 },
	},
	Ramps = {
		{ At = 8.34, Offset = 0, Width = 32, Length = 20, Angle = 13, Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks },
	},
	PickupRows = { 2.2, 6.0, 10.5, 14.0 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random
		local seaFloor = api.GroundY

		local function island(position: Vector3, radius: number, palms: number)
			api.part({ Name = "Island", Shape = Enum.PartType.Cylinder, Size = Vector3.new(16, radius * 2, radius * 2), CFrame = CFrame.new(position.X, 1.5 - 8, position.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Sand, Color = Color3.fromRGB(240, 220, 165), Attributes = { Surface = "Offroad" } })
			for _ = 1, palms do
				local angle = random:NextNumber() * math.pi * 2
				local r = random:NextNumber() * radius * 0.6
				P.tree(folder, Vector3.new(position.X + math.cos(angle) * r, 1.5, position.Z + math.sin(angle) * r), 1 + random:NextNumber() * 0.4, "palm")
			end
		end

		-- Palm islands dotted around the sea, rock stacks in the distance.
		for _ = 1, 30 do
			local spot = api.Center + Vector3.new(random:NextInteger(-520, 520), 0, random:NextInteger(-420, 420))
			local radius = random:NextInteger(12, 26)
			if api.isClear(spot, radius + 4) then
				island(spot, radius, random:NextInteger(1, 3))
			end
		end
		P.ring(api.Center, api.Extent + 260, 22, function(position)
			local h = random:NextInteger(30, 90)
			api.part({ Name = "SeaStack", Size = Vector3.new(random:NextInteger(30, 60), h + 14, random:NextInteger(30, 60)), CFrame = CFrame.new(position + Vector3.new(0, seaFloor + (h + 14) / 2, 0)) * CFrame.Angles(0, random:NextNumber() * 3, 0), Material = Enum.Material.Slate, Color = Color3.fromRGB(125, 120, 115) })
		end)

		-- Lighthouse Point.
		local base = Vector3.new(290, 0, -20)
		api.part({ Name = "LighthouseRock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(22, 40, 40), CFrame = CFrame.new(base.X, seaFloor + 9, base.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Slate, Color = Color3.fromRGB(120, 115, 110) })
		for i = 0, 5 do
			api.part({ Name = "LighthouseRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 14 - i, 14 - i), CFrame = CFrame.new(base.X, 3 + i * 10, base.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = if i % 2 == 0 then Color3.fromRGB(240, 240, 240) else Color3.fromRGB(220, 40, 40) })
		end
		local lamp = api.part({ Name = "LighthouseLamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 9, CFrame = CFrame.new(base.X, 63, base.Z), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 160) })
		local light = Instance.new("PointLight")
		light.Range = 60
		light.Brightness = 3
		light.Parent = lamp

		-- Sunken pirate ship in the middle of the bay.
		local ship = CFrame.new(-110, seaFloor + 10, 70) * CFrame.Angles(math.rad(18), math.rad(30), math.rad(-12))
		api.part({ Name = "Hull", Size = Vector3.new(24, 16, 70), CFrame = ship, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(95, 60, 35) })
		api.part({ Name = "Mast", Size = Vector3.new(2, 50, 2), CFrame = ship * CFrame.new(0, 30, -8), Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 50, 30) })
		api.part({ Name = "Sail", Size = Vector3.new(26, 18, 0.5), CFrame = ship * CFrame.new(0, 38, -8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(235, 225, 200) })
		local flag = api.part({ Name = "Flag", Size = Vector3.new(8, 5, 0.3), CFrame = ship * CFrame.new(4, 56, -8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(20, 20, 20) })
		api.sign(flag, "☠", Color3.new(1, 1, 1))

		-- Coral under the reef shortcut.
		local coralColors = { Color3.fromRGB(255, 110, 140), Color3.fromRGB(255, 170, 60), Color3.fromRGB(180, 90, 255), Color3.fromRGB(80, 220, 200) }
		for _ = 1, 26 do
			local spot = Vector3.new(random:NextInteger(40, 190), 0, random:NextInteger(-120, 0))
			if api.isClear(spot, 2) then
				api.part({ Name = "Coral", Shape = Enum.PartType.Ball, Size = Vector3.one * random:NextInteger(3, 7), CFrame = CFrame.new(spot.X, -1, spot.Z), Material = Enum.Material.SmoothPlastic, Color = coralColors[random:NextInteger(1, #coralColors)] })
			end
		end

		-- Boats, buoys and shark fins.
		for _ = 1, 12 do
			local spot = api.Center + Vector3.new(random:NextInteger(-500, 500), 0, random:NextInteger(-400, 400))
			if api.isClear(spot, 12) then
				local cf = CFrame.new(spot.X, 0.8, spot.Z) * CFrame.Angles(0, random:NextNumber() * math.pi * 2, 0)
				api.part({ Name = "Boat", Size = Vector3.new(8, 3, 18), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 240) })
				api.part({ Name = "BoatStripe", Size = Vector3.new(8.2, 0.8, 18.2), CFrame = cf * CFrame.new(0, 0.6, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 110, 200) })
				api.part({ Name = "BoatCabin", Size = Vector3.new(6, 4, 6), CFrame = cf * CFrame.new(0, 3.5, 2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 240) })
			end
		end
		for _ = 1, 30 do
			local spot = api.Center + Vector3.new(random:NextInteger(-480, 480), 0, random:NextInteger(-380, 380))
			if api.isClear(spot, 3) then
				if random:NextNumber() < 0.6 then
					api.part({ Name = "Buoy", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, CFrame = CFrame.new(spot.X, 1.2, spot.Z), Material = Enum.Material.SmoothPlastic, Color = if random:NextNumber() < 0.5 then Color3.fromRGB(230, 40, 40) else Color3.fromRGB(250, 200, 0) })
				else
					api.part({ ClassName = "WedgePart", Name = "SharkFin", Size = Vector3.new(0.6, 4, 4), CFrame = CFrame.new(spot.X, 2.5, spot.Z) * CFrame.Angles(0, random:NextNumber() * math.pi * 2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(110, 120, 130) })
				end
			end
		end

		-- Pier with grandstand, beach huts and umbrellas along the start straight.
		local pierZ = 300 + api.Edge + 18
		api.part({ Name = "Pier", Size = Vector3.new(260, 1, 40), CFrame = CFrame.new(100, 2.5, pierZ), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(160, 115, 75) })
		for x = -20, 220, 20 do
			api.part({ Name = "PierPost", Size = Vector3.new(1.5, 18, 1.5), CFrame = CFrame.new(x, -6, pierZ + 19), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 75, 45) })
		end
		api.grandstand(1.45, 1, 70, Color3.fromRGB(0, 170, 220), 3)
		for i, x in { 150, 185, 215 } do
			local spot = Vector3.new(x, 3, pierZ + 6)
			if i % 2 == 1 then
				api.part({ Name = "Hut", Size = Vector3.new(12, 8, 10), CFrame = CFrame.new(spot + Vector3.new(0, 4, 0)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(190, 145, 95) })
				api.part({ ClassName = "WedgePart", Name = "HutRoof", Size = Vector3.new(14, 4, 12), CFrame = CFrame.new(spot + Vector3.new(0, 10, 0)), Material = Enum.Material.Grass, Color = Color3.fromRGB(200, 180, 90) })
			else
				api.part({ Name = "UmbrellaPole", Size = Vector3.new(0.4, 8, 0.4), CFrame = CFrame.new(spot + Vector3.new(0, 4, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(240, 240, 240) })
				api.part({ Name = "Umbrella", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 10, 10), CFrame = CFrame.new(spot + Vector3.new(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(240, 70, 90) })
			end
		end

		-- Set pieces: sea cave tunnel and arches.
		api.tunnel(10.1, 10.9, { Height = 18, Material = Enum.Material.Slate, Color = Color3.fromRGB(110, 105, 100), LightColor = Color3.fromRGB(120, 220, 255) })
		api.arch(1.25, "CORAL COAST", Color3.fromRGB(0, 140, 190))
		api.arch(5.5, "LIGHTHOUSE POINT", Color3.fromRGB(200, 40, 40))
	end,
}
