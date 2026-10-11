-- Dusty Canyon Run: an all-dirt rally track. Climb onto a mesa, jump a gorge, drop back
-- to the desert floor and loop through the dunes. High-traction cars can cut straight
-- through the mud pit in the middle of the west loop.
return {
	Name = "Dusty Canyon Run",
	Laps = 3,
	Seed = 22,
	Width = 44,
	Surface = "Dirt",
	Curbs = false,
	BannerColor = Color3.fromRGB(200, 90, 30),
	Ground = { Material = Enum.Material.Sand, Color = Color3.fromRGB(220, 185, 125), Surface = "Offroad" },
	Support = "Fill",
	FillMaterial = Enum.Material.Sandstone,
	FillColor = Color3.fromRGB(195, 120, 75),
	Lighting = {
		ClockTime = 16.8,
		Brightness = 2.5,
		Ambient = Color3.fromRGB(140, 105, 80),
		OutdoorAmbient = Color3.fromRGB(150, 115, 90),
		FogEnd = 3000,
		FogColor = Color3.fromRGB(230, 190, 140),
	},

	Points = {
		Vector3.new(0, 1, 500), -- 1 start / finish
		Vector3.new(300, 1, 500),
		Vector3.new(550, 10, 420), -- 3 climb
		Vector3.new(650, 30, 250),
		Vector3.new(620, 45, 50), -- 5 mesa top
		Vector3.new(500, 45, -100),
		Vector3.new(350, 45, -150), -- 7 gorge jump
		Vector3.new(150, 25, -150),
		Vector3.new(-50, 10, -200),
		Vector3.new(-250, 1, -300),
		Vector3.new(-500, 1, -250), -- 11 west loop
		Vector3.new(-620, 1, -50),
		Vector3.new(-560, 1, 150),
		Vector3.new(-380, 1, 200),
		Vector3.new(-250, 1, 350),
	},

	Walls = {
		Height = 2,
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(150, 95, 60),
		Ranges = { { From = 4.4, To = 7.45 } },
	},
	Gaps = {
		{ From = 7.47, To = 7.6 },
	},

	Shortcuts = {
		{ -- mud pit: brutal unless your car has high Traction
			Width = 18,
			Surface = "Mud",
			Points = { Vector3.new(-480, 1, -245), Vector3.new(-455, 1, -20), Vector3.new(-420, 1, 185) },
		},
	},

	BoostPads = {
		{ At = 1.4, Offset = 0 },
		{ At = 3.6, Offset = 0, Width = 16 },
		{ At = 7.2, Offset = 0, Width = 20 }, -- hit this before the gorge!
		{ At = 9.5, Offset = -8 },
		{ At = 14.4, Offset = 8 },
	},
	Ramps = {
		{ At = 7.4, Offset = 0, Width = 44, Length = 24, Angle = 14, Color = Color3.fromRGB(150, 100, 60) },
		{ At = 2.4, Offset = 12, Width = 14, Length = 20, Angle = 12, Color = Color3.fromRGB(150, 100, 60) },
	},
	PickupRows = { 2.2, 6.0, 9.7, 12.5 },

	Decor = function(api)
		local random = api.Random
		local rockColors = {
			Color3.fromRGB(190, 110, 70),
			Color3.fromRGB(170, 95, 60),
			Color3.fromRGB(210, 140, 90),
		}

		-- Canyon rock towers.
		api.alongTrack(4, 26, function(position)
			if random:NextNumber() < 0.35 then
				return
			end
			local w, d = random:NextInteger(18, 40), random:NextInteger(18, 40)
			local h = random:NextInteger(20, 90)
			if not api.isClear(position, math.max(w, d) * 0.75) then
				return
			end
			local color = rockColors[random:NextInteger(1, #rockColors)]
			api.part({
				Name = "Rock",
				Size = Vector3.new(w, h, d),
				CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, random:NextNumber() * math.pi, 0),
				Material = Enum.Material.Sandstone,
				Color = color,
			})
			api.part({
				Name = "RockCap",
				Size = Vector3.new(w + 6, 4, d + 6),
				CFrame = CFrame.new(position + Vector3.new(0, h + 2, 0)),
				Material = Enum.Material.Sandstone,
				Color = color:Lerp(Color3.new(0, 0, 0), 0.15),
			})
		end)

		-- Cacti close to the track.
		api.alongTrack(3, 9, function(position)
			if random:NextNumber() < 0.6 or not api.isClear(position, 2) then
				return
			end
			local h = random:NextInteger(6, 11)
			local green = Color3.fromRGB(70, 140, 60)
			api.part({ Name = "Cactus", Size = Vector3.new(2, h, 2), CFrame = CFrame.new(position + Vector3.new(0, h / 2, 0)), Material = Enum.Material.Grass, Color = green, CanCollide = false })
			api.part({ Name = "CactusArm", Size = Vector3.new(4, 1.5, 1.5), CFrame = CFrame.new(position + Vector3.new(1.5, h * 0.6, 0)), Material = Enum.Material.Grass, Color = green, CanCollide = false })
			api.part({ Name = "CactusArm", Size = Vector3.new(1.5, 3, 1.5), CFrame = CFrame.new(position + Vector3.new(3, h * 0.6 + 1.5, 0)), Material = Enum.Material.Grass, Color = green, CanCollide = false })
		end)

		-- Warning signs before the gorge.
		local sample = api.sampleAt(7.25)
		for _, side in { -1, 1 } do
			local position = sample.Position + sample.Right * side * (api.Width / 2 + 4)
			api.part({ Name = "SignPost", Size = Vector3.new(0.6, 8, 0.6), CFrame = CFrame.new(position + Vector3.new(0, 4, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 80, 50) })
			local sign = api.part({
				Name = "Sign",
				Size = Vector3.new(8, 4, 0.4),
				CFrame = CFrame.lookAt(position + Vector3.new(0, 9, 0), position + Vector3.new(0, 9, 0) - sample.Forward),
				Material = Enum.Material.SmoothPlastic,
				Color = Color3.fromRGB(255, 200, 0),
			})
			api.sign(sign, "JUMP!", Color3.new(0, 0, 0))
		end

		-- Floating bones, er, "abandoned barrels" in the mud pit.
		for _, z in { -150, -60, 40, 120 } do
			api.part({
				Name = "Barrel",
				Shape = Enum.PartType.Cylinder,
				Size = Vector3.new(3, 2.5, 2.5),
				CFrame = CFrame.new(-470 + (z % 3) * 4, 1.5, z) * CFrame.Angles(0, 0, math.rad(90)),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(120, 60, 40),
			})
		end
	end,
}
