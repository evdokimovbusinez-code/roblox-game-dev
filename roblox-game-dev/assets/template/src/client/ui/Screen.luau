--!strict
-- Root of the UI: one ScreenGui, safe-area aware, scaled per device, split into layers.
--
--   ScreenGui (ScreenInsets = CoreUISafeInsets: the Roblox top bar / notch / home indicator are already excluded)
--     Root  Frame, Size = 1/scale so its children can use Scale positions while Offsets are DESIGN UNITS
--       UIScale (scale chosen from Theme.Sizes[device].refHeight)
--       Hud      layer 1: currency, menus, tabs, offers (interactive HUD, keep out of Theme.Zones)
--       Windows  layer 2: dim + modal windows (one at a time, see WindowManager)
--       Overlay  layer 3: flying reward sprites
--       Toasts   layer 4: toasts above everything
--
-- Everything is computed on size changes only (never per frame).

local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local Screen = {}

export type Screen = {
	Gui: ScreenGui,
	Root: Frame,
	Hud: Frame,
	Windows: Frame,
	Overlay: Frame,
	Toasts: Frame,
	Device: Theme.Device,
	Sizes: Theme.Sizes,
	Scale: number,
	Size: Vector2, -- usable size in design units
	Resized: RBXScriptSignal<Vector2>, -- fires with the new design-unit size
	toLocal: (self: Screen, absolute: Vector2) -> Vector2,
	centerOf: (self: Screen, target: GuiObject) -> Vector2,
	destroy: (self: Screen) -> (),
}

export type Options = {
	name: string?,
	displayOrder: number?,
	device: Theme.Device?, -- force a device class (testing); default: detect
}

local function detectDevice(absolute: Vector2): Theme.Device
	local touchFirst = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if not touchFirst then
		return "desktop"
	end
	if math.min(absolute.X, absolute.Y) < 600 then
		return "phone"
	end
	return "tablet"
end

local function layer(parent: Instance, name: string, order: number): Frame
	local frame = Util.frame(parent, name, UDim2.fromScale(1, 1))
	frame.ZIndex = order
	return frame
end

function Screen.new(playerGui: Instance, options: Options?): Screen
	local opts: Options = options or {}
	local cleaner = Util.newCleaner()

	local gui = Instance.new("ScreenGui")
	gui.Name = opts.name or "Ui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets -- interactive UI stays out of the top bar and notches
	gui.IgnoreGuiInset = false
	gui.DisplayOrder = opts.displayOrder or 10
	gui.Parent = playerGui

	local root = Util.frame(gui, "Root", UDim2.fromScale(1, 1))
	local uiScale = Util.scale(root, 1)

	local resized = Instance.new("BindableEvent")
	cleaner:add(resized)

	local screen: Screen = {
		Gui = gui,
		Root = root,
		Hud = layer(root, "Hud", 1),
		Windows = layer(root, "Windows", 2),
		Overlay = layer(root, "Overlay", 3),
		Toasts = layer(root, "Toasts", 4),
		Device = "desktop",
		Sizes = Theme.Sizes.desktop,
		Scale = 1,
		Size = Vector2.new(1280, 720),
		Resized = resized.Event,
		toLocal = function(self: Screen, absolute: Vector2): Vector2
			return (absolute - self.Root.AbsolutePosition) / self.Scale
		end,
		centerOf = function(self: Screen, target: GuiObject): Vector2
			return self:toLocal(target.AbsolutePosition + target.AbsoluteSize / 2)
		end,
		destroy = function(_self: Screen)
			cleaner:clean()
			gui:Destroy()
		end,
	}

	local function update()
		local absolute = gui.AbsoluteSize
		if absolute.X < 1 or absolute.Y < 1 then
			return
		end
		local device: Theme.Device = opts.device or detectDevice(absolute)
		local range = Theme.ScaleRange[device]
		local sizes = Theme.Sizes[device]
		local scale = math.clamp(absolute.Y / sizes.refHeight, range.min, range.max)
		-- very narrow windows: never let the design width exceed the screen (keeps tabs and windows on screen)
		scale = math.min(scale, absolute.X / 420)
		scale = math.max(scale, 0.4)

		local changed = device ~= screen.Device or math.abs(scale - screen.Scale) > 1e-3
		screen.Device = device
		screen.Sizes = sizes
		screen.Scale = scale
		screen.Size = absolute / scale
		uiScale.Scale = scale
		root.Size = UDim2.fromScale(1 / scale, 1 / scale)
		if changed then
			resized:Fire(screen.Size)
		end
	end

	cleaner:connect(gui:GetPropertyChangedSignal("AbsoluteSize"), update)
	update()
	return screen
end

return Screen
