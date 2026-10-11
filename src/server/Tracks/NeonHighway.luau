-- Neon Highway: a night-time figure 8. The low road crosses under an elevated freeway
-- in the middle of the map; the raised sections have glowing guard rails and plenty of
-- boost pads. Pure speed track.
return {
	Name = "Neon Highway",
	Laps = 3,
	Seed = 33,
	Width = 46,
	Surface = "Road",
	Curbs = false,
	RoadColor = Color3.fromRGB(28, 28, 38),
	BannerColor = Color3.fromRGB(255, 0, 170),
	Ground = { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(22, 18, 35), Surface = "Offroad" },
	Support = "Pillars",
	PillarColor = Color3.fromRGB(60, 55, 80),
	Lighting = {
		ClockTime = 0,
		Brightness = 1,
		Ambient = Color3.fromRGB(70, 50, 110),
		OutdoorAmbient = Color3.fromRGB(80, 60, 120),
		FogEnd = 2500,
		FogColor = Color3.fromRGB(30, 15, 60),
	},

	Points = {
		Vector3.new(-300, 1, 260), -- 1 start / finish
		Vector3.new(0, 1, 0), -- 2 low crossing (under the freeway)
		Vector3.new(300, 1, -260),
		Vector3.new(520, 10, -300),
		Vector3.new(650, 25, -150),
		Vector3.new(600, 35, 100),
		Vector3.new(420, 40, 230),
		Vector3.new(200, 40, 200),
		Vector3.new(0, 40, 0), -- 9 freeway crossing (over the low road)
		Vector3.new(-200, 40, -200),
		Vector3.new(-420, 35, -260),
		Vector3.new(-620, 25, -120),
		Vector3.new(-640, 12, 120),
		Vector3.new(-500, 2, 280),
	},

	Walls = {
		Height = 3,
		Material = Enum.Material.Metal,
		Color = Color3.fromRGB(50, 45, 70),
		Neon = Color3.fromRGB(255, 0, 200),
		AboveHeight = 6,
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 3.3, Offset = 0 },
		{ At = 5.5, Offset = -8 },
		{ At = 8.5, Offset = 0, Width = 20 },
		{ At = 9.5, Offset = 0, Width = 20 },
		{ At = 12.5, Offset = 8 },
		{ At = 13.6, Offset = 0 },
	},
	Ramps = {
		{ At = 2.5, Offset = 0, Width = 18, Length = 22, Angle = 12, Color = Color3.fromRGB(0, 220, 255) },
	},
	PickupRows = { 1.7, 4.5, 8.3, 11.5 },

	Decor = function(api)
		local random = api.Random
		local neonColors = {
			Color3.fromRGB(255, 0, 200),
			Color3.fromRGB(0, 220, 255),
			Color3.fromRGB(140, 80, 255),
			Color3.fromRGB(255, 220, 0),
		}

		-- Neon center line on the road.
		for i = 1, #api.Samples, 2 do
			local sample = api.Samples[i]
			api.part({
				Name = "LaneLine",
				Size = Vector3.new(0.6, 0.1, 5),
				CFrame = CFrame.lookAt(sample.Position, sample.Position + sample.Forward) * CFrame.new(0, 0.05, 0),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(230, 230, 255),
				CanCollide = false,
				CanQuery = false,
			})
		end

		-- Skyscrapers with neon outlines.
		api.alongTrack(6, 60, function(position)
			local w, d = random:NextInteger(30, 50), random:NextInteger(30, 50)
			local h = random:NextInteger(80, 260)
			if not api.isClear(position, math.max(w, d) * 0.75) then
				return
			end
			local tower = api.part({
				Name = "Tower",
				Size = Vector3.new(w, h, d),
				CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)),
				Material = Enum.Material.Glass,
				Color = Color3.fromRGB(25, 25, 45),
			})
			local neon = neonColors[random:NextInteger(1, #neonColors)]
			for _, corner in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
				api.part({
					Name = "Edge",
					Size = Vector3.new(0.8, h, 0.8),
					CFrame = tower.CFrame * CFrame.new(corner.X * w / 2, 0, corner.Z * d / 2),
					Material = Enum.Material.Neon,
					Color = neon,
				})
			end
			api.part({
				Name = "Crown",
				Size = Vector3.new(w + 1, 1, d + 1),
				CFrame = tower.CFrame * CFrame.new(0, h / 2, 0),
				Material = Enum.Material.Neon,
				Color = neon,
			})
		end)

		-- Light poles along the low road.
		api.alongTrack(8, 4, function(position, sample)
			if sample.Position.Y > 6 or not api.isClear(position, 1) then
				return
			end
			api.part({ Name = "Pole", Size = Vector3.new(0.8, 14, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 7, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 50) })
			local bulb = api.part({ Name = "Bulb", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(position + Vector3.new(0, 14.5, 0)), Material = Enum.Material.Neon, Color = neonColors[random:NextInteger(1, #neonColors)] })
			local light = Instance.new("PointLight")
			light.Range = 35
			light.Brightness = 2
			light.Color = bulb.Color
			light.Parent = bulb
		end)
	end,
}
