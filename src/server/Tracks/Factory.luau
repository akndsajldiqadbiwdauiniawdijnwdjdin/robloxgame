-- Crusher Factory: a steel paperclip through a giant factory hall. Conveyor-belt boost
-- pads, crushers that slam the road (time them!), a high catwalk, the glowing furnace
-- tunnel and a jump over the scrap heap. Shortcuts across both hairpins.
local TweenService = game:GetService("TweenService")

return {
	Name = "Crusher Factory",
	Laps = 3,
	Seed = 55,
	Width = 32,
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
		Ambient = Color3.fromRGB(115, 110, 105),
		OutdoorAmbient = Color3.fromRGB(130, 125, 120),
		FogEnd = 1500,
		FogColor = Color3.fromRGB(120, 115, 105),
		ExposureCompensation = 0.1,
	},
	Atmosphere = { Density = 0.4, Haze = 2.5, Color = Color3.fromRGB(170, 160, 140), Decay = Color3.fromRGB(110, 100, 90) },

	Points = {
		Vector3.new(-220, 1, 150), -- 1 start / finish
		Vector3.new(140, 1, 150),
		Vector3.new(230, 1, 90), -- 3 east hairpin (grating shortcut)
		Vector3.new(150, 1, 30),
		Vector3.new(-60, 1, 30), -- 5 crusher alley ends here
		Vector3.new(-135, 1, -25), -- 6 catwalk hairpin (cut across)
		Vector3.new(-60, 8, -80),
		Vector3.new(170, 18, -80), -- 8 high catwalk
		Vector3.new(250, 12, -150),
		Vector3.new(170, 4, -215), -- 10 furnace tunnel, then the scrap jump
		Vector3.new(-120, 1, -215),
		Vector3.new(-200, 1, -150),
		Vector3.new(-260, 1, -60),
		Vector3.new(-300, 1, 60),
	},

	Sections = {
		{ From = 4.2, To = 4.8, Surface = "Road", Color = Color3.fromRGB(40, 40, 45) }, -- crusher zone
	},
	Shortcuts = {
		{ Width = 14, Surface = "Road", Color = Color3.fromRGB(80, 80, 88), Points = { Vector3.new(-72, 1, 22), Vector3.new(-80, 2, -25), Vector3.new(-72, 6, -72) } },
		{ Width = 14, Surface = "Offroad", Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 60, 66), Points = { Vector3.new(150, 1, 138), Vector3.new(165, 1, 90), Vector3.new(150, 1, 42) } },
	},

	BoostPads = { -- conveyor belts
		{ At = 1.5, Offset = 0, Width = 20 },
		{ At = 4.9, Offset = 0, Width = 20 },
		{ At = 7.5, Offset = 0, Width = 20 },
		{ At = 10.45, Offset = 0, Width = 20 },
		{ At = 13.5, Offset = 0, Width = 20 },
	},
	Ramps = {
		{ At = 10.6, Offset = 0, Width = 22, Length = 18, Angle = 13, Color = Color3.fromRGB(240, 190, 0) },
	},
	PickupRows = { 2.6, 6.6, 9.9, 13.0 },

	Decor = function(api)
		local P = api.Props
		local random = api.Random
		local yellow = Color3.fromRGB(240, 190, 0)
		local steel = Color3.fromRGB(95, 98, 105)

		-- Grandstand first so the scenery placed afterwards keeps clear of it.
		api.grandstand(1.5, 1, 60, yellow)

		-- Hydraulic crushers over crusher alley, each on its own rhythm.
		for i, u in { 4.3, 4.5, 4.7 } do
			local sample = api.sampleAt(u)
			local cf = CFrame.lookAt(sample.Position, sample.Position + sample.Forward)
			for _, side in { -1, 1 } do
				api.part({ Name = "CrusherFrame", Size = Vector3.new(3, 30, 3), CFrame = cf * CFrame.new(side * (api.Edge + 2), 15, 0), Material = Enum.Material.DiamondPlate, Color = yellow })
			end
			api.part({ Name = "CrusherBeam", Size = Vector3.new(api.Edge * 2 + 7, 3, 4), CFrame = cf * CFrame.new(0, 31, 0), Material = Enum.Material.DiamondPlate, Color = yellow })
			local block = api.part({ Name = "Crusher", Size = Vector3.new(api.Width * 0.5, 10, 10), CFrame = cf * CFrame.new((i - 2) * 8, 22, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 40, 40) })
			for k = -1, 1, 2 do
				api.part({ Name = "Hazard", Size = Vector3.new(api.Width, 0.12, 1.5), CFrame = cf * CFrame.new(0, 0.08, k * 6), Material = Enum.Material.SmoothPlastic, Color = yellow, CanCollide = false, CanQuery = false })
			end
			TweenService:Create(block, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, -1, true, 1.2 + i * 0.4), { CFrame = cf * CFrame.new((i - 2) * 8, 5.5, 0) }):Play()
		end

		-- Furnace tunnel (glowing orange) and the scrap heap next to the jump.
		api.tunnel(9.3, 10.25, { Height = 18, Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 50, 45), LightColor = Color3.fromRGB(255, 120, 30) })
		local furnace = api.sampleAt(9.8)
		local glow = api.part({ Name = "FurnaceGlow", Size = Vector3.new(6, 6, 6), CFrame = CFrame.new(furnace.Position + furnace.Right * (api.Edge + 10) + Vector3.new(0, 4, 0)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 110, 20) })
		local fire = Instance.new("Fire")
		fire.Size = 12
		fire.Parent = glow
		local pit = api.sampleAt(10.75)
		api.part({ Name = "ScrapPile", Shape = Enum.PartType.Ball, Size = Vector3.one * 40, CFrame = CFrame.new(pit.Position + pit.Right * (api.Edge + 24) + Vector3.new(0, -8, 0)), Material = Enum.Material.CorrodedMetal, Color = Color3.fromRGB(120, 80, 60) })
		api.arch(1.7, "CRUSHER FACTORY", Color3.fromRGB(40, 40, 45))
		api.arch(4.15, "⚠ CRUSHERS ⚠", yellow)

		-- Factory hall walls with windows, roof girders and lights.
		local half = api.Extent + 120
		local hallHeight = 90
		for _, side in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			local along = Vector3.new(math.abs(side.Z), 0, math.abs(side.X))
			local wallCenter = api.Center + side * half + Vector3.new(0, hallHeight / 2, 0)
			api.part({ Name = "HallWall", Size = along * (half * 2) + Vector3.new(4, hallHeight, 4), CFrame = CFrame.new(wallCenter), Material = Enum.Material.Metal, Color = Color3.fromRGB(120, 115, 105) })
			api.part({ Name = "HallWindows", Size = along * (half * 2 - 20) + Vector3.new(5, 14, 5), CFrame = CFrame.new(wallCenter + Vector3.new(0, 25, 0)), Material = Enum.Material.Glass, Color = Color3.fromRGB(190, 210, 220), Transparency = 0.3 })
			api.part({ Name = "HazardStripe", Size = along * (half * 2) + Vector3.new(5, 3, 5), CFrame = CFrame.new(wallCenter - Vector3.new(0, hallHeight / 2 - 6, 0)), Material = Enum.Material.SmoothPlastic, Color = yellow })
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

		-- Smokestacks, vats of glowing goo, crate stacks, robot arms and pipes.
		for _ = 1, 40 do
			local spot = api.Center + Vector3.new(random:NextInteger(-half + 20, half - 20), 0, random:NextInteger(-half + 20, half - 20))
			local kind = random:NextInteger(1, 4)
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
			elseif kind == 4 and api.isClear(spot, 6) then
				local arm = Color3.fromRGB(255, 120, 0)
				api.part({ Name = "RobotBase", Size = Vector3.new(6, 4, 6), CFrame = CFrame.new(spot + Vector3.new(0, 2, 0)), Material = Enum.Material.Metal, Color = steel })
				api.part({ Name = "RobotArm", Size = Vector3.new(2.5, 16, 2.5), CFrame = CFrame.new(spot + Vector3.new(0, 4, 0)) * CFrame.Angles(0, random:NextNumber() * 6, math.rad(30)) * CFrame.new(0, 8, 0), Material = Enum.Material.SmoothPlastic, Color = arm })
			end
		end
		for _, z in { -40, 90 } do
			api.part({ Name = "Pipe", Shape = Enum.PartType.Cylinder, Size = Vector3.new(half * 2, 5, 5), CFrame = CFrame.new(api.Center + Vector3.new(0, 45, z)), Material = Enum.Material.Metal, Color = Color3.fromRGB(70, 120, 160) })
		end
		P.ring(api.Center, half + 60, 16, function(position)
			api.part({ Name = "OutsideTank", Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, 40, 40), CFrame = CFrame.new(position + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = Color3.fromRGB(150, 150, 155) })
		end)
	end,
}
