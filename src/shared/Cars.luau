-- Every car: price, the 6 stats (0-10), colors and a brick-built design.
--
-- Design coordinates are in studs, relative to the centre of the car on the ground:
--   x = right, y = up from the ground, z = backwards (negative z is the FRONT).
-- Helpers (see CarBody.luau):
--   d.hitbox(w, h, l)                      physics box (keep the car inside it)
--   d.seat(x, y, z)                        where the driver sits
--   d.roof(y)                              where stolen trophies stack
--   d.block(name, sx, sy, sz, x, y, z, color, opts)
--   d.wedge(...)                           slope rises toward the back; opts.Back flips it
--   d.cyl(name, length, diameter, x, y, z, color, opts)   axis along x (opts.Rot to turn it)
--   d.ball(name, diameter, x, y, z, color, opts)
--   d.wheels(x, z, radius, width)          a left+right pair at ±x
--   d.lights(x, y, frontZ, backZ)          headlights + taillights
-- opts: { Steal = true (can be ripped off), Material = Enum.Material.X, Rot = Vector3 (degrees),
--         Transparency = n, Back = true }
-- Colors: "Primary", "Secondary", "Accent" come from the car; "Tire", "Rim", "Glass",
-- "Chrome", "Dark", "Headlight", "Taillight" are shared.

local Cars = {}

local NEON = Enum.Material.Neon
local METAL = Enum.Material.Metal

