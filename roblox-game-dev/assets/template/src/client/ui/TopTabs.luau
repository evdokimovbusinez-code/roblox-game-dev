--!strict
-- Top-center tabs (ui-canon 3.7, GAG-style SEEDS / GARDEN / SELL). State by transparency and size, not only by color:
-- the selected tab is opaque and slightly larger, the others are 35% transparent. Keep to 2-4 tabs on a phone.

local Button = require(script.Parent.Button)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local TopTabs = {}

export type Tab = {
	id: string,
	label: string,
	color: Color3?, -- default info blue
}

export type Options = {
	tabs: { Tab },
	selected: string?,
	onSelect: ((id: string) -> ())?,
}

export type TopTabs = {
	Instance: Frame,
	setSelected: (self: TopTabs, id: string) -> (),
	selected: (self: TopTabs) -> string?,
	destroy: (self: TopTabs) -> (),
}

function TopTabs.new(screen: Screen.Screen, options: Options): TopTabs
	local cleaner = Util.newCleaner()
	local sizes = screen.Sizes

	local row = Util.frame(screen.Hud, "TopTabs", UDim2.fromOffset(0, sizes.tabHeight + 6))
	row.AutomaticSize = Enum.AutomaticSize.X
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.new(0.5, 0, 0, sizes.margin)
	Util.list(row, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

	local buttons: { [string]: Button.Button } = {}
	local current: string? = options.selected

	local function paint()
		for id, tab in buttons do
			local isSelected = id == current
			Util.tweenOut(tab.Button, 0.12, { BackgroundTransparency = if isSelected then 0 else 0.35 })
			Util.tweenOut(tab.Instance, 0.12, {
				Size = UDim2.fromOffset(sizes.tabWidth, if isSelected then sizes.tabHeight + 4 else sizes.tabHeight),
			})
		end
	end

	for index, tab in options.tabs do
		local button = Button.new({
			name = "Tab_" .. tab.id,
			text = tab.label,
			color = tab.color or Theme.Variants.info.fill,
			size = UDim2.fromOffset(sizes.tabWidth, sizes.tabHeight),
			textSize = sizes.tabText,
			onClick = function()
				if current == tab.id then
					return
				end
				current = tab.id
				paint()
				if options.onSelect then
					options.onSelect(tab.id)
				end
			end,
		})
		button.Instance.LayoutOrder = index
		button.Instance.Parent = row
		buttons[tab.id] = button
		cleaner:add(function()
			button:destroy()
		end)
	end
	paint()

	return {
		Instance = row,
		setSelected = function(_self: TopTabs, id: string)
			if buttons[id] and current ~= id then
				current = id
				paint()
			end
		end,
		selected = function(_self: TopTabs): string?
			return current
		end,
		destroy = function(_self: TopTabs)
			cleaner:clean()
			row:Destroy()
		end,
	}
end

return TopTabs
