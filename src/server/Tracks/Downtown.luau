-- Downtown Getaway: city streets, a chicane, a highway overpass, a dirt construction
-- zone through the S-bends, and a tight back-alley shortcut that skips them.
return {
	Name = "Downtown Getaway",
	Laps = 3,
	Seed = 11,
	Width = 44,
	Surface = "Road",
	RoadColor = Color3.fromRGB(50, 50, 56),
	BannerColor = Color3.fromRGB(255, 80, 0),
	Ground = { Material = Enum.Material.Grass, Color = Color3.fromRGB(85, 145, 70), Surface = "Offroad" },
	Lighting = {
		ClockTime = 13.5,
		Brightness = 2,
		Ambient = Color3.fromRGB(110, 110, 120),
		OutdoorAmbient = Color3.fromRGB(128, 128, 140),
		FogEnd = 4000,
		FogColor = Color3.fromRGB(190, 200, 215),
	},

	Points = {
		Vector3.new(-400, 1, 400), -- 1 start / finish
		Vector3.new(0, 1, 400),
		Vector3.new(350, 1, 400),
		Vector3.new(520, 1, 320),
		Vector3.new(560, 1, 150),
		Vector3.new(480, 1, 40), -- 6 chicane
		Vector3.new(560, 1, -80),
		Vector3.new(540, 1, -260),
		Vector3.new(420, 1, -380),
		Vector3.new(220, 1, -400),
		Vector3.new(60, 22, -400), -- 11 overpass
		Vector3.new(-120, 22, -400),
		Vector3.new(-280, 1, -400),
		Vector3.new(-450, 1, -330),
		Vector3.new(-520, 1, -170), -- 15 S-bends (construction zone)
		Vector3.new(-430, 1, -40),
		Vector3.new(-520, 1, 90),
		Vector3.new(-560, 1, 260),
		Vector3.new(-520, 1, 380),
	},

	Sections = {
		{ From = 15.2, To = 16.9, Surface = "Dirt" },
	},
	Walls = {
		Height = 3,
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(180, 180, 185),
		Ranges = { { From = 10.3, To = 12.7 } },
	},
	Support = "Pillars",

	Shortcuts = {
		{ -- back alley: narrow, cluttered, skips the S-bends
			Width = 16,
			Surface = "Road",
			Points = { Vector3.new(-530, 1, -150), Vector3.new(-535, 1, -40), Vector3.new(-530, 1, 70) },
		},
	},

	BoostPads = {
		{ At = 1.5, Offset = 8 },
		{ At = 2.5, Offset = -8 },
		{ At = 8.4, Offset = 0 },
		{ At = 12.3, Offset = 0 },
		{ At = 18.3, Offset = 6 },
	},
	Ramps = {
		{ At = 2.0, Offset = -12, Width = 16, Length = 22, Angle = 13 },
	},
	PickupRows = { 3.1, 9.4, 13.6, 17.8 },

	Decor = function(api)
		local random = api.Random
		local palette = {
			Color3.fromRGB(200, 190, 170),
			Color3.fromRGB(120, 130, 150),
			Color3.fromRGB(170, 90, 70),
			Color3.fromRGB(90, 100, 110),
			Color3.fromRGB(220, 210, 190),
			Color3.fromRGB(60, 80, 110),
		}

		-- Buildings lining the streets.
		api.alongTrack(5, 34, function(position)
			local w, d = random:NextInteger(26, 44), random:NextInteger(26, 44)
			local h = random:NextInteger(40, 150)
			if not api.isClear(position, math.max(w, d) * 0.75) then
				return
			end
			local color = palette[random:NextInteger(1, #palette)]
			local building = api.part({
				Name = "Building",
				Size = Vector3.new(w, h, d),
				CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)),
				Material = Enum.Material.Concrete,
				Color = color,
			})
			for floor = 12, h - 8, 14 do
				api.part({
					Name = "Windows",
					Size = Vector3.new(w + 0.4, 4, d + 0.4),
					CFrame = building.CFrame * CFrame.new(0, floor - h / 2, 0),
					Material = Enum.Material.Glass,
					Color = Color3.fromRGB(120, 170, 210),
					Transparency = 0.2,
				})
			end
			api.part({
				Name = "RoofTop",
				Size = Vector3.new(w * 0.4, 6, d * 0.4),
				CFrame = building.CFrame * CFrame.new(0, h / 2 + 3, 0),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(90, 90, 95),
			})
		end)

		-- Street lights.
		api.alongTrack(7, 5, function(position)
			if not api.isClear(position, 1) then
				return
			end
			api.part({ Name = "LampPost", Size = Vector3.new(0.8, 16, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 8, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 45) })
			local lamp = api.part({ Name = "Lamp", Size = Vector3.new(2, 1, 2), CFrame = CFrame.new(position + Vector3.new(0, 16.5, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 200) })
			local light = Instance.new("PointLight")
			light.Range = 30
			light.Brightness = 1.5
			light.Parent = lamp
		end)

		-- Canal under the overpass.
		api.part({
			Name = "Canal",
			Size = Vector3.new(70, 0.4, 460),
			CFrame = CFrame.new(-30, 0.2, -440),
			Material = Enum.Material.Glass,
			Color = Color3.fromRGB(40, 110, 170),
			Transparency = 0.2,
			CanCollide = false,
		})

		-- Construction zone props on the S-bends (cones and barriers on the edges).
		for u = 15.25, 16.85, 0.1 do
			local sample = api.sampleAt(u)
			for _, side in { -1, 1 } do
				local position = sample.Position + sample.Right * side * (api.Width / 2 - 2) + Vector3.new(0, 1.5, 0)
				api.part({
					Name = "Cone",
					Size = Vector3.new(1.5, 3, 1.5),
					CFrame = CFrame.new(position),
					Material = Enum.Material.SmoothPlastic,
					Color = Color3.fromRGB(255, 120, 0),
					CanCollide = false,
				})
			end
		end

		-- Alley clutter: crates and bins you have to weave around.
		local alley = {
			{ -533, -120, 4 },
			{ -528, -80, -4 },
			{ -536, -10, 4 },
			{ -531, 35, -4 },
		}
		for _, crate in alley do
			api.part({
				Name = "Crate",
				Size = Vector3.new(4, 4, 4),
				CFrame = CFrame.new(crate[1] + crate[3], 3, crate[2]),
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(160, 110, 60),
			})
		end
	end,
}
