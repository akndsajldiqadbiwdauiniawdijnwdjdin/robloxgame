local Server = script.Parent

-- The game builds its own world. Remove the Baseplate template's floor and spawn: they
-- sit exactly at ground level and make the track textures flicker.
for _, name in { "Baseplate", "SpawnLocation" } do
	local leftover = workspace:FindFirstChild(name)
	if leftover and leftover:IsA("BasePart") then
		leftover:Destroy()
	end
end

-- Keep the camera close to the action: players can only zoom out a little.
local StarterPlayer = game:GetService("StarterPlayer")
local Players = game:GetService("Players")
StarterPlayer.CameraMaxZoomDistance = 30
StarterPlayer.CameraMinZoomDistance = 6
local function limitZoom(player: Player)
	player.CameraMaxZoomDistance = 30
	player.CameraMinZoomDistance = 6
end
Players.PlayerAdded:Connect(limitZoom)
for _, player in Players:GetPlayers() do
	limitZoom(player)
end

require(Server.PlayerData).init()
require(Server.Shop).init()
require(Server.Monetization).init()
require(Server.Spin).init()
require(Server.RaceManager).start()
