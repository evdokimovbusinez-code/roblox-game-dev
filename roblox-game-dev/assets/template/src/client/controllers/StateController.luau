--!strict
-- Client-side mirror of the server's PlayerData (read-only for gameplay code). The client NEVER computes rewards or
-- prices: it renders what the server sent and sends intents back.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local state: { [string]: any } = {}
local changed = Instance.new("BindableEvent")

local StateController = {}

-- Fires (key, value) whenever the server replicates a key.
StateController.Changed = changed.Event

function StateController.get(key: string): any
	return state[key]
end

-- Calls `fn` with the current value (if already known) and again on every change.
function StateController.observe(key: string, fn: (value: any) -> ()): RBXScriptConnection
	if state[key] ~= nil then
		task.spawn(fn, state[key])
	end
	return changed.Event:Connect(function(changedKey: string, value: any)
		if changedKey == key then
			fn(value)
		end
	end)
end

function StateController.start()
	Remotes.get("StateChanged").OnClientEvent:Connect(function(key: unknown, value: unknown)
		if typeof(key) == "string" then
			state[key] = value
			changed:Fire(key, value)
		end
	end)
	-- Handshake AFTER the listener exists, so the initial state cannot be missed.
	Remotes.get("ClientReady"):FireServer()
end

return StateController
