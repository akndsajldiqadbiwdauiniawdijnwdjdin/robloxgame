-- Builds a track from a definition in server/Tracks. The road follows a smooth closed
-- curve through the definition's control Points (each Vector3's Y is the road height).
--
-- Track positions are written as "control point index + fraction": 4.5 means halfway
-- between control point 4 and 5. Sections, gaps, pads, ramps etc. all use that.
--
-- Surfaces (Surface attribute, read by the driving script):
--   Road  - full speed          Dirt - nearly full speed, slidier
--   Offroad - slowed by low Traction (grass, sand, ground)
--   Mud   - very slow unless your Traction is high
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local TrackBuilder = {}

local SURFACE_LOOKS = {
	Road = { Material = Enum.Material.Asphalt, Color = Color3.fromRGB(45, 45, 50) },
	Dirt = { Material = Enum.Material.Ground, Color = Color3.fromRGB(150, 105, 65) },
	Offroad = { Material = Enum.Material.Grass, Color = Color3.fromRGB(80, 140, 60) },
	Mud = { Material = Enum.Material.Mud, Color = Color3.fromRGB(85, 60, 40) },
}
local CURB_RED = Color3.fromRGB(210, 35, 35)
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

local function sampleCurve(points, closed: boolean, spacing: number)
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
			position = Vector3.new(position.X, math.max(position.Y, 1), position.Z)
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

local function newPart(parent: Instance, props)
	local part = Instance.new(props.ClassName or "Part")
	props.ClassName = nil
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local attributes = props.Attributes
	props.Attributes = nil
	for key, value in props do
		part[key] = value
	end
	if attributes then
		for key, value in attributes do
			part:SetAttribute(key, value)
		end
	end
	part.Parent = parent
	return part
end

local function addSign(part: BasePart, text: string, color: Color3?)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = text
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = color or Color3.new(1, 1, 1)
		label.Parent = gui
		gui.Parent = part
	end
end
TrackBuilder.addSign = addSign

