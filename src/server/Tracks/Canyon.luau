-- Dusty Canyon Run: an all-dirt rally track. Climb onto a mesa, jump a gorge, drop back
-- to the desert floor and loop through the dunes. High-traction cars can cut straight
-- through the mud pit in the middle of the west loop.
return {
	Name = "Dusty Canyon Run",
	Laps = 3,
	Seed = 22,
	Width = 36,
	Surface = "Dirt",
	Curbs = false,
	BannerColor = Color3.fromRGB(200, 90, 30),
	Ground = { Material = Enum.Material.Sand, Color = Color3.fromRGB(222, 186, 128), Surface = "Offroad" },
	Border = { Width = 10, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(235, 200, 140) },
	Barrier = { Height = 3, Material = Enum.Material.Slate, Color = Color3.fromRGB(150, 95, 60) },
	Support = "Fill",
	FillMaterial = Enum.Material.Sandstone,
	FillColor = Color3.fromRGB(195, 120, 75),
	Lighting = {
		ClockTime = 16.8,
		Brightness = 2.6,
		Ambient = Color3.fromRGB(140, 105, 80),
		OutdoorAmbient = Color3.fromRGB(150, 118, 92),
		FogEnd = 2200,
		FogColor = Color3.fromRGB(230, 190, 140),
		ExposureCompensation = 0,
	},
	Atmosphere = { Density = 0.35, Haze = 2, Color = Color3.fromRGB(235, 195, 150), Decay = Color3.fromRGB(200, 140, 90) },

	Points = {
		Vector3.new(0, 1, 300), -- 1 start / finish
		Vector3.new(180, 1, 300),
		Vector3.new(330, 8, 252), -- 3 climb
		Vector3.new(390, 22, 150),
		Vector3.new(372, 32, 30), -- 5 mesa top
		Vector3.new(300, 32, -60),
		Vector3.new(210, 32, -90), -- 7 gorge jump
		Vector3.new(90, 18, -90),
		Vector3.new(-30, 8, -120),
		Vector3.new(-150, 1, -180),
		Vector3.new(-300, 1, -150), -- 11 west loop
		Vector3.new(-372, 1, -30),
		Vector3.new(-336, 1, 90),
		Vector3.new(-228, 1, 120),
		Vector3.new(-150, 1, 210),
	},

	Gaps = {
		{ From = 7.45, To = 7.62 },
	},
	Shortcuts = {
		{ -- mud pit: brutal unless your car has high Traction
			Width = 16,
			Surface = "Mud",
			Points = { Vector3.new(-292, 1, -140), Vector3.new(-280, 1, -15), Vector3.new(-250, 1, 105) },
		},
	},

	BoostPads = {
		{ At = 1.4, Offset = 0 },
		{ At = 3.5, Offset = 0, Width = 14 },
		{ At = 7.25, Offset = 0, Width = 18 }, -- hit this before the gorge!
		{ At = 9.5, Offset = -7 },
		{ At = 14.4, Offset = 7 },
	},
	Ramps = {
		{ At = 7.36, Offset = 0, Width = 36, Length = 20, Angle = 14, Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks },
		{ At = 2.4, Offset = 10, Width = 12, Length = 18, Angle = 12, Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks },
	},
	PickupRows = { 2.2, 6.0, 9.7, 12.5 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random
		local rockColors = { Color3.fromRGB(190, 110, 70), Color3.fromRGB(170, 95, 60), Color3.fromRGB(210, 140, 90) }

		local function mesa(position: Vector3, w: number, d: number, h: number)
			local color = rockColors[random:NextInteger(1, #rockColors)]
			local rock = api.part({ Name = "Mesa", Size = Vector3.new(w, h, d), CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, random:NextNumber() * math.pi, 0), Material = Enum.Material.Sandstone, Color = color })
			for stripe = 0.3, 0.8, 0.25 do -- rock layers
				api.part({ Name = "Layer", Size = Vector3.new(w + 1, 2, d + 1), CFrame = rock.CFrame * CFrame.new(0, h * (stripe - 0.5), 0), Material = Enum.Material.Sandstone, Color = color:Lerp(Color3.fromRGB(255, 230, 190), 0.3) })
			end
			api.part({ Name = "Cap", Size = Vector3.new(w + 6, 4, d + 6), CFrame = rock.CFrame * CFrame.new(0, h / 2 + 2, 0), Material = Enum.Material.Sandstone, Color = color:Lerp(Color3.new(0, 0, 0), 0.15) })
		end

		-- Rock towers close in, canyon walls all around in the distance.
		api.alongTrack(3, 10, function(position)
			if random:NextNumber() < 0.45 then
				return
			end
			local w, d = random:NextInteger(14, 30), random:NextInteger(14, 30)
			if api.isClear(position, math.max(w, d) * 0.75) then
				mesa(position, w, d, random:NextInteger(18, 70))
			end
		end)
		P.ring(api.Center, api.Extent + 220, 34, function(position)
			mesa(position, random:NextInteger(70, 110), random:NextInteger(70, 110), random:NextInteger(90, 180))
		end)

		-- Cacti and dead trees.
		for _ = 1, 70 do
			local spot = api.Center + Vector3.new(random:NextInteger(-480, 480), 0, random:NextInteger(-360, 360))
			if api.isClear(spot, 3) then
				if random:NextNumber() < 0.7 then
					local h = random:NextInteger(6, 12)
					local green = Color3.fromRGB(70, 140, 60)
					api.part({ Name = "Cactus", Size = Vector3.new(2, h, 2), CFrame = CFrame.new(spot + Vector3.new(0, h / 2, 0)), Material = Enum.Material.Grass, Color = green })
					api.part({ Name = "CactusArm", Size = Vector3.new(4, 1.5, 1.5), CFrame = CFrame.new(spot + Vector3.new(1.5, h * 0.6, 0)), Material = Enum.Material.Grass, Color = green })
					api.part({ Name = "CactusArm", Size = Vector3.new(1.5, 3, 1.5), CFrame = CFrame.new(spot + Vector3.new(3, h * 0.6 + 1.5, 0)), Material = Enum.Material.Grass, Color = green })
				else
					P.tree(folder, spot, 0.8 + random:NextNumber() * 0.4, "dead")
				end
			end
		end

		-- Old west town by the start: saloon, water tower, windmill.
		local town = Vector3.new(60, 0, 200)
		local saloon = api.part({ Name = "Saloon", Size = Vector3.new(40, 18, 24), CFrame = CFrame.new(town + Vector3.new(0, 9, 0)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 100, 60) })
		api.part({ Name = "SaloonFront", Size = Vector3.new(44, 26, 1), CFrame = CFrame.new(town + Vector3.new(0, 13, 12.5)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(170, 115, 70) })
		api.part({ Name = "Porch", Size = Vector3.new(44, 1, 8), CFrame = CFrame.new(town + Vector3.new(0, 9, 17)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(120, 80, 50) })
		local sign = api.part({ Name = "SaloonSign", Size = Vector3.new(24, 5, 0.5), CFrame = CFrame.new(town + Vector3.new(0, 21, 13.2)), Material = Enum.Material.Wood, Color = Color3.fromRGB(90, 55, 30) })
		api.sign(sign, "SALOON", Color3.fromRGB(255, 220, 140))
		local tower = Vector3.new(-40, 0, 200)
		for _, corner in { Vector3.new(-4, 0, -4), Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4), Vector3.new(4, 0, 4) } do
			api.part({ Name = "TowerLeg", Size = Vector3.new(1, 24, 1), CFrame = CFrame.new(tower + corner + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 75, 45) })
		end
		api.part({ Name = "WaterTank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 14, 14), CFrame = CFrame.new(tower + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 95, 60) })
		local mill = Vector3.new(130, 0, 120)
		api.part({ Name = "MillTower", Size = Vector3.new(3, 36, 3), CFrame = CFrame.new(mill + Vector3.new(0, 18, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 120, 125) })
		for i = 0, 5 do
			api.part({ Name = "MillBlade", Size = Vector3.new(1.5, 12, 0.3), CFrame = CFrame.new(mill + Vector3.new(0, 36, -2)) * CFrame.Angles(0, 0, i * math.pi / 3) * CFrame.new(0, 6, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205) })
		end

		-- Warning signs before the gorge.
		local sample = api.sampleAt(7.25)
		for _, side in { -1, 1 } do
			local position = sample.Position + sample.Right * side * (api.Edge + 2)
			api.part({ Name = "SignPost", Size = Vector3.new(0.6, 8, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 4, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 80, 50) })
			local board = api.part({ Name = "Sign", Size = Vector3.new(8, 4, 0.4), CFrame = CFrame.lookAt(position + Vector3.new(0, 9, 0), position + Vector3.new(0, 9, 0) - sample.Forward), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 200, 0) })
			api.sign(board, "JUMP!", Color3.new(0, 0, 0))
		end

		-- Barrels sunk in the mud pit.
		for _, z in { -90, -40, 20, 70 } do
			api.part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 2.5, 2.5), CFrame = CFrame.new(-282 + (z % 3) * 3, 1.5, z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 60, 40) })
		end
	end,
}
