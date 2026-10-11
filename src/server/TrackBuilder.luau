-- Builds a track from a definition in server/Tracks. The road follows a smooth closed
-- curve through the definition's control Points (each Vector3's Y is the road height).
--
-- Track positions are written as "control point index + fraction": 4.5 means halfway
-- between control point 4 and 5. Sections, gaps, pads, ramps etc. all use that.
--
-- Layout, Mario Kart style:  | barrier | border (offroad) | curb | ROAD | curb | border | barrier |
-- Barriers get an opening wherever a shortcut leaves the road.
--
-- Surfaces (Surface attribute, read by the driving script):
--   Road    - full speed           Dirt - nearly full speed, slidier
--   Offroad - slowed unless your Traction is high (grass, sand, carpet...)
--   Mud     - very slow unless your Traction is high
--   Ice     - full speed, almost no grip (soap, polished floors)
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Props = require(script.Parent.Props)

local TrackBuilder = {}

local SURFACE_LOOKS = {
	Road = { Material = Enum.Material.Asphalt, Color = Color3.fromRGB(45, 45, 50) },
	Dirt = { Material = Enum.Material.Ground, Color = Color3.fromRGB(150, 105, 65) },
	Offroad = { Material = Enum.Material.Grass, Color = Color3.fromRGB(80, 140, 60) },
	Mud = { Material = Enum.Material.Mud, Color = Color3.fromRGB(85, 60, 40) },
	Ice = { Material = Enum.Material.Ice, Color = Color3.fromRGB(200, 235, 255) },
}
local CURB_RED = Color3.fromRGB(210, 35, 35)
local INVISIBLE_WALL_HEIGHT = 70
local CURB_WHITE = Color3.fromRGB(240, 240, 240)

local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2, t3 = t * t, t * t * t
	return 0.5 * ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
end

local function inRange(u: number, range): boolean
	if range.From <= range.To then
		return u >= range.From and u <= range.To
	end
	return u >= range.From or u <= range.To -- wraps past the start line
end

local function inAnyRange(u: number, ranges): boolean
	for _, range in ranges or {} do
		if inRange(u, range) then
			return true
		end
	end
	return false
end

local function angleBetween(u: Vector3, v: Vector3): number
	if u.Magnitude < 1e-3 or v.Magnitude < 1e-3 then
		return 0
	end
	return math.acos(math.clamp(u.Unit:Dot(v.Unit), -1, 1))
end

local function rightOf(forward: Vector3): Vector3
	local flat = Vector3.new(forward.X, 0, forward.Z)
	if flat.Magnitude < 1e-3 then
		return Vector3.xAxis
	end
	flat = flat.Unit
	return Vector3.new(-flat.Z, 0, flat.X)
end

local function flatDistance(a: Vector3, b: Vector3): number
	local d = a - b
	return Vector3.new(d.X, 0, d.Z).Magnitude
end

local function sampleCurve(points, closed: boolean, spacing: number, minY: number)
	local samples = {}
	local n = #points
	local function get(i)
		if closed then
			return points[(i - 1) % n + 1]
		end
		return points[math.clamp(i, 1, n)]
	end
	local last = if closed then n else n - 1
	for i = 1, last do
		local p0, p1, p2, p3 = get(i - 1), get(i), get(i + 1), get(i + 2)
		local steps = math.max(2, math.ceil((p2 - p1).Magnitude / spacing))
		for s = 0, steps - 1 do
			local t = s / steps
			local position = catmullRom(p0, p1, p2, p3, t)
			position = Vector3.new(position.X, math.max(position.Y, minY), position.Z)
			table.insert(samples, { Position = position, U = i + t })
		end
	end
	if not closed then
		table.insert(samples, { Position = points[n], U = n })
	end
	local count = #samples
	for i, sample in samples do
		local nextSample = samples[if closed then i % count + 1 else math.min(i + 1, count)]
		local previous = samples[if closed then (i - 2) % count + 1 else math.max(i - 1, 1)]
		local forward = nextSample.Position - sample.Position
		if forward.Magnitude < 1e-3 then
			forward = sample.Position - previous.Position
		end
		sample.Forward = forward.Unit
		sample.Right = rightOf(sample.Forward)
	end
	return samples
