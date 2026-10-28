--!strict
-- Toast stack (animation.md R19): plain outlined text without a panel, fade in <= 0.2 s, hold >= 2.6 s, fade out, max 4 alive.
-- The same message while it is still alive does NOT create a new toast: it gets a suffix "[X2]", "[X3]" and its timer restarts.
--
--   toasts:show("Not enough coins")                           info (white), top center, below the tabs
--   toasts:show("Saved!", { kind = "success" })               green
--   toasts:show("You successfully rebirthed!", { kind = "success", placement = "bottom", hold = 5 })   R18: >= 5 s, bottom center
--
-- Placement keeps clear of the touch controls: "top" sits under the top tabs, "bottom" only uses the middle ~28% of the width
-- (between the thumbstick and the jump button, Theme.Zones). Toasts are not interactive (Active = false), they never eat taps.

local Icons = require(script.Parent.Icons)
local Motion = require(script.Parent.Motion)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local Toasts = {}

export type Kind = "info" | "success" | "error" | "reward"
export type Placement = "top" | "bottom"

export type ShowOptions = {
	kind: Kind?, -- default "info"
	icon: string?, -- Icons key shown left of the text
	hold: number?, -- seconds on screen (default Motion.ToastHold, keep >= 2.6)
	key: string?, -- merge key (default: the text itself)
	placement: Placement?, -- default "top"
}

export type Toasts = {
	show: (self: Toasts, text: string, options: ShowOptions?) -> (),
	clear: (self: Toasts) -> (),
	destroy: (self: Toasts) -> (),
}

type Entry = {
	key: string,
	text: string,
	count: number,
	slot: Frame,
	label: TextLabel,
	stroke: UIStroke,
	icon: ImageLabel?,
	pop: UIScale,
	timer: thread?,
	dying: boolean,
}

local KIND_COLOR: { [string]: Color3 } = {
	info = Theme.Colors.White,
	success = Theme.lighten(Theme.Colors.Green, 0.25),
	error = Theme.lighten(Theme.Colors.Red, 0.3),
	reward = Theme.Colors.Gold,
}

local MAX_WIDTH = 420
local BOTTOM_SHARE = 0.28 -- of the screen width: the gap between thumbstick and jump button

local function holder(parent: Instance, name: string): Frame
	local frame = Util.frame(parent, name, UDim2.fromOffset(MAX_WIDTH, 0))
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.ZIndex = 1
	return frame
end

-- Fades every visible part of a toast to `alpha` (0 = visible). One helper, so fade in/out stay symmetrical.
local function fade(entry: Entry, alpha: number, duration: number, onDone: (() -> ())?)
	Util.tweenOut(entry.label, duration, { TextTransparency = alpha }, onDone)
	Util.tweenOut(entry.stroke, duration, { Transparency = alpha })
	local icon = entry.icon
	if icon then
		Util.tweenOut(icon, duration, { ImageTransparency = alpha })
		local glyph = icon:FindFirstChild("Glyph")
		if glyph and glyph:IsA("TextLabel") then
			Util.tweenOut(glyph, duration, { TextTransparency = alpha })
		end
	end
end

