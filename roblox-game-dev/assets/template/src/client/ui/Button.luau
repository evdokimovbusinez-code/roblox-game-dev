--!strict
-- Buttons with the canon semantics (ui-canon 3.4) and the "fat button" anatomy (ui-figma-workflow 1.2):
-- drop shadow, dark border, light-top/dark-bottom body, gloss strip, outlined text; states default / hover / pressed / disabled.
--
--   primary   green  Buy / Claim / Confirm / OK        (the ONLY color for purchases)
--   secondary grey   Okay / Later / neutral
--   danger    red    Cancel / Decline / Delete / Close X
--   gold      gold   special actions (Rebirth, Restock)
--   info      blue   Gift / Equip / navigation
--
-- Layout slot (Instance) is a transparent Frame that the caller sizes; the TextButton inside scales on press (UIScale),
-- so list/grid layouts never jitter. Purchases are NEVER started here: pass onClick and call the server/MarketplaceService
-- from your own code (the component only reports the click).

local UserInputService = game:GetService("UserInputService")

local Icons = require(script.Parent.Icons)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local Button = {}

export type Options = {
	text: string?,
	variant: Theme.Variant?,
	color: Color3?, -- custom body color (menu tiles use the icon tint); overrides the variant colors
	size: UDim2?, -- slot size (default: full width of the parent, Theme button height is the caller's job)
	textSize: number?,
	icon: string?, -- Icons key shown left of the text (or alone when text is nil)
	iconSize: number?, -- icon edge in design units (default 28)
	robux: (number | string)?, -- shows "<Robux glyph> price" as the label; the price string must come from ProductInfo
	onClick: (() -> ())?,
	enabled: boolean?,
	name: string?,
	hover: boolean?, -- grow on mouse hover (default true on non-touch devices)
}

export type Button = {
	Instance: Frame, -- the layout slot: parent it / size it
	Button: TextButton, -- the clickable body (children added here scale with the press)
	Scale: UIScale,
	setText: (self: Button, text: string) -> (),
	setVariant: (self: Button, variant: Theme.Variant) -> (),
	setColor: (self: Button, color: Color3?) -> (),
	setEnabled: (self: Button, enabled: boolean) -> (),
	isEnabled: (self: Button) -> boolean,
	setOnClick: (self: Button, fn: (() -> ())?) -> (),
	destroy: (self: Button) -> (),
}

local function canHover(): boolean
	return not UserInputService.TouchEnabled or UserInputService.KeyboardEnabled
end

-- Press / hover feedback for ANY GuiButton + UIScale pair (used by Button, menu tiles, offers, tabs).
-- Press = scale 0.95 (animation.md R14), release = back, hover (PC) = 1.05. Returns a function that reports pressed state.
function Button.attachFeedback(button: GuiButton, scale: UIScale, cleaner: Util.Cleaner, hover: boolean?)
	local hovering = false
	local pressed = false
	local useHover = if hover == nil then canHover() else hover

	local function refresh()
		local target = 1
		if pressed then
			target = Motion.PressScale
		elseif hovering and useHover then
			target = Motion.HoverScale
		end
		local duration = if pressed then Motion.PressTime else Motion.HoverTime
		Util.tweenOut(scale, duration, { Scale = target })
	end

	cleaner:connect(button.MouseButton1Down, function()
		pressed = true
		refresh()
	end)
	cleaner:connect(button.MouseButton1Up, function()
		pressed = false
		refresh()
	end)
	cleaner:connect(button.MouseEnter, function()
		hovering = true
		refresh()
	end)
	cleaner:connect(button.MouseLeave, function()
		hovering = false
		pressed = false
		refresh()
	end)
end

local function applyVariant(
	body: TextButton,
	border: UIStroke,
	shadow: Frame,
	variant: Theme.Variant,
	enabled: boolean,
	color: Color3?
)
	local style = Theme.Variants[variant]
	if enabled and color ~= nil then
		body.BackgroundColor3 = color
		border.Color = Theme.darken(color, 0.6)
		body.TextColor3 = Theme.Colors.White
		shadow.BackgroundColor3 = Theme.darken(color, 0.75)
	elseif enabled then
		body.BackgroundColor3 = style.fill
		border.Color = style.stroke
		body.TextColor3 = style.text
		shadow.BackgroundColor3 = Theme.darken(style.stroke, 0.35)
	else
		body.BackgroundColor3 = Theme.Colors.Disabled
		border.Color = Theme.Colors.DisabledStroke
		body.TextColor3 = Theme.lighten(Theme.Colors.Disabled, 0.7)
		shadow.BackgroundColor3 = Theme.Colors.DisabledStroke
	end
end

function Button.new(options: Options): Button
	local cleaner = Util.newCleaner()
	local variant: Theme.Variant = options.variant or "primary"
	local enabled = options.enabled ~= false
	local onClick = options.onClick
	local customColor = options.color

	local slot = Util.frame(nil, options.name or "Button", options.size or UDim2.new(1, 0, 0, 40))

	-- 1) shadow: a darker copy offset downwards (cheaper and more reliable than UIShadow, which is beta)
	local shadow = Util.frame(slot, "Shadow", UDim2.fromScale(1, 1))
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, Theme.Shadow.Offset)
	shadow.BackgroundTransparency = Theme.Shadow.Transparency
	shadow.ZIndex = 1
	Util.corner(shadow, Theme.Radius.Button)

	-- 2) body
	local body = Instance.new("TextButton")
	body.Name = "Body"
	body.AnchorPoint = Vector2.new(0.5, 0.5)
	body.Position = UDim2.fromScale(0.5, 0.5)
	body.Size = UDim2.fromScale(1, 1)
	body.AutoButtonColor = false
	body.BorderSizePixel = 0
	body.BackgroundColor3 = Color3.new(1, 1, 1)
	body.FontFace = Theme.Font.Display
	body.TextSize = options.textSize or 18
	body.TextTruncate = Enum.TextTruncate.AtEnd
	body.TextXAlignment = Enum.TextXAlignment.Center
	body.ZIndex = 2
	body.Parent = slot
	Util.corner(body, Theme.Radius.Button)
	local border = Util.stroke(body, Theme.Colors.Ink, Theme.Stroke.Button)
	Util.textStroke(body)
	Util.shade(body)
	local scale = Util.scale(body)

	-- 3) gloss: translucent strip in the top third
	local gloss = Util.frame(body, "Gloss", UDim2.new(1, -8, 0.32, 0), UDim2.new(0, 4, 0, 3))
	gloss.BackgroundColor3 = Color3.new(1, 1, 1)
	gloss.BackgroundTransparency = 0.85
	Util.corner(gloss, Theme.Radius.Button - 3)

	-- 4) optional icon on the left; the text keeps the centered rest
	local text = options.text or ""
	if options.robux ~= nil then
		text = Theme.RobuxGlyph .. " " .. tostring(options.robux)
	end
	body.Text = text
	if options.icon then
		local iconSize = options.iconSize or 28
		local image = Icons.new(body, options.icon, UDim2.fromOffset(iconSize, iconSize))
		image.SizeConstraint = Enum.SizeConstraint.RelativeXY
		if text ~= "" then
			image.AnchorPoint = Vector2.new(0, 0.5)
			image.Position = UDim2.new(0, 8, 0.5, 0)
		else
			image.AnchorPoint = Vector2.new(0.5, 0.5)
			image.Position = UDim2.fromScale(0.5, 0.5)
		end
	end

	local self: Button
	self = {
		Instance = slot,
		Button = body,
		Scale = scale,
		setText = function(_self: Button, value: string)
			body.Text = value
		end,
		setVariant = function(_self: Button, value: Theme.Variant)
			variant = value
			applyVariant(body, border, shadow, variant, enabled, customColor)
		end,
		setColor = function(_self: Button, color: Color3?)
			customColor = color
			applyVariant(body, border, shadow, variant, enabled, customColor)
		end,
		setEnabled = function(_self: Button, value: boolean)
			enabled = value
			body.Interactable = value
			applyVariant(body, border, shadow, variant, enabled, customColor)
		end,
		isEnabled = function(_self: Button): boolean
			return enabled
		end,
		setOnClick = function(_self: Button, fn: (() -> ())?)
			onClick = fn
		end,
		destroy = function(_self: Button)
			cleaner:clean()
			slot:Destroy()
		end,
	}

	applyVariant(body, border, shadow, variant, enabled, customColor)
	body.Interactable = enabled
	Button.attachFeedback(body, scale, cleaner, options.hover)
	cleaner:connect(body.Activated, function()
		if enabled and onClick then
			onClick()
		end
	end)

	return self
end

-- The canon close button: red rounded SQUARE with a white X, sits on the top-right corner of a panel, partly outside it.
-- Size = Theme.Sizes[device].close (>= 44 on phone). Window.luau places it on the corner.
function Button.close(size: number, onClick: () -> ()): Button
	local button = Button.new({
		name = "Close",
		text = "X",
		variant = "danger",
		size = UDim2.fromOffset(size, size),
		textSize = math.floor(size * 0.55),
		onClick = onClick,
	})
	return button
end

return Button
