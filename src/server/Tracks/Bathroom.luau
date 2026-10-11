-- Bathroom Blitz: you're toy-sized in a giant bathroom. Tile road, bath-mat offroad, a
-- slippery soap spill, the towel climb onto the bathtub rim, bubbles, a drain jump on the
-- way down, and a race through a toilet-paper roll. Shortcuts: the bath mat and the
-- path under the sink.
return {
	Name = "Bathroom Blitz",
	Laps = 3,
	Seed = 77,
	Width = 32,
	Surface = "Road",
	Curbs = false,
	RoadMaterial = Enum.Material.SmoothPlastic,
	RoadColor = Color3.fromRGB(150, 200, 225),
	BannerColor = Color3.fromRGB(80, 190, 255),
	Ground = { Material = Enum.Material.Marble, Color = Color3.fromRGB(238, 238, 242), Surface = "Offroad" },
	Border = { Width = 8, Surface = "Offroad", Material = Enum.Material.Fabric, Color = Color3.fromRGB(110, 200, 180) },
	Barrier = { Height = 3, Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(250, 250, 252) },
	Support = "Fill",
	FillMaterial = Enum.Material.SmoothPlastic,
	FillColor = Color3.fromRGB(245, 245, 248), -- the side of the bathtub
	Lighting = {
		ClockTime = 12,
		Brightness = 3,
		Ambient = Color3.fromRGB(165, 170, 180),
		OutdoorAmbient = Color3.fromRGB(180, 185, 195),
		FogEnd = 1600,
		FogColor = Color3.fromRGB(225, 235, 245),
		ExposureCompensation = 0,
	},
	Atmosphere = { Density = 0.2, Haze = 0.5, Color = Color3.fromRGB(230, 240, 250) },

	Points = {
		Vector3.new(0, 1, 250), -- 1 start / finish on the floor tiles
		Vector3.new(220, 1, 250),
		Vector3.new(320, 1, 150), -- 3 soap spill
		Vector3.new(300, 1, 20),
		Vector3.new(200, 1, -60), -- 5 up the towel
		Vector3.new(221, 10, -143),
		Vector3.new(120, 24, -200), -- 7 bathtub rim
		Vector3.new(-60, 24, -200),
		Vector3.new(-200, 24, -140), -- 9 drain jump on the way down
		Vector3.new(-230, 12, -40),
		Vector3.new(-180, 1, 40),
		Vector3.new(-250, 1, 120), -- 12 toilet-paper tunnel
		Vector3.new(-200, 1, 200),
		Vector3.new(-100, 1, 250),
	},

	Sections = {
		{ From = 3.3, To = 3.8, Surface = "Ice", Material = Enum.Material.Glass, Color = Color3.fromRGB(255, 190, 220) }, -- soap spill
		{ From = 5.0, To = 6.1, Surface = "Road", Material = Enum.Material.Fabric, Color = Color3.fromRGB(240, 120, 80) }, -- towel
		{ From = 6.1, To = 9.3, Surface = "Road", Material = Enum.Material.Marble, Color = Color3.fromRGB(250, 250, 252) }, -- tub rim
		{ From = 7.4, To = 7.7, Surface = "Ice", Material = Enum.Material.Glass, Color = Color3.fromRGB(190, 230, 255) }, -- bubbles on the rim
	},
	Shortcuts = {
		{ Width = 14, Surface = "Offroad", Material = Enum.Material.Fabric, Color = Color3.fromRGB(240, 150, 190), Points = { Vector3.new(-170, 1, 30), Vector3.new(-120, 1, 140), Vector3.new(-115, 1, 235) } }, -- bath mat
		{ Width = 14, Surface = "Road", Color = Color3.fromRGB(170, 150, 120), Points = { Vector3.new(310, 1, 35), Vector3.new(330, 1, -50), Vector3.new(245, 9, -140) } }, -- under the sink
	},

	BoostPads = {
		{ At = 1.5, Offset = 0 },
		{ At = 4.6, Offset = 0, Width = 16 },
		{ At = 9.25, Offset = 0, Width = 16 }, -- before the drain jump
		{ At = 11.5, Offset = -6 },
		{ At = 13.5, Offset = 0 },
	},
	Ramps = {
		{ At = 9.36, Offset = 0, Width = 32, Length = 18, Angle = 13, Color = Color3.fromRGB(80, 200, 255), Material = Enum.Material.SmoothPlastic },
		{ At = 1.9, Offset = 9, Width = 12, Length = 16, Angle = 12, Color = Color3.fromRGB(255, 220, 60), Material = Enum.Material.SmoothPlastic }, -- toothbrush
	},
	PickupRows = { 2.3, 6.5, 10.4, 13.0 },

	Decor = function(api)
		local random = api.Random
		local white = Color3.fromRGB(250, 250, 252)
		local half = api.Extent + 110
		local wallHeight = 260

		-- Set pieces first: toilet-paper tunnel and arches.
		api.tunnel(12.35, 12.75, { Style = "Rings", Height = 20, Color = white })
		api.arch(1.35, "BATHROOM BLITZ", Color3.fromRGB(40, 120, 170))
		api.arch(6.6, "TUB RIM · DON'T FALL IN", Color3.fromRGB(240, 120, 80))

		-- Tiled walls with an accent band, and grout lines on the floor.
		for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			local along = Vector3.new(math.abs(side.Z), 0, math.abs(side.X))
			local center = api.Center + side * half + Vector3.new(0, wallHeight / 2, 0)
			api.part({ Name = "TileWall", Size = along * (half * 2) + Vector3.new(4, wallHeight, 4), CFrame = CFrame.new(center), Material = Enum.Material.Marble, Color = Color3.fromRGB(215, 235, 245) })
			api.part({ Name = "TileBand", Size = along * (half * 2) + Vector3.new(5, 16, 5), CFrame = CFrame.new(center - Vector3.new(0, wallHeight / 2 - 60, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(40, 120, 170) })
			api.part({ Name = "Skirting", Size = along * (half * 2) + Vector3.new(5, 6, 5), CFrame = CFrame.new(center - Vector3.new(0, wallHeight / 2 - 3, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(200, 180, 150) })
		end
		for offset = -half, half, 40 do
			api.part({ Name = "Grout", Size = Vector3.new(0.6, 0.06, half * 2), CFrame = CFrame.new(api.Center + Vector3.new(offset, 0.03, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 200, 205), CanCollide = false, CanQuery = false })
			api.part({ Name = "Grout", Size = Vector3.new(half * 2, 0.06, 0.6), CFrame = CFrame.new(api.Center + Vector3.new(0, 0.035, offset)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(200, 200, 205), CanCollide = false, CanQuery = false })
		end

		-- The bathtub: the rim road runs along its edge; water, bubbles and a giant duck inside.
		local tub = Vector3.new(-40, 0, -138)
		api.part({ Name = "TubInside", Size = Vector3.new(250, 15, 84), CFrame = CFrame.new(tub + Vector3.new(0, 7.5, 0)), Material = Enum.Material.SmoothPlastic, Color = white })
		api.part({ Name = "TubWater", Size = Vector3.new(248, 1, 82), CFrame = CFrame.new(tub + Vector3.new(0, 16, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(120, 200, 240), Transparency = 0.25, CanCollide = false })
		local duck = tub + Vector3.new(20, 0, 5)
		api.part({ Name = "DuckBody", Shape = Enum.PartType.Ball, Size = Vector3.one * 34, CFrame = CFrame.new(duck + Vector3.new(0, 26, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 215, 0) })
		api.part({ Name = "DuckHead", Shape = Enum.PartType.Ball, Size = Vector3.one * 22, CFrame = CFrame.new(duck + Vector3.new(-10, 48, 0)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 215, 0) })
		api.part({ ClassName = "WedgePart", Name = "DuckBeak", Size = Vector3.new(8, 5, 10), CFrame = CFrame.new(duck + Vector3.new(-23, 46, 0)) * CFrame.Angles(0, math.rad(-90), 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 120, 0) })
		for _, z in { -5, 5 } do
			api.part({ Name = "DuckEye", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, CFrame = CFrame.new(duck + Vector3.new(-19, 52, z)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(20, 20, 20) })
		end
		for _ = 1, 40 do
			local size = random:NextInteger(3, 10)
			api.part({ Name = "Bubble", Shape = Enum.PartType.Ball, Size = Vector3.one * size, CFrame = CFrame.new(tub + Vector3.new(random:NextInteger(-120, 120), random:NextInteger(18, 70), random:NextInteger(-38, 38))), Material = Enum.Material.Glass, Color = Color3.fromRGB(220, 240, 255), Transparency = 0.6, CanCollide = false, CanQuery = false })
		end
		api.part({ Name = "Faucet", Size = Vector3.new(6, 30, 6), CFrame = CFrame.new(tub + Vector3.new(-120, 30, 0)), Material = Enum.Material.Metal, Color = Color3.fromRGB(210, 210, 220) })

		-- Giant toilet.
		local toilet = Vector3.new(150, 0, 110)
		api.part({ Name = "ToiletBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(30, 34, 34), CFrame = CFrame.new(toilet + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = white })
		api.part({ Name = "ToiletBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 50, 50), CFrame = CFrame.new(toilet + Vector3.new(0, 34, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = white })
		api.part({ Name = "ToiletSeat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 52, 52), CFrame = CFrame.new(toilet + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(235, 235, 240) })
		api.part({ Name = "ToiletTank", Size = Vector3.new(58, 52, 20), CFrame = CFrame.new(toilet + Vector3.new(0, 52, 32)), Material = Enum.Material.SmoothPlastic, Color = white })
		api.part({ Name = "FlushHandle", Size = Vector3.new(10, 2, 2), CFrame = CFrame.new(toilet + Vector3.new(-26, 70, 21)), Material = Enum.Material.Metal, Color = Color3.fromRGB(200, 200, 210) })

		-- Spare toilet-paper roll, toothpaste, shampoo bottles, soap bars, a sponge.
		local paper = Vector3.new(-30, 0, 120)
		api.part({ Name = "PaperRoll", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26, 34, 34), CFrame = CFrame.new(paper + Vector3.new(0, 17, 0)), Material = Enum.Material.Fabric, Color = white })
		api.part({ Name = "PaperTube", Shape = Enum.PartType.Cylinder, Size = Vector3.new(26.4, 12, 12), CFrame = CFrame.new(paper + Vector3.new(0, 17, 0)), Material = Enum.Material.Cardboard, Color = Color3.fromRGB(180, 140, 90) })
		local tube = CFrame.new(60, 5, 160) * CFrame.Angles(0, math.rad(20), 0)
		api.part({ Name = "ToothpasteTube", Size = Vector3.new(14, 8, 50), CFrame = tube, Material = Enum.Material.SmoothPlastic, Color = white })
		api.part({ Name = "ToothpasteStripe", Size = Vector3.new(14.2, 8.2, 10), CFrame = tube * CFrame.new(0, 0, 10), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(220, 40, 50) })
		for k = 0, 2 do
			local bottle = Vector3.new(-60 + k * 26, 0, 20)
			local color = ({ Color3.fromRGB(120, 60, 200), Color3.fromRGB(40, 180, 120), Color3.fromRGB(250, 140, 40) })[k + 1]
			api.part({ Name = "Bottle", Shape = Enum.PartType.Cylinder, Size = Vector3.new(60 - k * 10, 20, 20), CFrame = CFrame.new(bottle + Vector3.new(0, (60 - k * 10) / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Glass, Color = color, Transparency = 0.1 })
			api.part({ Name = "BottleCap", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 10, 10), CFrame = CFrame.new(bottle + Vector3.new(0, 63 - k * 10, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.SmoothPlastic, Color = white })
		end
		local soap = api.sampleAt(3.55)
		for _, side in { -1, 1 } do
			local position = soap.Position + soap.Right * side * (api.Edge + 10)
			if api.isClear(Vector3.new(position.X, 0, position.Z), 10) then
				api.part({ Name = "SoapBar", Size = Vector3.new(16, 7, 26), CFrame = CFrame.lookAt(Vector3.new(position.X, 3.5, position.Z), Vector3.new(position.X, 3.5, position.Z) + soap.Forward), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 170, 210) })
			end
		end
		api.part({ Name = "Sponge", Size = Vector3.new(24, 12, 16), CFrame = CFrame.new(70, 6, 40), Material = Enum.Material.Foil, Color = Color3.fromRGB(255, 220, 90) })

		-- Sink cabinet and mirror on the far wall (the "under the sink" shortcut runs nearby).
		local sink = Vector3.new(api.Center.X + 60, 0, api.Center.Z - half + 30)
		api.part({ Name = "Cabinet", Size = Vector3.new(160, 90, 50), CFrame = CFrame.new(sink + Vector3.new(0, 45, 0)), Material = Enum.Material.Wood, Color = Color3.fromRGB(150, 110, 70) })
		api.part({ Name = "Counter", Size = Vector3.new(170, 6, 56), CFrame = CFrame.new(sink + Vector3.new(0, 93, 0)), Material = Enum.Material.Marble, Color = Color3.fromRGB(235, 235, 240) })
		api.part({ Name = "Mirror", Size = Vector3.new(130, 90, 2), CFrame = CFrame.new(sink + Vector3.new(0, 160, -24)), Material = Enum.Material.Glass, Color = Color3.fromRGB(200, 220, 230), Reflectance = 0.6 })
	end,
}
