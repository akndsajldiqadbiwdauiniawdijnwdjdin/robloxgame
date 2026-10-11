-- Lobby emotes (press B). Animation ids are Roblox's built-in R15 emotes; swap in your own
-- uploaded animations for custom ones.
local Emotes = {}

Emotes.List = {
	{ Id = "Wave", Name = "Wave", Animation = "rbxassetid://507770239", Price = 0 },
	{ Id = "Point", Name = "Point", Animation = "rbxassetid://507770453", Price = 0 },
	{ Id = "Cheer", Name = "Glad", Animation = "rbxassetid://507770677", Price = 0 },
	{ Id = "Laugh", Name = "Laugh", Animation = "rbxassetid://507770818", Price = 500 },
	{ Id = "Dance", Name = "Groove", Animation = "rbxassetid://507771019", Price = 1000 },
	{ Id = "Dance2", Name = "Shuffle", Animation = "rbxassetid://507776043", Price = 1500 },
	{ Id = "Dance3", Name = "Floss-ish", Animation = "rbxassetid://507777268", Price = 2500 },
}

Emotes.ById = {}
for _, emote in Emotes.List do
	Emotes.ById[emote.Id] = emote
end

Emotes.Starter = { "Wave", "Point", "Cheer" }

return Emotes
