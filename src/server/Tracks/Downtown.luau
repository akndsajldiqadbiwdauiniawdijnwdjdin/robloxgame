-- Downtown Getaway: a street circuit. Long front straight past the grandstand, a chicane
-- (cut it on the park grass), a tunnel under a skyscraper, an overpass over the canal, a
-- dirt construction-zone hairpin (or cut through the parking lot), and a park shortcut.
return {
	Name = "Downtown Getaway",
	Laps = 3,
	Seed = 11,
	Width = 32,
	Surface = "Road",
	RoadColor = Color3.fromRGB(52, 52, 58),
	BannerColor = Color3.fromRGB(255, 80, 0),
	Ground = { Material = Enum.Material.Grass, Color = Color3.fromRGB(90, 150, 70), Surface = "Offroad" },
	Border = { Width = 8, Surface = "Offroad", Material = Enum.Material.Pavement, Color = Color3.fromRGB(175, 175, 170) },
	Barrier = { Height = 4, Material = Enum.Material.Concrete, Color = Color3.fromRGB(215, 215, 210) },
	Support = "Pillars",
	Lighting = {
		ClockTime = 13.5,
		Brightness = 2.2,
		Ambient = Color3.fromRGB(110, 110, 120),
		OutdoorAmbient = Color3.fromRGB(130, 130, 140),
		FogEnd = 2500,
		FogColor = Color3.fromRGB(195, 205, 220),
		ExposureCompensation = 0,
	},
	Atmosphere = { Density = 0.25, Haze = 1, Color = Color3.fromRGB(200, 210, 230) },

	Points = {
		Vector3.new(-300, 1, 230), -- 1 start / finish (grandstand)
		Vector3.new(80, 1, 230),
		Vector3.new(250, 1, 230),
		Vector3.new(330, 1, 170),
		Vector3.new(335, 1, 75), -- 5 chicane
		Vector3.new(275, 1, 0),
		Vector3.new(335, 1, -80),
		Vector3.new(320, 1, -190), -- 8 skyscraper tunnel
		Vector3.new(240, 1, -250),
		Vector3.new(130, 1, -210),
		Vector3.new(10, 14, -240), -- 11 canal overpass
		Vector3.new(-110, 14, -240),
		Vector3.new(-210, 1, -200), -- 13 construction hairpin
		Vector3.new(-235, 1, -110),
		Vector3.new(-135, 1, -75),
		Vector3.new(-60, 1, -10), -- 16 park S-bends
		Vector3.new(-120, 1, 75),
		Vector3.new(-250, 1, 60),
		Vector3.new(-340, 1, 135),
	},

	Sections = {
		{ From = 13.0, To = 14.9, Surface = "Dirt" },
	},
	Shortcuts = {
		{ Width = 14, Surface = "Offroad", Points = { Vector3.new(352, 1, 55), Vector3.new(362, 1, 0), Vector3.new(352, 1, -60) } }, -- park grass round the chicane
		{ Width = 14, Surface = "Road", Color = Color3.fromRGB(70, 70, 75), Points = { Vector3.new(-198, 1, -188), Vector3.new(-170, 1, -140), Vector3.new(-145, 1, -92) } }, -- parking lot
		{ Width = 14, Surface = "Offroad", Points = { Vector3.new(-70, 1, 20), Vector3.new(-175, 1, 130), Vector3.new(-285, 1, 105) } }, -- through the park
	},

	BoostPads = {
		{ At = 1.6, Offset = 6 },
		{ At = 4.5, Offset = 0 },
		{ At = 7.6, Offset = 0 },
		{ At = 11.5, Offset = 0 },
		{ At = 16.5, Offset = -6 },
	},
	Ramps = {
		{ At = 2.2, Offset = -9, Width = 12, Length = 20, Angle = 13 },
	},
	PickupRows = { 3.2, 8.0, 12.9, 17.5 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random

		-- Grandstand first so the scenery placed afterwards keeps clear of it.
		api.grandstand(1.4, 1, 80)
		local palette = {
			{ Enum.Material.Brick, Color3.fromRGB(170, 85, 65) },
			{ Enum.Material.Brick, Color3.fromRGB(140, 70, 55) },
			{ Enum.Material.Concrete, Color3.fromRGB(200, 195, 185) },
			{ Enum.Material.Concrete, Color3.fromRGB(120, 130, 150) },
			{ Enum.Material.Glass, Color3.fromRGB(80, 120, 160) },
			{ Enum.Material.Marble, Color3.fromRGB(225, 215, 195) },
		}
		local awnings = { Color3.fromRGB(220, 50, 60), Color3.fromRGB(40, 140, 90), Color3.fromRGB(240, 180, 40), Color3.fromRGB(50, 110, 200) }

		local function building(position: Vector3, w: number, d: number, h: number, facing: Vector3?)
			local look = palette[random:NextInteger(1, #palette)]
			local cf = if facing then CFrame.lookAt(position + Vector3.new(0, h / 2, 0), position + Vector3.new(0, h / 2, 0) + facing) else CFrame.new(position + Vector3.new(0, h / 2, 0))
			local tower = api.part({ Name = "Building", Size = Vector3.new(w, h, d), CFrame = cf, Material = look[1], Color = look[2] })
			for floor = 12, h - 6, 10 do
				api.part({ Name = "Windows", Size = Vector3.new(w + 0.3, 3.5, d + 0.3), CFrame = tower.CFrame * CFrame.new(0, floor - h / 2, 0), Material = Enum.Material.Glass, Color = Color3.fromRGB(150, 195, 230), Transparency = 0.15 })
			end
			api.part({ Name = "RoofTrim", Size = Vector3.new(w + 1.5, 2, d + 1.5), CFrame = tower.CFrame * CFrame.new(0, h / 2 + 1, 0), Material = Enum.Material.Concrete, Color = look[2]:Lerp(Color3.new(0, 0, 0), 0.3) })
			if facing then -- shop front with an awning facing the street
				api.part({ Name = "ShopWindow", Size = Vector3.new(w * 0.8, 6, 0.4), CFrame = tower.CFrame * CFrame.new(0, -h / 2 + 4, -d / 2 - 0.2), Material = Enum.Material.Glass, Color = Color3.fromRGB(255, 240, 200), Transparency = 0.1 })
				api.part({ Name = "Awning", Size = Vector3.new(w * 0.85, 0.4, 4), CFrame = tower.CFrame * CFrame.new(0, -h / 2 + 8, -d / 2 - 2) * CFrame.Angles(math.rad(-15), 0, 0), Material = Enum.Material.Fabric, Color = awnings[random:NextInteger(1, #awnings)] })
			end
			if random:NextNumber() < 0.4 then
				api.part({ Name = "WaterTank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 6, 6), CFrame = tower.CFrame * CFrame.new(w * 0.2, h / 2 + 5.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 90, 60) })
			end
		end

		-- Shop-front buildings lining the streets, skyline behind.
		api.alongTrack(3, 12, function(position, sample, side)
			local w, d, h = random:NextInteger(22, 34), random:NextInteger(22, 34), random:NextInteger(28, 110)
			if api.isClear(position, math.max(w, d) * 0.72) then
				building(position, w, d, h, -sample.Right * side)
			end
		end)
		P.ring(api.Center, api.Extent + 240, 40, function(position)
			building(position, random:NextInteger(40, 70), random:NextInteger(40, 70), random:NextInteger(90, 220))
		end)

		-- Street furniture: parked cars, lamps, benches, traffic lights.
		api.alongTrack(5, 3, function(position, sample, side)
			if not api.isClear(position, 3) then
				return
			end
			local roll = random:NextNumber()
			if roll < 0.45 then
				P.parkedCar(folder, CFrame.lookAt(position, position + sample.Forward))
			elseif roll < 0.75 then
				api.part({ Name = "LampPost", Size = Vector3.new(0.8, 16, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 8, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 45) })
				local lamp = api.part({ Name = "Lamp", Size = Vector3.new(2, 1, 4), CFrame = CFrame.lookAt(position + Vector3.new(0, 16.5, 0), position + Vector3.new(0, 16.5, 0) - sample.Right * side) * CFrame.new(0, 0, -1.5), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200) })
				local light = Instance.new("PointLight")
				light.Range = 26
				light.Parent = lamp
			elseif roll < 0.9 then
				api.part({ Name = "Bench", Size = Vector3.new(6, 1, 2), CFrame = CFrame.lookAt(position + Vector3.new(0, 2, 0), position + Vector3.new(0, 2, 0) - sample.Right * side), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(140, 95, 60) })
			else
				api.part({ Name = "TrafficPole", Size = Vector3.new(0.8, 14, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 7, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(50, 50, 55) })
				local box = api.part({ Name = "TrafficLight", Size = Vector3.new(1.6, 4.5, 1.6), CFrame = CFrame.new(position + Vector3.new(0, 15, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(30, 30, 30) })
				for k, color in { Color3.fromRGB(255, 40, 40), Color3.fromRGB(255, 200, 0), Color3.fromRGB(40, 255, 90) } do
					api.part({ Name = "Signal", Shape = Enum.PartType.Ball, Size = Vector3.one * 1.1, CFrame = box.CFrame * CFrame.new(0, 1.4 - (k - 1) * 1.4, -0.8), Material = Enum.Material.Neon, Color = color })
				end
			end
		end)

		-- Set pieces: grandstand + sponsor arch on the front straight, skyscraper tunnel.
		api.arch(2.7, "ILLEGAL RACING", Color3.fromRGB(255, 80, 0))
		api.arch(5.9, "CHICANE · CUT THE GRASS", Color3.fromRGB(40, 140, 90))
		api.tunnel(8.25, 9.55, { Height = 18, Material = Enum.Material.Concrete, Color = Color3.fromRGB(110, 115, 125) })
		local tower = api.sampleAt(8.9)
		api.part({ Name = "Skyscraper", Size = Vector3.new(api.Edge * 2 + 12, 160, 60), CFrame = CFrame.lookAt(tower.Position + Vector3.new(0, 98, 0), tower.Position + Vector3.new(0, 98, 0) + tower.Forward), Material = Enum.Material.Glass, Color = Color3.fromRGB(70, 110, 150), Reflectance = 0.1 })

		-- Billboards.
		local ads = { { "NO SPEED LIMIT", Color3.fromRGB(230, 40, 40) }, { "DRIFT KING", Color3.fromRGB(40, 120, 230) }, { "STEAL EVERYTHING", Color3.fromRGB(255, 180, 0) } }
		for i, u in { 3.6, 10.4, 18.4 } do
			local sample = api.sampleAt(u)
			local position = sample.Position + sample.Right * (api.Edge + 8)
			local ground = Vector3.new(position.X, 0, position.Z)
			if api.isClear(ground, 6) then
				P.billboard(folder, CFrame.lookAt(ground, ground - sample.Right), ads[i][1], ads[i][2])
			end
		end

		-- Park: fountain, trees and flower beds in the infield.
		local park = Vector3.new(-150, 0, 172)
		api.part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 22, 22), CFrame = CFrame.new(park + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = Color3.fromRGB(220, 220, 225) })
		api.part({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 19, 19), CFrame = CFrame.new(park + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Glass, Color = Color3.fromRGB(70, 160, 220), Transparency = 0.2 })
		for _ = 1, 60 do
			local spot = api.Center + Vector3.new(random:NextInteger(-330, 330), 0, random:NextInteger(-240, 240))
			if api.isClear(spot, 5) and (spot - park).Magnitude > 16 then
				if random:NextNumber() < 0.7 then
					P.tree(folder, spot, 0.8 + random:NextNumber() * 0.5, "round")
				else
					api.part({ Name = "FlowerBed", Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(spot + Vector3.new(0, 0.5, 0)), Material = Enum.Material.Grass, Color = Color3.fromHSV(random:NextNumber(), 0.6, 0.9) })
				end
			end
		end

		-- Canal under the overpass, with a little boat.
		api.part({ Name = "Canal", Size = Vector3.new(40, 0.4, 330), CFrame = CFrame.new(-50, 0.2, -315), Material = Enum.Material.Glass, Color = Color3.fromRGB(40, 110, 170), Transparency = 0.15, CanCollide = false })
		api.part({ Name = "CanalBoat", Size = Vector3.new(6, 2, 16), CFrame = CFrame.new(-45, 1, -300), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 100, 60) })

		-- Construction zone: cones and a tower crane; crates in the parking lot.
		for u = 13.05, 14.85, 0.08 do
			local sample = api.sampleAt(u)
			for _, side in { -1, 1 } do
				api.part({ Name = "Cone", Size = Vector3.new(1.5, 3, 1.5), CFrame = CFrame.new(sample.Position + sample.Right * side * (api.Width / 2 - 1) + Vector3.new(0, 1.5, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 120, 0), CanCollide = false })
			end
		end
		local craneBase = Vector3.new(-300, 0, -170)
		if api.isClear(craneBase, 4) then
			api.part({ Name = "CraneMast", Size = Vector3.new(5, 110, 5), CFrame = CFrame.new(craneBase + Vector3.new(0, 55, 0)), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(255, 200, 0) })
			api.part({ Name = "CraneJib", Size = Vector3.new(120, 4, 5), CFrame = CFrame.new(craneBase + Vector3.new(30, 108, 0)), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(255, 200, 0) })
		end
		for _, crate in { { -188, -172 }, { -165, -128 }, { -155, -108 } } do
			api.part({ Name = "Crate", Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(crate[1], 2.05, crate[2]), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(160, 110, 60) })
		end
	end,
}
