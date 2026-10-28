--!strict
-- Remote definitions, shared by server and client. The SERVER creates every remote at boot (Remotes.createAll),
-- the client only waits for them. Names are a closed union so typos fail in the analyzer, not in production.
--
-- Direction conventions (traffic in the wrong direction is a tamper signal):
--   StateChanged  server -> client   (key, value)        replicate one PlayerData key
--   ClientReady   client -> server   ()                  "my controllers are connected, send me my state"
--   BuyItem       client -> server   (itemName: string)  an INTENT only; the server decides the outcome
--
-- Hot paths (positions, VFX) should use UnreliableRemoteEvent (payload <= 1000 bytes, may be dropped), or a generated
-- buffer-networking library (Zap / Blink). Keep server-side validation either way.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteName = "StateChanged" | "ClientReady" | "BuyItem"

local FOLDER_NAME = "Remotes"

local NAMES: { RemoteName } = { "StateChanged", "ClientReady", "BuyItem" }

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing and existing:IsA("Folder") then
			return existing
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

-- Server only: create every remote once, before any player can join.
function Remotes.createAll()
	assert(RunService:IsServer(), "Remotes.createAll is server-only")
	local folder = getFolder()
	for _, name in NAMES do
		if not folder:FindFirstChild(name) then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
	end
end

-- Server: returns the remote created by createAll. Client: waits for it to replicate.
function Remotes.get(name: RemoteName): RemoteEvent
	local folder = getFolder()
	if RunService:IsServer() then
		return folder:FindFirstChild(name) :: RemoteEvent
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return Remotes
