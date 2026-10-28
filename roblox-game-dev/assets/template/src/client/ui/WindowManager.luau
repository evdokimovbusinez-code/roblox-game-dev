--!strict
-- "One menu at a time" (art-ui-audio 9.4): opening a window closes the current one; dim and blur follow the window's DimMode.
-- Also the single place that knows whether a menu is open (gate HUD hints, hide the offer column, pause auto-hatch ...).

local Lighting = game:GetService("Lighting")

local Motion = require(script.Parent.Motion)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)
local Window = require(script.Parent.Window)

local WindowManager = {}

export type WindowManager = {
	register: (self: WindowManager, window: Window.Window) -> (),
	open: (self: WindowManager, id: string) -> (),
	close: (self: WindowManager) -> (),
	toggle: (self: WindowManager, id: string) -> (),
	current: (self: WindowManager) -> string?,
	get: (self: WindowManager, id: string) -> Window.Window?,
	Changed: RBXScriptSignal<string?>, -- fires with the open window id or nil
	destroy: (self: WindowManager) -> (),
}

function WindowManager.new(screen: Screen.Screen): WindowManager
	local cleaner = Util.newCleaner()
	local windows: { [string]: Window.Window } = {}
	local currentId: string? = nil

	local changed = Instance.new("BindableEvent")
	cleaner:add(changed)

	-- full-screen dim; a TextButton so it swallows taps meant for the HUD behind the modal
	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.AutoButtonColor = false
	dim.Text = ""
	dim.BorderSizePixel = 0
	dim.BackgroundColor3 = Theme.Colors.Dim
	dim.BackgroundTransparency = 1
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 1
	dim.Visible = false
	dim.Parent = screen.Windows
	cleaner:add(dim)

	local blur: BlurEffect? = nil
	local function getBlur(): BlurEffect
		if blur == nil then
			local effect = Instance.new("BlurEffect")
			effect.Name = "UiBlur"
			effect.Size = 0
			effect.Parent = Lighting
			blur = effect
			cleaner:add(effect)
		end
		return blur :: BlurEffect
	end

	local function applyBackdrop(mode: Window.DimMode, fade: boolean)
		local wantDim = mode == "dim" or mode == "both"
		local wantBlur = mode == "blur" or mode == "both"
		local duration = if fade then Motion.DimTime else 0
		if wantDim then
			dim.Visible = true
			Util.tweenOut(dim, duration, { BackgroundTransparency = Motion.DimTransparency })
		else
			Util.tweenOut(dim, duration, { BackgroundTransparency = 1 }, function()
				dim.Visible = false
			end)
		end
		if wantBlur or blur ~= nil then
			Util.tweenOut(getBlur(), duration, { Size = if wantBlur then Motion.BlurSize else 0 })
		end
	end

	local closeCurrent: () -> ()
	local openWindow: (id: string) -> ()

	local manager: WindowManager = {
		Changed = changed.Event :: any,
		register = function(_self: WindowManager, window: Window.Window)
			windows[window.Id] = window
			window.onCloseRequest = function(_w: Window.Window)
				closeCurrent()
			end
		end,
		get = function(_self: WindowManager, id: string): Window.Window?
			return windows[id]
		end,
		current = function(_self: WindowManager): string?
			return currentId
		end,
		open = function(_self: WindowManager, id: string)
			openWindow(id)
		end,
		close = function(_self: WindowManager)
			closeCurrent()
		end,
		toggle = function(_self: WindowManager, id: string)
			if currentId == id then
				closeCurrent()
			else
				openWindow(id)
			end
		end,
		destroy = function(_self: WindowManager)
			cleaner:clean()
			for _, window in windows do
				window:destroy()
			end
			table.clear(windows)
		end,
	}

	openWindow = function(id: string)
		local target = windows[id]
		if target == nil or currentId == id then
			return
		end
		local previous = if currentId then windows[currentId] else nil
		if previous then
			previous:close(true) -- instant: the new window pops in right away
		end
		currentId = id
		applyBackdrop(target.DimMode, previous == nil)
		target:open()
		changed:Fire(id)
	end

	closeCurrent = function()
		local id = currentId
		if id == nil then
			return
		end
		currentId = nil
		local window = windows[id]
		if window then
			window:close()
		end
		applyBackdrop("none", true)
		changed:Fire(nil)
	end

	cleaner:connect(dim.Activated, function()
		local id = currentId
		local window = if id then windows[id] else nil
		if window and window.DismissOnDim then
			closeCurrent()
		end
	end)

	return manager
end

return WindowManager
