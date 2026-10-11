-- Neon City: a dusk figure 8. Blast through the neon ring tunnel, under the freeway, up
-- the spiral onto the elevated freeway and back down through the S-bends. Two shortcuts:
-- the rooftop ramp on the east climb and the back alley on the west descent.
return {
	Name = "Neon City",
	Laps = 3,
	Seed = 33,
	Width = 34,
	Surface = "Road",
	Curbs = false,
	RoadColor = Color3.fromRGB(62, 60, 84),
	BannerColor = Color3.fromRGB(255, 0, 170),
	Ground = { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(48, 40, 74), Surface = "Offroad" },
	Border = { Width = 6, Surface = "Offroad", Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(80, 68, 112) },
	Barrier = { Height = 3, Material = Enum.Material.Metal, Color = Color3.fromRGB(90, 80, 120), Neon = Color3.fromRGB(255, 0, 200) },
	Support = "Pillars",
	PillarColor = Color3.fromRGB(95, 90, 125),
	-- Dusk instead of pitch black, so you can actually see the road.
	Lighting = {
		ClockTime = 18.6,
		Brightness = 3,
		Ambient = Color3.fromRGB(125, 105, 165),
		OutdoorAmbient = Color3.fromRGB(155, 130, 195),
		FogEnd = 1800,
		FogColor = Color3.fromRGB(95, 65, 145),
		ExposureCompensation = 0.45,
	},
	Atmosphere = { Density = 0.3, Haze = 1.5, Color = Color3.fromRGB(175, 125, 225), Decay = Color3.fromRGB(110, 60, 160), Glare = 0.5 },

	Points = {
		Vector3.new(-200, 1, 170), -- 1 start / finish
		Vector3.new(0, 1, 0), -- 2 under the freeway
		Vector3.new(180, 1, -150), -- 3 neon ring tunnel
		Vector3.new(320, 8, -170),
		Vector3.new(390, 18, -80), -- 5 east climb (rooftop shortcut)
		Vector3.new(330, 26, 30),
		Vector3.new(361, 30, 134),
		Vector3.new(250, 30, 170),
		Vector3.new(120, 30, 110),
		Vector3.new(0, 30, 0), -- 10 freeway crossing
		Vector3.new(-130, 30, -110),
		Vector3.new(-260, 24, -150),
		Vector3.new(-360, 16, -60), -- 13 west descent (back alley)
		Vector3.new(-305, 8, 30),
		Vector3.new(-380, 4, 120),
		Vector3.new(-320, 1, 200),
	},

	Shortcuts = {
		{ Width = 14, Surface = "Road", Color = Color3.fromRGB(40, 38, 60), Points = { Vector3.new(-345, 16, -45), Vector3.new(-372, 10, 30), Vector3.new(-370, 5, 110) } }, -- back alley
		{ Width = 14, Surface = "Road", Color = Color3.fromRGB(70, 40, 90), Points = { Vector3.new(400, 19, -60), Vector3.new(412, 24, 20), Vector3.new(372, 29, 110) } }, -- rooftops
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 2.6, Offset = 0 },
		{ At = 3.4, Offset = 0 },
		{ At = 5.5, Offset = -6 },
		{ At = 8.5, Offset = 0, Width = 18 },
		{ At = 10.5, Offset = 0, Width = 18 },
		{ At = 13.6, Offset = 6 },
	},
	Ramps = {
		{ At = 15.4, Offset = 0, Width = 16, Length = 18, Angle = 12, Color = Color3.fromRGB(0, 220, 255), Material = Enum.Material.Neon },
	},
	PickupRows = { 1.8, 5.0, 9.2, 12.5 },

	Decor = function(api)
		local P = api.Props
		local folder = api.Folder
		local random = api.Random

		-- Grandstand first so the scenery placed afterwards keeps clear of it.
		api.grandstand(1.35, 1, 70, Color3.fromRGB(255, 0, 170))
		local neonColors = { Color3.fromRGB(255, 0, 200), Color3.fromRGB(0, 220, 255), Color3.fromRGB(140, 80, 255), Color3.fromRGB(255, 220, 0), Color3.fromRGB(0, 255, 140) }

		local function tower(position: Vector3, w: number, d: number, h: number)
			local neon = neonColors[random:NextInteger(1, #neonColors)]
			local body = api.part({ Name = "Tower", Size = Vector3.new(w, h, d), CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(50, 50, 80), Reflectance = 0.15 })
			for floor = 12, h - 8, 14 do
				api.part({ Name = "WindowBand", Size = Vector3.new(w + 0.3, 2, d + 0.3), CFrame = body.CFrame * CFrame.new(0, floor - h / 2, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 230, 170), Transparency = 0.35 })
			end
			for _, corner in { Vector3.new(1, 0, 1), Vector3.new(-1, 0, 1), Vector3.new(1, 0, -1), Vector3.new(-1, 0, -1) } do
				api.part({ Name = "Edge", Size = Vector3.new(0.8, h, 0.8), CFrame = body.CFrame * CFrame.new(corner.X * w / 2, 0, corner.Z * d / 2), Material = Enum.Material.Neon, Color = neon })
			end
			api.part({ Name = "Crown", Size = Vector3.new(w + 1, 1, d + 1), CFrame = body.CFrame * CFrame.new(0, h / 2, 0), Material = Enum.Material.Neon, Color = neon })
			if random:NextNumber() < 0.35 then
				api.part({ Name = "Antenna", Size = Vector3.new(1, 30, 1), CFrame = body.CFrame * CFrame.new(0, h / 2 + 15, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 160) })
				api.part({ Name = "AntennaLight", Shape = Enum.PartType.Ball, Size = Vector3.one * 2, CFrame = body.CFrame * CFrame.new(0, h / 2 + 30, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 40) })
			end
		end

		-- Neon centre line.
		for i = 1, #api.Samples, 2 do
			local sample = api.Samples[i]
			api.part({ Name = "LaneLine", Size = Vector3.new(0.6, 0.1, 5), CFrame = CFrame.lookAt(sample.Position, sample.Position + sample.Forward) * CFrame.new(0, 0.08, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(230, 230, 255), CanCollide = false, CanQuery = false })
		end

		api.alongTrack(3, 12, function(position)
			local w, d, h = random:NextInteger(24, 38), random:NextInteger(24, 38), random:NextInteger(60, 200)
			if api.isClear(position, math.max(w, d) * 0.72) then
				tower(position, w, d, h)
			end
		end)
		P.ring(api.Center, api.Extent + 240, 36, function(position)
			tower(position, random:NextInteger(40, 70), random:NextInteger(40, 70), random:NextInteger(140, 320))
		end)

		-- Ground grid lines.
		for offset = -600, 600, 100 do
			api.part({ Name = "GridX", Size = Vector3.new(1, 0.1, 1300), CFrame = CFrame.new(api.Center + Vector3.new(offset, 0.05, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(130, 70, 210), CanCollide = false, CanQuery = false, Transparency = 0.3 })
			api.part({ Name = "GridZ", Size = Vector3.new(1300, 0.1, 1), CFrame = CFrame.new(api.Center + Vector3.new(0, 0.06, offset)), Material = Enum.Material.Neon, Color = Color3.fromRGB(130, 70, 210), CanCollide = false, CanQuery = false, Transparency = 0.3 })
		end

		-- Street lights.
		api.alongTrack(5, 1, function(position, sample)
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

		-- Set pieces: neon ring tunnel, grandstand, freeway arch, holo billboards.
		api.tunnel(2.25, 3.7, { Style = "Rings", Height = 18, Color = Color3.fromRGB(0, 220, 255) })
		api.arch(9.6, "NEON CITY FREEWAY", Color3.fromRGB(60, 20, 90))
		api.arch(15.8, "ALMOST HOME", Color3.fromRGB(20, 60, 90))
		local ads = { "ILLEGAL RACING", "NEON NIGHTS", "BOOST OR LOSE", "NO BRAKES" }
		for i, u in { 1.6, 4.4, 7.6, 12.3 } do
			local sample = api.sampleAt(u)
			local position = sample.Position + sample.Right * (api.Edge + 10)
			local ground = Vector3.new(position.X, 0, position.Z)
			if api.isClear(ground, 8) then
				P.billboard(folder, CFrame.lookAt(ground, ground - sample.Right), ads[i], Color3.fromRGB(30, 10, 60), neonColors[i], false)
			end
		end

		-- Floating blimp with an ad.
		local blimp = api.part({ Name = "Blimp", Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, 22, 22), CFrame = CFrame.new(api.Center + Vector3.new(0, 140, 60)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(220, 220, 230), CanCollide = false })
		local banner = api.part({ Name = "BlimpBanner", Size = Vector3.new(34, 7, 1), CFrame = blimp.CFrame * CFrame.new(0, -4, -11.2), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 0, 170), CanCollide = false })
		api.sign(banner, "ILLEGAL RACING")
	end,
}
