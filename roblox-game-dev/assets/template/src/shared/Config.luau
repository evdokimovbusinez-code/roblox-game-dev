--!strict
-- Shared, read-only game constants. Safe to expose to clients: NEVER put secrets or server-only tuning here.
-- Live-tunable values (event flags, balance numbers) belong in Roblox Configs (ConfigService), not in this file.

local Config = {
	GameName = "MyGame",

	-- Data ------------------------------------------------------------------------------------------------------
	-- Changing DataStoreName points the game at EMPTY data. Bump only for a deliberate wipe (use SCHEMA migrations otherwise).
	DataStoreName = "PlayerData_v1",
	-- Key = KeyPrefix .. UserId. Register the right-to-be-forgotten template "Player_{UserId}" in Creator Hub on day 1.
	KeyPrefix = "Player_",
	AutosaveSeconds = 300, -- ProfileStore default; never save per action
	PurchaseIdHistory = 100, -- ring buffer of processed receipt ids kept in the profile (every append-only list needs a cap)
	GrantHistory = 200, -- how many grant records are kept for refund reversal
	MaxInventoryItems = 200,

	-- Keys of PlayerData that are mirrored to the owning client (whitelist: never send PurchaseIds/Grants).
	ReplicatedKeys = { "Coins", "Inventory", "Settings" },

	-- Monetization -----------------------------------------------------------------------------------------------
	-- Placeholder ids. Create real products in Creator Hub (or via Open Cloud, see assets/automation) and paste them here.
	Products = {
		Coins1000 = 1111111,
		Coins10000 = 2222222,
	},
}

return table.freeze(Config)
