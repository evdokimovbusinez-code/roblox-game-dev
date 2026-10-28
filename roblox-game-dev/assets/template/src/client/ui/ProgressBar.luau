--!strict
-- Level / XP bar: dark pill track, colored fill, "120/500" text with outline, optional round level badge on the left.
-- set() resizes only the Fill's Size (one property, no layout pass); text is rewritten only when the string changes.

local Format = require(script.Parent.Format)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local ProgressBar = {}

export type Options = {
	size: UDim2?, -- default (1, 0, 0, 22)
	color: Color3?, -- fill color (default green)
	level: number?, -- shows a round level badge when given
	showText: boolean?, -- "value/max" in the middle (default true)
	textSize: number?,
	name: string?,
}

export type ProgressBar = {
	Instance: Frame,
	Fill: Frame,
	Label: TextLabel,
	set: (self: ProgressBar, value: number, max: number, animate: boolean?) -> (),
	setLevel: (self: ProgressBar, level: number) -> (),
	destroy: (self: ProgressBar) -> (),
}

function ProgressBar.new(options: Options?): ProgressBar
	local opts: Options = options or {}
	local height = if opts.size then opts.size.Y.Offset else 22
	local root = Util.frame(nil, opts.name or "ProgressBar", opts.size or UDim2.new(1, 0, 0, height))

	local track = Util.frame(root, "Track", UDim2.new(1, 0, 1, 0))
	track.BackgroundTransparency = 0
	track.BackgroundColor3 = Theme.Colors.Pill
	Util.pill(track)
	Util.stroke(track, Theme.Colors.Ink, Theme.Stroke.Pill)

	local fillHolder = Util.frame(track, "FillHolder", UDim2.new(1, -6, 1, -6), UDim2.fromOffset(3, 3))
	fillHolder.ClipsDescendants = true
	Util.pill(fillHolder)
	local fill = Util.frame(fillHolder, "Fill", UDim2.fromScale(0, 1))
	fill.BackgroundTransparency = 0
	fill.BackgroundColor3 = opts.color or Theme.Variants.primary.fill
	Util.pill(fill)
	Util.shade(fill, 0.75)

	local label = Util.text(track, "", opts.textSize or math.max(12, math.floor(height * 0.6)))
	label.Name = "Label"
	label.Visible = opts.showText ~= false

	local badge: TextLabel? = nil
	if opts.level ~= nil then
		local size = height + 10
		local circle = Util.frame(root, "LevelBadge", UDim2.fromOffset(size, size))
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.Position = UDim2.new(0, 0, 0.5, 0)
		circle.BackgroundTransparency = 0
		circle.BackgroundColor3 = Theme.Colors.Gold
		circle.ZIndex = 3
		Util.pill(circle)
		Util.stroke(circle, Theme.Colors.GoldDark, Theme.Stroke.Pill)
		badge = Util.text(circle, tostring(opts.level), math.floor(size * 0.5))
		track.Size = UDim2.new(1, -size / 2, 1, 0)
		track.Position = UDim2.fromOffset(size / 2, 0)
	end

	local shownText = ""
	local self: ProgressBar = {
		Instance = root,
		Fill = fill,
		Label = label,
		set = function(_self: ProgressBar, value: number, max: number, animate: boolean?)
			local fraction = if max > 0 then math.clamp(value / max, 0, 1) else 0
			if animate == false then
				fill.Size = UDim2.fromScale(fraction, 1)
			else
				Util.tweenOut(fill, Motion.BarFill, { Size = UDim2.fromScale(fraction, 1) })
			end
			local text = Format.abbreviate(value) .. "/" .. Format.abbreviate(max)
			if text ~= shownText then
				shownText = text
				label.Text = text
			end
		end,
		setLevel = function(_self: ProgressBar, level: number)
			if badge then
				badge.Text = tostring(level)
			end
		end,
		destroy = function(_self: ProgressBar)
			root:Destroy()
		end,
	}
	return self
end

return ProgressBar
