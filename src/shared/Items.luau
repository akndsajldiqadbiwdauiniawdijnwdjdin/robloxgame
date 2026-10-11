-- Every item you can get from item boxes. You own items (starter items, Item Rolls, the
-- Daily Shop, daily rewards) and pick a LOADOUT; item boxes in a race only give items
-- from your loadout. Behaviour lives in server/PowerUps.luau.
local Items = {}

Items.Rarities = {
	Common = { Order = 1, Color = Color3.fromRGB(150, 150, 155), Rate = 0.62, Refund = 100, Price = 600 },
	Rare = { Order = 2, Color = Color3.fromRGB(50, 140, 255), Rate = 0.30, Refund = 250, Price = 1500 },
	Epic = { Order = 3, Color = Color3.fromRGB(170, 80, 255), Rate = 0.07, Refund = 600, Price = 4000 },
	Mythic = { Order = 4, Color = Color3.fromRGB(255, 50, 110), Rate = 0.01, Refund = 2000, Price = 12000 },
}
Items.RarityOrder = { "Common", "Rare", "Epic", "Mythic" }

Items.List = {
	-- Common
	{ Id = "Nitro", Name = "Nitro", Icon = "🔥", Rarity = "Common", Description = "A quick burst of speed." },
	{ Id = "Oil", Name = "Oil Slick", Icon = "🛢️", Rarity = "Common", Description = "Drop a puddle that spins out whoever drives through it." },
	{ Id = "Spikes", Name = "Spike Strip", Icon = "📌", Rarity = "Common", Description = "Drop spikes behind you. Pops cars into the air." },
	{ Id = "Smoke", Name = "Smoke Bomb", Icon = "💨", Rarity = "Common", Description = "A cloud that blinds and slows anyone behind you." },
	-- Rare
	{ Id = "Rocket", Name = "Rocket", Icon = "🚀", Rarity = "Rare", Description = "Homing rocket at the racer ahead of you." },
	{ Id = "EMP", Name = "EMP Blast", Icon = "⚡", Rarity = "Rare", Description = "Shockwave that knocks back everyone near you." },
	{ Id = "Steal", Name = "Steal Part", Icon = "💰", Rarity = "Rare", Description = "Rip a part off the car ahead: they slow down, you speed up." },
	{ Id = "Shield", Name = "Bubble Shield", Icon = "🛡️", Rarity = "Rare", Description = "Blocks the next attack that hits you (8s)." },
	-- Epic
	{ Id = "Freeze", Name = "Freeze Ray", Icon = "❄️", Rarity = "Epic", Description = "Freezes the racer ahead in a block of ice." },
	{ Id = "Hook", Name = "Magnet Hook", Icon = "🧲", Rarity = "Epic", Description = "Yank yourself toward the racer ahead at high speed." },
	{ Id = "Tornado", Name = "Tornado", Icon = "🌪️", Rarity = "Epic", Description = "Leave a tornado that throws racers behind you into the air." },
	-- Mythic
	{ Id = "Jetpack", Name = "Jetpack", Icon = "🎒", Rarity = "Mythic", Description = "Fly at huge speed for 3s. Immune to attacks and offroad." },
	{ Id = "Laser", Name = "Orbital Laser", Icon = "🛰️", Rarity = "Mythic", Description = "A laser from space strikes the race leader." },
	{ Id = "BlackHole", Name = "Black Hole", Icon = "🕳️", Rarity = "Mythic", Description = "Drags back and stuns every racer ahead of you." },
}

Items.ById = {}
for _, item in Items.List do
	Items.ById[item.Id] = item
end

Items.Starter = { "Nitro", "Oil", "Rocket" }
Items.LoadoutSlots = 3 -- VIP pass adds one

function Items.ofRarity(rarity: string)
	local list = {}
	for _, item in Items.List do
		if item.Rarity == rarity then
			table.insert(list, item)
		end
	end
	return list
end

return Items
