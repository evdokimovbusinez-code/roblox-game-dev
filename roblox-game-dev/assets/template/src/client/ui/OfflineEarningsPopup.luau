--!strict
-- "Welcome BACK!" offline-earnings popup (animation.md R29, R31): shown on join, no dim and no blur (HUD keeps running behind it),
-- text "You were offline for 2h 19m", a big green number on a dark inset, a grey OKAY and a green "DOUBLE IT! x2" button with the price.
--
-- IMPORTANT, money rules:
--   * The component NEVER prompts a purchase and NEVER grants anything. "DOUBLE IT" calls the injected `onRequestDouble`; your code
--     does MarketplaceService:PromptProductPurchase (or asks the server to) and reports back with popup:resolveDouble(true|false).
--     The server grants the x1 / x2 amount (ProcessReceipt for x2). `earned` is a server-computed number for DISPLAY only.
--   * `onCollect(multiplier, amount)` runs once, AFTER the close animation (<= 0.15 s). That is your cue to play the reward fly and
--     counter:countTo (R31: popup closes, sprites fly, counter counts ~1 s).
--   * Nothing is lost if the popup is replaced by another window: that counts as OKAY (x1).
--
--   local popup = OfflineEarningsPopup.new(screen, {
--       manager = windows, offlineSeconds = 8375, earned = 1.25e9, capSeconds = 8 * 3600,
--       doublePriceText = "25",                 -- from ProductInfo, never hardcoded
--       onRequestDouble = function() requestDoublePurchase() end,
--       onCollect = function(multiplier, amount) ... end,
--   })
--   popup:show()

local Button = require(script.Parent.Button)
local Format = require(script.Parent.Format)
local Icons = require(script.Parent.Icons)
local Motion = require(script.Parent.Motion)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)
local Window = require(script.Parent.Window)
local WindowManager = require(script.Parent.WindowManager)

local OfflineEarningsPopup = {}

export type Options = {
	earned: number, -- amount for x1, computed by the SERVER
	offlineSeconds: number,
	capSeconds: number?, -- if offlineSeconds reached the cap, a "capped" note is shown
	currencyIcon: string?, -- Icons key (default "coin")
	doublePriceText: string?, -- ready price text, e.g. "25"; nil hides the DOUBLE button
	onRequestDouble: (() -> ())?, -- injected: starts the purchase. nil = no DOUBLE button
	onCollect: (multiplier: number, amount: number) -> (),
	manager: WindowManager.WindowManager?, -- register in it (one window at a time); without it the popup opens by itself
}

export type Popup = {
	Window: Window.Window,
	show: (self: Popup) -> boolean,
	resolveDouble: (self: Popup, success: boolean) -> (), -- the purchase result: true = collect x2, false = back to idle
	isOpen: (self: Popup) -> boolean,
	destroy: (self: Popup) -> (),
}

local WINDOW_ID = "offline"
local GREEN_TEXT = Theme.lighten(Theme.Colors.Green, 0.2)