end

local newPart = Props.part
local addSign = Props.sign
TrackBuilder.addSign = addSign

local function applyLighting(def)
	for key, value in def.Lighting or {} do
		Lighting[key] = value
	end
	for _, className in { "Atmosphere", "Sky" } do
		local old = Lighting:FindFirstChildOfClass(className)
		if old then
			old:Destroy()
		end
		local props = def[className]
		if props then
			local instance = Instance.new(className)
			for key, value in props do
				instance[key] = value
			end
			instance.Parent = Lighting
		end
	end
end

-- Builds road segments (plus curbs, borders, barriers and supports) along `samples`.
local function buildStrip(folder, samples, closed, opts)
	local count = #samples
	local width = opts.Width
	local border = opts.Border
	local borderWidth = if border then border.Width else 0
	local curbWidth = if opts.Curbs then 2 else 0
	local lastIndex = if closed then count else count - 1

	for i = 1, lastIndex do
		local a = samples[i]
		local b = samples[i % count + 1]
		if not (opts.IsGap and opts.IsGap(a.U)) then
			-- A section can override the surface and its look (e.g. a soap patch, a dirt zone).
			local section = if opts.SectionAt then opts.SectionAt(a.U) else nil
			local surface = if section then section.Surface else opts.Surface
			local look = SURFACE_LOOKS[surface] or SURFACE_LOOKS.Road
			local segment = b.Position - a.Position
			local length = segment.Magnitude

			-- Extend each piece just enough to cover the outside of the bend.
			local after = samples[(i + 1) % count + 1]
			local before = samples[(i - 2) % count + 1]
			local turn = math.max(angleBetween(a.Forward, after.Position - b.Position), angleBetween(a.Position - before.Position, a.Forward))
			local fullWidth = width + 2 * (curbWidth + borderWidth)
			local extra = fullWidth * math.tan(math.min(turn, math.rad(60)) / 2) + 0.4

			-- Neighbouring pieces overlap a little; alternating heights by a hair stops the
			-- overlapping faces from flickering (z-fighting).
			local lift = if i % 2 == 0 then 0.03 else 0
			local cf = CFrame.lookAt((a.Position + b.Position) / 2, b.Position) * CFrame.new(0, -0.5 + lift, 0)
			local useRoadLook = surface == "Road" and opts.RoadMaterial
			newPart(folder, {
				Name = "Road",
				Size = Vector3.new(width, 1, length + extra),
				CFrame = cf,
				Material = (section and section.Material) or (if useRoadLook then opts.RoadMaterial else look.Material),
				Color = (section and section.Color) or (if surface == "Road" and opts.RoadColor then opts.RoadColor else look.Color),
				Attributes = { Surface = surface },
			})

			for _, side in { -1, 1 } do
				if opts.Curbs then
					newPart(folder, {
						Name = "Curb",
						-- Flush with the road (a raised lip snags cars).
						Size = Vector3.new(curbWidth, 1, length + extra * 0.5),
						CFrame = cf * CFrame.new(side * (width / 2 + curbWidth / 2), 0.01, 0),
						Material = Enum.Material.SmoothPlastic,
						Color = if i % 2 == 0 then CURB_RED else CURB_WHITE,
						Attributes = { Surface = "Road" },
					})
				end
				if border then
					newPart(folder, {
						Name = "Border",
						Size = Vector3.new(borderWidth, 1, length + extra),
						CFrame = cf * CFrame.new(side * (width / 2 + curbWidth + borderWidth / 2), 0, 0),
						Material = border.Material or SURFACE_LOOKS[border.Surface or "Offroad"].Material,
						Color = border.Color or SURFACE_LOOKS[border.Surface or "Offroad"].Color,
						Attributes = { Surface = border.Surface or "Offroad" },
					})
				end
				local barrier = opts.Barrier
				if barrier and not inAnyRange(a.U, barrier.Except) then
					local offset = width / 2 + curbWidth + borderWidth + 1
					local wallCf = cf * CFrame.new(side * offset, barrier.Height / 2 + 0.5, 0)
					if not (opts.IsOpening and opts.IsOpening(wallCf.Position, i)) then
						-- Invisible wall on top so nobody flies off the track.
						newPart(folder, {
							Name = "InvisibleWall",
							Size = Vector3.new(1.5, INVISIBLE_WALL_HEIGHT, length + extra * 0.5),
							CFrame = wallCf * CFrame.new(0, barrier.Height / 2 + INVISIBLE_WALL_HEIGHT / 2, 0),
							Transparency = 1,
							CanQuery = false,
							CanTouch = false,
						})
						newPart(folder, {
							Name = "Barrier",
							Size = Vector3.new(1.5 + lift, barrier.Height, length + extra * 0.5),
							CFrame = wallCf,
							Material = barrier.Material,
							Color = barrier.Color,
						})
						if barrier.Neon then
							newPart(folder, {
								Name = "BarrierTrim",
								Size = Vector3.new(1.7 + lift, 0.4, length + extra * 0.5),
								CFrame = wallCf * CFrame.new(0, barrier.Height / 2 + 0.2, 0),
								Material = Enum.Material.Neon,
								Color = barrier.Neon,
								CanCollide = false,
							})
						end
					end
				end
			end

			-- Hold up raised road: solid fill (canyon) or pillars (highway).
			local low = math.min(a.Position.Y, b.Position.Y) - 1 - opts.GroundY
			if opts.Support and low > 3 then
				local flatDir = Vector3.new(segment.X, 0, segment.Z)
				if opts.Support == "Fill" and flatDir.Magnitude > 0.1 then
					local mid = (a.Position + b.Position) / 2
					local center = Vector3.new(mid.X, opts.GroundY + (low - lift) / 2, mid.Z)
					newPart(folder, {
						Name = "Fill",
						Size = Vector3.new(fullWidth + 6 + lift * 4, low - lift, length + extra),
						CFrame = CFrame.lookAt(center, center + flatDir),
						Material = opts.FillMaterial or Enum.Material.Sandstone,
						Color = opts.FillColor or Color3.fromRGB(190, 120, 70),
						Attributes = { Surface = "Offroad" },
					})
				elseif opts.Support == "Pillars" and i % 5 == 0 then
					newPart(folder, {
						Name = "Pillar",
						Size = Vector3.new(5, low, 5),
						CFrame = CFrame.new(a.Position.X, opts.GroundY + low / 2, a.Position.Z),
						Material = opts.PillarMaterial or Enum.Material.Concrete,
						Color = opts.PillarColor or Color3.fromRGB(110, 110, 120),
					})
				end
			end
		end
	end
