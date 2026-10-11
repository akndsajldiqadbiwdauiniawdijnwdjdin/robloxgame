-- Coral Coast: a wooden boardwalk on a sandy causeway across a tropical sea. Climb to the
-- lighthouse island, jump the gap between islands (miss it and you're swimming), and cut
-- across the sandbar on the west side.
return {
	Name = "Coral Coast",
	Laps = 3,
	Seed = 44,
	Width = 36,
	Surface = "Road",
	Curbs = false,
	RoadMaterial = Enum.Material.WoodPlanks,
	RoadColor = Color3.fromRGB(176, 128, 82),
	BannerColor = Color3.fromRGB(0, 170, 220),
	Ground = { Y = -14, Material = Enum.Material.Sand, Color = Color3.fromRGB(205, 185, 135), Surface = "Offroad", Margin = 350 },
	Water = { Level = 0.6, Color = Color3.fromRGB(20, 150, 200), Transparency = 0.3 },
	KillY = -3, -- fell in the sea
	Border = { Width = 10, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(240, 220, 165) },
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
		Vector3.new(0, 3, 275), -- 1 start / finish on the pier
		Vector3.new(200, 3, 275),
		Vector3.new(338, 3, 212),
		Vector3.new(375, 6, 75),
		Vector3.new(312, 12, -50), -- 5 lighthouse island
		Vector3.new(188, 12, -112),
		Vector3.new(38, 6, -138), -- 7 gap jump between islands
		Vector3.new(-112, 3, -188),
		Vector3.new(-262, 3, -138),
		Vector3.new(-362, 3, -12), -- 10 west loop (sandbar shortcut cuts inside)
		Vector3.new(-338, 3, 125),
		Vector3.new(-212, 3, 212),
		Vector3.new(-112, 3, 269),
	},

	Gaps = {
		{ From = 6.42, To = 6.56 },
	},
	Shortcuts = {
		{
			Width = 18,
			Surface = "Offroad",
			Material = Enum.Material.Sand,
			Color = Color3.fromRGB(240, 220, 165),
			Points = { Vector3.new(-269, 3, -119), Vector3.new(-250, 3, 38), Vector3.new(-225, 3, 188) },
		},
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 3.4, Offset = 6 },
		{ At = 6.28, Offset = 0, Width = 18 }, -- before the island jump
		{ At = 8.5, Offset = -6 },
		{ At = 12.5, Offset = 0 },
	},
	Ramps = {
		{ At = 6.36, Offset = 0, Width = 36, Length = 20, Angle = 13, Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks },
	},
	PickupRows = { 2.3, 5.6, 8.9, 11.6 },

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

		-- Palm islands dotted around the sea.
		for _ = 1, 26 do
			local spot = api.Center + Vector3.new(random:NextInteger(-520, 520), 0, random:NextInteger(-420, 420))
			local radius = random:NextInteger(14, 30)
			if api.isClear(spot, radius + 4) then
				island(spot, radius, random:NextInteger(1, 3))
			end
		end

		-- Lighthouse on its own rock next to the climb.
		local base = Vector3.new(250, 0, 40)
		api.part({ Name = "LighthouseRock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(22, 44, 44), CFrame = CFrame.new(base.X, seaFloor + 9, base.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Slate, Color = Color3.fromRGB(120, 115, 110) })
		for i = 0, 5 do
			api.part({ Name = "LighthouseRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 14 - i, 14 - i), CFrame = CFrame.new(base.X, -2 + 5 + i * 10, base.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = if i % 2 == 0 then Color3.fromRGB(240, 240, 240) else Color3.fromRGB(220, 40, 40) })
		end
		local lamp = api.part({ Name = "LighthouseLamp", Shape = Enum.PartType.Ball, Size = Vector3.one * 9, CFrame = CFrame.new(base.X, 63, base.Z), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 160) })
		local light = Instance.new("PointLight")
		light.Range = 60
		light.Brightness = 3
		light.Parent = lamp

		-- Sunken pirate ship, sticking out of the water.
		local ship = CFrame.new(-120, seaFloor + 10, 40) * CFrame.Angles(math.rad(18), math.rad(30), math.rad(-12))
		api.part({ Name = "Hull", Size = Vector3.new(24, 16, 70), CFrame = ship, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(95, 60, 35) })
		api.part({ Name = "Mast", Size = Vector3.new(2, 50, 2), CFrame = ship * CFrame.new(0, 30, -8), Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 50, 30) })
		api.part({ Name = "Sail", Size = Vector3.new(26, 18, 0.5), CFrame = ship * CFrame.new(0, 38, -8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(235, 225, 200) })
		local flag = api.part({ Name = "Flag", Size = Vector3.new(8, 5, 0.3), CFrame = ship * CFrame.new(4, 56, -8), Material = Enum.Material.Fabric, Color = Color3.fromRGB(20, 20, 20) })
		api.sign(flag, "☠", Color3.new(1, 1, 1))

		-- Boats, buoys and shark fins.
		for _ = 1, 10 do
			local spot = api.Center + Vector3.new(random:NextInteger(-500, 500), 0, random:NextInteger(-400, 400))
			if api.isClear(spot, 12) then
				local cf = CFrame.new(spot.X, 0.8, spot.Z) * CFrame.Angles(0, random:NextNumber() * math.pi * 2, 0)
				api.part({ Name = "Boat", Size = Vector3.new(8, 3, 18), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 240) })
				api.part({ Name = "BoatStripe", Size = Vector3.new(8.2, 0.8, 18.2), CFrame = cf * CFrame.new(0, 0.6, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 110, 200) })
				api.part({ Name = "BoatCabin", Size = Vector3.new(6, 4, 6), CFrame = cf * CFrame.new(0, 3.5, 2), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(240, 240, 240) })
			end
		end
		for _ = 1, 24 do
			local spot = api.Center + Vector3.new(random:NextInteger(-480, 480), 0, random:NextInteger(-380, 380))
			if api.isClear(spot, 3) then
				if random:NextNumber() < 0.6 then
					api.part({ Name = "Buoy", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, CFrame = CFrame.new(spot.X, 1.2, spot.Z), Material = Enum.Material.SmoothPlastic, Color = if random:NextNumber() < 0.5 then Color3.fromRGB(230, 40, 40) else Color3.fromRGB(250, 200, 0) })
				else
					api.part({ ClassName = "WedgePart", Name = "SharkFin", Size = Vector3.new(0.6, 4, 4), CFrame = CFrame.new(spot.X, 2.5, spot.Z) * CFrame.Angles(0, random:NextNumber() * math.pi * 2, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(110, 120, 130) })
				end
			end
		end

		-- Beach huts and umbrellas along the start pier.
		for i, x in { -60, -20, 30, 80, 130 } do
			local spot = Vector3.new(x, 0, 275 + api.Edge + 14)
			api.part({ Name = "Pier", Size = Vector3.new(30, 1, 22), CFrame = CFrame.new(spot.X, 2.5, spot.Z), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(160, 115, 75) })
			if i % 2 == 1 then
				api.part({ Name = "Hut", Size = Vector3.new(12, 8, 10), CFrame = CFrame.new(spot.X, 7, spot.Z + 2), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(190, 145, 95) })
				api.part({ ClassName = "WedgePart", Name = "HutRoof", Size = Vector3.new(14, 4, 12), CFrame = CFrame.new(spot.X, 13, spot.Z + 2), Material = Enum.Material.Grass, Color = Color3.fromRGB(200, 180, 90) })
			else
				api.part({ Name = "UmbrellaPole", Size = Vector3.new(0.4, 8, 0.4), CFrame = CFrame.new(spot.X, 7, spot.Z), Material = Enum.Material.Wood, Color = Color3.fromRGB(240, 240, 240) })
				api.part({ Name = "Umbrella", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 10, 10), CFrame = CFrame.new(spot.X, 11, spot.Z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = if i == 2 then Color3.fromRGB(240, 70, 90) else Color3.fromRGB(60, 200, 220) })
			end
		end
	end,
}