function OfflineEarningsPopup.new(screen: Screen.Screen, options: Options): Popup
	local cleaner = Util.newCleaner()
	local sizes = screen.Sizes
	local manager = options.manager
	local canDouble = options.onRequestDouble ~= nil and options.doublePriceText ~= nil

	local finished = false -- onCollect has been (or is being) delivered
	local pending = false -- a purchase is in flight
	local showing = false
	local closeDelay: thread? = nil

	local popup: Popup
	local collect: (multiplier: number) -> ()

	local window = Window.new(screen, {
		id = WINDOW_ID,
		title = "Welcome BACK!",
		size = Vector2.new(440, 250),
		dim = "none", -- R29: no darkening, no blur
		closable = false, -- OKAY is the exit; a red X would have no clear meaning (collect or lose?)
		dismissOnDim = false,
		onClose = function()
			-- closed by someone else (another window opened): the earnings still go out as x1
			if showing and not finished then
				collect(1)
			end
		end,
	})
	cleaner:add(function()
		window:destroy()
	end)

	local content = window.Content

	local info = Util.text(content, "", sizes.body, Theme.Colors.TextDark, false)
	info.Name = "OfflineFor"
	info.Size = UDim2.new(1, 0, 0, 24)
	info.Text = "You were offline for " .. Format.duration(options.offlineSeconds, 2)

	-- dark inset with a thick green frame and the big number (R29)
	local inset = Util.frame(content, "Earned", UDim2.new(1, 0, 0, 84), UDim2.fromOffset(0, 30))
	inset.BackgroundTransparency = 0
	inset.BackgroundColor3 = Theme.Colors.Pill
	Util.corner(inset, Theme.Radius.Button)
	Util.stroke(inset, Theme.Variants.primary.fill, Theme.Stroke.Panel)

	local icon = Icons.new(inset, options.currencyIcon or "coin", UDim2.fromOffset(52, 52))
	icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 14, 0.5, 0)

	local amount = Util.text(inset, "", 44, GREEN_TEXT)
	amount.Name = "Amount"
	amount.AnchorPoint = Vector2.new(1, 0)
	amount.Position = UDim2.new(1, -14, 0, 6)
	amount.Size = UDim2.new(1, -86, 0, 50)
	amount.TextScaled = true
	amount.Text = "+" .. Format.abbreviate(options.earned, 2)
	local amountLimit = Instance.new("UITextSizeConstraint")
	amountLimit.MaxTextSize = 44
	amountLimit.MinTextSize = 14
	amountLimit.Parent = amount

	local exact = Util.text(inset, Format.commas(options.earned), sizes.small, Theme.Colors.White, false)
	exact.Name = "Exact"
	exact.AnchorPoint = Vector2.new(1, 1)
	exact.Position = UDim2.new(1, -14, 1, -6)
	exact.Size = UDim2.new(1, -86, 0, sizes.small + 2)
	exact.TextTransparency = 0.25
	exact.TextXAlignment = Enum.TextXAlignment.Right

	local note = Util.text(content, "", sizes.small, Theme.Colors.TextMuted, false)
	note.Name = "CapNote"
	note.Position = UDim2.fromOffset(0, 118)
	note.Size = UDim2.new(1, 0, 0, sizes.small + 4)
	local cap = options.capSeconds
	if cap ~= nil and options.offlineSeconds >= cap then
		note.Text = "Offline earnings are capped at " .. Format.duration(cap, 2)
	end

	-- buttons: grey OKAY on the left, green DOUBLE IT on the right (R29)
	local row = Util.frame(content, "Buttons", UDim2.new(1, 0, 0, 56), UDim2.new(0, 0, 1, -56))
	local okay = Button.new({
		name = "Okay",
		text = "OKAY",
		variant = "secondary",
		size = if canDouble then UDim2.new(0.34, 0, 1, -4) else UDim2.new(0.5, 0, 1, -4),
		textSize = sizes.buttonText,
		onClick = function()
			if not pending then
				collect(1)
			end
		end,
	})
	okay.Instance.AnchorPoint = if canDouble then Vector2.new(0, 0) else Vector2.new(0.5, 0)
	okay.Instance.Position = if canDouble then UDim2.new() else UDim2.fromScale(0.5, 0)
	okay.Instance.Parent = row
	cleaner:add(function()
		okay:destroy()
	end)

	local doubleTitle: TextLabel? = nil
	if canDouble then
		local button = Button.new({
			name = "DoubleIt",
			text = "",
			variant = "primary",
			size = UDim2.new(0.62, 0, 1, -4),
			onClick = function()
				if pending or finished then
					return
				end
				pending = true
				okay:setEnabled(false)
				if doubleTitle then
					doubleTitle.Text = "..."
				end
				-- the purchase itself belongs to the caller; the result comes back through resolveDouble
				local request = options.onRequestDouble
				if request then
					request()
				end
			end,
		})
		button.Instance.AnchorPoint = Vector2.new(1, 0)
		button.Instance.Position = UDim2.fromScale(1, 0)
		button.Instance.Parent = row
		cleaner:add(function()
			button:destroy()
		end)
		local title = Util.text(button.Button, "DOUBLE IT! x2", sizes.buttonText)
		title.Name = "Title"
		title.Position = UDim2.fromOffset(0, 2)
		title.Size = UDim2.new(1, 0, 0.58, 0)
		local priceText = Format.robux(options.doublePriceText or "", Theme.RobuxGlyph)
		local price = Util.text(button.Button, priceText, sizes.small)
		price.Name = "Price"
		price.AnchorPoint = Vector2.new(0, 1)
		price.Position = UDim2.new(0, 0, 1, -3)
		price.Size = UDim2.new(1, 0, 0.36, 0)
		doubleTitle = title
	end

	local function idle()
		pending = false
		okay:setEnabled(true)
		if doubleTitle then
			doubleTitle.Text = "DOUBLE IT! x2"
		end
	end

	collect = function(multiplier: number)
		if finished then
			return
		end
		finished = true
		showing = false
		pending = false
		-- close first (<= 0.15 s, brief shrink), THEN report: the count-up starts after the popup is gone
		local function deliver()
			closeDelay = nil
			options.onCollect(multiplier, options.earned * multiplier)
		end
		if window:isOpen() then
			if manager and manager:current() == WINDOW_ID then
				manager:close()
			else
				window:close()
			end
		end
		if Util.reducedMotion() then
			deliver()
		else
			closeDelay = task.delay(Motion.WindowClose, deliver)
		end
	end

	cleaner:add(function()
		if closeDelay then
			task.cancel(closeDelay)
			closeDelay = nil
		end
	end)

	if manager then
		manager:register(window)
		-- the manager's default close request would just hide the window; the earnings must not be dropped
		window.onCloseRequest = function()
			collect(1)
		end
	end

	popup = {
		Window = window,
		show = function(_self: Popup): boolean
			if finished or showing or options.earned <= 0 then
				return false
			end
			showing = true
			if manager then
				manager:open(WINDOW_ID)
			else
				window:open()
			end
			return true
		end,
		resolveDouble = function(_self: Popup, success: boolean)
			if not pending or finished then
				return
			end
			if success then
				collect(2)
			else
				idle()
			end
		end,
		isOpen = function(_self: Popup): boolean
			return showing
		end,
		destroy = function(_self: Popup)
			showing = false
			cleaner:clean()
		end,
	}
	return popup
end

return OfflineEarningsPopup
