-- Race loop: Intermission -> Countdown -> Racing -> Results -> next track.
-- Public state lives in workspace attributes (RaceState, StateEndsAt, RacerCount,
-- TrackName, Laps) and player attributes (Place, Lap, PowerUp) for the HUD.
--
-- Progress: each racer has a Sample (index along the track's centre line). Every tick it
-- can only move FORWARD to the nearest sample within Config.Track.ProgressSearch, so
-- shortcuts work but driving backwards over the line never counts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CarBuilder = require(script.Parent.CarBuilder)
local Lobby = require(script.Parent.Lobby)
local PlayerData = require(script.Parent.PlayerData)
local PowerUps = require(script.Parent.PowerUps)
local TrackBuilder = require(script.Parent.TrackBuilder)

local RaceManager = {}

local RACE = Config.Race
local TRACK = Config.Track
local TRACK_ORDER = { "Downtown", "Canyon", "NeonHighway" }

local track
local carsFolder: Folder
local currentRace -- nil between races

local function setState(name: string, duration: number?)
	workspace:SetAttribute("RaceState", name)
	workspace:SetAttribute("StateEndsAt", if duration then workspace:GetServerTimeNow() + duration else 0)
end

local function flatDistance(a: Vector3, b: Vector3): number
	local d = a - b
	return Vector3.new(d.X, 0, d.Z).Magnitude
end

local function formatTime(seconds: number): string
	return string.format("%d:%05.2f", seconds // 60, seconds % 60)
end

local function notify(player: Player, text: string, duration: number?, big: boolean?)
	if player.Parent then
		Remotes.Notify:FireClient(player, text, duration or 2.5, big)
	end
end

local function notifyAll(text: string, duration: number?, big: boolean?)
	Remotes.Notify:FireAllClients(text, duration or 2.5, big)
end

local function markOut(racer)
	if not racer.Active then
		return
	end
	racer.Active = false
	racer.Out = true
	PowerUps.give(racer, nil)
	racer.Car:Destroy()
end

local function updateStandings(race)
	local samples = track.Samples
	local count = #samples
	for _, racer in race.Ordered do
		if racer.Finished then
			racer.Score = 1e12 - racer.FinishPlace
		elseif racer.Out then
			racer.Score = -1e12
		else
			local nextSample = samples[racer.Sample % count + 1]
			racer.Score = (racer.Lap * count + racer.Sample) * 1000 - flatDistance(racer.Chassis.Position, nextSample.Position)
		end
	end
	table.sort(race.Ordered, function(a, b)
		return a.Score > b.Score
	end)
	for place, racer in race.Ordered do
		racer.Place = place
		if racer.Player.Parent then
			racer.Player:SetAttribute("Place", place)
			racer.Player:SetAttribute("Lap", math.clamp(racer.Lap, 1, track.Laps))
		end
	end
	workspace:SetAttribute("RacerCount", #race.Ordered)
end

local function resetCar(racer)
	local sample = track.Samples[racer.Sample]
	local halfHeight = racer.Car:GetAttribute("HalfHeight")
	local position = sample.Position + Vector3.new(0, halfHeight + 1.5, 0)
	racer.Car:PivotTo(CFrame.lookAt(position, position + sample.Forward))
	Remotes.Effect:FireClient(racer.Player, "Stop")
end

local function finish(race, racer)
	race.FinishedCount += 1
	racer.Finished = true
	racer.Active = false
	racer.FinishPlace = race.FinishedCount
	racer.FinishTime = os.clock() - race.StartClock
	racer.Car:SetAttribute("Locked", true)
	PowerUps.give(racer, nil)
	notifyAll(string.format("🏁 %s finished #%d (%s)", racer.Player.DisplayName, racer.FinishPlace, formatTime(racer.FinishTime)), 4)

	if race.FinishedCount == 1 then
		race.Deadline = math.min(race.Deadline, os.clock() + RACE.FinishGraceTime)
		setState("Racing", race.Deadline - os.clock())
	end
end

local function updateRacer(race, racer)
	if not racer.Player.Parent or not racer.Chassis.Parent or racer.Humanoid.Health <= 0 then
		markOut(racer)
		return
	end

	local samples = track.Samples
	local count = #samples
	local position = racer.Chassis.Position

	-- Fell off the track (gorge, highway edge, out of the world).
	if position.Y < samples[racer.Sample].Position.Y - TRACK.FallDistance then
		resetCar(racer)
		notify(racer.Player, "Whoops! Back on track.", 1.5)
		return
	end

	-- Nearest sample ahead (height counts double, so bridges and underpasses don't mix).
	local bestOffset, bestDistance = nil, track.Width * 1.25
	for offset = 0, TRACK.ProgressSearch do
		local sample = samples[(racer.Sample - 1 + offset) % count + 1]
		local distance = flatDistance(position, sample.Position) + math.abs(position.Y - sample.Position.Y) * 2
		if distance < bestDistance then
			bestOffset, bestDistance = offset, distance
		end
	end
	if not bestOffset or bestOffset == 0 then
		return
	end

	local newIndex = racer.Sample + bestOffset
	if newIndex > count then
		newIndex -= count
		racer.Lap += 1
		if racer.Lap > track.Laps then
			racer.Sample = newIndex
			finish(race, racer)
			return
		end
		if racer.Lap > 1 then
			notify(racer.Player, if racer.Lap == track.Laps then "FINAL LAP!" else "LAP " .. racer.Lap, 1.5, true)
		end
	end
	racer.Sample = newIndex
end

local function spawnRacers(race, participants)
	for _, player in participants do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local data = PlayerData.get(player)
		if humanoid and humanoid.Health > 0 and data then
			local slot = #race.Ordered + 1
			local ground, sampleIndex = track.Grid(slot)
			local car = CarBuilder.build(player, data.Equipped, data.Upgrades, ground, carsFolder)
			local chassis = car.PrimaryPart
			local seat = car.DriverSeat
			chassis.Anchored = true -- frozen until the countdown ends
			seat:Sit(humanoid)

			local racer = {
				Player = player,
				Car = car,
				Chassis = chassis,
				Humanoid = humanoid,
				Lap = 0, -- becomes 1 when they cross the start line
				Sample = sampleIndex,
				Place = slot,
				Score = 0,
				Steals = 0,
				Active = true,
				Finished = false,
				Out = false,
				PowerUp = nil,
				LastReset = 0,
			}

			-- Jumping out of the car isn't allowed mid-race: put them back in.
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				if seat.Occupant == nil and racer.Active then
					task.delay(0.25, function()
						if racer.Active and seat.Parent and seat.Occupant == nil and humanoid.Health > 0 then
							seat:Sit(humanoid)
						end
					end)
				end
			end)
			humanoid.Died:Connect(function()
				markOut(racer)
			end)

			race.Racers[player] = racer
			table.insert(race.Ordered, racer)
		end
	end
	race.Count = #race.Ordered
end

local function giveRewards(race)
	local rewards = Config.Rewards
	local lines = { "🏆 RESULTS — " .. track.Name }
	for place, racer in race.Ordered do
		local reward = if racer.Finished then rewards.Placement[place] or rewards.Finish else rewards.DNF
		reward += racer.Steals * rewards.PerSteal

		if racer.Player.Parent and PlayerData.get(racer.Player) then
			local earned = PlayerData.addCash(racer.Player, reward)
			PlayerData.update(racer.Player, function(data)
				data.Races += 1
				-- Solo races don't count as wins, so wins can't be farmed alone.
				if place == 1 and racer.Finished and race.Count >= 2 then
					data.Wins += 1
				end
			end)
			notify(racer.Player, "+$" .. earned, 5, true)
		end
		local result = if racer.Finished then formatTime(racer.FinishTime) else "DNF"
		table.insert(lines, string.format("%d. %s  %s", place, racer.Player.DisplayName, result))
	end
	notifyAll(table.concat(lines, "\n"), RACE.ResultsTime)
end

local function cleanup(race)
	currentRace = nil
	for _, racer in race.Ordered do
		racer.Active = false
		if racer.Car.Parent then
			racer.Car:Destroy()
		end
		local player = racer.Player
		if player.Parent then
			player:SetAttribute("Place", nil)
			player:SetAttribute("Lap", nil)
			player:SetAttribute("PowerUp", nil)
			player:LoadCharacter() -- back to the lobby
		end
	end
	workspace:SetAttribute("RacerCount", 0)
	PowerUps.reset(track)
end

local function runRace(race, participants)
	spawnRacers(race, participants)
	if race.Count == 0 then
		return
	end
	updateStandings(race)

	setState("Countdown", RACE.CountdownTime)
	task.wait(RACE.CountdownTime)

	for _, racer in race.Ordered do
		if racer.Active then
			racer.Chassis.Anchored = false
			-- The driver simulates their own car so steering feels instant.
			pcall(racer.Chassis.SetNetworkOwner, racer.Chassis, racer.Player)
			racer.Car:SetAttribute("Locked", false)
		end
	end
	race.StartClock = os.clock()
	race.Deadline = race.StartClock + RACE.MaxRaceTime
	setState("Racing", RACE.MaxRaceTime)
	notifyAll("GO!", 1.2, true)

	while os.clock() < race.Deadline do
		task.wait(0.1)
		local anyActive = false
		for _, racer in race.Ordered do
			if racer.Active then
				updateRacer(race, racer)
				anyActive = anyActive or racer.Active
			end
		end
		if not anyActive then
			break
		end
		PowerUps.update(race)
		updateStandings(race)
	end

	for _, racer in race.Ordered do
		racer.Active = false
	end
	updateStandings(race)
	giveRewards(race)
	setState("Results", RACE.ResultsTime)
	task.wait(RACE.ResultsTime)
end

local trackIndex = 0
local function loadNextTrack()
	trackIndex = trackIndex % #TRACK_ORDER + 1
	local def = require(script.Parent.Tracks[TRACK_ORDER[trackIndex]])
	if track then
		PowerUps.reset(track) -- clear leftovers from the previous track first
	end
	track = TrackBuilder.build(def)
	workspace:SetAttribute("TrackName", track.Name)
	workspace:SetAttribute("Laps", track.Laps)
end

function RaceManager.start()
	Lobby.build()

	carsFolder = Instance.new("Folder")
	carsFolder.Name = "RaceCars"
	carsFolder.Parent = workspace
	PowerUps.init(carsFolder)

	local function activeRacer(player: Player)
		local race = currentRace
		local racer = race and race.Racers[player]
		if racer and racer.Active and workspace:GetAttribute("RaceState") == "Racing" then
			return race, racer
		end
		return nil, nil
	end

	Remotes.UsePowerUp.OnServerEvent:Connect(function(player)
		local race, racer = activeRacer(player)
		if racer then
			PowerUps.use(race, racer)
		end
	end)

	Remotes.ResetCar.OnServerEvent:Connect(function(player)
		local _, racer = activeRacer(player)
		if racer and os.clock() - racer.LastReset >= RACE.ResetCooldown then
			racer.LastReset = os.clock()
			resetCar(racer)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local racer = currentRace and currentRace.Racers[player]
		if racer then
			markOut(racer)
		end
	end)

	task.spawn(function()
		local needTrack = true
		while true do
			if needTrack then
				loadNextTrack()
				needTrack = false
			end
			setState("Intermission", RACE.IntermissionTime)
			task.wait(RACE.IntermissionTime)

			local participants = {}
			for _, player in Players:GetPlayers() do
				if #participants < RACE.MaxPlayers and player.Character and PlayerData.get(player) then
					table.insert(participants, player)
				end
			end

			if #participants >= RACE.MinPlayers then
				local race = { Racers = {}, Ordered = {}, Track = track, FinishedCount = 0, Count = 0 }
				currentRace = race
				local ok, err = pcall(runRace, race, participants)
				if not ok then
					warn("[RaceManager] Race crashed:", err)
				end
				cleanup(race)
				needTrack = true
			end
		end
	end)
end

return RaceManager
