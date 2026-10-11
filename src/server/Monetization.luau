-- Robux purchases: game passes (Config.Passes) and developer products (Config.Store:
-- coins, spins and item rolls). Owned passes show up as player attributes "Pass_<Key>".
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Monetization = {}

local productsById = {}
for _, item in Config.Store do
	if item.ProductId ~= 0 then
		productsById[item.ProductId] = item
	end
end

local function checkPasses(player: Player)
	for _, pass in Config.Passes do
		if pass.PassId ~= 0 then
			local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.PassId)
			if ok and owns then
				player:SetAttribute("Pass_" .. pass.Key, true)
			end
		end
	end
end

function Monetization.init()
	Players.PlayerAdded:Connect(checkPasses)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPasses, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		for _, pass in Config.Passes do
			if pass.PassId == passId then
				player:SetAttribute("Pass_" .. pass.Key, true)
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		local item = productsById[receipt.ProductId]
		if not (player and item and PlayerData.get(player)) then
			-- Roblox retries later (e.g. next time the player joins).
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		PlayerData.update(player, function(data)
			if data.Purchases[receipt.PurchaseId] then
				return -- already granted (Roblox can resend receipts)
			end
			data.Purchases[receipt.PurchaseId] = true
			if item.Kind == "Cash" then
				data.Cash += item.Amount
			elseif item.Kind == "Spins" then
				data.Spins += item.Amount
			elseif item.Kind == "Rolls" then
				data.RollTokens += item.Amount
			end
		end)
		PlayerData.save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Monetization
