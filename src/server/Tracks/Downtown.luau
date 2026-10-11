-- Downtown Getaway: city streets with sidewalks and concrete barriers, a chicane, a
-- highway overpass over a canal, a dirt construction zone through the S-bends, a narrow
-- back-alley shortcut that skips them, and a grass cut around the outside of the chicane.
return {
	Name = "Downtown Getaway",
	Laps = 3,
	Seed = 11,
	Width = 36,
	Surface = "Road",
	RoadColor = Color3.fromRGB(52, 52, 58),
	BannerColor = Color3.fromRGB(255, 80, 0),
	Ground = { Material = Enum.Material.Grass, Color = Color3.fromRGB(90, 150, 70), Surface = "Offroad" },
	Border = { Width = 10, Surface = "Offroad", Material = Enum.Material.Pavement, Color = Color3.fromRGB(175, 175, 170) },
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
		Vector3.new(-240, 1, 240), -- 1 start / finish
		Vector3.new(0, 1, 240),
		Vector3.new(210, 1, 240),
		Vector3.new(312, 1, 192),
		Vector3.new(340, 1, 110),
		Vector3.new(268, 1, 24), -- 6 chicane (grass cut around the outside)
		Vector3.new(340, 1, -66),
		Vector3.new(324, 1, -160),
		Vector3.new(252, 1, -228),
		Vector3.new(132, 1, -240),
		Vector3.new(36, 16, -240), -- 11 overpass over the canal
		Vector3.new(-72, 16, -240),
		Vector3.new(-168, 1, -240),
		Vector3.new(-270, 1, -198),
		Vector3.new(-318, 1, -120), -- 15 S-bends (construction zone)
		Vector3.new(-245, 1, -24),
		Vector3.new(-318, 1, 72),
		Vector3.new(-340, 1, 160),
		Vector3.new(-312, 1, 228),
	},

	Sections = {
		{ From = 15.1, To = 16.95, Surface = "Dirt" },
	},
	Shortcuts = {
		{ -- back alley: narrow and cluttered, skips the construction zone
			Width = 16,
			Surface = "Road",
			Color = Color3.fromRGB(70, 65, 65),
			Points = { Vector3.new(-328, 1, -110), Vector3.new(-334, 1, -24), Vector3.new(-328, 1, 62) },
		},
		{ -- park grass around the chicane: shorter, but slow unless you boost or have Traction
			Width = 16,
			Surface = "Offroad",
			Points = { Vector3.new(352, 1, 95), Vector3.new(360, 1, 24), Vector3.new(352, 1, -50) },
		},
	},

	BoostPads = {
		{ At = 1.5, Offset = 7 },
		{ At = 2.5, Offset = -7 },
		{ At = 8.5, Offset = 0 },
		{ At = 12.4, Offset = 0 },
		{ At = 18.4, Offset = 5 },
	},
	Ramps = {
		{ At = 2.0, Offset = -10, Width = 14, Length = 20, Angle = 13 },
	},
	PickupRows = { 3.2, 9.4, 13.6, 17.8 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random
		local palette = {
			{ Enum.Material.Brick, Color3.fromRGB(170, 85, 65) },
			{ Enum.Material.Brick, Color3.fromRGB(140, 70, 55) },
			{ Enum.Material.Concrete, Color3.fromRGB(200, 195, 185) },
			{ Enum.Material.Concrete, Color3.fromRGB(120, 130, 150) },
			{ Enum.Material.Glass, Color3.fromRGB(80, 120, 160) },
			{ Enum.Material.Marble, Color3.fromRGB(225, 215, 195) },
		}

		local function building(position: Vector3, w: number, d: number, h: number)
			local look = palette[random:NextInteger(1, #palette)]
			local tower = api.part({ Name = "Building", Size = Vector3.new(w, h, d), CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)), Material = look[1], Color = look[2] })
			for floor = 10, h - 6, 10 do
				api.part({ Name = "Windows", Size = Vector3.new(w + 0.3, 3.5, d + 0.3), CFrame = tower.CFrame * CFrame.new(0, floor - h / 2, 0), Material = Enum.Material.Glass, Color = Color3.fromRGB(150, 195, 230), Transparency = 0.15 })
			end
			api.part({ Name = "RoofTrim", Size = Vector3.new(w + 1.5, 2, d + 1.5), CFrame = tower.CFrame * CFrame.new(0, h / 2 + 1, 0), Material = Enum.Material.Concrete, Color = look[2]:Lerp(Color3.new(0, 0, 0), 0.3) })
			if random:NextNumber() < 0.5 then
				api.part({ Name = "WaterTank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, 6, 6), CFrame = tower.CFrame * CFrame.new(w * 0.2, h / 2 + 5.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(130, 90, 60) })
			end
		end

		-- Dense buildings lining the streets.
		api.alongTrack(3, 14, function(position)
			local w, d, h = random:NextInteger(22, 36), random:NextInteger(22, 36), random:NextInteger(30, 120)
			if api.isClear(position, math.max(w, d) * 0.72) then
				building(position, w, d, h)
			end
		end)
		-- Distant skyline so the world doesn't just end.
		P.ring(api.Center, api.Extent + 260, 40, function(position)
			building(position, random:NextInteger(40, 70), random:NextInteger(40, 70), random:NextInteger(90, 220))
		end)

		-- Parked cars and street lights on the sidewalks.
		api.alongTrack(9, 4, function(position, sample, side)
			if api.isClear(position, 3) then
				if random:NextNumber() < 0.6 then
					P.parkedCar(folder, CFrame.lookAt(position, position + sample.Forward))
				else
					api.part({ Name = "LampPost", Size = Vector3.new(0.8, 16, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 8, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 45) })
					local lamp = api.part({ Name = "Lamp", Size = Vector3.new(2, 1, 4), CFrame = CFrame.lookAt(position + Vector3.new(0, 16.5, 0), position + Vector3.new(0, 16.5, 0) - sample.Right * side) * CFrame.new(0, 0, -1.5), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200) })
					local light = Instance.new("PointLight")
					light.Range = 26
					light.Parent = lamp
				end
			end
		end)

		-- Billboards.
		local ads = {
			{ "NO SPEED LIMIT", Color3.fromRGB(230, 40, 40) },
			{ "DRIFT KING", Color3.fromRGB(40, 120, 230) },
			{ "STEAL EVERYTHING", Color3.fromRGB(255, 180, 0) },
			{ "ILLEGAL RACING", Color3.fromRGB(255, 90, 0) },
		}
		for i, u in { 1.6, 3.6, 9.6, 18.6 } do
			local sample = api.sampleAt(u)
			local position = sample.Position + sample.Right * (api.Edge + 8)
			local ground = Vector3.new(position.X, 0, position.Z)
			P.billboard(folder, CFrame.lookAt(ground, ground - sample.Right), ads[i][1], ads[i][2])
		end

		-- Park in the middle with trees and a fountain.
		local park = api.Center + Vector3.new(0, 0, 0)
		api.part({ Name = "Fountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 30, 30), CFrame = CFrame.new(park + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = Color3.fromRGB(220, 220, 225) })
		api.part({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 26, 26), CFrame = CFrame.new(park + Vector3.new(0, 2.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Glass, Color = Color3.fromRGB(70, 160, 220), Transparency = 0.2 })
		api.part({ Name = "FountainSpout", Size = Vector3.new(3, 10, 3), CFrame = CFrame.new(park + Vector3.new(0, 5, 0)), Material = Enum.Material.Marble, Color = Color3.fromRGB(230, 230, 235) })
		for _ = 1, 40 do
			local spot = api.Center + Vector3.new(random:NextInteger(-260, 260), 0, random:NextInteger(-190, 190))
			if api.isClear(spot, 6) and (spot - park).Magnitude > 22 then
				P.tree(folder, spot, 0.9 + random:NextNumber() * 0.5, "round")
			end
		end

		-- Canal under the overpass.
		api.part({ Name = "Canal", Size = Vector3.new(50, 0.4, 600), CFrame = CFrame.new(-18, 0.2, -240), Material = Enum.Material.Glass, Color = Color3.fromRGB(40, 110, 170), Transparency = 0.15, CanCollide = false })

		-- Construction zone: cones on the edges and a tower crane.
		for u = 15.15, 16.9, 0.08 do
			local sample = api.sampleAt(u)
			for _, side in { -1, 1 } do
				api.part({ Name = "Cone", Size = Vector3.new(1.5, 3, 1.5), CFrame = CFrame.new(sample.Position + sample.Right * side * (api.Width / 2 - 1) + Vector3.new(0, 1.5, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 120, 0), CanCollide = false })
			end
		end
		local craneBase = Vector3.new(-205, 0, -24)
		api.part({ Name = "CraneMast", Size = Vector3.new(5, 110, 5), CFrame = CFrame.new(craneBase + Vector3.new(0, 55, 0)), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(255, 200, 0) })
		api.part({ Name = "CraneJib", Size = Vector3.new(5, 4, 120), CFrame = CFrame.new(craneBase + Vector3.new(0, 108, -30)), Material = Enum.Material.DiamondPlate, Color = Color3.fromRGB(255, 200, 0) })
		api.part({ Name = "CraneWeight", Size = Vector3.new(8, 8, 10), CFrame = CFrame.new(craneBase + Vector3.new(0, 104, 26)), Material = Enum.Material.Concrete, Color = Color3.fromRGB(110, 110, 110) })

		-- Alley clutter: crates you have to weave around.
		for _, crate in { { -330, -80 }, { -336, -45 }, { -331, 0 }, { -337, 35 } } do
			api.part({ Name = "Crate", Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(crate[1], 3, crate[2]), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(160, 110, 60) })
		end
	end,
}
