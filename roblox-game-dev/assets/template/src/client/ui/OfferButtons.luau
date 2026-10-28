--!strict
-- Right-hand column of offers (Starter Pack, X2 Money, VIP ...): square tile with icon + short title and a GREEN price chip
-- under it (ui-canon 3.3: green = buy). Optional countdown pill on top.
--
-- Honesty rules (compliance.md): the countdown only displays a real, server-known deadline and never restarts by itself;
-- a struck-through "old price" is never shown. Prices come from ProductInfo and are passed in as ready text.
-- The component only reports clicks; opening the purchase prompt is the caller's job (usually: open the Shop window first).
--
-- Phone safety: the column ends above Theme.Zones.rightColumnBottom (55% of height): the jump / action buttons stay free.

local Button = require(script.Parent.Button)
local Format = require(script.Parent.Format)
local Icons = require(script.Parent.Icons)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local OfferButtons = {}

export type Offer = {
	id: string,
	title: string, -- 1-2 short words, "Starter", "x2 Cash"
	icon: string, -- Icons key
	priceText: string?, -- ready text from ProductInfo ("99"); nil = no chip
	robux: boolean?, -- prefix the official Robux glyph (default true when priceText is set)
	accent: Color3?, -- tile color (default orange)
	timerSeconds: number?, -- remaining seconds from the SERVER deadline
	onClick: (() -> ())?,
	onExpire: (() -> ())?,
}

export type Options = {
	offers: { Offer },
	onClick: ((id: string) -> ())?,
}

export type OfferButtons = {
	Instance: Frame,
	setTimer: (self: OfferButtons, id: string, seconds: number?) -> (),
	setVisible: (self: OfferButtons, id: string, visible: boolean) -> (),
	destroy: (self: OfferButtons) -> (),
}

type Entry = {
	slot: Frame,
	timerPill: Frame,
	timerLabel: TextLabel,
	endAt: number?,
	offer: Offer,
}

local DEFAULT_ACCENT = Color3.fromHex("FF8A2B")
local CHIP_OVERHANG = 12

