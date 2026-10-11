-- Neon City: a dusk figure 8. The low road crosses under an elevated freeway in the
-- middle; glowing rails, lit-up towers and lots of boost pads. Pure speed track.
return {
	Name = "Neon City",
	Laps = 3,
	Seed = 33,
	Width = 38,
	Surface = "Road",
	Curbs = false,
	RoadColor = Color3.fromRGB(60, 58, 80),
	BannerColor = Color3.fromRGB(255, 0, 170),
	Ground = { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(45, 38, 70), Surface = "Offroad" },
	Border = { Width = 8, Surface = "Offroad", Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(70, 60, 100) },
	Barrier = { Height = 3, Material = Enum.Material.Metal, Color = Color3.fromRGB(80, 70, 110), Neon = Color3.fromRGB(255, 0, 200) },
	Support = "Pillars",
	PillarColor = Color3.fromRGB(90, 85, 120),
	-- Dusk instead of pitch black, so you can actually see the road.
	Lighting = {
		ClockTime = 18.6,
		Brightness = 3,
		Ambient = Color3.fromRGB(120, 100, 160),
		OutdoorAmbient = Color3.fromRGB(150, 125, 190),
		FogEnd = 1800,
		FogColor = Color3.fromRGB(90, 60, 140),
		ExposureCompensation = 0.4,
	},
	Atmosphere = { Density = 0.3, Haze = 1.5, Color = Color3.fromRGB(170, 120, 220), Decay = Color3.fromRGB(110, 60, 160), Glare = 0.5 },

	Points = {
		Vector3.new(-180, 1, 156), -- 1 start / finish
		Vector3.new(0, 1, 0), -- 2 low crossing (under the freeway)
		Vector3.new(180, 1, -156),
		Vector3.new(312, 8, -180),
		Vector3.new(390, 18, -90),
		Vector3.new(360, 26, 60),
		Vector3.new(252, 30, 138),
		Vector3.new(120, 30, 120),
		Vector3.new(0, 30, 0), -- 9 freeway crossing (over the low road)
		Vector3.new(-120, 30, -120),
		Vector3.new(-252, 26, -156),
		Vector3.new(-372, 18, -72),
		Vector3.new(-384, 8, 72),
		Vector3.new(-300, 2, 168),
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 3.3, Offset = 0 },
		{ At = 5.5, Offset = -7 },
		{ At = 8.5, Offset = 0, Width = 18 },
		{ At = 9.5, Offset = 0, Width = 18 },
		{ At = 12.5, Offset = 7 },
		{ At = 13.6, Offset = 0 },
	},
	Ramps = {
		{ At = 2.5, Offset = 0, Width = 16, Length = 20, Angle = 12, Color = Color3.fromRGB(0, 220, 255), Material = Enum.Material.Neon },
	},
	PickupRows = { 1.7, 4.5, 8.3, 11.5 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random
		local neonColors = { Color3.fromRGB(255, 0, 200), Color3.fromRGB(0, 220, 255), Color3.fromRGB(140, 80, 255), Color3.fromRGB(255, 220, 0), Color3.fromRGB(0, 255, 140) }

		local function tower(position: Vector3, w: number, d: number, h: number)
			local neon = neonColors[random:NextInteger(1, #neonColors)]
			local body = api.part({ Name = "Tower", Size = Vector3.new(w, h, d), CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(45, 45, 75), Reflectance = 0.15 })
			for floor = 12, h - 8, 16 do -- lit window bands
				api.part({ Name = "WindowBand", Size = Vector3.new(w + 0.3, 2, d + 0.3), CFrame = body.CFrame * CFrame.new(0, floor - h / 2, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 230, 170), Transparency = 0.35 })
			end
			for _, corner in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
				api.part({ Name = "Edge", Size = Vector3.new(0.8, h, 0.8), CFrame = body.CFrame * CFrame.new(corner.X * w / 2, 0, corner.Z * d / 2), Material = Enum.Material.Neon, Color = neon })
			end
			api.part({ Name = "Crown", Size = Vector3.new(w + 1, 1, d + 1), CFrame = body.CFrame * CFrame.new(0, h / 2, 0), Material = Enum.Material.Neon, Color = neon })
		end

		-- Neon centre line.
		for i = 1, #api.Samples, 2 do
			local sample = api.Samples[i]
			api.part({ Name = "LaneLine", Size = Vector3.new(0.6, 0.1, 5), CFrame = CFrame.lookAt(sample.Position, sample.Position + sample.Forward) * CFrame.new(0, 0.08, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(230, 230, 255), CanCollide = false, CanQuery = false })
		end

		-- Towers near the road and a skyline ring.
		api.alongTrack(4, 16, function(position)
			local w, d, h = random:NextInteger(26, 40), random:NextInteger(26, 40), random:NextInteger(60, 200)
			if api.isClear(position, math.max(w, d) * 0.72) then
				tower(position, w, d, h)
			end
		end)
		P.ring(api.Center, api.Extent + 250, 36, function(position)
			tower(position, random:NextInteger(40, 70), random:NextInteger(40, 70), random:NextInteger(140, 320))
		end)

		-- Ground grid lines.
		for offset = -600, 600, 100 do
			api.part({ Name = "GridX", Size = Vector3.new(1, 0.1, 1300), CFrame = CFrame.new(api.Center + Vector3.new(offset, 0.05, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 60, 200), CanCollide = false, CanQuery = false, Transparency = 0.3 })
			api.part({ Name = "GridZ", Size = Vector3.new(1300, 0.1, 1), CFrame = CFrame.new(api.Center + Vector3.new(0, 0.06, offset)), Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 60, 200), CanCollide = false, CanQuery = false, Transparency = 0.3 })
		end

		-- Street lights along the low road.
		api.alongTrack(6, 2, function(position, sample)
			if sample.Position.Y > 6 or not api.isClear(position, 1) then
				return
			end
			api.part({ Name = "Pole", Size = Vector3.new(0.8, 14, 0.8), CFrame = CFrame.new(position + Vector3.new(0, 7, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 60, 75) })
			local bulb = api.part({ Name = "Bulb", Size = Vector3.new(1.8, 1.8, 1.8), CFrame = CFrame.new(position + Vector3.new(0, 14.5, 0)), Material = Enum.Material.Neon, Color = neonColors[random:NextInteger(1, #neonColors)] })
			local light = Instance.new("PointLight")
			light.Range = 40
			light.Brightness = 2.5
			light.Color = bulb.Color
			light.Parent = bulb
		end)

		-- Holographic billboards.
		local ads = { "ILLEGAL RACING", "NEON NIGHTS", "BOOST OR LOSE", "NO BRAKES" }
		for i, u in { 1.5, 4.2, 7.5, 12.2 } do
			local sample = api.sampleAt(u)
			local position = sample.Position + sample.Right * (api.Edge + 10)
			local ground = Vector3.new(position.X, 0, position.Z)
			P.billboard(folder, CFrame.lookAt(ground, ground - sample.Right), ads[i], Color3.fromRGB(30, 10, 60), neonColors[i], false)
		end
	end,
}