end

function TrackBuilder.build(def)
	local existing = workspace:FindFirstChild("Track")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Track"
	folder.Parent = workspace

	applyLighting(def)

	local width = def.Width or Config.Track.DefaultWidth
	local spacing = Config.Track.SampleSpacing
	local ground = def.Ground or {}
	local groundY = ground.Y or 0
	-- Flat by default: every road sits flush with the ground (a step between grass and
	-- road stops cars getting back on). def.RoadY raises it (e.g. over water);
	-- def.Flat = false keeps each point's own height.
	local roadY = def.RoadY or (groundY + 0.05)
	local function flatten(points)
		if def.Flat == false then
			return points
		end
		local flat = {}
		for index, point in points do
			flat[index] = Vector3.new(point.X, roadY, point.Z)
		end
		return flat
	end
	local samples = sampleCurve(flatten(def.Points), true, spacing, if def.Flat == false then groundY + 1 else roadY)
	local count = #samples

	local function sectionAt(u: number)
		for _, section in def.Sections or {} do
			if inRange(u, section) then
				return section
			end
		end
		return nil
	end
	local function sampleIndexAt(u: number): number
		local best, bestDiff = 1, math.huge
		for i, sample in samples do
			local diff = math.abs(sample.U - u)
			if diff < bestDiff then
				best, bestDiff = i, diff
			end
		end
		return best
	end

	-- Shortcuts are sampled first so the main barrier can leave openings for them.
	local shortcutPaths = {}
	for _, shortcut in def.Shortcuts or {} do
		local path = sampleCurve(flatten(shortcut.Points), false, spacing, if def.Flat == false then groundY + 1 else roadY)
		table.insert(shortcutPaths, { Samples = path, Width = shortcut.Width, Def = shortcut })
	end
	local crossClear = width / 2 + (if def.Curbs ~= false then 2 else 0) + (if def.Border then def.Border.Width else 0) + 3
	-- No barrier where a shortcut leaves the road, or where the track crosses itself.
	local function isOpening(position: Vector3, index: number?): boolean
		if index then
			for other, sample in samples do
				local apart = math.abs(other - index)
				apart = math.min(apart, count - apart)
				if apart > 12 and flatDistance(position, sample.Position) < crossClear and math.abs(position.Y - sample.Position.Y) < 8 then
					return true
				end
			end
		end
		for _, shortcut in shortcutPaths do
			for _, sample in shortcut.Samples do
				if flatDistance(position, sample.Position) < shortcut.Width / 2 + 8 and math.abs(position.Y - sample.Position.Y) < 10 then
					return true
				end
			end
		end
		return false
	end

	buildStrip(folder, samples, true, {
		Width = width,
		Surface = def.Surface or "Road",
		SectionAt = sectionAt,
		IsGap = function(u)
			return inAnyRange(u, def.Gaps)
		end,
		IsOpening = isOpening,
		RoadMaterial = def.RoadMaterial,
		RoadColor = def.RoadColor,
		Curbs = def.Curbs ~= false,
		Border = def.Border,
		Barrier = def.Barrier,
		Support = def.Support,
		FillMaterial = def.FillMaterial,
		FillColor = def.FillColor,
		PillarColor = def.PillarColor,
		PillarMaterial = def.PillarMaterial,
		GroundY = groundY,
	})
	for _, shortcut in shortcutPaths do
		buildStrip(folder, shortcut.Samples, false, {
			Width = shortcut.Width,
			Surface = shortcut.Def.Surface,
			SectionAt = function()
				return shortcut.Def -- lets a shortcut set its own Material / Color
			end,
			RoadMaterial = def.RoadMaterial,
			RoadColor = def.RoadColor,
			Curbs = false,
			Barrier = shortcut.Def.Barrier,
			Support = def.Support,
			FillMaterial = def.FillMaterial,
			FillColor = def.FillColor,
			PillarColor = def.PillarColor,
			GroundY = groundY,
		})
	end

	-- Ground (tiled: a single part can't be bigger than 2048 studs).
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, sample in samples do
		minX, maxX = math.min(minX, sample.Position.X), math.max(maxX, sample.Position.X)
		minZ, maxZ = math.min(minZ, sample.Position.Z), math.max(maxZ, sample.Position.Z)
	end
	local margin = ground.Margin or 300
	local tile = 800
	for x = minX - margin, maxX + margin, tile do
		for z = minZ - margin, maxZ + margin, tile do
			newPart(folder, {
				Name = "Ground",
				Size = Vector3.new(tile, 2, tile),
				CFrame = CFrame.new(x + tile / 2, groundY - 1, z + tile / 2),
				Material = ground.Material or Enum.Material.Grass,
				Color = ground.Color or Color3.fromRGB(80, 140, 60),
				Attributes = { Surface = ground.Surface or "Offroad" },
			})
			if def.Water then
				newPart(folder, {
					Name = "Water",
					Size = Vector3.new(tile, 0.4, tile),
					CFrame = CFrame.new(x + tile / 2, def.Water.Level, z + tile / 2),
					Material = Enum.Material.Glass,
					Color = def.Water.Color or Color3.fromRGB(30, 120, 190),
					Transparency = def.Water.Transparency or 0.25,
					CanCollide = false,
					CanQuery = false,
				})
			end
		end
	end

	-- Start/finish gate at sample 1.
	local start = samples[1]
	local startCf = CFrame.lookAt(start.Position, start.Position + start.Forward)
	newPart(folder, {
		Name = "StartLine",
		Size = Vector3.new(width, 0.1, 4),
		CFrame = startCf * CFrame.new(0, 0.08, 0),
		Material = Enum.Material.Neon,
		Color = CURB_WHITE,
		CanCollide = false,
		CanQuery = false,
	})
	local gateHalf = width / 2 + (if def.Curbs ~= false then 2 else 0) + (if def.Border then def.Border.Width else 0) + 4
	for _, side in { -1, 1 } do
		newPart(folder, {
			Name = "GatePillar",
			Size = Vector3.new(3, 22, 3),
			CFrame = startCf * CFrame.new(side * gateHalf, 11, 0),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(30, 30, 30),
		})
	end
	local banner = newPart(folder, {
		Name = "GateBanner",
		Size = Vector3.new(gateHalf * 2 + 3, 6, 2),
		CFrame = startCf * CFrame.new(0, 23, 0),
		Material = Enum.Material.Neon,
		Color = def.BannerColor or Color3.fromRGB(255, 80, 0),
	})
	addSign(banner, string.upper(def.Name))

	local function sampleCFrame(index: number): CFrame
		local sample = samples[index]
		return CFrame.lookAt(sample.Position, sample.Position + sample.Forward)
	end

	-- Boost pads (dash panels).
	for _, pad in def.BoostPads or {} do
		local cf = sampleCFrame(sampleIndexAt(pad.At)) * CFrame.new(pad.Offset or 0, 0.08, 0)
		local panel = newPart(folder, {
			Name = "BoostPad",
			Size = Vector3.new(pad.Width or 12, 0.12, 10),
			CFrame = cf,
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(255, 200, 0),
			CanCollide = false,
			Attributes = { BoostPad = true, Surface = "Road" },
		})
		for k = -1, 1 do
			newPart(folder, {
				Name = "Chevron",
				Size = Vector3.new((pad.Width or 12) * 0.6, 0.14, 1),
				CFrame = panel.CFrame * CFrame.new(0, 0.03, k * 3),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 90, 0),
				CanCollide = false,
				CanQuery = false,
			})
		end
	end

	-- Jump ramps: wedges whose low edge sits flush on the road, so nothing to snag on.
	for _, ramp in def.Ramps or {} do
		local angle = math.rad(ramp.Angle or 12)
		local length = ramp.Length or 24
		local height = length * math.tan(angle)
		newPart(folder, {
			ClassName = "WedgePart",
			Name = "Ramp",
			Size = Vector3.new(ramp.Width or width * 0.4, height, length),
			-- Wedges slope down toward their front; turn it around so it rises ahead of you.
			CFrame = sampleCFrame(sampleIndexAt(ramp.At)) * CFrame.new(ramp.Offset or 0, height / 2, 0) * CFrame.Angles(0, math.pi, 0),
			Material = ramp.Material or Enum.Material.DiamondPlate,
			Color = ramp.Color or Color3.fromRGB(255, 200, 0),
			Attributes = { Surface = "Road" },
		})
	end

	-- Power-up box rows.
	local pickups = {}
	for _, u in def.PickupRows or {} do
		local sample = samples[sampleIndexAt(u)]
		for _, offset in { -width * 0.3, 0, width * 0.3 } do
			local position = sample.Position + sample.Right * offset + Vector3.new(0, 3, 0)
			local box = newPart(folder, {
				Name = "PowerUpBox",
				Size = Vector3.new(4, 4, 4),
				CFrame = CFrame.new(position) * CFrame.Angles(math.rad(45), math.rad(45), 0),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 170, 0),
				Transparency = 0.15,
				CanCollide = false,
				CanQuery = false,
			})
			table.insert(pickups, { Part = box, Position = position, ReadyAt = 0 })
		end
	end

	-- Scenery API for the track's Decor function.
	local edge = width / 2 + (if def.Curbs ~= false then 2 else 0) + (if def.Border then def.Border.Width else 0) + 3
	local clearPaths = { { Samples = samples, Half = edge } }
	for _, shortcut in shortcutPaths do
		table.insert(clearPaths, { Samples = shortcut.Samples, Half = shortcut.Width / 2 + 3 })
	end
	local random = Random.new(def.Seed or 1)
	local api = {
		Folder = folder,
		Samples = samples,
		Width = width,
		Edge = edge, -- distance from the centre line to the outside of the barrier
		GroundY = groundY,
		Random = random,
		Props = Props,
		Center = Vector3.new((minX + maxX) / 2, groundY, (minZ + maxZ) / 2),
		Extent = math.max(maxX - minX, maxZ - minZ) / 2,
	}
	function api.part(props)
		return newPart(folder, props)
	end
	api.sign = addSign
	-- Areas taken by set pieces (grandstands...), so scenery doesn't get placed on them.
	local reserved = {}
	function api.reserve(position: Vector3, radius: number)
		table.insert(reserved, { Position = position, Radius = radius })
	end
	-- True if nothing on any road/shortcut/set piece is within `radius` of `position`.
	function api.isClear(position: Vector3, radius: number): boolean
		for _, area in reserved do
			if flatDistance(area.Position, position) < radius + area.Radius then
				return false
			end
		end
		for _, path in clearPaths do
			for _, sample in path.Samples do
				if flatDistance(sample.Position, position) < radius + path.Half then
					return false
				end
			end
		end
		return true
	end
	-- Calls fn(position, sample, side) every `step` samples on both sides, `offset` studs
	-- beyond the barrier. position.Y is ground level.
	function api.alongTrack(step: number, offset: number, fn)
		for i = 1, count, step do
			local sample = samples[i]
			for _, side in { -1, 1 } do
				local position = sample.Position + sample.Right * side * (edge + offset)
				fn(Vector3.new(position.X, groundY, position.Z), sample, side)
			end
		end
	end
	function api.sampleAt(u: number)
		return samples[sampleIndexAt(u)]
	end
	local function samplesBetween(fromU: number, toU: number)
		local list = {}
		for _, sample in samples do
			if inRange(sample.U, { From = fromU, To = toU }) then
				table.insert(list, sample)
			end
		end
		return list
	end

	-- A roofed tunnel over the road. style "Box" (walls + roof) or "Rings" (neon hoops).
	function api.tunnel(fromU: number, toU: number, opts)
		opts = opts or {}
		local height = opts.Height or 16
		local half = edge + 1
		for index, sample in samplesBetween(fromU, toU) do
			local cf = CFrame.lookAt(sample.Position, sample.Position + sample.Forward)
			local lift = if index % 2 == 0 then 0.04 else 0
			if opts.Style == "Rings" then
				if index % 3 == 0 then
					for _, piece in {
						{ Vector3.new(2, height, 2), CFrame.new(-half, height / 2, 0) },
						{ Vector3.new(2, height, 2), CFrame.new(half, height / 2, 0) },
						{ Vector3.new(half * 2 + 2, 2, 2), CFrame.new(0, height, 0) },
					} do
						newPart(folder, { Name = "TunnelRing", Size = piece[1], CFrame = cf * piece[2], Material = Enum.Material.Neon, Color = opts.Color or Color3.fromRGB(0, 220, 255), CanCollide = false })
					end
				end
			else
				local length = spacing + 3
				newPart(folder, { Name = "TunnelRoof", Size = Vector3.new(half * 2 + 6, 3, length), CFrame = cf * CFrame.new(0, height + lift, 0), Material = opts.Material or Enum.Material.Concrete, Color = opts.Color or Color3.fromRGB(120, 120, 125) })
				-- Walls reach down to the ground so raised tunnels don't float.
				local drop = math.max(0, sample.Position.Y - groundY)
				for _, side in { -1, 1 } do
					newPart(folder, { Name = "TunnelWall", Size = Vector3.new(3 + lift, height + drop, length), CFrame = cf * CFrame.new(side * (half + 1.5), (height - drop) / 2, 0), Material = opts.Material or Enum.Material.Concrete, Color = opts.Color or Color3.fromRGB(120, 120, 125) })
				end
				if index % 3 == 0 then
					local lamp = newPart(folder, { Name = "TunnelLight", Size = Vector3.new(half * 1.2, 0.3, 1), CFrame = cf * CFrame.new(0, height - 1.6, 0), Material = Enum.Material.Neon, Color = opts.LightColor or Color3.fromRGB(255, 230, 170), CanCollide = false })
					local light = Instance.new("PointLight")
					light.Range = 26
					light.Brightness = 1.5
					light.Color = lamp.Color
					light.Parent = lamp
				end
			end
		end
	end

	-- Grandstand full of (blocky) spectators beside the road at track position u.
	-- baseY lets a stand sit on a pier/platform instead of the ground.
	function api.grandstand(u: number, side: number, length: number?, roofColor: Color3?, baseY: number?)
		length = length or 60
		local sample = api.sampleAt(u)
		local base = sample.Position + sample.Right * side * (edge + 14)
		local ground = Vector3.new(base.X, baseY or groundY, base.Z)
		local cf = CFrame.lookAt(ground, ground - sample.Right * side) -- faces the road
		api.reserve((cf * CFrame.new(0, 0, 16)).Position, length / 2 + 6)
		for tier = 0, 3 do
			newPart(folder, { Name = "Bleacher", Size = Vector3.new(length, 2.5 + tier * 2.5, 5), CFrame = cf * CFrame.new(0, (2.5 + tier * 2.5) / 2, 6 + tier * 5), Material = Enum.Material.Concrete, Color = Color3.fromRGB(150, 150, 155) })
			for seat = -length / 2 + 2, length / 2 - 2, 3 do
				if random:NextNumber() < 0.75 then
					local fan = cf * CFrame.new(seat, 2.5 + tier * 2.5 + 1.5, 6 + tier * 5)
					newPart(folder, { Name = "Fan", Size = Vector3.new(1.6, 2, 1), CFrame = fan, Material = Enum.Material.SmoothPlastic, Color = Color3.fromHSV(random:NextNumber(), 0.7, 0.9), CanCollide = false })
					newPart(folder, { Name = "FanHead", Size = Vector3.new(1.2, 1.2, 1.2), CFrame = fan * CFrame.new(0, 1.6, 0), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(255, 210, 160), CanCollide = false })
				end
			end
		end
		newPart(folder, { Name = "StandRoof", Size = Vector3.new(length + 4, 1, 26), CFrame = cf * CFrame.new(0, 18, 14) * CFrame.Angles(math.rad(-8), 0, 0), Material = Enum.Material.Metal, Color = roofColor or def.BannerColor or Color3.fromRGB(255, 80, 0) })
		for _, x in { -length / 2, length / 2 } do
			newPart(folder, { Name = "StandPost", Size = Vector3.new(1.5, 18, 1.5), CFrame = cf * CFrame.new(x, 9, 24), Material = Enum.Material.Metal, Color = Color3.fromRGB(60, 60, 65) })
		end
	end

	-- Sponsor arch over the road.
	function api.arch(u: number, label: string, color: Color3?)
		local sample = api.sampleAt(u)
		local cf = CFrame.lookAt(sample.Position, sample.Position + sample.Forward)
		for _, side in { -1, 1 } do
			newPart(folder, { Name = "ArchPost", Size = Vector3.new(2.5, 20, 2.5), CFrame = cf * CFrame.new(side * (edge + 2), 10, 0), Material = Enum.Material.Metal, Color = Color3.fromRGB(40, 40, 45) })
		end
		local board = newPart(folder, { Name = "ArchSign", Size = Vector3.new(edge * 2 + 6, 5, 1.5), CFrame = cf * CFrame.new(0, 21, 0), Material = Enum.Material.SmoothPlastic, Color = color or Color3.fromRGB(30, 30, 35) })
		addSign(board, label)
	end

	if def.Decor then
		def.Decor(api)
	end

	-- Grid slots: two per row, following the road backwards from the start line.
	local function grid(slot: number): (CFrame, number)
		local row = (slot - 1) // 2
		local column = (slot - 1) % 2
		local index = (count - 1 - row * 2) % count + 1
		local sample = samples[index]
		local position = sample.Position + sample.Right * (if column == 0 then -width * 0.22 else width * 0.22)
		return CFrame.lookAt(position, position + sample.Forward), index
	end

	return {
		Id = def.Id,
		Name = def.Name,
		Laps = def.Laps or Config.Race.Laps,
		Folder = folder,
		Samples = samples,
		Width = width,
		Edge = edge, -- centre line to the outside of the barrier
		KillY = def.KillY or (groundY - 40),
		Pickups = pickups,
		Shortcuts = shortcutPaths,
		Grid = grid,
		SampleCFrame = sampleCFrame,
	}
end

return TrackBuilder