function OfferButtons.new(screen: Screen.Screen, options: Options): OfferButtons
	local cleaner = Util.newCleaner()
	local sizes = screen.Sizes
	local tileSize = sizes.tile
	local gap = sizes.tileGap
	local cellHeight = tileSize + CHIP_OVERHANG

	local container = Util.frame(screen.Hud, "OfferButtons", UDim2.new())
	container.AutomaticSize = Enum.AutomaticSize.XY
	container.AnchorPoint = Vector2.new(1, 0)
	container.Position = UDim2.new(1, -sizes.margin, 0, sizes.margin)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(tileSize, cellHeight)
	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.FillDirection = Enum.FillDirection.Vertical
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Right
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.Parent = container

	local entries: { [string]: Entry } = {}
	local running = false

	local function refreshTimers()
		local now = os.clock()
		local anyActive = false
		for _, entry in entries do
			local endAt = entry.endAt
			if endAt ~= nil then
				local left = endAt - now
				if left <= 0 then
					entry.endAt = nil
					entry.timerPill.Visible = false
					if entry.offer.onExpire then
						task.spawn(entry.offer.onExpire)
					end
				else
					anyActive = true
					entry.timerPill.Visible = true
					local text = if left >= 86400 then Format.duration(left, 2) else Format.clock(left)
					if entry.timerLabel.Text ~= text then
						entry.timerLabel.Text = text
					end
				end
			end
		end
		return anyActive
	end

	local function ensureLoop()
		if running then
			return
		end
		running = true
		task.spawn(function()
			while running do
				if not refreshTimers() then
					running = false
					break
				end
				task.wait(1)
			end
		end)
	end
	cleaner:add(function()
		running = false
	end)

	for index, offer in options.offers do
		local slot = Util.frame(container, "Offer_" .. offer.id, UDim2.fromOffset(tileSize, cellHeight))
		slot.LayoutOrder = index

		local tile = Button.new({
			name = "Tile",
			text = "",
			color = offer.accent or DEFAULT_ACCENT,
			size = UDim2.new(1, 0, 0, tileSize),
			onClick = function()
				if offer.onClick then
					offer.onClick()
				end
				if options.onClick then
					options.onClick(offer.id)
				end
			end,
		})
		tile.Instance.Parent = slot

		local iconEdge = math.floor(tileSize * 0.52)
		local icon = Icons.new(tile.Button, offer.icon, UDim2.fromOffset(iconEdge, iconEdge))
		icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 3)

		local title = Util.text(tile.Button, offer.title, sizes.tileLabel)
		title.AnchorPoint = Vector2.new(0.5, 1)
		title.Position = UDim2.new(0.5, 0, 1, -2)
		title.Size = UDim2.new(1, -2, 0, sizes.tileLabel + 2)
		title.TextTruncate = Enum.TextTruncate.AtEnd

		-- price chip (green, overlaps the bottom edge)
		if offer.priceText ~= nil then
			local chip = Util.frame(slot, "Price", UDim2.new(1, 2, 0, CHIP_OVERHANG * 2 - 4))
			chip.AnchorPoint = Vector2.new(0.5, 1)
			chip.Position = UDim2.new(0.5, 0, 1, 0)
			chip.BackgroundTransparency = 0
			chip.BackgroundColor3 = Theme.Variants.primary.fill
			chip.ZIndex = 5
			Util.pill(chip)
			Util.stroke(chip, Theme.Variants.primary.stroke, Theme.Stroke.Pill)
			Util.shade(chip, 0.78)
			local text = offer.priceText
			if offer.robux ~= false then
				text = Theme.RobuxGlyph .. " " .. text
			end
			local priceLabel = Util.text(chip, text, sizes.small)
			priceLabel.TextTruncate = Enum.TextTruncate.AtEnd
		end

		-- timer pill on top
		local timerPill = Util.frame(slot, "Timer", UDim2.new(1, -4, 0, 14), UDim2.new(0, 2, 0, -4))
		timerPill.BackgroundTransparency = 0.15
		timerPill.BackgroundColor3 = Theme.Colors.Pill
		timerPill.ZIndex = 6
		timerPill.Visible = false
		Util.pill(timerPill)
		local timerLabel = Util.text(timerPill, "", 11)

		entries[offer.id] = {
			slot = slot,
			timerPill = timerPill,
			timerLabel = timerLabel,
			endAt = if offer.timerSeconds then os.clock() + offer.timerSeconds else nil,
			offer = offer,
		}
		cleaner:add(function()
			tile:destroy()
		end)
	end

	local function relayout(available: Vector2)
		local maxHeight = available.Y * Theme.Zones.rightColumnBottom - sizes.margin
		local rows = math.max(1, math.floor((maxHeight + gap) / (cellHeight + gap)))
		local columns = math.max(1, math.ceil(#options.offers / rows))
		rows = math.max(1, math.ceil(#options.offers / columns))
		grid.FillDirectionMaxCells = rows
	end
	relayout(screen.Size)
	cleaner:connect(screen.Resized, relayout)

	if refreshTimers() then
		ensureLoop()
	end

	return {
		Instance = container,
		setTimer = function(_self: OfferButtons, id: string, seconds: number?)
			local entry = entries[id]
			if entry == nil then
				return
			end
			entry.endAt = if seconds then os.clock() + seconds else nil
			if seconds == nil then
				entry.timerPill.Visible = false
			elseif refreshTimers() then
				ensureLoop()
			end
		end,
		setVisible = function(_self: OfferButtons, id: string, visible: boolean)
			local entry = entries[id]
			if entry then
				entry.slot.Visible = visible
			end
		end,
		destroy = function(_self: OfferButtons)
			cleaner:clean()
			container:Destroy()
		end,
	}
end

return OfferButtons