-- Builds a strip of road segments along `samples`. Returns nothing; parts go in `folder`.
local function buildRoad(folder, samples, closed, width, surfaceAt, isGap, options)
	local count = #samples
	local lastIndex = if closed then count else count - 1
	for i = 1, lastIndex do
		local a = samples[i]
		local b = samples[i % count + 1]
		if not isGap(a.U) then
			local surface = surfaceAt(a.U)
			local look = SURFACE_LOOKS[surface]
			local segment = b.Position - a.Position
			local length = segment.Magnitude

			-- Extend each piece just enough to cover the outside of the bend.
			local after = samples[(i + 1) % count + 1]
			local before = samples[(i - 2) % count + 1]
			local turn = math.max(angleBetween(a.Forward, after.Position - b.Position), angleBetween(a.Position - before.Position, a.Forward))
			local extra = width * math.tan(math.min(turn, math.rad(60)) / 2) + 0.4

			local cf = CFrame.lookAt((a.Position + b.Position) / 2, b.Position) * CFrame.new(0, -0.5, 0)
			newPart(folder, {
				Name = "Road",
				Size = Vector3.new(width, 1, length + extra),
				CFrame = cf,
				Material = if surface == "Road" and options.RoadMaterial then options.RoadMaterial else look.Material,
				Color = if surface == "Road" and options.RoadColor then options.RoadColor else look.Color,
				Attributes = { Surface = surface },
			})

			if options.Curbs and surface == "Road" then
				for _, side in { -1, 1 } do
					newPart(folder, {
						Name = "Curb",
						Size = Vector3.new(2, 1.2, length + 1),
						CFrame = cf * CFrame.new(side * (width / 2 + 1), 0.1, 0),
						Material = Enum.Material.SmoothPlastic,
						Color = if i % 2 == 0 then CURB_RED else CURB_WHITE,
						Attributes = { Surface = "Road" },
					})
				end
			end

			if options.WallAt and options.WallAt(a.U, a.Position.Y) then
				local wall = options.Wall
				for _, side in { -1, 1 } do
					newPart(folder, {
						Name = "Wall",
						Size = Vector3.new(1, wall.Height, length + 1),
						CFrame = cf * CFrame.new(side * (width / 2 + 2.5), wall.Height / 2 + 0.5, 0),
						Material = wall.Material,
						Color = wall.Color,
					})
					if wall.Neon then
						newPart(folder, {
							Name = "WallTrim",
							Size = Vector3.new(1.2, 0.4, length + 1),
							CFrame = cf * CFrame.new(side * (width / 2 + 2.5), wall.Height + 0.6, 0),
							Material = Enum.Material.Neon,
							Color = wall.Neon,
							CanCollide = false,
						})
					end
				end
			end

			-- Hold up raised road: solid fill (canyon) or pillars (highway).
			local low = math.min(a.Position.Y, b.Position.Y) - 1
			if options.Support and low > 3 then
				if options.Support == "Fill" then
					local flatCenter = (a.Position + b.Position) / 2
					local flatDir = Vector3.new(segment.X, 0, segment.Z)
					if flatDir.Magnitude > 0.1 then
						newPart(folder, {
							Name = "Fill",
							Size = Vector3.new(width + 16, low, length + extra),
							CFrame = CFrame.lookAt(Vector3.new(flatCenter.X, low / 2, flatCenter.Z), Vector3.new(flatCenter.X, low / 2, flatCenter.Z) + flatDir),
							Material = options.FillMaterial or Enum.Material.Sandstone,
							Color = options.FillColor or Color3.fromRGB(190, 120, 70),
							Attributes = { Surface = "Offroad" },
						})
					end
				elseif options.Support == "Pillars" and i % 5 == 0 then
					newPart(folder, {
						Name = "Pillar",
						Size = Vector3.new(6, low, 6),
						CFrame = CFrame.new(a.Position.X, low / 2, a.Position.Z),
						Material = Enum.Material.Concrete,
						Color = options.PillarColor or Color3.fromRGB(110, 110, 120),
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

	local width = def.Width or Config.Track.DefaultWidth
	local spacing = Config.Track.SampleSpacing
	local samples = sampleCurve(def.Points, true, spacing)
	local count = #samples

	-- Lighting / atmosphere.
	for key, value in def.Lighting or {} do
		Lighting[key] = value
	end

	local function surfaceAt(u: number): string
		for _, section in def.Sections or {} do
			if inRange(u, section) then
				return section.Surface
			end
		end
		return def.Surface or "Road"
	end
	local function isGap(u: number): boolean
		for _, gap in def.Gaps or {} do
			if inRange(u, gap) then
				return true
			end
		end
		return false
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

	local wall = def.Walls
	local roadOptions = {
		RoadMaterial = def.RoadMaterial,
		RoadColor = def.RoadColor,
		Curbs = def.Curbs ~= false,
		Support = def.Support,
		FillMaterial = def.FillMaterial,
		FillColor = def.FillColor,
		PillarColor = def.PillarColor,
		Wall = wall,
		WallAt = wall and function(u, y)
			if wall.AboveHeight and y > wall.AboveHeight then
				return true
			end
			for _, range in wall.Ranges or {} do
				if inRange(u, range) then
					return true
				end
			end
			return false
		end,
	}
	buildRoad(folder, samples, true, width, surfaceAt, isGap, roadOptions)

	-- Shortcuts: open strips off the main road.
	local clearPaths = { samples }
	for _, shortcut in def.Shortcuts or {} do
		local path = sampleCurve(shortcut.Points, false, spacing)
		buildRoad(folder, path, false, shortcut.Width, function()
			return shortcut.Surface
		end, function()
			return false
		end, { Curbs = false })
		table.insert(clearPaths, path)
	end

	-- Ground (tiled: a single part can't be bigger than 2048 studs).
	local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
	for _, sample in samples do
		minX, maxX = math.min(minX, sample.Position.X), math.max(maxX, sample.Position.X)
		minZ, maxZ = math.min(minZ, sample.Position.Z), math.max(maxZ, sample.Position.Z)
	end
	local margin = 450
	local ground = def.Ground or {}
	local tile = 1000
	for x = minX - margin, maxX + margin, tile do
		for z = minZ - margin, maxZ + margin, tile do
			newPart(folder, {
				Name = "Ground",
				Size = Vector3.new(tile, 2, tile),
				CFrame = CFrame.new(x + tile / 2, -1, z + tile / 2),
				Material = ground.Material or Enum.Material.Grass,
				Color = ground.Color or Color3.fromRGB(80, 140, 60),
				Attributes = { Surface = ground.Surface or "Offroad" },
			})
		end
	end

	-- Start/finish gate at sample 1.
	local start = samples[1]
	local startCf = CFrame.lookAt(start.Position, start.Position + start.Forward)
	newPart(folder, {
		Name = "StartLine",
		Size = Vector3.new(width, 0.1, 4),
		CFrame = startCf * CFrame.new(0, 0.05, 0),
		Material = Enum.Material.Neon,
		Color = CURB_WHITE,
		CanCollide = false,
		Attributes = { Surface = "Road" },
	})
	for _, side in { -1, 1 } do
		newPart(folder, {
			Name = "GatePillar",
			Size = Vector3.new(3, 24, 3),
			CFrame = startCf * CFrame.new(side * (width / 2 + 5), 12, 0),
			Material = Enum.Material.Metal,
			Color = Color3.fromRGB(30, 30, 30),
		})
	end
	local banner = newPart(folder, {
		Name = "GateBanner",
		Size = Vector3.new(width + 13, 6, 2),
		CFrame = startCf * CFrame.new(0, 25, 0),
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
		local cf = sampleCFrame(sampleIndexAt(pad.At)) * CFrame.new(pad.Offset or 0, 0.06, 0)
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
				CFrame = panel.CFrame * CFrame.new(0, 0.02, k * 3),
				Material = Enum.Material.Neon,
				Color = Color3.fromRGB(255, 90, 0),
				CanCollide = false,
				CanQuery = false,
			})
		end
	end

	-- Jump ramps. Tilted so the back edge is flush with the road.
	for _, ramp in def.Ramps or {} do
		local angle = math.rad(ramp.Angle or 12)
		local length = ramp.Length or 24
		local thickness = 1
		local cf = sampleCFrame(sampleIndexAt(ramp.At))
			* CFrame.new(ramp.Offset or 0, length / 2 * math.sin(angle) - thickness / 2 * math.cos(angle), 0)
			* CFrame.Angles(angle, 0, 0)
		newPart(folder, {
			Name = "Ramp",
			Size = Vector3.new(ramp.Width or width * 0.4, thickness, length),
			CFrame = cf,
			Material = Enum.Material.DiamondPlate,
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
	local random = Random.new(def.Seed or 1)
	local api = {
		Folder = folder,
		Samples = samples,
		Width = width,
		Random = random,
	}
	function api.part(props)
		return newPart(folder, props)
	end
	api.sign = addSign
	-- True if nothing on any road/shortcut is within `radius` of `position` (flat distance).
	function api.isClear(position: Vector3, radius: number): boolean
		for _, path in clearPaths do
			for _, sample in path do
				local d = sample.Position - position
				if Vector3.new(d.X, 0, d.Z).Magnitude < radius + width / 2 + 4 then
					return false
				end
			end
		end
		return true
	end
	-- Calls fn(position, sample, side) every `step` samples on both sides, `offset` studs
	-- beyond the road edge.
	function api.alongTrack(step: number, offset: number, fn)
		for i = 1, count, step do
			local sample = samples[i]
			for _, side in { -1, 1 } do
				local position = sample.Position + sample.Right * side * (width / 2 + offset)
				fn(Vector3.new(position.X, 0, position.Z), sample, side)
			end
		end
	end
	function api.sampleAt(u: number)
		return samples[sampleIndexAt(u)]
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
		Name = def.Name,
		Laps = def.Laps or Config.Race.Laps,
		Folder = folder,
		Samples = samples,
		Width = width,
		Pickups = pickups,
		Grid = grid,
		SampleCFrame = sampleCFrame,
	}
end

return TrackBuilder
