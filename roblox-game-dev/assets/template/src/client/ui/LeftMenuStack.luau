--!strict
-- Left menu (ui-canon 3.1): icon tiles with a label UNDER the icon and an optional red notification badge.
-- Order by canon: Shop first, Rebirth under it, Index/Settings last. One menu location for the whole game.
--
-- Phone safety: the stack never reaches below Theme.Zones.leftStackBottom (58% of the screen height) so the left thumbstick area
-- stays free; when the items do not fit in one column they wrap into balanced columns (4 items -> 2 x 2 on a phone).

local Badge = require(script.Parent.Badge)
local Button = require(script.Parent.Button)
local Icons = require(script.Parent.Icons)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local LeftMenuStack = {}

export type Item = {
	id: string,
	label: string,
	icon: string, -- Icons key
	color: Color3?, -- tile color; default Icons.tint(icon)
	badge: Badge.Value?,
	onClick: (() -> ())?,
}

export type Options = {
	items: { Item },
	topOffset: number?, -- distance from the top of the safe area (default: below one currency row)
	onClick: ((id: string) -> ())?, -- called for every tile after the item's own onClick
}

export type LeftMenuStack = {
	Instance: Frame,
	setBadge: (self: LeftMenuStack, id: string, value: Badge.Value) -> (),
	getTile: (self: LeftMenuStack, id: string) -> Button.Button?,
	destroy: (self: LeftMenuStack) -> (),
}

function LeftMenuStack.new(screen: Screen.Screen, options: Options): LeftMenuStack
	local cleaner = Util.newCleaner()
	local sizes = screen.Sizes
	local tileSize = sizes.tile
	local gap = sizes.tileGap
	local startY = options.topOffset or (sizes.margin * 2 + sizes.currencyHeight)

	local container = Util.frame(screen.Hud, "LeftMenuStack", UDim2.new())
	container.AutomaticSize = Enum.AutomaticSize.XY
	container.Position = UDim2.fromOffset(sizes.margin, startY)

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(tileSize, tileSize)
	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.FillDirection = Enum.FillDirection.Vertical
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.VerticalAlignment = Enum.VerticalAlignment.Top
	grid.Parent = container

	local tiles: { [string]: Button.Button } = {}
	local badges: { [string]: Badge.Badge } = {}

	for index, item in options.items do
		local tint = item.color or Icons.tint(item.icon)
		local tile = Button.new({
			name = "Tile_" .. item.id,
			text = "",
			color = tint,
			size = UDim2.fromOffset(tileSize, tileSize),
			onClick = function()
				if item.onClick then
					item.onClick()
				end
				if options.onClick then
					options.onClick(item.id)
				end
			end,
		})
		tile.Instance.LayoutOrder = index

		local iconEdge = math.floor(tileSize * 0.58)
		local icon = Icons.new(tile.Button, item.icon, UDim2.fromOffset(iconEdge, iconEdge))
		icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 3)

		local label = Util.text(tile.Button, item.label, sizes.tileLabel)
		label.Name = "Label"
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 1, -2)
		label.Size = UDim2.new(1, -2, 0, sizes.tileLabel + 2)
		label.TextTruncate = Enum.TextTruncate.AtEnd

		local badge = Badge.new(tile.Button, sizes.badge)
		badge:set(item.badge)

		tile.Instance.Parent = container
		tiles[item.id] = tile
		badges[item.id] = badge
		cleaner:add(function()
			tile:destroy()
		end)
	end

	-- Recompute the column count only when the screen size changes (never per frame).
	local function relayout(available: Vector2)
		local maxHeight = available.Y * Theme.Zones.leftStackBottom - startY
		local rows = math.max(1, math.floor((maxHeight + gap) / (tileSize + gap)))
		local count = #options.items
		local columns = math.max(1, math.ceil(count / rows))
		rows = math.max(1, math.ceil(count / columns))
		grid.FillDirectionMaxCells = rows
	end
	relayout(screen.Size)
	cleaner:connect(screen.Resized, relayout)

	return {
		Instance = container,
		setBadge = function(_self: LeftMenuStack, id: string, value: Badge.Value)
			local badge = badges[id]
			if badge then
				badge:set(value)
			end
		end,
		getTile = function(_self: LeftMenuStack, id: string): Button.Button?
			return tiles[id]
		end,
		destroy = function(_self: LeftMenuStack)
			cleaner:clean()
			container:Destroy()
		end,
	}
end

return LeftMenuStack
