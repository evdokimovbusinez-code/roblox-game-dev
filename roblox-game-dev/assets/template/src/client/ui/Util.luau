--!strict
-- Small helpers shared by the components: instance builders, reduced-motion aware tweens, cleanup.
-- No external dependencies: plain Instance.new + TweenService.

local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Util = {}

-- Cleanup ------------------------------------------------------------------------------------------------------------

export type Cleanable = Instance | RBXScriptConnection | () -> ()

export type Cleaner = {
	add: (self: Cleaner, item: Cleanable) -> (),
	connect: <T...>(self: Cleaner, signal: RBXScriptSignal<T...>, fn: (T...) -> ()) -> (),
	clean: (self: Cleaner) -> (),
}

-- Collects connections, instances and callbacks; clean() releases everything once. Every component owns one.
function Util.newCleaner(): Cleaner
	local items: { Cleanable } = {}
	local cleaner: Cleaner
	cleaner = {
		add = function(_self: Cleaner, item: Cleanable)
			table.insert(items, item)
		end,
		connect = function<T...>(self: Cleaner, signal: RBXScriptSignal<T...>, fn: (T...) -> ())
			self:add(signal:Connect(fn))
		end,
		clean = function(_self: Cleaner)
			local list = items
			items = {}
			for _, item in list do
				local kind = typeof(item)
				if kind == "RBXScriptConnection" then
					(item :: RBXScriptConnection):Disconnect()
				elseif kind == "Instance" then
					(item :: Instance):Destroy()
				elseif kind == "function" then
					(item :: () -> ())()
				end
			end
		end,
	}
	return cleaner
end

-- Motion -------------------------------------------------------------------------------------------------------------

-- GuiService.ReducedMotionEnabled (player setting). When true every tween below completes instantly.
function Util.reducedMotion(): boolean
	local ok, value = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	return ok and value == true
end

-- Tween with a completion callback that only fires when the tween REALLY completed (not when a newer tween cancelled it).
-- Reduced motion or duration <= 0: properties are set immediately and onDone runs at once. Returns the Tween or nil.
function Util.tween(
	instance: Instance,
	duration: number,
	style: Enum.EasingStyle,
	direction: Enum.EasingDirection,
	goals: { [string]: any },
	onDone: (() -> ())?
): Tween?
	if duration <= 0 or Util.reducedMotion() then
		for property, value in goals do
			(instance :: any)[property] = value
		end
		if onDone then
			onDone()
		end
		return nil
	end
	local tween = TweenService:Create(instance, TweenInfo.new(duration, style, direction), goals)
	if onDone then
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed then
				onDone()
			end
		end)
	end
	tween:Play()
	return tween
end

-- Quad Out shorthand (entrances and confirmations).
function Util.tweenOut(instance: Instance, duration: number, goals: { [string]: any }, onDone: (() -> ())?): Tween?
	return Util.tween(instance, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, goals, onDone)
end

-- Quad In shorthand (exits).
function Util.tweenIn(instance: Instance, duration: number, goals: { [string]: any }, onDone: (() -> ())?): Tween?
	return Util.tween(instance, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In, goals, onDone)
end

-- Instance builders --------------------------------------------------------------------------------------------------

function Util.corner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

-- Round pill (fully rounded ends).
function Util.pill(parent: Instance): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = parent
	return corner
end

-- Border stroke on a Frame/Button (outline of the shape).
function Util.stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

-- Outline of TEXT (set on a TextLabel/TextButton). Do not animate Thickness (flicker, cost).
function Util.textStroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Color = color or Theme.Colors.Ink
	stroke.Thickness = thickness or Theme.Stroke.Text
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Parent = parent
	return stroke
end

-- Top-light to bottom-dark gradient. The parent's BackgroundColor3 carries the real color (gradient is a multiplier).
function Util.shade(parent: Instance, bottom: number?): UIGradient
	local shade = bottom or 0.78
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(shade, shade, shade))
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

function Util.padding(parent: Instance, all: number): UIPadding
	local padding = Instance.new("UIPadding")
	local unit = UDim.new(0, all)
	padding.PaddingTop = unit
	padding.PaddingBottom = unit
	padding.PaddingLeft = unit
	padding.PaddingRight = unit
	padding.Parent = parent
	return padding
end

function Util.list(
	parent: Instance,
	direction: Enum.FillDirection,
	gap: number,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction
	layout.Padding = UDim.new(0, gap)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left
	layout.VerticalAlignment = vertical or Enum.VerticalAlignment.Top
	layout.Parent = parent
	return layout
end

function Util.frame(parent: Instance?, name: string, size: UDim2, position: UDim2?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = size
	frame.Position = position or UDim2.new()
	frame.Parent = parent
	return frame
end

-- Text with the canon outline: bold round font, white, dark UIStroke. Returns the label (stroke is its child).
function Util.text(
	parent: Instance?,
	text: string,
	textSize: number,
	color: Color3?,
	outline: boolean?
): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.FontFace = Theme.Font.Display
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color or Theme.Colors.White
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Size = UDim2.fromScale(1, 1)
	if outline ~= false then
		Util.textStroke(label)
	end
	label.Parent = parent
	return label
end

-- A UIScale child used for press/pop feedback (create once, tween its Scale; never resize the element itself).
function Util.scale(parent: Instance, value: number?): UIScale
	local scale = Instance.new("UIScale")
	scale.Scale = value or 1
	scale.Parent = parent
	return scale
end

-- Removes (and destroys) all non-layout children: helper for rebuilding content lists.
function Util.clear(parent: Instance)
	for _, child in parent:GetChildren() do
		if not child:IsA("UIListLayout") and not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

return Util
