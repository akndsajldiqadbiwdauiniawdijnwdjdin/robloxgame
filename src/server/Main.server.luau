local Server = script.Parent

-- The game builds its own world. Remove the Baseplate template's floor and spawn: they
-- sit exactly at ground level and make the track textures flicker.
for _, name in { "Baseplate", "SpawnLocation" } do
	local leftover = workspace:FindFirstChild(name)
	if leftover and leftover:IsA("BasePart") then
		leftover:Destroy()
	end
end

require(Server.PlayerData).init()
require(Server.Shop).init()
require(Server.Monetization).init()
require(Server.Spin).init()
require(Server.RaceManager).start()
