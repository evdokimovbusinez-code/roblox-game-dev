--!strict
-- Notification badge (ui-canon 3.4): red circle with a white number or "!", on the top-right corner of a menu tile.
-- Hidden when the value is nil / 0 / false. Pops (scale 1.25 -> 1) when it changes so the eye catches it.

local Motion = require(script.Parent.Motion)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local Badge = {}

export type Value = number | boolean | nil

export type Badge = {
	Instance: Frame,
	set: (self: Badge, value: Value) -> (),
}

-- true -> "!", n -> "n" (99+ above 99), nil/false/0 -> hidden.
function Badge.textFor(value: Value): string?
	if value == nil or value == false then
		return nil
	end
	if value == true then
		return "!"
	end
	if typeof(value) ~= "number" or value ~= value or value <= 0 then
		return nil
	end
	if value > 99 then
		return "99+"
	end
	return tostring(math.floor(value))
end

function Badge.new(parent: Instance, diameter: number): Badge
	local circle = Util.frame(parent, "Badge", UDim2.fromOffset(diameter, diameter))
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new(1, -3, 0, 3)
	circle.BackgroundTransparency = 0
	circle.BackgroundColor3 = Theme.Colors.Red
	circle.ZIndex = 10
	circle.Visible = false
	Util.pill(circle)
	Util.stroke(circle, Color3.new(1, 1, 1), 1.5)
	local label = Util.text(circle, "!", math.floor(diameter * 0.62))
	label.TextXAlignment = Enum.TextXAlignment.Center
	local scale = Util.scale(circle)

	local shown: string? = nil
	return {
		Instance = circle,
		set = function(_self: Badge, value: Value)
			local text = Badge.textFor(value)
			if text == nil then
				shown = nil
				circle.Visible = false
				return
			end
			circle.Visible = true
			if text ~= shown then
				shown = text
				label.Text = text
				scale.Scale = 1.25
				Util.tweenOut(scale, Motion.BumpTime * 2, { Scale = 1 })
			end
		end,
	}
end

return Badge
