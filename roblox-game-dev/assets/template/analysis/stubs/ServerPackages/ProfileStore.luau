--!strict
-- ============================================================================================================
-- ANALYSIS-ONLY STUB. NOT THE REAL ProfileStore. NEVER SHIPPED: no Rojo project maps this folder.
-- Purpose: let `luau-lsp analyze` resolve `ServerScriptService.ServerPackages.ProfileStore` on machines where
-- `wally install` has not run (CI sandboxes, offline agents). The real package comes from wally.toml:
--   [server-dependencies] ProfileStore = "lm-loleris/profilestore@1.0.3"
-- The surface below mirrors only what src/server/services/PlayerData.luau calls.
-- ============================================================================================================

type Connection = { Disconnect: (self: Connection) -> () }

local function stubSignal()
	return {
		Connect = function(_self: any, _listener: (...any) -> ()): Connection
			return { Disconnect = function() end }
		end,
	}
end

local Stub = {}

function Stub.SetConstant(_name: string, _value: number) end

function Stub.New(_storeName: string, template: { [string]: any })
	local store = {}
	function store.StartSessionAsync(_self: any, _key: string, _params: { [string]: any }?)
		local profile = {
			Data = template,
			LastSavedData = template,
			OnSessionEnd = stubSignal(),
			OnAfterSave = stubSignal(),
		}
		function profile.IsActive(_self: any): boolean
			return true
		end
		function profile.Reconcile(_self: any) end
		function profile.EndSession(_self: any) end
		function profile.AddUserId(_self: any, _userId: number) end
		function profile.Save(_self: any) end
		return profile
	end
	return store
end

return Stub
