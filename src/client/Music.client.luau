-- Background music (lobby / race / results), the engine loop and game-event sound
-- effects. Music + engine ids come from Config.Audio; effects are built-in sounds.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Sounds = require(Shared:WaitForChild("Sounds"))
local UI = require(Shared:WaitForChild("UI"))

local player = Players.LocalPlayer
local AUDIO = Config.Audio

-- Music ------------------------------------------------------------------------------------

local music = Instance.new("Sound")
music.Name = "Music"
music.Looped = true
music.Volume = AUDIO.MusicVolume
music.Parent = SoundService
local muted = false
local currentId = 0
local raceTrackId = 0

local function playMusic(id: number)
	if id == currentId then
		return
	end
	currentId = id
	local fadeOut = TweenService:Create(music, TweenInfo.new(0.6), { Volume = 0 })
	fadeOut:Play()
	fadeOut.Completed:Wait()
	music:Stop()
	if id ~= 0 and currentId == id then
		music.SoundId = "rbxassetid://" .. id
		music.Volume = 0
		music:Play()
		TweenService:Create(music, TweenInfo.new(1), { Volume = if muted then 0 else AUDIO.MusicVolume }):Play()
	end
end

local muteButton = UI.sideButton(player, "MUSIC", "🔊", 6)
local muteIcon
for _, child in muteButton:GetChildren() do
	if child:IsA("TextLabel") and child.Text == "🔊" then
		muteIcon = child
	end
end
muteButton.Activated:Connect(function()
	muted = not muted
	music.Volume = if muted then 0 else AUDIO.MusicVolume
	if muteIcon then
		muteIcon.Text = if muted then "🔇" else "🔊"
	end
end)

-- Engine loop ------------------------------------------------------------------------------

local engine: Sound? = nil
local function getCar()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	if seat and seat.Parent and seat.Parent:GetAttribute("IsRaceCar") then
		return seat.Parent, seat
	end
	return nil, nil
end

-- Event sounds -----------------------------------------------------------------------------

local lastCountdown = nil
local lastState = nil
RunService.Heartbeat:Connect(function()
	local state = workspace:GetAttribute("RaceState")
	local racing = player:GetAttribute("Place") ~= nil

	-- Countdown beeps and the GO! beep.
	if state == "Countdown" and racing then
		local remaining = math.ceil((workspace:GetAttribute("StateEndsAt") or 0) - workspace:GetServerTimeNow())
		if remaining ~= lastCountdown and remaining >= 1 and remaining <= 3 then
			lastCountdown = remaining
			Sounds.play("Beep", 1)
		end
	elseif state == "Racing" and lastState == "Countdown" and racing then
		Sounds.play("Beep", 1.6, 0.8)
		lastCountdown = nil
	end
	lastState = state

	-- Pick the music for what's happening.
	local wanted
	if state == "Results" and AUDIO.ResultsMusic ~= 0 then
		wanted = AUDIO.ResultsMusic
	elseif racing then
		if raceTrackId == 0 and #AUDIO.RaceMusic > 0 then
			raceTrackId = AUDIO.RaceMusic[math.random(1, #AUDIO.RaceMusic)]
		end
		wanted = raceTrackId
	else
		raceTrackId = 0
		wanted = AUDIO.LobbyMusic
	end
	if wanted ~= currentId then
		task.spawn(playMusic, wanted)
	end

	-- Engine loop follows your speed.
	local car, seat = getCar()
	if AUDIO.EngineLoop ~= 0 and car and car.PrimaryPart then
		if not engine or engine.Parent ~= car.PrimaryPart then
			if engine then
				engine:Destroy()
			end
			engine = Instance.new("Sound")
			engine.SoundId = "rbxassetid://" .. AUDIO.EngineLoop
			engine.Looped = true
			engine.Volume = AUDIO.EngineVolume
			engine.Parent = car.PrimaryPart
			engine:Play()
		end
		local top = car:GetAttribute("TopSpeed") or 100
		engine.PlaybackSpeed = 0.6 + math.clamp(seat.AssemblyLinearVelocity.Magnitude / top, 0, 1.6) * 0.9
	elseif engine then
		engine:Destroy()
		engine = nil
	end
end)

local previousItem = nil
player:GetAttributeChangedSignal("PowerUp"):Connect(function()
	local item = player:GetAttribute("PowerUp")
	if item and not previousItem then
		Sounds.play("Beep", 1.8, 0.5) -- picked up an item box
	elseif not item and previousItem and player:GetAttribute("Place") ~= nil then
		Sounds.play(if previousItem == "Rocket" or previousItem == "Laser" then "Rocket" else "Whoosh")
	end
	previousItem = item
end)

local previousReady = 0
player:GetAttributeChangedSignal("AbilityReadyAt"):Connect(function()
	local readyAt = player:GetAttribute("AbilityReadyAt") or 0
	if readyAt > previousReady then
		Sounds.play("Whoosh", 0.8) -- ability used
	end
	previousReady = readyAt
end)

player:GetAttributeChangedSignal("TurboCount"):Connect(function()
	local tier = player:GetAttribute("TurboTier") or 1
	Sounds.play("Whoosh", 1 + tier * 0.15)
end)

player:GetAttributeChangedSignal("Lap"):Connect(function()
	if player:GetAttribute("Place") ~= nil and (player:GetAttribute("Lap") or 1) > 1 then
		Sounds.play("Beep", 1.2)
		task.delay(0.15, Sounds.play, "Beep", 1.5)
	end
end)

local previousLevel = player:GetAttribute("Level") or 1
player:GetAttributeChangedSignal("Level"):Connect(function()
	local level = player:GetAttribute("Level") or 1
	if level > previousLevel then
		Sounds.play("Victory", 1.2)
	end
	previousLevel = level
end)

Remotes.Effect.OnClientEvent:Connect(function(kind)
	if kind == "Launch" then
		Sounds.play("Hit")
	elseif kind == "Rescue" then
		Sounds.play(if workspace:GetAttribute("TrackName") == "Coral Coast" then "Splash" else "Whoops")
	elseif kind == "Hop" or kind == "Leap" then
		Sounds.play("Jump")
	elseif kind == "Dash" then
		Sounds.play("Whoosh", 1.2)
	elseif kind == "Blink" then
		Sounds.play("Whoosh", 1.8)
	end
end)

Remotes.Notify.OnClientEvent:Connect(function(message)
	message = tostring(message)
	if message:find("🛢️") or message:find("📌") then
		Sounds.play("Splat")
	elseif message:find("Incoming rocket") or message:find("LOCKED ON") then
		Sounds.play("Beep", 0.6) -- warning
	end
end)

Remotes.Results.OnClientEvent:Connect(function()
	Sounds.play("Victory")
end)