function Toasts.new(screen: Screen.Screen): Toasts
	local cleaner = Util.newCleaner()
	local sizes = screen.Sizes

	local top = holder(screen.Toasts, "TopToasts")
	top.AnchorPoint = Vector2.new(0.5, 0)
	Util.list(top, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

	local bottom = holder(screen.Toasts, "BottomToasts")
	bottom.AnchorPoint = Vector2.new(0.5, 1)
	Util.list(bottom, Enum.FillDirection.Vertical, 2, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Bottom)

	local function relayout(available: Vector2)
		local currentSizes = screen.Sizes
		local topY = currentSizes.margin + currentSizes.tabHeight + 12 -- below the top tabs
		top.Position = UDim2.new(0.5, 0, 0, topY)
		top.Size = UDim2.fromOffset(math.min(MAX_WIDTH, available.X - 2 * currentSizes.margin), 0)
		bottom.Position = UDim2.new(0.5, 0, 1, -currentSizes.margin * 3)
		bottom.Size = UDim2.fromOffset(math.clamp(available.X * BOTTOM_SHARE, 180, MAX_WIDTH), 0)
	end
	relayout(screen.Size)
	cleaner:connect(screen.Resized, relayout)

	local alive: { Entry } = {} -- oldest first
	local byKey: { [string]: Entry } = {}
	local order = 0

	local function remove(entry: Entry)
		local index = table.find(alive, entry)
		if index then
			table.remove(alive, index)
		end
		if byKey[entry.key] == entry then
			byKey[entry.key] = nil
		end
	end

	local function dismiss(entry: Entry)
		if entry.dying then
			return
		end
		entry.dying = true
		if entry.timer then
			task.cancel(entry.timer)
			entry.timer = nil
		end
		-- leaves the merge map at once: a new identical message starts a fresh toast
		if byKey[entry.key] == entry then
			byKey[entry.key] = nil
		end
		fade(entry, 1, Motion.ToastOut, function()
			remove(entry)
			entry.slot:Destroy()
		end)
	end

	local function arm(entry: Entry, hold: number)
		if entry.timer then
			task.cancel(entry.timer)
		end
		entry.timer = task.delay(hold, function()
			entry.timer = nil
			dismiss(entry)
		end)
	end

	local api: Toasts
	api = {
		show = function(_self: Toasts, text: string, options: ShowOptions?)
			local opts: ShowOptions = options or {}
			local key = opts.key or text
			local hold = math.max(opts.hold or Motion.ToastHold, 0.5)

			local existing = byKey[key]
			if existing and not existing.dying then
				existing.count += 1
				existing.label.Text = existing.text .. " [X" .. tostring(existing.count) .. "]"
				existing.pop.Scale = 1.12
				Util.tweenOut(existing.pop, Motion.BumpTime * 2, { Scale = 1 })
				arm(existing, hold)
				return
			end

			-- over the limit: the oldest toast leaves early so the stack never grows past ToastMax
			local living = 0
			for _, entry in alive do
				if not entry.dying then
					living += 1
				end
			end
			if living >= Motion.ToastMax then
				for _, entry in alive do
					if not entry.dying then
						dismiss(entry)
						break
					end
				end
			end

			order += 1
			local parent = if opts.placement == "bottom" then bottom else top
			local color = KIND_COLOR[opts.kind or "info"] or Theme.Colors.White

			local slot = Util.frame(parent, "Toast", UDim2.new(1, 0, 0, 0))
			slot.AutomaticSize = Enum.AutomaticSize.Y
			slot.LayoutOrder = order
			slot.Active = false
			local center = Enum.HorizontalAlignment.Center
			Util.list(slot, Enum.FillDirection.Horizontal, 4, center, Enum.VerticalAlignment.Center)

			local icon: ImageLabel? = nil
			if opts.icon then
				local edge = sizes.toastText + 6
				local image = Icons.new(slot, opts.icon, UDim2.fromOffset(edge, edge))
				image.SizeConstraint = Enum.SizeConstraint.RelativeXY
				image.LayoutOrder = 1
				icon = image
			end

			local label = Util.text(slot, text, sizes.toastText, color, false)
			label.Name = "Message"
			label.LayoutOrder = 2
			label.AutomaticSize = Enum.AutomaticSize.XY
			label.Size = UDim2.new(0, 0, 0, 0)
			label.TextWrapped = true
			label.Active = false
			local limit = Instance.new("UISizeConstraint")
			limit.MaxSize = Vector2.new(MAX_WIDTH - 40, math.huge)
			limit.Parent = label
			local stroke = Util.textStroke(label, Theme.Colors.Ink, Theme.Stroke.Text + 0.5)
			local pop = Util.scale(label)

			local entry: Entry = {
				key = key,
				text = text,
				count = 1,
				slot = slot,
				label = label,
				stroke = stroke,
				icon = icon,
				pop = pop,
				timer = nil,
				dying = false,
			}
			table.insert(alive, entry)
			byKey[key] = entry

			-- fade in (<= 0.2 s) with a small grow from 0.85
			label.TextTransparency = 1
			stroke.Transparency = 1
			if icon then
				icon.ImageTransparency = 1
				local glyph = icon:FindFirstChild("Glyph")
				if glyph and glyph:IsA("TextLabel") then
					glyph.TextTransparency = 1
				end
			end
			pop.Scale = 0.85
			Util.tweenOut(pop, Motion.ToastIn, { Scale = 1 })
			fade(entry, 0, Motion.ToastIn, nil)
			arm(entry, hold)
		end,
		clear = function(_self: Toasts)
			for _, entry in table.clone(alive) do
				dismiss(entry)
			end
		end,
		destroy = function(_self: Toasts)
			for _, entry in alive do
				if entry.timer then
					task.cancel(entry.timer)
					entry.timer = nil
				end
			end
			table.clear(alive)
			table.clear(byKey)
			cleaner:clean()
			top:Destroy()
			bottom:Destroy()
		end,
	}
	return api
end

return Toasts
