--!strict
-- Server side of the network layer: per-player token-bucket rate limiting + argument validators.
-- Contract for every client -> server remote:
--   1. The client sends an INTENT ("buy Flashlight"), never an outcome ("give me 100 coins").
--   2. Rate limit first (cheap), then validate types / ranges / enums, then ownership and state, then mutate.
--   3. Malformed input is dropped silently (no error messages for exploiters to probe), valid-but-denied input is
--      answered via a StateChanged correction.
-- Engine limit to remember: about 500 requests/s per client per remote type; excess reliable events are delayed,
-- excess unreliable events are dropped.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SharedRemotes = require(ReplicatedStorage.Shared.Remotes)

export type Limit = { capacity: number, refillPerSecond: number }
type Bucket = { tokens: number, last: number }

local buckets: { [string]: { [number]: Bucket } } = {}

local Remotes = {}

-- Validators ---------------------------------------------------------------------------------------------------------
-- Each returns the validated value or nil. `typeof(x) == "number"` is NOT enough: NaN and +-inf are numbers.
local check = {}

function check.number(value: unknown, min: number, max: number): number?
	if typeof(value) ~= "number" or not math.isfinite(value) then
		return nil
	end
	if value < min or value > max then
		return nil
	end
	return value
end

function check.integer(value: unknown, min: number, max: number): number?
	local number = check.number(value, min, max)
	if number == nil or number ~= math.floor(number) then
		return nil
	end
	return number
end

-- Valid UTF-8 and bounded length (in characters). Text shown to other players must ALSO go through Policy.filterForBroadcast.
function check.string(value: unknown, maxLength: number): string?
	if typeof(value) ~= "string" then
		return nil
	end
	local length = utf8.len(value)
	if length == nil or length > maxLength then
		return nil
	end
	return value
end

-- Whitelist lookup: returns the key if `allowed` has it. Never use client strings as table keys without this.
function check.key(value: unknown, allowed: { [string]: any }): string?
	if typeof(value) ~= "string" or allowed[value] == nil then
		return nil
	end
	return value
end

function check.boolean(value: unknown): boolean?
	if typeof(value) ~= "boolean" then
		return nil
	end
	return value
end

Remotes.check = check

-- Rate limiting -----------------------------------------------------------------------------------------------------
function Remotes.allow(name: string, userId: number, limit: Limit): boolean
	local perName = buckets[name]
	if perName == nil then
		perName = {}
		buckets[name] = perName
	end
	local now = os.clock()
	local bucket = perName[userId]
	if bucket == nil then
		bucket = { tokens = limit.capacity, last = now }
		perName[userId] = bucket
	end
	bucket.tokens = math.min(limit.capacity, bucket.tokens + (now - bucket.last) * limit.refillPerSecond)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

-- Wiring ------------------------------------------------------------------------------------------------------------
-- Connect a handler to a client -> server remote with rate limiting and error isolation.
-- The handler receives raw `unknown` arguments and MUST validate them with Remotes.check.*.
function Remotes.listen(name: SharedRemotes.RemoteName, limit: Limit, handler: (player: Player, ...unknown) -> ())
	local remote = SharedRemotes.get(name)
	remote.OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not Remotes.allow(name, player.UserId, limit) then
			return
		end
		local ok: boolean, err: any = pcall(handler, player, ...)
		if not ok then
			warn(`[Remotes] handler for {name} failed: {err}`)
		end
	end)
end

-- Server -> client. Send deltas, not whole inventories.
function Remotes.send(name: SharedRemotes.RemoteName, player: Player, ...: any)
	SharedRemotes.get(name):FireClient(player, ...)
end

function Remotes.init()
	SharedRemotes.createAll()
end

function Remotes.start()
	Players.PlayerRemoving:Connect(function(player)
		for _, perName in buckets do
			perName[player.UserId] = nil
		end
	end)
end

return Remotes
