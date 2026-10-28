--!strict
-- Types shared by server and client. Only data shapes live here, no logic.

export type ItemRecord = {
	id: string, -- GUID, also the key in Inventory
	kind: string, -- catalog key, e.g. "Flashlight"
	createdAt: number, -- os.time()
	locked: boolean?, -- true while refund-held or inside a pending trade
}

export type GrantRecord = {
	productId: number,
	at: number,
	robux: number,
}

-- Shape of the persistent profile. Add fields here AND to TEMPLATE in services/PlayerData.luau.
-- Rules: only JSON-friendly values, string keys, no Instances, every list capped.
export type PlayerData = {
	SchemaVersion: number,
	Coins: number,
	Inventory: { [string]: ItemRecord },
	Settings: { Music: boolean },
	PurchaseIds: { string }, -- processed receipt ids (ring buffer, see Config.PurchaseIdHistory)
	Grants: { [string]: GrantRecord }, -- PurchaseId -> what was granted (needed to reverse refunds)
}

return {}
