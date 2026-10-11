-- Client sound effects. Uses Roblox's built-in engine sounds (rbxasset://sounds/...),
-- which ship with every Roblox client, so they work without uploading anything.
-- Music and the engine loop use asset ids from Config.Audio (see Music.client.luau).
local SoundService = game:GetService("SoundService")

local Sounds = {}

local LIBRARY = {
	Click = { Id = "rbxasset://sounds/clickfast.wav", Volume = 0.5 },
	Beep = { Id = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.6 },
	Whoosh = { Id = "rbxasset://sounds/swoosh.wav", Volume = 0.7 },
	Rocket = { Id = "rbxasset://sounds/Rocket shot.wav", Volume = 0.6 },
	Hit = { Id = "rbxasset://sounds/collide.wav", Volume = 0.8 },
	Splat = { Id = "rbxasset://sounds/splat.wav", Volume = 0.7 },
	Victory = { Id = "rbxasset://sounds/victory.wav", Volume = 0.6 },
	Jump = { Id = "rbxasset://sounds/action_jump.mp3", Volume = 0.6 },
	Splash = { Id = "rbxasset://sounds/impact_water.mp3", Volume = 0.8 },
	Whoops = { Id = "rbxasset://sounds/uuhhh.mp3", Volume = 0.5 },
}

local cache = {}

-- Plays a named effect. pitch 1 = normal.
function Sounds.play(name: string, pitch: number?, volume: number?)
	local entry = LIBRARY[name]
	if not entry then
		return
	end
	local sound = cache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "Sfx_" .. name
		sound.SoundId = entry.Id
		sound.Parent = SoundService
		cache[name] = sound
	end
	sound.PlaybackSpeed = pitch or 1
	sound.Volume = volume or entry.Volume
	SoundService:PlayLocalSound(sound)
end

return Sounds
