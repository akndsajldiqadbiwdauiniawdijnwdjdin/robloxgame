-- Turns a car's Design function (see Cars.luau) into brick parts. Used by the server for
-- real cars and the lobby showroom, and by the client for the garage preview.
local CarBody = {}

local SHARED_COLORS = {
	Tire = Color3.fromRGB(28, 28, 30),
	Rim = Color3.fromRGB(200, 200, 205),
	Glass = Color3.fromRGB(40, 55, 75),
	Chrome = Color3.fromRGB(205, 205, 210),
	Dark = Color3.fromRGB(35, 35, 40),
	Headlight = Color3.fromRGB(255, 250, 215),
	Taillight = Color3.fromRGB(255, 35, 35),
	Waffle = Color3.fromRGB(215, 160, 90),
}

local specCache = {}

-- Runs the design once and returns { Hitbox, Seat, Roof, Parts = { ... } }.
function CarBody.spec(car)
	if specCache[car.Id] then
		return specCache[car.Id]
	end

	local spec = {
		Hitbox = Vector3.new(6, 2.4, 11),
		Seat = Vector3.new(0, 2, 1),
		Roof = 4,
		Parts = {},
	}

	local function resolve(color)
		if typeof(color) == "Color3" then
			return color
		end
		return car.Colors[color] or SHARED_COLORS[color] or Color3.new(1, 0, 1)
	end

	local function add(shape, name, size, position, color, opts)
		opts = opts or {}
		local material = opts.Material
		local transparency = opts.Transparency
		if color == "Glass" then
			material = material or Enum.Material.Glass
			transparency = transparency or 0.25
		end
		table.insert(spec.Parts, {
			Shape = shape,
			Name = name,
			Size = size,
			Position = position,
			Color = resolve(color),
			Material = material,
			Transparency = transparency or 0,
			Steal = opts.Steal == true,
			Rotation = opts.Rot,
			Back = opts.Back == true,
		})
	end

	local d = {}
	function d.hitbox(w, h, l)
		spec.Hitbox = Vector3.new(w, h, l)
	end
	function d.seat(x, y, z)
		spec.Seat = Vector3.new(x, y, z)
	end
	function d.roof(y)
		spec.Roof = y
	end
	function d.block(name, sx, sy, sz, x, y, z, color, opts)
		add("Block", name, Vector3.new(sx, sy, sz), Vector3.new(x, y, z), color, opts)
	end
	function d.wedge(name, sx, sy, sz, x, y, z, color, opts)
		add("Wedge", name, Vector3.new(sx, sy, sz), Vector3.new(x, y, z), color, opts)
	end
	function d.cyl(name, length, diameter, x, y, z, color, opts)
		add("Cylinder", name, Vector3.new(length, diameter, diameter), Vector3.new(x, y, z), color, opts)
	end
	function d.ball(name, diameter, x, y, z, color, opts)
		add("Ball", name, Vector3.one * diameter, Vector3.new(x, y, z), color, opts)
	end
	function d.wheels(x, z, radius, width)
		for _, side in { -1, 1 } do
			add("Cylinder", "Wheel", Vector3.new(width, radius * 2, radius * 2), Vector3.new(side * x, radius, z), "Tire")
			add("Cylinder", "Hubcap", Vector3.new(0.2, radius, radius), Vector3.new(side * (x + width / 2), radius, z), "Rim")
		end
	end
	-- One wheel in the middle (motorcycles).
	function d.wheel(z, radius, width)
		add("Cylinder", "Wheel", Vector3.new(width, radius * 2, radius * 2), Vector3.new(0, radius, z), "Tire")
		for _, side in { -1, 1 } do
			add("Cylinder", "Hubcap", Vector3.new(0.2, radius, radius), Vector3.new(side * width / 2, radius, z), "Rim")
		end
	end
	-- A brick rider in a helmet (motorcycles): hips at height y, z = where they sit,
	-- reaching forward to handlebars at handZ.
	function d.rider(y, z, handZ)
		add("Block", "Rider Legs", Vector3.new(1.6, 0.6, 1.6), Vector3.new(0, y, z - 0.6), "Dark")
		add("Block", "Rider Torso", Vector3.new(1.5, 1.6, 0.9), Vector3.new(0, y + 1.1, z), "Accent", { Rot = Vector3.new(-20, 0, 0) })
		local armLength = math.max(0.6, z - handZ)
		for _, side in { -1, 1 } do
			add("Block", "Rider Arm", Vector3.new(0.45, 0.45, armLength), Vector3.new(side * 0.85, y + 1.3, z - armLength / 2), "Accent")
		end
		add("Ball", "Helmet", Vector3.one * 1.3, Vector3.new(0, y + 2.3, z - 0.35), "Primary")
		add("Block", "Visor", Vector3.new(1, 0.45, 0.3), Vector3.new(0, y + 2.35, z - 0.95), "Glass", { Transparency = 0.1 })
	end
	function d.lights(x, y, frontZ, backZ)
		for _, side in { -1, 1 } do
			add("Block", "Headlight", Vector3.new(1.2, 0.6, 0.2), Vector3.new(side * x, y, frontZ), "Headlight", { Material = Enum.Material.Neon })
			add("Block", "Taillight", Vector3.new(1.2, 0.5, 0.2), Vector3.new(side * x, y, backZ), "Taillight", { Material = Enum.Material.Neon })
		end
	end

	car.Design(d)
	specCache[car.Id] = spec
	return spec
end

-- Builds the body. `root` is the centre of the car at ground level, facing forward.
-- physical = true: unanchored, massless, non-colliding (the server welds them to the chassis).
-- physical = false: anchored display model (showroom / garage preview).
function CarBody.build(car, root: CFrame, physical: boolean): (Model, any)
	local spec = CarBody.spec(car)

	local model = Instance.new("Model")
	model.Name = car.Id
	local body = Instance.new("Folder")
	body.Name = "Body"
	body.Parent = model
	local stealable = Instance.new("Folder")
	stealable.Name = "Stealable"
	stealable.Parent = model

	for _, p in spec.Parts do
		local part
		if p.Shape == "Wedge" then
			part = Instance.new("WedgePart")
		else
			part = Instance.new("Part")
			if p.Shape == "Cylinder" then
				part.Shape = Enum.PartType.Cylinder
			elseif p.Shape == "Ball" then
				part.Shape = Enum.PartType.Ball
			end
		end
		part.Name = p.Name
		part.Size = p.Size
		part.Color = p.Color
		part.Material = p.Material or Enum.Material.Plastic
		part.Transparency = p.Transparency

		-- Classic Roblox brick look: studs on top, inlets underneath.
		if p.Shape == "Block" and part.Material == Enum.Material.Plastic then
			part.TopSurface = Enum.SurfaceType.Studs
			part.BottomSurface = Enum.SurfaceType.Inlet
		else
			part.TopSurface = Enum.SurfaceType.Smooth
			part.BottomSurface = Enum.SurfaceType.Smooth
		end

		local cf = root * CFrame.new(p.Position)
		if p.Back then
			cf *= CFrame.Angles(0, math.pi, 0)
		end
		if p.Rotation then
			cf *= CFrame.Angles(math.rad(p.Rotation.X), math.rad(p.Rotation.Y), math.rad(p.Rotation.Z))
		end
		part.CFrame = cf

		part.Anchored = not physical
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.Parent = if p.Steal then stealable else body
	end

	return model, spec
end

return CarBody
