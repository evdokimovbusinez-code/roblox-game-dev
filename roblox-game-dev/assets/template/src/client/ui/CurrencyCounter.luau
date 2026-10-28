--!strict
-- Currency pill (ui-canon 3.2 "Панель валют"): icon + abbreviated number (K/M/B/T) with a thick outline, optional green "+" button.
--
--   set(v)           instant: small changes, every tick of a passive income (animation.md R16: no count-up for small deltas)
--   countTo(v, s)    ~1 s count-up for BIG rewards: creep 25% of the time, fast sweep, soft tail (Curves.countCurve)
--   bump()           1.08 pop on the pill (call when fly sprites arrive)
--   Icon             the fly-to target for RewardFly
--
-- The displayed text is rewritten only when the formatted string changes, so a 1 s count-up costs ~20 text updates, not 60.

local RunService = game:GetService("RunService")

local Button = require(script.Parent.Button)
local Curves = require(script.Parent.Curves)
local Format = require(script.Parent.Format)
local Icons = require(script.Parent.Icons)
local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local CurrencyCounter = {}

export type Options = {
	id: string,
	icon: string, -- Icons key ("coin", "gem")
	value: number?,
	accent: Color3?, -- pill border/fill tint; defaults to the icon tint darkened
	height: number?, -- design units (default Theme.Sizes.currencyHeight via screen)
	textSize: number?,
	decimals: number?, -- digits after the point in K/M/B/T (default 1)
	onPlus: (() -> ())?, -- show a green "+" that opens the shop (only for currencies you sell)
	minTextWidth: number?, -- keeps the pill from jittering while digits change
}

export type CurrencyCounter = {
	Id: string,
	Instance: Frame,
	Icon: ImageLabel,
	Label: TextLabel,
	Value: number, -- last target value (what the pill shows or is counting to)
	set: (self: CurrencyCounter, value: number) -> (),
	countTo: (self: CurrencyCounter, value: number, seconds: number?) -> (),
	bump: (self: CurrencyCounter) -> (),
	destroy: (self: CurrencyCounter) -> (),
}

function CurrencyCounter.new(options: Options): CurrencyCounter
	local cleaner = Util.newCleaner()
	local height = options.height or 32
	local textSize = options.textSize or 20
	local decimals = options.decimals or 1
	local accent = options.accent or Theme.darken(Icons.tint(options.icon), 0.55)

	local pill = Util.frame(nil, "Currency_" .. options.id, UDim2.fromOffset(0, height))
	pill.AutomaticSize = Enum.AutomaticSize.X
	pill.BackgroundTransparency = 0
	pill.BackgroundColor3 = accent
	Util.pill(pill)
	Util.stroke(pill, Theme.Colors.Ink, Theme.Stroke.Pill)
	Util.shade(pill, 0.7)
	local scale = Util.scale(pill)

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 4)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = pill
	Util.list(pill, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local icon = Icons.new(pill, options.icon, UDim2.fromOffset(height + 6, height + 6))
	icon.SizeConstraint = Enum.SizeConstraint.RelativeXY
	icon.LayoutOrder = 1

	local label = Util.text(pill, "0", textSize, Theme.Colors.White)
	label.Name = "Value"
	label.AutomaticSize = Enum.AutomaticSize.X
	label.Size = UDim2.new(0, 0, 1, 0)
	label.LayoutOrder = 2
	label.TextXAlignment = Enum.TextXAlignment.Left
	local minWidth = Instance.new("UISizeConstraint")
	minWidth.MinSize = Vector2.new(options.minTextWidth or textSize * 2.2, 0)
	minWidth.Parent = label

	if options.onPlus then
		local button = Button.new({
			name = "Plus",
			text = "+",
			variant = "primary",
			size = UDim2.fromOffset(height - 6, height - 6),
			textSize = textSize,
			onClick = options.onPlus,
		})
		button.Instance.LayoutOrder = 3
		button.Instance.Parent = pill
		cleaner:add(function()
			button:destroy()
		end)
	end

	local shown = ""
	local animation: RBXScriptConnection? = nil

	local function show(value: number)
		local text = Format.abbreviate(value, decimals)
		if text ~= shown then
			shown = text
			label.Text = text
		end
	end

	local function stop()
		if animation then
			animation:Disconnect()
			animation = nil
		end
	end
	cleaner:add(stop)

	local counter: CurrencyCounter
	counter = {
		Id = options.id,
		Instance = pill,
		Icon = icon,
		Label = label,
		Value = options.value or 0,
		set = function(self: CurrencyCounter, value: number)
			stop()
			self.Value = value
			show(value)
		end,
		countTo = function(self: CurrencyCounter, value: number, seconds: number?)
			local from = self.Value
			local duration = seconds or Motion.CountDuration
			stop()
			self.Value = value
			if Util.reducedMotion() or duration <= 0 or from == value then
				show(value)
				return
			end
			local started = os.clock()
			animation = RunService.RenderStepped:Connect(function()
				local t = (os.clock() - started) / duration
				if t >= 1 then
					stop()
					show(value)
					return
				end
				show(from + (value - from) * Curves.countCurve(t))
			end)
		end,
		bump = function(_self: CurrencyCounter)
			scale.Scale = Motion.BumpScale
			Util.tweenOut(scale, Motion.BumpTime * 2, { Scale = 1 })
		end,
		destroy = function(_self: CurrencyCounter)
			cleaner:clean()
			pill:Destroy()
		end,
	}

	show(counter.Value)
	return counter
end

return CurrencyCounter
