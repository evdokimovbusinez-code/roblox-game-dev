--!strict
-- Persistent player data: ProfileStore session locking + schema migrations + autosave + shutdown flush + replication.
--
-- Guarantees (what ProfileStore gives you, do not re-implement):
--   * one live session per key across all servers (session lock), stolen only after a conflict timeout / dead server
--   * autosave every Config.AutosaveSeconds, final save on EndSession and on server shutdown
--   * Profile:IsActive() is only guaranteed until your code yields: re-check after any yield before mutating.
-- Rules this module enforces:
--   * key = "Player_" .. UserId (compatible with right-to-be-forgotten templates)
--   * migrations run BEFORE Reconcile (Reconcile would stamp the new SchemaVersion on old data and skip them)
--   * if the profile fails to load the player is KICKED, never given default data that could overwrite a real save
--   * no per-action saves; call profile:Save() only after purchases and trades

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local Types = require(ReplicatedStorage.Shared.Types)
local Remotes = require(script.Parent.Remotes)

-- Minimal structural types for the ProfileStore package (lm-loleris/profilestore 1.0.x). The package ships its own
-- generic types, but a local contract keeps this module independent of them and of the stub in analysis/.
type Connection = { Disconnect: (self: Connection) -> () }
type Signal = { Connect: (self: Signal, listener: () -> ()) -> Connection }
type SaveSignal = { Connect: (self: SaveSignal, listener: (lastSaved: Types.PlayerData) -> ()) -> Connection }

export type Profile = {
	Data: Types.PlayerData,
	LastSavedData: Types.PlayerData,
	OnSessionEnd: Signal,
	OnAfterSave: SaveSignal,
	IsActive: (self: Profile) -> boolean,
	Reconcile: (self: Profile) -> (),
	EndSession: (self: Profile) -> (),
	AddUserId: (self: Profile, userId: number) -> (),
	Save: (self: Profile) -> (),
}

type StartParams = { Steal: boolean?, Cancel: (() -> boolean)? }
type Store = {
	StartSessionAsync: (self: Store, key: string, params: StartParams?) -> Profile?,
}
type ProfileStoreModule = {
	New: (name: string, template: Types.PlayerData) -> Store,
	SetConstant: (name: string, value: number) -> (),
}

-- Wally server-dependency (ServerScriptService.ServerPackages). Cast through any: the package's own types differ slightly.
local ProfileStore = (require(ServerScriptService.ServerPackages.ProfileStore) :: any) :: ProfileStoreModule

local SCHEMA_VERSION = 1

-- Default data for a new player. Every field of Types.PlayerData must appear here.
local TEMPLATE: Types.PlayerData = {
	SchemaVersion = SCHEMA_VERSION,
	Coins = 0,
	Inventory = {},
	Settings = { Music = true },
	PurchaseIds = {},
	Grants = {},
}

-- MIGRATIONS[n] upgrades data from version n to n + 1. Must be idempotent and must never delete data that
-- older server versions still read (during a rollout both versions run side by side).
-- Example for the day the Inventory format changes (v1 -> v2):
--   [1] = function(data) for id, item in data.Inventory do item.locked = item.locked or false end end,
local MIGRATIONS: { [number]: (data: any) -> () } = {}

local function migrate(data: any)
	if next(data) == nil then
		data.SchemaVersion = SCHEMA_VERSION -- brand-new profile: nothing to migrate
		return
	end
	local version: number = data.SchemaVersion or 1
	while version < SCHEMA_VERSION do
		local step = MIGRATIONS[version]
		if step then
			step(data)
		end
		version += 1
		data.SchemaVersion = version
	end
end

local store: Store
local profiles: { [Player]: Profile } = {}
local loadedEvent = Instance.new("BindableEvent")

local PlayerData = {}

-- Fires (player, profile) once a profile is loaded, migrated and ready.
PlayerData.Loaded = loadedEvent.Event

-- The active profile of a player, or nil (not loaded yet / session ended).
function PlayerData.get(player: Player): Profile?
	local profile = profiles[player]
	if profile ~= nil and profile:IsActive() then
		return profile
	end
	return nil
end

-- Yields until the profile is loaded or the player leaves.
function PlayerData.waitFor(player: Player): Profile?
	while profiles[player] == nil and player.Parent == Players do
		task.wait(0.1)
	end
	return PlayerData.get(player)
end

-- Send ONE key of the player's data to the player. Only whitelisted keys (Config.ReplicatedKeys) ever leave the server.
function PlayerData.replicate(player: Player, key: string)
	local profile = PlayerData.get(player)
	if profile == nil or table.find(Config.ReplicatedKeys, key) == nil then
		return
	end
	local data: { [string]: any } = profile.Data :: any
	Remotes.send("StateChanged", player, key, data[key])
end

function PlayerData.replicateAll(player: Player)
	for _, key in Config.ReplicatedKeys do
		PlayerData.replicate(player, key)
	end
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(Config.KeyPrefix .. player.UserId, {
		-- Stop waiting for the session lock if the player already left.
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Load failed or was cancelled. Never continue with default data: the next autosave could wipe a real save.
		if player.Parent == Players then
			player:Kick("Your data could not be loaded. Please rejoin.")
		end
		return
	end

	profile:AddUserId(player.UserId) -- associates the profile with the user (right to be forgotten)
	migrate(profile.Data) -- MUST come before Reconcile
	profile:Reconcile() -- fills fields added since the player's last visit

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		if player.Parent == Players then
			player:Kick("Your session ended (it was opened on another server). Please rejoin.")
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession() -- left while loading
		return
	end

	profiles[player] = profile
	loadedEvent:Fire(player, profile)
end

function PlayerData.init()
	ProfileStore.SetConstant("AUTO_SAVE_PERIOD", Config.AutosaveSeconds)
	store = ProfileStore.New(Config.DataStoreName, TEMPLATE)
end

function PlayerData.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local profile = profiles[player]
		if profile ~= nil then
			profile:EndSession() -- final save + releases the session lock
		end
	end)

	-- Client handshake: once the client's controllers are connected, send the initial state.
	Remotes.listen("ClientReady", { capacity = 2, refillPerSecond = 0.1 }, function(player)
		if PlayerData.waitFor(player) ~= nil then
			PlayerData.replicateAll(player)
		end
	end)

	-- ProfileStore installs its own BindToClose; this one makes the intent explicit and bounded (the engine gives
	-- ~30 s): end every session (= final save), then wait until all of them are gone.
	game:BindToClose(function()
		for _, profile in profiles do
			profile:EndSession()
		end
		local deadline = os.clock() + 25
		while next(profiles) ~= nil and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

-- Used by tests and by services that need a fresh GUID for an item record.
function PlayerData.newId(): string
	return HttpService:GenerateGUID(false)
end

return PlayerData