Cars.List = {
	{
		Id = "Beater",
		Name = "Rusty Beater",
		Price = 0,
		Description = "Held together with duct tape and hope.",
		Stats = { Speed = 3, Acceleration = 5, Weight = 5, Handling = 4, Traction = 5, MiniTurbo = 4 },
		Colors = {
			Primary = Color3.fromRGB(150, 110, 80),
			Secondary = Color3.fromRGB(110, 120, 110),
			Accent = Color3.fromRGB(120, 60, 30),
		},
		Design = function(d)
			d.hitbox(6, 2.4, 11)
			d.seat(0, 2.0, 1)
			d.roof(3.9)
			d.wheels(2.8, -3.5, 1.3, 1.2)
			d.wheels(2.8, 3.5, 1.3, 1.2)
			d.block("Shell", 6, 1.2, 11, 0, 1.6, 0, "Primary")
			d.block("Cabin", 5, 1.2, 5, 0, 2.8, 0.6, "Glass")
			d.block("Roof", 5.2, 0.4, 4.4, 0, 3.6, 0.8, "Primary")
			d.block("Odd Door", 0.2, 1, 3, 3.05, 1.7, 0.5, "Secondary")
			d.block("Hood Patch", 1.6, 0.2, 2, 1.4, 2.25, -3.5, "Secondary")
			d.block("Rust", 1, 0.2, 1, -1.8, 2.25, 3.8, "Accent")
			d.lights(2, 1.7, -5.55, 5.55)
			d.block("Front Bumper", 6.4, 0.6, 0.6, 0, 1.0, -5.8, "Accent", { Steal = true, Rot = Vector3.new(0, 0, 6) })
			d.block("Rear Bumper", 6.4, 0.6, 0.6, 0, 1.0, 5.8, "Accent", { Steal = true })
			d.block("Antenna", 0.2, 2, 0.2, 2, 4.6, 2, "Chrome", { Steal = true })
		end,
	},
	{
		Id = "GoKart",
		Name = "Go-Kart",
		Price = 1500,
		Description = "Featherweight. Turns on a dime, gets bullied by everyone.",
		Stats = { Speed = 3, Acceleration = 8, Weight = 1, Handling = 8, Traction = 4, MiniTurbo = 7 },
		Colors = {
			Primary = Color3.fromRGB(0, 170, 70),
			Secondary = Color3.fromRGB(35, 35, 40),
			Accent = Color3.fromRGB(255, 220, 0),
		},
		Design = function(d)
			d.hitbox(5, 1.6, 8)
			d.seat(0, 1.3, 1)
			d.roof(3.4)
			d.wheels(2.2, -2.6, 0.9, 1)
			d.wheels(2.3, 2.6, 1.1, 1.4)
			d.block("Floor", 3.6, 0.4, 7, 0, 0.7, 0, "Secondary")
			d.wedge("Nose", 3, 0.8, 2, 0, 1.3, -3.2, "Primary")
			d.block("Left Pod", 0.8, 0.8, 3, -1.9, 1.1, 0.5, "Primary")
			d.block("Right Pod", 0.8, 0.8, 3, 1.9, 1.1, 0.5, "Primary")
			d.block("Seat Back", 2, 1.6, 0.5, 0, 1.9, 1.9, "Secondary")
			d.block("Steering", 1.2, 0.2, 0.2, 0, 2.0, -0.8, "Dark")
			d.block("Engine", 2, 1, 1.5, 0, 1.4, 3.1, "Chrome", { Material = METAL })
			d.block("Number Plate", 1.6, 1.2, 0.2, 0, 1.6, -2.3, "Accent", { Steal = true })
			d.block("Front Bumper", 3.6, 0.4, 0.4, 0, 0.9, -4.3, "Accent", { Steal = true })
			d.cyl("Exhaust", 1.5, 0.5, 0.7, 1.6, 3.9, "Chrome", { Steal = true, Rot = Vector3.new(0, 90, 0) })
		end,
	},
	{
		Id = "Tuner",
		Name = "Street Tuner",
		Price = 3000,
		Description = "Big wing, bigger attitude. Born to drift.",
		Stats = { Speed = 5, Acceleration = 6, Weight = 3, Handling = 6, Traction = 4, MiniTurbo = 8 },
		Colors = {
			Primary = Color3.fromRGB(30, 110, 255),
			Secondary = Color3.fromRGB(245, 245, 245),
			Accent = Color3.fromRGB(255, 60, 120),
		},
		Design = function(d)
			d.hitbox(6, 2.4, 10.5)
			d.seat(0, 2.0, 1)
			d.roof(4.2)
			d.wheels(2.8, -3.3, 1.2, 1.2)
			d.wheels(2.8, 3.3, 1.2, 1.2)
			d.block("Shell", 6, 1.1, 10.5, 0, 1.5, 0, "Primary")
			d.wedge("Hood", 6, 0.6, 2.4, 0, 2.35, -2.8, "Primary")
			d.block("Cabin", 5.2, 1.3, 4.5, 0, 2.7, 0.8, "Glass")
			d.block("Roof", 5.4, 0.3, 3.6, 0, 3.45, 1.0, "Primary")
			d.block("Stripe", 1, 0.1, 3.6, 0, 3.65, 1.0, "Secondary")
			d.block("Left Skirt", 0.3, 0.5, 6, -3.1, 1.0, 0, "Secondary")
			d.block("Right Skirt", 0.3, 0.5, 6, 3.1, 1.0, 0, "Secondary")
			d.block("Wing Strut L", 0.3, 1.2, 0.3, -2, 2.6, 4.6, "Dark")
			d.block("Wing Strut R", 0.3, 1.2, 0.3, 2, 2.6, 4.6, "Dark")
			d.lights(2, 1.6, -5.3, 5.3)
			d.block("Big Wing", 6.4, 0.3, 1.6, 0, 3.3, 4.6, "Secondary", { Steal = true })
			d.block("Front Splitter", 6.4, 0.2, 0.8, 0, 0.85, -5.4, "Accent", { Steal = true })
			d.cyl("Exhaust", 1, 0.7, 2, 1.2, 5.4, "Chrome", { Steal = true, Rot = Vector3.new(0, 90, 0) })
		end,
	},
	{
		Id = "Buggy",
		Name = "Dune Buggy",
		Price = 5000,
		Description = "Laughs at sand, mud and grass. Roll cage included.",
		Stats = { Speed = 4, Acceleration = 6, Weight = 3, Handling = 5, Traction = 9, MiniTurbo = 5 },
		Colors = {
			Primary = Color3.fromRGB(255, 120, 0),
			Secondary = Color3.fromRGB(30, 30, 30),
			Accent = Color3.fromRGB(255, 230, 60),
		},
		Design = function(d)
			d.hitbox(6, 2.6, 9.5)
			d.seat(0, 2.2, 0.8)
			d.roof(5.2)
			d.wheels(2.9, -3.2, 1.4, 1.4)
			d.wheels(3.0, 3.2, 1.6, 1.8)
			d.block("Tub", 4, 1, 7, 0, 1.6, 0.3, "Primary")
			d.wedge("Nose", 4, 1, 2, 0, 1.6, -4.0, "Primary")
			for _, z in { -0.8, 2.2 } do
				d.block("Cage Post", 0.3, 2.4, 0.3, -1.8, 3.3, z, "Secondary")
				d.block("Cage Post", 0.3, 2.4, 0.3, 1.8, 3.3, z, "Secondary")
				d.block("Cage Bar", 3.9, 0.3, 0.3, 0, 4.5, z, "Secondary")
			end
			d.block("Cage Side", 0.3, 0.3, 3.3, -1.8, 4.5, 0.7, "Secondary")
			d.block("Cage Side", 0.3, 0.3, 3.3, 1.8, 4.5, 0.7, "Secondary")
			d.block("Engine", 2.4, 1.2, 1.6, 0, 2.4, 3.6, "Chrome", { Material = Enum.Material.DiamondPlate })
			d.block("Seat Back", 2, 1.4, 0.4, 0, 2.6, 1.8, "Secondary")
			d.block("Light Bar", 3, 0.4, 0.4, 0, 4.85, -0.8, "Accent", { Steal = true, Material = NEON })
			d.cyl("Spare Tire", 0.8, 2.4, 0, 2.6, 4.6, "Tire", { Steal = true, Rot = Vector3.new(0, 90, 0) })
			d.block("Bull Bar", 4.4, 0.8, 0.3, 0, 1.4, -5.1, "Chrome", { Steal = true, Material = METAL })
		end,
	},
	{
		Id = "Muscle",
		Name = "Muscle Car",
		Price = 8000,
		Description = "All engine, no brakes. Hits hard, turns wide.",
		Stats = { Speed = 7, Acceleration = 4, Weight = 7, Handling = 3, Traction = 4, MiniTurbo = 4 },
		Colors = {
			Primary = Color3.fromRGB(200, 25, 25),
			Secondary = Color3.fromRGB(20, 20, 20),
			Accent = Color3.fromRGB(255, 255, 255),
		},
		Design = function(d)
			d.hitbox(6.4, 2.4, 11.5)
			d.seat(0, 2.0, 1.2)
			d.roof(4.0)
			d.wheels(2.9, -3.7, 1.25, 1.2)
			d.wheels(3.0, 3.7, 1.45, 1.8)
			d.block("Shell", 6.4, 1.3, 11.5, 0, 1.65, 0, "Primary")
			d.block("Cabin", 5.4, 1.2, 4, 0, 2.9, 1.3, "Glass")
			d.block("Roof", 5.6, 0.3, 3.4, 0, 3.6, 1.5, "Primary")
			d.wedge("Fastback", 5.6, 0.9, 1.6, 0, 2.75, 3.9, "Primary", { Back = true })
			d.block("Hood Stripe L", 0.8, 0.1, 4.5, -0.9, 2.35, -3.4, "Secondary")
			d.block("Hood Stripe R", 0.8, 0.1, 4.5, 0.9, 2.35, -3.4, "Secondary")
			d.cyl("Side Pipe R", 4, 0.6, 3.35, 1.0, 0, "Chrome", { Rot = Vector3.new(0, 90, 0) })
			d.lights(2.2, 1.8, -5.8, 5.8)
			d.block("Hood Scoop", 2, 0.8, 2.4, 0, 2.7, -2.8, "Secondary", { Steal = true })
			d.block("Ducktail", 6, 0.3, 1, 0, 2.5, 5.4, "Secondary", { Steal = true })
			d.block("Chrome Bumper", 6.6, 0.6, 0.5, 0, 1.1, -5.95, "Chrome", { Steal = true, Material = METAL })
			d.cyl("Side Pipe L", 4, 0.6, -3.35, 1.0, 0, "Chrome", { Steal = true, Rot = Vector3.new(0, 90, 0) })
		end,
	},
	{
		Id = "IceCream",
		Name = "Ice Cream Truck",
		Price = 10000,
		Description = "Slow, heavy, and absolutely unstoppable once it gets going.",
		Stats = { Speed = 5, Acceleration = 3, Weight = 10, Handling = 2, Traction = 6, MiniTurbo = 3 },
		Colors = {
			Primary = Color3.fromRGB(255, 190, 220),
			Secondary = Color3.fromRGB(250, 250, 250),
			Accent = Color3.fromRGB(110, 230, 190),
		},
		Design = function(d)
			d.hitbox(6.6, 3.2, 12.5)
			d.seat(0, 2.6, -3.8)
			d.roof(8.4)
			d.wheels(3.0, -4.2, 1.4, 1.4)
			d.wheels(3.0, 4.2, 1.4, 1.4)
			d.block("Cab", 6.6, 1.6, 3.5, 0, 2.0, -4.3, "Secondary")
			d.wedge("Hood", 6.4, 0.8, 1.6, 0, 3.2, -5.3, "Secondary")
			d.block("Windshield", 6.2, 1.4, 2.4, 0, 3.5, -3.6, "Glass")
			d.block("Cab Roof", 6.6, 0.4, 3, 0, 4.4, -3.9, "Secondary")
			d.block("Box", 6.6, 4.2, 8.5, 0, 3.3, 1.9, "Primary")
			d.block("Trim", 6.7, 0.5, 8.6, 0, 2.0, 1.9, "Accent")
			d.block("Serving Window", 0.2, 1.6, 4, 3.35, 3.8, 1.5, "Dark")
			d.block("Awning", 1.2, 0.2, 4.6, 3.9, 4.9, 1.5, "Accent", { Rot = Vector3.new(0, 0, -15) })
			d.lights(2.2, 1.8, -6.1, 6.2)
			d.cyl("Cone", 2, 1.6, 0, 6.4, 1.5, "Waffle", { Rot = Vector3.new(0, 0, 90) })
			d.ball("Scoop", 2.4, 0, 7.6, 1.5, "Accent", { Steal = true })
			d.cyl("Speaker", 1.2, 1, 0, 5.0, -3.6, "Chrome", { Steal = true, Rot = Vector3.new(0, 90, 0) })
			d.block("Rear Bumper", 6.8, 0.6, 0.6, 0, 1.0, 6.3, "Chrome", { Steal = true, Material = METAL })
		end,
	},
	{
		Id = "Cop",
		Name = "Stolen Cop Car",
		Price = 15000,
		Description = "Borrowed. Indefinitely. Great all-rounder.",
		Stats = { Speed = 7, Acceleration = 6, Weight = 6, Handling = 5, Traction = 5, MiniTurbo = 5 },
		Colors = {
			Primary = Color3.fromRGB(20, 20, 25),
			Secondary = Color3.fromRGB(245, 245, 245),
			Accent = Color3.fromRGB(255, 200, 0),
		},
		Design = function(d)
			d.hitbox(6, 2.4, 11.5)
			d.seat(0, 2.0, 1.2)
			d.roof(4.6)
			d.wheels(2.8, -3.6, 1.3, 1.2)
			d.wheels(2.8, 3.6, 1.3, 1.2)
			d.block("Shell", 6, 1.2, 11.5, 0, 1.6, 0, "Primary")
			d.block("Doors", 6.1, 1.0, 4, 0, 1.65, 0.6, "Secondary")
			d.block("Cabin", 5, 1.3, 5, 0, 2.85, 0.8, "Glass")
			d.block("Roof", 5.2, 0.3, 4.2, 0, 3.6, 0.9, "Secondary")
			d.block("Badge L", 0.1, 0.6, 0.6, -3.06, 1.9, 0.6, "Accent")
			d.block("Badge R", 0.1, 0.6, 0.6, 3.06, 1.9, 0.6, "Accent")
			d.lights(2, 1.7, -5.8, 5.8)
			d.block("Red Siren", 2, 0.5, 0.8, -1.1, 3.95, 0.9, Color3.fromRGB(255, 30, 30), { Steal = true, Material = NEON })
			d.block("Blue Siren", 2, 0.5, 0.8, 1.1, 3.95, 0.9, Color3.fromRGB(30, 90, 255), { Steal = true, Material = NEON })
			d.block("Push Bar", 5, 1.2, 0.4, 0, 1.6, -6.0, "Dark", { Steal = true, Material = METAL })
		end,
	},
	{
		Id = "Monster",
		Name = "Monster Truck",
		Price = 22000,
		Description = "Huge tires. Drives over offroad like it's not there.",
		Stats = { Speed = 6, Acceleration = 5, Weight = 9, Handling = 3, Traction = 10, MiniTurbo = 3 },
		Colors = {
			Primary = Color3.fromRGB(60, 200, 40),
			Secondary = Color3.fromRGB(30, 30, 30),
			Accent = Color3.fromRGB(255, 120, 0),
		},
		Design = function(d)
			d.hitbox(7.5, 4.4, 12)
			d.seat(0, 4.6, 0.8)
			d.roof(7.4)
			d.wheels(3.4, -3.8, 2.2, 2)
			d.wheels(3.4, 3.8, 2.2, 2)
			d.block("Frame", 4, 0.8, 10, 0, 2.6, 0, "Secondary")
			d.block("Body", 7, 1.4, 11.5, 0, 4.1, 0, "Primary")
			d.block("Cabin", 6, 1.6, 4, 0, 5.6, 0.6, "Glass")
			d.block("Roof", 6.2, 0.4, 4.2, 0, 6.6, 0.6, "Primary")
			d.block("Bed Wall", 7, 0.8, 0.3, 0, 5.2, 5.6, "Primary")
			d.block("Flame L", 0.1, 0.6, 3, -3.55, 4.1, -3, "Accent")
			d.block("Flame R", 0.1, 0.6, 3, 3.55, 4.1, -3, "Accent")
			for _, x in { -2.6, 2.6 } do
				for _, z in { -3.8, 3.8 } do
					d.cyl("Shock", 2, 0.5, x, 3.2, z, "Chrome", { Rot = Vector3.new(0, 0, 90) })
				end
			end
			d.lights(2.4, 4.1, -5.8, 5.8)
			d.block("Roof Lights", 5, 0.5, 0.5, 0, 7.05, -0.6, Color3.fromRGB(255, 240, 120), { Steal = true, Material = NEON })
			d.cyl("Exhaust Stack", 2, 0.6, 2.6, 6.2, 2.8, "Chrome", { Steal = true, Rot = Vector3.new(0, 0, 90) })
			d.block("Front Bumper", 7.4, 1, 0.6, 0, 3.4, -6.1, "Chrome", { Steal = true, Material = METAL })
		end,
	},
	{
		Id = "Supercar",
		Name = "Supercar",
		Price = 35000,
		Description = "Wedge-shaped rocket. Twitchy on dirt.",
		Stats = { Speed = 9, Acceleration = 6, Weight = 5, Handling = 6, Traction = 3, MiniTurbo = 6 },
		Colors = {
			Primary = Color3.fromRGB(255, 200, 0),
			Secondary = Color3.fromRGB(25, 25, 25),
			Accent = Color3.fromRGB(255, 255, 255),
		},
		Design = function(d)
			d.hitbox(6.6, 2, 11.5)
			d.seat(0, 1.6, 0.3)
			d.roof(3.4)
			d.wheels(3.0, -3.8, 1.2, 1.3)
			d.wheels(3.0, 3.8, 1.2, 1.3)
			d.block("Shell", 6.6, 0.9, 11.5, 0, 1.25, 0, "Primary")
			d.wedge("Nose", 6.6, 0.9, 4, 0, 2.15, -3.75, "Primary")
			d.block("Cabin", 4.6, 1, 3.4, 0, 2.2, 0, "Glass")
			d.block("Roof", 4.8, 0.2, 2.6, 0, 2.8, 0.3, "Secondary")
			d.wedge("Engine Cover", 6, 0.8, 3.5, 0, 2.1, 3.6, "Secondary", { Back = true })
			d.block("Vent L", 0.3, 0.8, 2, -3.35, 1.6, 1.6, "Secondary")
			d.block("Vent R", 0.3, 0.8, 2, 3.35, 1.6, 1.6, "Secondary")
			d.block("Wing Strut L", 0.3, 0.9, 0.3, -2, 2.9, 5.0, "Secondary")
			d.block("Wing Strut R", 0.3, 0.9, 0.3, 2, 2.9, 5.0, "Secondary")
			d.lights(2.4, 1.4, -5.8, 5.8)
			d.block("Rear Wing", 6.4, 0.25, 1.2, 0, 3.4, 5.0, "Secondary", { Steal = true })
			d.block("Front Splitter", 6.8, 0.2, 0.8, 0, 0.8, -5.9, "Accent", { Steal = true })
			d.block("Diffuser", 5, 0.5, 0.6, 0, 0.9, 5.9, "Secondary", { Steal = true })
		end,
	},
	{
		Id = "Hypercar",
		Name = "Hypercar",
		Price = 75000,
		Description = "Top of the food chain. Glows in the dark.",
		Stats = { Speed = 10, Acceleration = 7, Weight = 5, Handling = 7, Traction = 3, MiniTurbo = 7 },
		Colors = {
			Primary = Color3.fromRGB(130, 0, 255),
			Secondary = Color3.fromRGB(20, 20, 30),
			Accent = Color3.fromRGB(0, 255, 210),
		},
		Design = function(d)
			d.hitbox(6.8, 1.9, 12)
			d.seat(0, 1.4, 0.6)
			d.roof(3.3)
			d.wheels(3.1, -4, 1.15, 1.3)
			d.wheels(3.1, 4, 1.15, 1.3)
			d.block("Shell", 6.8, 0.8, 12, 0, 1.15, 0, "Primary")
			d.wedge("Nose", 6.4, 0.8, 4.5, 0, 1.95, -3.75, "Primary")
			d.block("Canopy", 4, 0.9, 4, 0, 2.0, 0.4, "Glass")
			d.block("Canopy Top", 4, 0.2, 3, 0, 2.55, 0.6, "Primary")
			d.wedge("Rear Deck", 6.4, 0.7, 4, 0, 1.9, 4.0, "Primary", { Back = true })
			d.block("Underglow", 6.2, 0.15, 11, 0, 0.65, 0, "Accent", { Material = NEON })
			d.block("Side Neon L", 0.1, 0.15, 10, -3.42, 1.3, 0, "Accent", { Material = NEON })
			d.block("Side Neon R", 0.1, 0.15, 10, 3.42, 1.3, 0, "Accent", { Material = NEON })
			d.lights(2.4, 1.3, -6.05, 6.05)
			d.block("Shark Fin", 0.3, 2, 3, 0, 3.0, 4.2, "Primary", { Steal = true })
			d.block("Rear Wing", 6.6, 0.25, 1, 0, 2.9, 5.6, "Accent", { Steal = true, Material = NEON })
			d.block("Canards", 6.9, 0.15, 0.6, 0, 1.0, -5.9, "Accent", { Steal = true })
		end,
	},
}

Cars.ById = {}
for _, car in Cars.List do
	Cars.ById[car.Id] = car
end
Cars.Default = Cars.List[1].Id

return Cars
