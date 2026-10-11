-- Dusty Canyon Run: an all-dirt rally. Past the old west town, up through the mine tunnel
-- onto the mesa, jump the gorge, then wind through the badlands. Two shortcuts: the mud
-- pit (great for high Traction) and the dusty trail behind the town.
return {
	Name = "Dusty Canyon Run",
	Laps = 3,
	Seed = 22,
	Width = 32,
	Surface = "Dirt",
	Curbs = false,
	BannerColor = Color3.fromRGB(200, 90, 30),
	Ground = { Material = Enum.Material.Sand, Color = Color3.fromRGB(222, 186, 128), Surface = "Offroad" },
	Border = { Width = 8, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(235, 200, 140) },
	Barrier = { Height = 3, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 85, 50) },
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
		Vector3.new(0, 1, 300), -- 1 start / finish by the west town
		Vector3.new(200, 1, 300),
		Vector3.new(330, 6, 240),
		Vector3.new(380, 18, 130), -- 4 mine tunnel climb
		Vector3.new(330, 30, 60),
		Vector3.new(380, 34, -30), -- 6 mesa top
		Vector3.new(330, 34, -140),
		Vector3.new(200, 30, -120),
		Vector3.new(120, 20, -180), -- 9 gorge jump
		Vector3.new(0, 8, -240),
		Vector3.new(-150, 1, -220),
		Vector3.new(-260, 1, -140), -- 12 badlands (mud-pit shortcut)
		Vector3.new(-220, 1, -42),
		Vector3.new(-320, 1, 40),
		Vector3.new(-300, 1, 170), -- 15 dusty trail shortcut
		Vector3.new(-160, 1, 220),
	},

	Gaps = {
		{ From = 8.42, To = 8.58 },
	},
	Shortcuts = {
		{ Width = 14, Surface = "Mud", Points = { Vector3.new(-245, 1, -128), Vector3.new(-300, 1, -50), Vector3.new(-310, 1, 25) } },
		{ Width = 14, Surface = "Offroad", Material = Enum.Material.Sand, Color = Color3.fromRGB(240, 205, 150), Points = { Vector3.new(-300, 1, 190), Vector3.new(-235, 1, 265), Vector3.new(-110, 1, 265) } },
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 3.4, Offset = 0, Width = 14 },
		{ At = 8.15, Offset = 0, Width = 18 }, -- hit this before the gorge!
		{ At = 11.5, Offset = -6 },
		{ At = 14.5, Offset = 6 },
	},
	Ramps = {
		{ At = 8.3, Offset = 0, Width = 32, Length = 20, Angle = 14, Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks },
		{ At = 2.4, Offset = 9, Width = 12, Length = 18, Angle = 12, Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks },
	},
	PickupRows = { 2.4, 6.5, 10.5, 13.6 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random

		-- Grandstand first so the scenery placed afterwards keeps clear of it.
		api.grandstand(1.4, -1, 70, Color3.fromRGB(170, 70, 30))
		local rockColors = { Color3.fromRGB(190, 110, 70), Color3.fromRGB(170, 95, 60), Color3.fromRGB(210, 140, 90) }

		local function mesa(position: Vector3, w: number, d: number, h: number)
			local color = rockColors[random:NextInteger(1, #rockColors)]
			local rock = api.part({ Name = "Mesa", Size = Vector3.new(w, h, d), CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, random:NextNumber() * math.pi, 0), Material = Enum.Material.Sandstone, Color = color })
			for stripe = 0.3, 0.8, 0.25 do
				api.part({ Name = "Layer", Size = Vector3.new(w + 1, 2, d + 1), CFrame = rock.CFrame * CFrame.new(0, h * (stripe - 0.5), 0), Material = Enum.Material.Sandstone, Color = color:Lerp(Color3.fromRGB(255, 230, 190), 0.3) })
			end
			api.part({ Name = "Cap", Size = Vector3.new(w + 6, 4, d + 6), CFrame = rock.CFrame * CFrame.new(0, h / 2 + 2, 0), Material = Enum.Material.Sandstone, Color = color:Lerp(Color3.new(0, 0, 0), 0.15) })
		end

		api.alongTrack(3, 8, function(position)
			if random:NextNumber() < 0.5 then
				return
			end
			local w, d = random:NextInteger(14, 28), random:NextInteger(14, 28)
			if api.isClear(position, math.max(w, d) * 0.75) then
				mesa(position, w, d, random:NextInteger(18, 60))
			end
		end)
		P.ring(api.Center, api.Extent + 200, 34, function(position)
			mesa(position, random:NextInteger(70, 110), random:NextInteger(70, 110), random:NextInteger(90, 180))
		end)

		-- Cacti, dead trees, tumbleweeds and boulders.
		for _ = 1, 90 do
			local spot = api.Center + Vector3.new(random:NextInteger(-450, 450), 0, random:NextInteger(-350, 350))
			if api.isClear(spot, 3) then
				local roll = random:NextNumber()
				if roll < 0.5 then
					local h = random:NextInteger(6, 12)
					local green = Color3.fromRGB(70, 140, 60)
					api.part({ Name = "Cactus", Size = Vector3.new(2, h, 2), CFrame = CFrame.new(spot + Vector3.new(0, h / 2, 0)), Material = Enum.Material.Grass, Color = green })
					api.part({ Name = "CactusArm", Size = Vector3.new(4, 1.5, 1.5), CFrame = CFrame.new(spot + Vector3.new(1.5, h * 0.6, 0)), Material = Enum.Material.Grass, Color = green })
					api.part({ Name = "CactusArm", Size = Vector3.new(1.5, 3, 1.5), CFrame = CFrame.new(spot + Vector3.new(3, h * 0.6 + 1.5, 0)), Material = Enum.Material.Grass, Color = green })
				elseif roll < 0.7 then
					P.tree(folder, spot, 0.8 + random:NextNumber() * 0.4, "dead")
				elseif roll < 0.85 then
					api.part({ Name = "Tumbleweed", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, CFrame = CFrame.new(spot + Vector3.new(0, 1.5, 0)), Material = Enum.Material.Grass, Color = Color3.fromRGB(170, 140, 90), Transparency = 0.2, CanCollide = false })
				else
					api.part({ Name = "Boulder", Shape = Enum.PartType.Ball, Size = Vector3.one * random:NextInteger(5, 12), CFrame = CFrame.new(spot), Material = Enum.Material.Slate, Color = Color3.fromRGB(150, 110, 80) })
				end
			end
		end

		-- Set pieces: rodeo stands + arch, the mine tunnel, the gorge warning signs.
		api.arch(15.6, "DUSTY CANYON", Color3.fromRGB(150, 70, 30))
		api.tunnel(4.25, 5.2, { Height = 16, Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 75, 45), LightColor = Color3.fromRGB(255, 190, 110) })
		local sample = api.sampleAt(8.1)
		for _, side in { -1, 1 } do
			local position = sample.Position + sample.Right * side * (api.Edge + 2)
			api.part({ Name = "SignPost", Size = Vector3.new(0.6, 8, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 4, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 80, 50) })
			local board = api.part({ Name = "Sign", Size = Vector3.new(8, 4, 0.4), CFrame = CFrame.lookAt(position + Vector3.new(0, 9, 0), position + Vector3.new(0, 9, 0) - sample.Forward), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 200, 0) })
			api.sign(board, "JUMP!", Color3.new(0, 0, 0))
		end

		-- Old west town by the start: saloon, sheriff's office, water tower, windmill.
		local function storefront(position: Vector3, w: number, label: string, color: Color3)
			local body = api.part({ Name = "Storefront", Size = Vector3.new(w, 16, 20), CFrame = CFrame.new(position + Vector3.new(0, 8, 0)), Material = Enum.Material.WoodPlanks, Color = color })
			api.part({ Name = "FalseFront", Size = Vector3.new(w + 4, 24, 1), CFrame = body.CFrame * CFrame.new(0, 4, -10.5), Material = Enum.Material.WoodPlanks, Color = color:Lerp(Color3.new(1, 1, 1), 0.15) })
			api.part({ Name = "Porch", Size = Vector3.new(w + 4, 1, 7), CFrame = body.CFrame * CFrame.new(0, -7.5, -14), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(110, 75, 45) })
			local board = api.part({ Name = "Sign", Size = Vector3.new(w * 0.7, 4, 0.5), CFrame = body.CFrame * CFrame.new(0, 10, -11.3), Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 50, 30) })
			api.sign(board, label, Color3.fromRGB(255, 220, 140))
		end
		storefront(Vector3.new(60, 0, 360), 34, "SALOON", Color3.fromRGB(160, 105, 60))
		storefront(Vector3.new(110, 0, 360), 26, "SHERIFF", Color3.fromRGB(140, 95, 55))
		storefront(Vector3.new(150, 0, 360), 24, "GENERAL STORE", Color3.fromRGB(175, 120, 70))
		local tower = Vector3.new(-30, 0, 365)
		for _, corner in { Vector3.new(-4, 0, -4), Vector3.new(4, 0, -4), Vector3.new(-4, 0, 4), Vector3.new(4, 0, 4) } do
			api.part({ Name = "TowerLeg", Size = Vector3.new(1, 24, 1), CFrame = CFrame.new(tower + corner + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 75, 45) })
		end
		api.part({ Name = "WaterTank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 14, 14), CFrame = CFrame.new(tower + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 95, 60) })
		local mill = Vector3.new(200, 0, 380)
		api.part({ Name = "MillTower", Size = Vector3.new(3, 36, 3), CFrame = CFrame.new(mill + Vector3.new(0, 18, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 120, 125) })
		for i = 0, 5 do
			api.part({ Name = "MillBlade", Size = Vector3.new(1.5, 12, 0.3), CFrame = CFrame.new(mill + Vector3.new(0, 36, -2)) * CFrame.Angles(0, 0, i * math.pi / 3) * CFrame.new(0, 6, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 205) })
		end

		-- Dinosaur skeleton in the infield.
		local dino = Vector3.new(20, 0, 40)
		local bone = Color3.fromRGB(240, 230, 205)
		for k = 0, 11 do
			local x = -30 + k * 5.5
			local height = 14 + math.sin(k / 11 * math.pi) * 6
			api.part({ Name = "Spine", Size = Vector3.new(4.5, 2, 2), CFrame = CFrame.new(dino + Vector3.new(x, height, 0)), Material = Enum.Material.SmoothPlastic, Color = bone })
			if k > 2 and k < 9 then
				for _, side in { -1, 1 } do
					api.part({ Name = "Rib", Size = Vector3.new(1, 10, 1), CFrame = CFrame.new(dino + Vector3.new(x, height - 5, side * 3.5)) * CFrame.Angles(math.rad(side * 20), 0, 0), Material = Enum.Material.SmoothPlastic, Color = bone })
				end
			end
		end
		api.part({ Name = "Skull", Size = Vector3.new(10, 6, 6), CFrame = CFrame.new(dino + Vector3.new(36, 18, 0)) * CFrame.Angles(0, 0, math.rad(-15)), Material = Enum.Material.SmoothPlastic, Color = bone })
		for _, x in { -14, 14 } do
			api.part({ Name = "Leg", Size = Vector3.new(2, 14, 2), CFrame = CFrame.new(dino + Vector3.new(x, 7, 2)), Material = Enum.Material.SmoothPlastic, Color = bone })
		end

		-- Barrels sunk in the mud pit.
		for _, spot in { { -275, -95 }, { -298, -50 }, { -305, 0 } } do
			api.part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 2.5, 2.5), CFrame = CFrame.new(spot[1] + 4, 1.5, spot[2]) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 60, 40) })
		end
	end,
}
