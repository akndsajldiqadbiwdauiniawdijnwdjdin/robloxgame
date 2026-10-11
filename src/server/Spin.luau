-- Daily spin wheel. The server picks the prize; the client only animates the wheel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cars = require(ReplicatedStorage.Shared.Cars)
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerData = require(script.Parent.PlayerData)

local Spin = {}

local busy = {}

local function pickPrize(): number
	local total = 0
	for _, prize in Config.Spin.Prizes do
		total += prize.Weight
	end
	local roll = math.random() * total
	for index, prize in Config.Spin.Prizes do
		roll -= prize.Weight
		if roll <= 0 then
			return index
		end
	end
	return 1
end

-- Gives the prize and returns a message for the player.
local function award(player: Player, prize): string
	if prize.Kind == "Cash" then
		PlayerData.update(player, function(data)
			data.Cash += prize.Amount
		end)
		return "You won $" .. prize.Amount .. "!"
	elseif prize.Kind == "Spin" then
		PlayerData.update(player, function(data)
			data.Spins += prize.Amount
		end)
		return "You won an extra spin!"
	elseif prize.Kind == "Car" then
		local data = PlayerData.get(player)
		local unowned = {}
		for _, car in Cars.List do
			if not data.OwnedCars[car.Id] then
				table.insert(unowned, car)
			end
		end
		if #unowned == 0 then
			PlayerData.update(player, function(d)
				d.Cash += 10000
			end)
			return "You own every car, so here's $10,000!"
		end
		local car = unowned[math.random(1, #unowned)]
		PlayerData.update(player, function(d)
			d.OwnedCars[car.Id] = true
		end)
		return "MYSTERY CAR: you won the " .. car.Name .. "!"
	end
	return ""
end

function Spin.init()
	Remotes.Spin.OnServerInvoke = function(player)
		local data = PlayerData.get(player)
		if not data then
			return false, "Data not loaded yet"
		end
		if busy[player] then
			return false, "Already spinning"
		end

		local now = os.time()
		local free = now - data.LastFreeSpin >= Config.Spin.Cooldown
		if not free and data.Spins <= 0 then
			return false, "No spins left. Come back tomorrow or grab more in the store!"
		end

		busy[player] = true
		PlayerData.update(player, function(d)
			if free then
				d.LastFreeSpin = now
			else
				d.Spins -= 1
			end
		end)
		local index = pickPrize()
		-- Pay out after the wheel animation has had time to finish.
		task.delay(4.2, function()
			busy[player] = nil
			if player.Parent and PlayerData.get(player) then
				local message = award(player, Config.Spin.Prizes[index])
				Remotes.Notify:FireClient(player, "🎡 " .. message, 4)
				PlayerData.save(player)
			end
		end)
		return true, index
	end

	game:GetService("Players").PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return Spin
