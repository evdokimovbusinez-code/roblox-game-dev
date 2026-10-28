--!strict
-- Modal window in the canon panel form (ui-canon 3.7): cream rounded panel, thick dark stroke, floating blue title tab on the
-- top edge, RED SQUARE close button with a white X overlapping the top-right corner.
--
-- Motion (animation.md R12/R13): open = UIScale 0.6 -> 1 in 0.3 s Back Out; close = 1 -> 0.95 in 0.1 s Quad In, then hidden.
-- Windows do not fade through a CanvasGroup (extra texture memory on phones): scale only, the dim layer does the rest.
-- Open/close dim/blur and the "one window at a time" rule belong to WindowManager; a Window alone works too.

local Button = require(script.Parent.Button)
local Motion = require(script.Parent.Motion)
local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)

local Window = {}

export type DimMode = "none" | "dim" | "blur" | "both"

export type Options = {
	id: string,
	title: string,
	size: Vector2?, -- design units, default 480 x 280; shrunk automatically to fit small screens
	dim: DimMode?, -- background treatment applied by WindowManager (default "both")
	closable: boolean?, -- show the red X (default true)
	dismissOnDim: boolean?, -- tapping outside closes (default false, never for purchase dialogs)
	onOpen: (() -> ())?,
	onClose: (() -> ())?,
}

export type Window = {
	Id: string,
	DimMode: DimMode,
	DismissOnDim: boolean,
	Instance: Frame, -- the holder (scaled by open/close animation)
	Panel: Frame,
	Content: Frame, -- put your UI here
	Title: TextLabel,
	CloseButton: Button.Button?,
	onCloseRequest: ((window: Window) -> ())?, -- WindowManager sets this so X goes through the manager
	open: (self: Window) -> (),
	close: (self: Window, instant: boolean?) -> (),
	isOpen: (self: Window) -> boolean,
	setTitle: (self: Window, title: string) -> (),
	destroy: (self: Window) -> (),
}

local TITLE_TAB_HEIGHT = 34
local CONTENT_TOP = 26
local PADDING = 12

function Window.new(screen: Screen.Screen, options: Options): Window
	local cleaner = Util.newCleaner()
	local sizes = screen.Sizes
	local wanted = options.size or Vector2.new(480, 280)
	local open = false

	local holder = Util.frame(screen.Windows, "Window_" .. options.id, UDim2.fromOffset(wanted.X, wanted.Y))
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.52) -- a little low: leaves room for the title tab and X overhang
	holder.ZIndex = 2
	holder.Visible = false
	local scale = Util.scale(holder, Motion.WindowOpenFromScale)

	-- shadow
	local shadow = Util.frame(holder, "Shadow", UDim2.fromScale(1, 1), UDim2.fromOffset(0, Theme.Shadow.Offset * 2))
	shadow.BackgroundColor3 = Theme.Shadow.Color
	shadow.BackgroundTransparency = Theme.Shadow.Transparency
	shadow.ZIndex = 1
	Util.corner(shadow, Theme.Radius.Panel)

	-- panel body: cream fill, thick dark stroke, thin light inner line
	local panel = Util.frame(holder, "Panel", UDim2.fromScale(1, 1))
	panel.BackgroundTransparency = 0
	panel.BackgroundColor3 = Theme.Colors.PanelBody
	panel.ZIndex = 2
	Util.corner(panel, Theme.Radius.Panel)
	Util.stroke(panel, Theme.Colors.PanelStroke, Theme.Stroke.Panel + 1)
	local inner = Util.frame(panel, "Inner", UDim2.new(1, -8, 1, -8), UDim2.fromOffset(4, 4))
	Util.corner(inner, Theme.Radius.Panel - 3)
	Util.stroke(inner, Theme.Colors.PanelInner, 1.5)

	local content =
		Util.frame(panel, "Content", UDim2.new(1, -PADDING * 2, 1, -(CONTENT_TOP + PADDING)), UDim2.fromOffset(PADDING, CONTENT_TOP))

	-- title tab floating on the top edge
	local tab = Util.frame(holder, "TitleTab", UDim2.fromOffset(0, TITLE_TAB_HEIGHT))
	tab.AutomaticSize = Enum.AutomaticSize.X
	tab.AnchorPoint = Vector2.new(0.5, 0.5)
	tab.Position = UDim2.fromScale(0.5, 0)
	tab.BackgroundTransparency = 0
	tab.BackgroundColor3 = Theme.Colors.Header
	tab.ZIndex = 3
	Util.corner(tab, 12)
	Util.stroke(tab, Theme.Colors.HeaderStroke, Theme.Stroke.Panel)
	Util.shade(tab, 0.82)
	local tabPad = Instance.new("UIPadding")
	tabPad.PaddingLeft = UDim.new(0, 22)
	tabPad.PaddingRight = UDim.new(0, 22)
	tabPad.Parent = tab
	local title = Util.text(tab, options.title, sizes.title, Theme.Colors.White)
	title.Name = "Title"
	title.AutomaticSize = Enum.AutomaticSize.X
	title.Size = UDim2.fromScale(0, 1)

	local window: Window
	window = {
		Id = options.id,
		DimMode = options.dim or "both",
		DismissOnDim = options.dismissOnDim == true,
		Instance = holder,
		Panel = panel,
		Content = content,
		Title = title,
		CloseButton = nil :: Button.Button?,
		onCloseRequest = nil :: ((window: Window) -> ())?,
		open = function(self: Window)
			if open then
				return
			end
			open = true
			holder.Visible = true
			scale.Scale = Motion.WindowOpenFromScale
			Util.tween(
				scale,
				Motion.WindowOpen,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out,
				{ Scale = 1 }
			)
			if options.onOpen then
				options.onOpen()
			end
		end,
		close = function(self: Window, instant: boolean?)
			if not open then
				return
			end
			open = false
			local function hide()
				holder.Visible = false
				scale.Scale = Motion.WindowOpenFromScale
			end
			if instant == true then
				Util.tween(scale, 0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { Scale = 1 })
				hide()
			else
				Util.tweenIn(scale, Motion.WindowClose, { Scale = Motion.WindowCloseToScale }, hide)
			end
			if options.onClose then
				options.onClose()
			end
		end,
		isOpen = function(_self: Window): boolean
			return open
		end,
		setTitle = function(_self: Window, text: string)
			title.Text = text
		end,
		destroy = function(_self: Window)
			cleaner:clean()
			holder:Destroy()
		end,
	}

	-- red square X on the top-right corner, half outside the panel
	if options.closable ~= false then
		local close = Button.close(sizes.close, function()
			if window.onCloseRequest then
				window.onCloseRequest(window)
			else
				window:close()
			end
		end)
		close.Instance.AnchorPoint = Vector2.new(0.5, 0.5)
		close.Instance.Position = UDim2.new(1, -6, 0, 6)
		close.Instance.ZIndex = 4
		close.Instance.Parent = holder
		window.CloseButton = close
		cleaner:add(function()
			close:destroy()
		end)
	end

	-- fit to the screen: never larger than the usable area (phone landscape is only ~350 units tall)
	local function fit(available: Vector2)
		local width = math.min(wanted.X, available.X - 2 * sizes.margin - sizes.close)
		local height = math.min(wanted.Y, available.Y - 2 * sizes.margin - TITLE_TAB_HEIGHT)
		holder.Size = UDim2.fromOffset(math.max(width, 200), math.max(height, 120))
	end
	fit(screen.Size)
	cleaner:connect(screen.Resized, function(available: Vector2)
		fit(available)
	end)

	return window
end

return Window
