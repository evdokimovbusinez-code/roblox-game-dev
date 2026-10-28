--!strict
-- Example HUD built ONLY from src/client/ui: currency (top left), left menu stack (Shop / Pass / Rebirth / Index), top tabs, right offer
-- column, two windows (one open at a time), toasts, reward fly + count-up, and the "Welcome BACK!" offline popup.
-- It is a usage reference and a smoke test for `rojo serve`; copy the parts you need into your own controller and delete this file.
--
-- Data: the Coins counter mirrors StateController ("Coins"); buying items sends the INTENT through HudController.requestBuy and the
-- server decides. The offline earnings, the "double it" purchase and the rewards below are FAKE local demo numbers: in a real game the
-- server computes them, grants them, and the client only displays (code-architecture.md: the client never computes rewards).
--
-- Studio-only debug keys (also three small buttons at the bottom center for the phone emulator):
--   P  offline popup      T  toast (press repeatedly: "[X2]", "[X3]" merge)      R  reward fly + count-up

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ui = script.Parent.Parent.ui
local Button = require(ui.Button)
local CurrencyCounter = require(ui.CurrencyCounter)
local Icons = require(ui.Icons)
local LeftMenuStack = require(ui.LeftMenuStack)
local OfferButtons = require(ui.OfferButtons)
local OfflineEarningsPopup = require(ui.OfflineEarningsPopup)
local ProgressBar = require(ui.ProgressBar)
local RewardFlyToCounter = require(ui.RewardFlyToCounter)
local Screen = require(ui.Screen)
local Theme = require(ui.Theme)
local Toasts = require(ui.Toasts)
local TopTabs = require(ui.TopTabs)
local Util = require(ui.Util)
local Window = require(ui.Window)
local WindowManager = require(ui.WindowManager)
local ZoneAudit = require(ui.ZoneAudit)

local HudController = require(script.Parent.HudController)
local StateController = require(script.Parent.StateController)

local UiDemoController = {}

local function countEntries(value: any): number
	local count = 0
	if typeof(value) == "table" then
		for _ in value :: { [any]: any } do
			count += 1
		end
	end
	return count
end

-- One shop card: icon, name, and a buy button the caller built. Dark text on the white card (no outline, readable on a phone).
local function shopCard(
	parent: Instance,
	order: number,
	name: string,
	iconKey: string,
	buy: Button.Button,
	textSize: number
)
	local card = Util.frame(parent, "Card_" .. name, UDim2.new(1 / 3, -8, 1, 0))
	card.LayoutOrder = order
	card.BackgroundTransparency = 0
	card.BackgroundColor3 = Theme.Colors.PanelInner
	Util.corner(card, Theme.Radius.Button)
	Util.stroke(card, Theme.Colors.PanelStroke, 2)

	local icon = Icons.new(card, iconKey, UDim2.fromOffset(64, 64))
	icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 10)

	local label = Util.text(card, name, textSize, Theme.Colors.TextDark, false)
	label.Position = UDim2.fromOffset(0, 78)
	label.Size = UDim2.new(1, 0, 0, textSize + 4)

	buy.Instance.AnchorPoint = Vector2.new(0.5, 1)
	buy.Instance.Position = UDim2.new(0.5, 0, 1, -10)
	buy.Instance.Parent = card
end

