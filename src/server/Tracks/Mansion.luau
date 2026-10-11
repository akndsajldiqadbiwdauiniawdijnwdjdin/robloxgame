-- Grand Mansion: race down red carpets through a millionaire's mansion. Through the
-- portrait-gallery corridor, up the grand marble staircase to the balcony, back down past
-- the fireplace and through the ballroom chicane, or sneak through the library.
return {
	Name = "Grand Mansion",
	Laps = 3,
	Seed = 66,
	Width = 32,
	Surface = "Road",
	Curbs = false,
	RoadMaterial = Enum.Material.Fabric,
	RoadColor = Color3.fromRGB(165, 22, 38),
	BannerColor = Color3.fromRGB(200, 160, 60),
	Ground = { Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(125, 76, 44), Surface = "Offroad" },
	Border = { Width = 6, Surface = "Offroad", Material = Enum.Material.Fabric, Color = Color3.fromRGB(205, 165, 70) },
	Barrier = { Height = 5, Material = Enum.Material.Wood, Color = Color3.fromRGB(85, 48, 28) },
	Support = "Fill",
	FillMaterial = Enum.Material.Marble,
	FillColor = Color3.fromRGB(232, 226, 215),
	Lighting = {
		ClockTime = 17.8,
		Brightness = 1.9,
		Ambient = Color3.fromRGB(155, 120, 90),
		OutdoorAmbient = Color3.fromRGB(170, 135, 105),
		FogEnd = 1400,
		FogColor = Color3.fromRGB(120, 90, 70),
		ExposureCompensation = 0.25,
	},
	Atmosphere = { Density = 0.3, Haze = 1, Color = Color3.fromRGB(220, 180, 140) },

	Points = {
		Vector3.new(0, 1, 240), -- 1 start / finish in the entrance hall
		Vector3.new(200, 1, 240),
		Vector3.new(290, 1, 160), -- 3 portrait gallery corridor
		Vector3.new(290, 1, 20),
		Vector3.new(220, 8, -100), -- 5 grand staircase up
		Vector3.new(80, 20, -170), -- 6 balcony
		Vector3.new(-60, 20, -170),
		Vector3.new(-160, 14, -110), -- 8 staircase down
		Vector3.new(-120, 6, -30),
		Vector3.new(-157, 1, 26), -- 10 ballroom (library shortcut skips it)
		Vector3.new(-150, 1, 90),
		Vector3.new(-270, 1, 170),
		Vector3.new(-200, 1, 250),
	},

	Sections = {
		{ From = 4.6, To = 9.4, Surface = "Road", Material = Enum.Material.Marble, Color = Color3.fromRGB(235, 230, 220) }, -- marble stairs + balcony
		{ From = 10.0, To = 11.6, Surface = "Road", Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(200, 150, 90) }, -- ballroom floor
	},
	Shortcuts = {
		{ Width = 14, Surface = "Offroad", Material = Enum.Material.Fabric, Color = Color3.fromRGB(40, 100, 60), Points = { Vector3.new(-165, 1, 10), Vector3.new(-235, 1, 85), Vector3.new(-255, 1, 160) } }, -- library
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 3.6, Offset = 6 },
		{ At = 6.5, Offset = 0, Width = 16 },
		{ At = 10.5, Offset = -6 },
		{ At = 12.5, Offset = 0 },
	},
	Ramps = {
		{ At = 2.4, Offset = -8, Width = 12, Length = 16, Angle = 12, Color = Color3.fromRGB(200, 160, 60), Material = Enum.Material.Wood },
	},
	PickupRows = { 2.2, 5.8, 9.6, 12.2 },

	Decor = function(api)
		local folder = api.Folder
		local random = api.Random
		local gold = Color3.fromRGB(215, 175, 70)
		local marble = Color3.fromRGB(235, 230, 220)
		local half = api.Extent + 90
		local wallHeight = 110

		-- Set pieces first: gallery corridor, arches.
		api.tunnel(3.15, 3.85, { Height = 18, Material = Enum.Material.Wood, Color = Color3.fromRGB(95, 55, 30), LightColor = Color3.fromRGB(255, 210, 150) })
		api.arch(1.4, "GRAND MANSION", Color3.fromRGB(120, 20, 35))
		api.arch(10.4, "BALLROOM", Color3.fromRGB(60, 40, 90))

		-- Outer mansion walls with tall windows, curtains and paintings.
		for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			local along = Vector3.new(math.abs(side.Z), 0, math.abs(side.X))
			local center = api.Center + side * half + Vector3.new(0, wallHeight / 2, 0)
			api.part({ Name = "MansionWall", Size = along * (half * 2) + Vector3.new(4, wallHeight, 4), CFrame = CFrame.new(center), Material = Enum.Material.Plaster, Color = Color3.fromRGB(230, 212, 185) })
			api.part({ Name = "Wainscot", Size = along * (half * 2) + Vector3.new(5, 24, 5), CFrame = CFrame.new(center - Vector3.new(0, wallHeight / 2 - 12, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(95, 55, 30) })
			api.part({ Name = "GoldTrim", Size = along * (half * 2) + Vector3.new(5.5, 2, 5.5), CFrame = CFrame.new(center - Vector3.new(0, wallHeight / 2 - 25, 0)), Material = Enum.Material.Metal, Color = gold })
			for k = -3, 3 do
				local windowCenter = center + along * (k * half / 3.6) + Vector3.new(0, 10, 0)
				api.part({ Name = "Window", Size = along * 26 + Vector3.new(5, 50, 5), CFrame = CFrame.new(windowCenter), Material = Enum.Material.Glass, Color = Color3.fromRGB(170, 200, 230), Transparency = 0.2 })
				api.part({ Name = "Curtain", Size = along * 8 + Vector3.new(6, 56, 6), CFrame = CFrame.new(windowCenter + along * 16), Material = Enum.Material.Fabric, Color = Color3.fromRGB(140, 20, 40) })
				local frame = api.part({ Name = "PaintingFrame", Size = along * 22 + Vector3.new(5.5, 16, 5.5), CFrame = CFrame.new(windowCenter + along * (half / 7.2) - Vector3.new(0, 18, 0)), Material = Enum.Material.Metal, Color = gold })
				api.part({ Name = "Canvas", Size = along * 18 + Vector3.new(6, 12, 6), CFrame = frame.CFrame, Material = Enum.Material.SmoothPlastic, Color = Color3.fromHSV(random:NextNumber(), 0.5, 0.6) })
			end
		end

		-- Chandeliers over the carpet.
		for i = 1, #api.Samples, 12 do
			local sample = api.Samples[i]
			local top = sample.Position + Vector3.new(0, 42, 0)
			api.part({ Name = "Chain", Size = Vector3.new(0.4, wallHeight - top.Y, 0.4), CFrame = CFrame.new(top + Vector3.new(0, (wallHeight - top.Y) / 2, 0)), Material = Enum.Material.Metal, Color = gold, CanCollide = false })
			api.part({ Name = "ChandelierRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 12, 12), CFrame = CFrame.new(top) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = gold, CanCollide = false })
			for k = 0, 5 do
				local angle = k * math.pi / 3
				api.part({ Name = "Candle", Size = Vector3.new(0.8, 2, 0.8), CFrame = CFrame.new(top + Vector3.new(math.cos(angle) * 5, 1.5, math.sin(angle) * 5)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 220, 150), CanCollide = false })
			end
			local light = Instance.new("PointLight")
			light.Range = 45
			light.Brightness = 2
			light.Color = Color3.fromRGB(255, 210, 150)
			light.Parent = api.part({ Name = "ChandelierGlow", Size = Vector3.one, CFrame = CFrame.new(top), Transparency = 1, CanCollide = false })
		end

		-- Marble columns lining the route.
		api.alongTrack(5, 3, function(position)
			if api.isClear(position, 3) then
				api.part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(50, 6, 6), CFrame = CFrame.new(position + Vector3.new(0, 25, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = marble })
				api.part({ Name = "ColumnBase", Size = Vector3.new(8, 3, 8), CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)), Material = Enum.Material.Marble, Color = marble })
			end
		end)

		-- Library bookshelves on both sides of the shortcut.
		local function libraryX(z: number): number
			if z < 85 then
				return -165 + (z - 10) / 75 * -70
			end
			return -235 + (z - 85) / 75 * -20
		end
		for z = 20, 155, 13 do
			for _, side in { -1, 1 } do
				local position = Vector3.new(libraryX(z) + side * 13, 0, z)
				if api.isClear(position, 1.5) then
					local shelf = api.part({ Name = "Bookshelf", Size = Vector3.new(4, 24, 12), CFrame = CFrame.new(position + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(90, 55, 30) })
					for row = 0, 3 do
						api.part({ Name = "Books", Size = Vector3.new(4.4, 4, 10), CFrame = shelf.CFrame * CFrame.new(0, -8 + row * 5.5, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromHSV(random:NextNumber(), 0.6, 0.6) })
					end
				end
			end
		end

		-- Dining hall, grand piano, fireplace, suits of armour, rugs and plants.
		local dining = Vector3.new(40, 0, 70)
		api.part({ Name = "DiningTable", Size = Vector3.new(80, 2, 16), CFrame = CFrame.new(dining + Vector3.new(0, 12, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(110, 60, 30) })
		for k = -3, 3 do
			api.part({ Name = "TableLeg", Size = Vector3.new(2, 11, 2), CFrame = CFrame.new(dining + Vector3.new(k * 12, 5.5, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(90, 50, 25) })
			for _, side in { -1, 1 } do
				api.part({ Name = "ChairSeat", Size = Vector3.new(6, 1, 6), CFrame = CFrame.new(dining + Vector3.new(k * 12, 7, side * 12)), Material = Enum.Material.Fabric, Color = Color3.fromRGB(150, 20, 35) })
				api.part({ Name = "ChairBack", Size = Vector3.new(6, 10, 1), CFrame = CFrame.new(dining + Vector3.new(k * 12, 12, side * 15)), Material = Enum.Material.Wood, Color = Color3.fromRGB(90, 50, 25) })
			end
			api.part({ Name = "Candle", Size = Vector3.new(1, 3, 1), CFrame = CFrame.new(dining + Vector3.new(k * 12, 14.5, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 230, 170) })
		end
		local piano = Vector3.new(-40, 0, -10)
		api.part({ Name = "PianoBody", Size = Vector3.new(26, 10, 18), CFrame = CFrame.new(piano + Vector3.new(0, 9, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(15, 15, 18), Reflectance = 0.3 })
		api.part({ Name = "PianoKeys", Size = Vector3.new(24, 1, 4), CFrame = CFrame.new(piano + Vector3.new(0, 10, 10)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(245, 245, 245) })
		local fire = Vector3.new(api.Center.X, 0, api.Center.Z - half + 8)
		api.part({ Name = "Fireplace", Size = Vector3.new(50, 40, 12), CFrame = CFrame.new(fire + Vector3.new(0, 20, 0)), Material = Enum.Material.Brick, Color = Color3.fromRGB(120, 60, 45) })
		local flames = api.part({ Name = "Flames", Size = Vector3.new(26, 12, 3), CFrame = CFrame.new(fire + Vector3.new(0, 8, 6)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 20) })
		local glow = Instance.new("PointLight")
		glow.Range = 60
		glow.Brightness = 3
		glow.Color = Color3.fromRGB(255, 140, 50)
		glow.Parent = flames
		for _ = 1, 30 do
			local spot = api.Center + Vector3.new(random:NextInteger(-260, 260), 0, random:NextInteger(-220, 220))
			local roll = random:NextNumber()
			if roll < 0.3 and api.isClear(spot, 4) then
				local armour = Color3.fromRGB(170, 175, 185)
				api.part({ Name = "ArmourLegs", Size = Vector3.new(4, 8, 2.5), CFrame = CFrame.new(spot + Vector3.new(0, 4, 0)), Material = Enum.Material.Metal, Color = armour })
				api.part({ Name = "ArmourBody", Size = Vector3.new(5, 7, 3), CFrame = CFrame.new(spot + Vector3.new(0, 11.5, 0)), Material = Enum.Material.Metal, Color = armour })
				api.part({ Name = "ArmourHelmet", Shape = Enum.PartType.Ball, Size = Vector3.one * 3.6, CFrame = CFrame.new(spot + Vector3.new(0, 16.5, 0)), Material = Enum.Material.Metal, Color = armour })
			elseif roll < 0.7 and api.isClear(spot, 12) then
				api.part({ Name = "Rug", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 24, 24), CFrame = CFrame.new(spot + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Fabric, Color = Color3.fromHSV(random:NextNumber(), 0.5, 0.55), CanCollide = false })
				api.part({ Name = "Pot", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, 5, 5), CFrame = CFrame.new(spot + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Marble, Color = Color3.fromRGB(200, 90, 60) })
				api.Props.tree(folder, spot + Vector3.new(0, 4, 0), 0.6, "round")
			elseif api.isClear(spot, 6) then
				api.part({ Name = "GrandfatherClock", Size = Vector3.new(5, 20, 4), CFrame = CFrame.new(spot + Vector3.new(0, 10, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(80, 45, 25) })
				api.part({ Name = "ClockFace", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 4, 4), CFrame = CFrame.new(spot + Vector3.new(0, 16, -2.1)) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(245, 235, 210) })
			end
		end
	end,
}
