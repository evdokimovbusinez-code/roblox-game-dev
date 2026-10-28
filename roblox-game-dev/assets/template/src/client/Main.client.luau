--!strict
-- The ONLY client entry point. Controllers expose start(). UI subscribes first, then StateController.start() sends
-- ClientReady, so the initial state cannot arrive before anyone listens.

local controllers = script.Parent.controllers

local HudController = require(controllers.HudController)
local StateController = require(controllers.StateController)
local UiDemoController = require(controllers.UiDemoController)

-- true: `rojo serve` shows the example HUD built with src/client/ui (currency, menus, tabs, offers, windows, toasts, offline popup).
-- Set false (then delete the require above and controllers/UiDemoController.luau) when you start your own game UI.
local SHOW_UI_DEMO = true

HudController.start({ coinLabel = not SHOW_UI_DEMO }) -- builds the minimal HUD (coin label) and subscribes to state
if SHOW_UI_DEMO then
	UiDemoController.start()
end
StateController.start() -- connects StateChanged, then tells the server "ready" (initial state arrives after this)
