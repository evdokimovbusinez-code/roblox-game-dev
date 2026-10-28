--!strict
-- Example of a correct client -> server purchase with SOFT currency (the pattern for every gameplay remote):
-- rate limit -> validate -> check state -> mutate (no yields between check and mutate) -> replicate -> log.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Analytics = require(script.Parent.Analytics)
local PlayerData = require(script.Parent.PlayerData)
local Remotes = require(script.Parent.Remotes)

-- The server owns the catalog and the prices. The client only ever sends the item NAME.
local CATALOG: { [string]: { price: number } } = {
	Flashlight = { price = 100 },
	SpeedCoil = { price = 250 },
}

local Shop = {}

local function countItems(inventory: { [string]: any }): number
	local count = 0
	for _ in inventory do
		count += 1
	end
	return count
end

local function buy(player: Player, rawItem: unknown)
	local itemName = Remotes.check.key(rawItem, CATALOG)
	if itemName == nil then
		return -- malformed or unknown: drop silently
	end
	local profile = PlayerData.get(player)
	if profile == nil then
		return
	end
	local data = profile.Data
	local price = CATALOG[itemName].price
	if data.Coins < price or countItems(data.Inventory) >= Config.MaxInventoryItems then
		PlayerData.replicate(player, "Coins") -- resync the client's view instead of trusting it
		return
	end

	-- check passed; mutate without yielding
	data.Coins -= price
	local id = PlayerData.newId()
	data.Inventory[id] = { id = id, kind = itemName, createdAt = os.time() }

	PlayerData.replicate(player, "Coins")
	PlayerData.replicate(player, "Inventory")
	Analytics.economy(
		player,
		Enum.AnalyticsEconomyFlowType.Sink,
		"Coins",
		price,
		data.Coins,
		Enum.AnalyticsEconomyTransactionType.Shop,
		itemName
	)
end

function Shop.start()
	Remotes.listen("BuyItem", { capacity = 5, refillPerSecond = 1 }, buy)
	-- Rate-limit buckets are cleaned up per player in services/Remotes.
end

return Shop
