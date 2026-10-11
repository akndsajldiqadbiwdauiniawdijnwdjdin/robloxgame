-- Robux purchases: the 2x Cash game pass and the store's developer products (cash and
-- spin packs). IDs live in Config.Monetization and Config.Store.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(script.Parent.PlayerData)

local Monetization = {}

local PASS_ID = Config.Monetization.DoubleCashPassId

local productsById = {}
for _, item in Config.Store do
	if item.ProductId ~= 0 then
		productsById[item.ProductId] = item
	end
end

local function checkPass(player: Player)
	if PASS_ID == 0 then
		return
	end
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, PASS_ID)
	if ok and owns then
		player:SetAttribute("DoubleCash", true)
	end
end

function Monetization.init()
	Players.PlayerAdded:Connect(checkPass)
	for _, player in Players:GetPlayers() do
		task.spawn(checkPass, player)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased and passId == PASS_ID then
			player:SetAttribute("DoubleCash", true)
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
			end
		end)
		PlayerData.save(player)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Monetization