function UiDemoController.start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	local screen = Screen.new(playerGui, { name = "UiDemo" })
	local sizes = screen.Sizes
	local toasts = Toasts.new(screen)
	local fly = RewardFlyToCounter.new(screen)
	local windows = WindowManager.new(screen)

	-- Currency, top left (ui-canon 3.2) -----------------------------------------------------------------------------
	local currencies = Util.frame(screen.Hud, "Currencies", UDim2.fromOffset(0, sizes.currencyHeight))
	currencies.AutomaticSize = Enum.AutomaticSize.X
	currencies.Position = UDim2.fromOffset(sizes.margin, sizes.margin)
	local left, middle = Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center
	Util.list(currencies, Enum.FillDirection.Horizontal, 8, left, middle)

	local coins = CurrencyCounter.new({
		id = "coins",
		icon = "coin",
		value = 0,
		height = sizes.currencyHeight,
		textSize = sizes.currencyText,
		onPlus = function()
			windows:open("shop")
		end,
	})
	coins.Instance.LayoutOrder = 1
	coins.Instance.Parent = currencies
	local gems = CurrencyCounter.new({
		id = "gems",
		icon = "gem",
		value = 25, -- demo only
		height = sizes.currencyHeight,
		textSize = sizes.currencyText,
	})
	gems.Instance.LayoutOrder = 2
	gems.Instance.Parent = currencies

	local serverCoins = 0
	local demoBonus = 0 -- local fake rewards on top of the server value (demo only)
	StateController.observe("Coins", function(value)
		serverCoins = if typeof(value) == "number" then value else 0
		coins:set(serverCoins + demoBonus) -- small changes are instant (R16)
	end)

	local lastItems: number? = nil
	StateController.observe("Inventory", function(value)
		local count = countEntries(value)
		if lastItems ~= nil and count > lastItems then
			toasts:show("Item added!", { kind = "success", icon = "star" })
		end
		lastItems = count
	end)

	-- Windows: Shop and Rebirth (one open at a time) -----------------------------------------------------------------
	local shop = Window.new(screen, { id = "shop", title = "Shop", size = Vector2.new(500, 250) })
	windows:register(shop)
	local cards = Util.frame(shop.Content, "Cards", UDim2.fromScale(1, 1))
	Util.list(cards, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
	local buyWidth = UDim2.new(1, -16, 0, sizes.buttonHeight)
	shopCard(
		cards,
		1,
		"Flashlight",
		"luck",
		Button.new({
			text = "100",
			icon = "coin",
			variant = "primary",
			size = buyWidth,
			textSize = sizes.buttonText,
			onClick = function()
				HudController.requestBuy("Flashlight") -- intent only; the server checks price and balance
			end,
		}),
		sizes.body
	)
	shopCard(
		cards,
		2,
		"Speed Coil",
		"speed",
		Button.new({
			text = "250",
			icon = "coin",
			variant = "primary",
			size = buyWidth,
			textSize = sizes.buttonText,
			onClick = function()
				HudController.requestBuy("SpeedCoil")
			end,
		}),
		sizes.body
	)
	shopCard(
		cards,
		3,
		"Gem Pack",
		"gem",
		Button.new({
			robux = "99", -- real games: the ProductInfo price string
			variant = "primary",
			size = buyWidth,
			textSize = sizes.buttonText,
			onClick = function()
				-- the component only reports the click; PromptProductPurchase is YOUR code (Config.Products + server receipt handler)
				toasts:show("Your code prompts the Robux purchase here", { kind = "info" })
			end,
		}),
		sizes.body
	)

	local rebirth = Window.new(screen, { id = "rebirth", title = "Rebirth", size = Vector2.new(380, 230) })
	windows:register(rebirth)
	local rebirthText = "Reset your progress for a permanent x2 bonus"
	local rebirthInfo = Util.text(rebirth.Content, rebirthText, sizes.body, Theme.Colors.TextDark, false)
	rebirthInfo.Size = UDim2.new(1, 0, 0, sizes.body + 6)
	local bar = ProgressBar.new({ size = UDim2.new(1, -24, 0, 26), color = Theme.Variants.gold.fill, level = 1 })
	bar.Instance.Position = UDim2.fromOffset(24, 48)
	bar.Instance.Parent = rebirth.Content
	bar:set(640_000, 1_000_000, false)
	local rebirthRow = Util.frame(rebirth.Content, "Buttons", UDim2.new(1, 0, 0, 52), UDim2.new(0, 0, 1, -52))
	local center = Enum.HorizontalAlignment.Center
	Util.list(rebirthRow, Enum.FillDirection.Horizontal, 12, center, middle)
	local rebirthButton = Button.new({
		text = "REBIRTH",
		variant = "gold", -- gold = special action (rebirth, restock); green stays reserved for purchases
		size = UDim2.new(0.55, 0, 0, sizes.buttonHeight),
		textSize = sizes.buttonText,
		onClick = function()
			toasts:show("Send the rebirth intent to the server here", { kind = "info" })
		end,
	})
	rebirthButton.Instance.Parent = rebirthRow
	local cancelButton = Button.new({
		text = "CANCEL",
		variant = "danger", -- red = cancel / decline
		size = UDim2.new(0.35, 0, 0, sizes.buttonHeight),
		textSize = sizes.buttonText,
		onClick = function()
			windows:close()
		end,
	})
	cancelButton.Instance.Parent = rebirthRow

	-- Left menu stack (canon order: Shop, Pass, Rebirth, Index) ---------------------------------------------------------
	local stack = LeftMenuStack.new(screen, {
		items = {
			{ id = "shop", label = "Shop", icon = "shop", badge = true },
			{ id = "pass", label = "Pass", icon = "pass" },
			{ id = "rebirth", label = "Rebirth", icon = "rebirth", badge = 1 },
			{ id = "index", label = "Index", icon = "index" },
		},
		onClick = function(id: string)
			if id == "shop" or id == "rebirth" then
				windows:toggle(id)
			else
				toasts:show(string.upper(string.sub(id, 1, 1)) .. string.sub(id, 2) .. ": add your window here")
			end
		end,
	})

	-- Top tabs, right offers --------------------------------------------------------------------------------------------
	TopTabs.new(screen, {
		tabs = {
			{ id = "collect", label = "COLLECT" },
			{ id = "upgrade", label = "UPGRADE" },
			{ id = "sell", label = "SELL" },
		},
		selected = "collect",
		onSelect = function(id: string)
			toasts:show("Tab: " .. id)
		end,
	})

	OfferButtons.new(screen, {
		offers = {
			-- demo timer; a real offer shows the remaining time of a SERVER deadline and never restarts on its own
			{ id = "starter", title = "Starter", icon = "starter", priceText = "99", timerSeconds = 12_300 },
			{ id = "x2", title = "x2 Cash", icon = "x2", priceText = "199", accent = Theme.Variants.primary.fill },
			{ id = "vip", title = "VIP", icon = "pass", priceText = "399", accent = Theme.Colors.Gold },
		},
		onClick = function(_id: string)
			windows:open("shop") -- the offer opens the shop; the prompt is shown from there by your own code
		end,
	})

	-- Reward chain: fly sprites to the counter, counter counts up ~1 s (R16, R17, R31) -------------------------------------
	local function giveReward(amount: number, spriteCount: number)
		demoBonus += amount
		coins:countTo(serverCoins + demoBonus) -- creep / sweep / soft tail; matches the first sprites still in the air
		fly:play({
			count = spriteCount,
			icon = "coin",
			from = Vector2.new(screen.Size.X / 2, screen.Size.Y / 2),
			target = coins.Icon,
			onBump = function()
				coins:bump()
			end,
		})
	end

	local function showOffline()
		local popup: OfflineEarningsPopup.Popup
		popup = OfflineEarningsPopup.new(screen, {
			manager = windows,
			offlineSeconds = 8375,
			earned = 1_250_000, -- DEMO: the server computes this on join
			capSeconds = 8 * 3600,
			doublePriceText = "25",
			onRequestDouble = function()
				-- DEMO: pretend the purchase was approved after 1.2 s. Real game: PromptProductPurchase, wait for the server
				-- receipt, then call popup:resolveDouble(true), or resolveDouble(false) when the player cancels.
				task.delay(1.2, function()
					popup:resolveDouble(true)
				end)
			end,
			onCollect = function(multiplier: number, amount: number)
				giveReward(amount, 24)
				toasts:show("Collected x" .. tostring(multiplier), { kind = "reward", icon = "coin" })
				task.delay(1, function()
					popup:destroy()
				end)
			end,
		})
		popup:show()
	end

	-- Studio-only debug input ---------------------------------------------------------------------------------------------
	if RunService:IsStudio() then
		local function toast()
			toasts:show("Not enough coins", { kind = "error" })
		end
		local function reward()
			giveReward(5_000, 12)
		end

		UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.P then
				showOffline()
			elseif input.KeyCode == Enum.KeyCode.T then
				toast()
			elseif input.KeyCode == Enum.KeyCode.R then
				reward()
			end
		end)

		-- the same actions as small buttons, inside the free middle band (between thumbstick and jump button)
		local debugRow = Util.frame(screen.Hud, "Debug", UDim2.fromOffset(170, 26))
		debugRow.AnchorPoint = Vector2.new(0.5, 1)
		debugRow.Position = UDim2.new(0.54, 0, 1, -sizes.margin)
		Util.list(debugRow, Enum.FillDirection.Horizontal, 4, center, middle)
		local actions: { { label: string, run: () -> () } } = {
			{ label = "Offline", run = showOffline },
			{ label = "Toast", run = toast },
			{ label = "Fly", run = reward },
		}
		for index, action in actions do
			local debugButton = Button.new({
				text = action.label,
				variant = "secondary",
				size = UDim2.fromOffset(54, 24),
				textSize = 12,
				onClick = action.run,
			})
			debugButton.Instance.LayoutOrder = index
			debugButton.Instance.Parent = debugRow
		end

		-- the touch-zone audit needs a laid-out UI: run it a moment after the build
		task.delay(1, function()
			for _, problem in ZoneAudit.check(screen) do
				warn("[UiDemo] touch zone: " .. problem)
			end
		end)
	end

	-- clear the "new" badge on the Shop tile the first time the shop opens
	windows.Changed:Connect(function(id: string?)
		if id == "shop" then
			stack:setBadge("shop", nil)
		end
	end)
end

return UiDemoController
