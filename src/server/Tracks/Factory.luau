-- Crusher Factory: a steel paperclip through a giant factory hall. Conveyor-belt boost
-- pads, a high catwalk, a jump over the scrap pit, and hydraulic crushers that slam
-- down onto the road. Time them right!
local TweenService = game:GetService("TweenService")

return {
	Name = "Crusher Factory",
	Laps = 3,
	Seed = 55,
	Width = 36,
	Surface = "Road",
	Curbs = false,
	RoadMaterial = Enum.Material.DiamondPlate,
	RoadColor = Color3.fromRGB(105, 108, 115),
	BannerColor = Color3.fromRGB(255, 190, 0),
	Ground = { Material = Enum.Material.Concrete, Color = Color3.fromRGB(80, 80, 85), Surface = "Offroad" },
	Border = { Width = 8, Surface = "Offroad", Material = Enum.Material.Metal, Color = Color3.fromRGB(55, 55, 60) },
	Barrier = { Height = 5, Material = Enum.Material.Metal, Color = Color3.fromRGB(240, 190, 0) },
	Support = "Pillars",
	PillarMaterial = Enum.Material.DiamondPlate,
	PillarColor = Color3.fromRGB(70, 70, 80),
	Lighting = {
		ClockTime = 15,
		Brightness = 2,
		Ambient = Color3.fromRGB(110, 105, 100),
		OutdoorAmbient = Color3.fromRGB(125, 120, 115),
		FogEnd = 1500,
		FogColor = Color3.fromRGB(120, 115, 105),
		ExposureCompensation = 0,
	},
	Atmosphere = { Density = 0.4, Haze = 2.5, Color = Color3.fromRGB(170, 160, 140), Decay = Color3.fromRGB(110, 100, 90) },

	Points = {
		Vector3.new(-180, 1, 140), -- 1 start / finish
		Vector3.new(150, 1, 140),
		Vector3.new(210, 1, 80),
		Vector3.new(150, 1, 30),
		Vector3.new(-100, 1, 30), -- 5 crusher alley
		Vector3.new(-160, 1, -30),
		Vector3.new(-100, 8, -90),
		Vector3.new(150, 18, -90), -- 8 high catwalk
		Vector3.new(220, 12, -150),
		Vector3.new(150, 4, -205),
		Vector3.new(-200, 1, -205), -- 11 scrap-pit jump
		Vector3.new(-265, 1, -110),
		Vector3.new(-265, 1, 60),
	},

	Sections = {
		{ From = 4.2, To = 4.8, Surface = "Road", Color = Color3.fromRGB(40, 40, 45) }, -- crusher zone
	},

	BoostPads = { -- conveyor belts
		{ At = 1.5, Offset = 0, Width = 20 },
		{ At = 4.85, Offset = 0, Width = 20 },
		{ At = 7.5, Offset = 0, Width = 20 },
		{ At = 10.4, Offset = 0, Width = 20 },
		{ At = 12.5, Offset = 0, Width = 20 },
	},
	Ramps = {
		{ At = 10.6, Offset = 0, Width = 24, Length = 18, Angle = 13, Color = Color3.fromRGB(240, 190, 0) },
	},
	PickupRows = { 2.4, 6.3, 9.3, 12.0 },

	Decor = function(api)
		local folder = api.Folder
		local random = api.Random
		local yellow = Color3.fromRGB(240, 190, 0)
		local steel = Color3.fromRGB(95, 98, 105)

		-- Hydraulic crushers over the crusher alley, each on its own rhythm.
		for i, u in { 4.3, 4.5, 4.7 } do
			local sample = api.sampleAt(u)
			local cf = CFrame.lookAt(sample.Position, sample.Position + sample.Forward)
			for _, side in { -1, 1 } do
				api.part({ Name = "CrusherFrame", Size = Vector3.new(3, 30, 3), CFrame = cf * CFrame.new(side * (api.Width / 2 + 3), 15, 0), Material = Enum.Material.DiamondPlate, Color = yellow })
			end
			api.part({ Name = "CrusherBeam", Size = Vector3.new(api.Width + 9, 3, 4), CFrame = cf * CFrame.new(0, 31, 0), Material = Enum.Material.DiamondPlate, Color = yellow })
			local block = api.part({ Name = "Crusher", Size = Vector3.new(api.Width * 0.5, 10, 10), CFrame = cf * CFrame.new((i - 2) * 9, 22, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 40, 40) })
			for k = -1, 1, 2 do -- hazard stripes on the road below
				api.part({ Name = "Hazard", Size = Vector3.new(api.Width, 0.12, 1.5), CFrame = cf * CFrame.new(0, 0.07, k * 6), Material = Enum.Material.SmoothPlastic, Color = yellow, CanCollide = false, CanQuery = false })
			end
			local down = TweenService:Create(block, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, true, 1.2 + i * 0.4), { CFrame = cf * CFrame.new((i - 2) * 9, 5.5, 0) })
			down:Play()
		end

		-- Factory hall walls with windows, roof girders and lights.
		local half = api.Extent + 120
		local hallHeight = 90
		for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			local along = Vector3.new(math.abs(side.Z), 0, math.abs(side.X))
			local wallCenter = api.Center + side * half + Vector3.new(0, hallHeight / 2, 0)
			api.part({ Name = "HallWall", Size = along * (half * 2) + Vector3.new(4, hallHeight, 4), CFrame = CFrame.new(wallCenter), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 115, 105) })
			api.part({ Name = "HallWindows", Size = along * (half * 2 - 20) + Vector3.new(5, 14, 5), CFrame = CFrame.new(wallCenter + Vector3.new(0, 25, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(190, 210, 220), Transparency = 0.3 })
		end
		for offset = -half, half, 60 do
			api.part({ Name = "Girder", Size = Vector3.new(half * 2, 4, 3), CFrame = CFrame.new(api.Center + Vector3.new(0, hallHeight - 2, offset)), Material = Enum.Material.DiamondPlate, Color = steel })
			local lamp = api.part({ Name = "HangingLamp", Size = Vector3.new(8, 1, 8), CFrame = CFrame.new(api.Center + Vector3.new(offset * 0.7, hallHeight - 12, offset)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 240, 210) })
			local light = Instance.new("SpotLight")
			light.Face = Enum.NormalId.Bottom
			light.Range = 60
			light.Angle = 90
			light.Brightness = 2
			light.Parent = lamp
		end

		-- Smokestacks, vats of glowing goo, crate stacks and pipes.
		for _ = 1, 30 do
			local spot = api.Center + Vector3.new(random:NextInteger(-half + 20, half - 20), 0, random:NextInteger(-half + 20, half - 20))
			local kind = random:NextInteger(1, 3)
			if kind == 1 and api.isClear(spot, 12) then
				api.part({ Name = "Vat", Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 22, 22), CFrame = CFrame.new(spot + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = steel })
				api.part({ Name = "Goo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 19, 19), CFrame = CFrame.new(spot + Vector3.new(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = Color3.fromRGB(80, 255, 60) })
			elseif kind == 2 and api.isClear(spot, 8) then
				for level = 0, random:NextInteger(1, 3) do
					api.part({ Name = "Crate", Size = Vector3.new(8, 8, 8), CFrame = CFrame.new(spot + Vector3.new(0, 4 + level * 8, 0)) * CFrame.Angles(0, random:NextNumber(), 0), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(165, 120, 70) })
				end
			elseif kind == 3 and api.isClear(spot, 8) then
				api.part({ Name = "Smokestack", Shape = Enum.PartType.Cylinder, Size = Vector3.new(80, 10, 10), CFrame = CFrame.new(spot + Vector3.new(0, 40, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Brick, Color = Color3.fromRGB(140, 70, 55) })
				local smoke = Instance.new("Smoke")
				smoke.RiseVelocity = 8
				smoke.Size = 12
				smoke.Color = Color3.fromRGB(90, 90, 90)
				smoke.Parent = api.part({ Name = "SmokeTop", Size = Vector3.new(6, 1, 6), CFrame = CFrame.new(spot + Vector3.new(0, 80.5, 0)), Transparency = 1, CanCollide = false })
			end
		end
		for _, z in { -60, 90 } do
			api.part({ Name = "Pipe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(half * 2, 5, 5), CFrame = CFrame.new(api.Center + Vector3.new(0, 45, z)), Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 120, 160) })
		end

		-- Scrap pit beside the jump.
		local pit = api.sampleAt(10.75)
		api.part({ Name = "ScrapPile", Shape = Enum.PartType.Ball, Size = Vector3.new(40, 40, 40), CFrame = CFrame.new(pit.Position + pit.Right * (api.Edge + 22) + Vector3.new(0, -8, 0)), Material = Enum.Material.CorrodedMetal, Color = Color3.fromRGB(120, 80, 60) })
	end,
}
