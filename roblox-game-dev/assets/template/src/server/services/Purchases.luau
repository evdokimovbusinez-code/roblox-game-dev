--!strict
-- Developer Product fulfilment. ONE receipt handler for the whole game, idempotent, durable.
--
-- Contract (MarketplaceService):
--   * Processed  = "granted AND durably saved"; NotProcessedYet = "try again later" (redelivered on rejoin / next purchase).
--   * The handler MAY yield (no timeout while the server runs); the grant function itself must NOT yield.
--   * The same receipt can be delivered to two servers at once (rejoin race) -> PurchaseId is checked against the
--     session-locked profile, so a duplicate can never grant twice.
--   * Not registering any handler auto-acknowledges purchases and they cannot be recovered. Register early (Main.server).
-- Rewarded-video ads pay out through the same path (ProductPurchaseChannel = "AdReward"), never from the ad result.
-- Roblox audits this handler on an ongoing basis; a broken one removes the product from external surfaces.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local Analytics = require(script.Parent.Analytics)
local PlayerData = require(script.Parent.PlayerData)

export type Receipt = {
	PurchaseId: string,
	PlayerId: number,
	ProductId: number,
	CurrencySpent: number,
	ProductPurchaseChannel: any,
}

-- Grants mutate profile data in memory only: no yields, no DataStore calls, no remotes inside.
type Grant = (data: Types.PlayerData) -> ()

local SAVE_CONFIRM_TIMEOUT = 60

-- productId -> grant. Add one entry per product. Keep a matching reversal for refunds (see code-architecture.md).
local GRANTS: { [number]: Grant } = {
	[Config.Products.Coins1000] = function(data)
		data.Coins += 1000
	end,
	[Config.Products.Coins10000] = function(data)
		data.Coins += 10000
	end,
}

local function isDurablySaved(profile: PlayerData.Profile, purchaseId: string): boolean
	return table.find(profile.LastSavedData.PurchaseIds, purchaseId) ~= nil
end

-- Returns true only when the purchase is granted and written to the DataStore.
local function fulfil(receipt: Receipt): boolean
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if player == nil then
		return false -- player left: the receipt is redelivered when they rejoin
	end
	local profile = PlayerData.waitFor(player)
	if profile == nil then
		return false
	end

	local data = profile.Data
	if table.find(data.PurchaseIds, receipt.PurchaseId) == nil then
		local grant = GRANTS[receipt.ProductId]
		if grant == nil then
			warn(`[Purchases] no grant registered for product {receipt.ProductId}`)
			return false
		end
		local ok: boolean, err: any = pcall(grant, data)
		if not ok then
			warn(`[Purchases] grant failed: {err}`)
			return false
		end
		-- Idempotency record + refund-reversal record, both capped.
		table.insert(data.PurchaseIds, receipt.PurchaseId)
		while #data.PurchaseIds > Config.PurchaseIdHistory do
			table.remove(data.PurchaseIds, 1)
		end
		data.Grants[receipt.PurchaseId] =
			{ productId = receipt.ProductId, at = os.time(), robux = receipt.CurrencySpent }
		PlayerData.replicate(player, "Coins")
		Analytics.economy(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Robux",
			receipt.CurrencySpent,
			0,
			Enum.AnalyticsEconomyTransactionType.IAP,
			tostring(receipt.ProductId)
		)
	end

	-- Acknowledge only once the PurchaseId is in LastSavedData. Poll (not OnAfterSave:Wait) so a failing DataStore
	-- cannot hang this thread forever.
	local deadline = os.clock() + SAVE_CONFIRM_TIMEOUT
	local nextSave = 0
	while not isDurablySaved(profile, receipt.PurchaseId) do
		if not profile:IsActive() or os.clock() > deadline then
			return false
		end
		if os.clock() >= nextSave then
			profile:Save()
			nextSave = os.clock() + 10
		end
		task.wait(0.5)
	end
	return true
end

local Purchases = {}

function Purchases.start()
	-- BindReceiptHandler (2026) is the preferred API; a bound catch-all takes precedence over ProcessReceipt.
	-- Cast: older Roblox type definitions (luau-lsp globalTypes) do not know the method yet.
	(MarketplaceService :: any):BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, function(receipt: Receipt)
		if fulfil(receipt) then
			return Enum.ReceiptDecision.Processed
		end
		return Enum.ReceiptDecision.NotProcessedYet
	end)

	-- Legacy alternative (exactly ONE ProcessReceipt in the whole game, do not combine with the call above):
	-- MarketplaceService.ProcessReceipt = function(receipt)
	-- 	return if fulfil(receipt) then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
	-- end
end

return Purchases
