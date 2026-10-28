--!strict
-- Motion defaults for UI (references/builder/animation.md sections 10 and 14, rules R12-R20, R29, R31).
-- One place for timings so the whole game feels the same and "reduce motion" is handled once (Util.tween).

local Motion = {
	-- Window (R12, R13): open is lively, close is nearly instant with a brief shrink.
	WindowOpen = 0.3,
	WindowOpenFromScale = 0.6,
	WindowClose = 0.1,
	WindowCloseToScale = 0.95,
	DimTransparency = 0.55, -- black overlay, about 45% darkening
	BlurSize = 12,
	DimTime = 0.2,

	-- Buttons (R14): press shrink 0.95, release back; hover grows on PC only.
	PressScale = 0.95,
	PressTime = 0.08,
	HoverScale = 1.05,
	HoverTime = 0.12,

	-- Counters (R16): small changes are instant; big rewards count up ~1 s (creep, sweep, soft tail).
	CountDuration = 1.0,
	CountInstantBelow = 0.0, -- reserved: set > 0 to skip animation for tiny deltas (fraction of the current value)
	BumpScale = 1.08,
	BumpTime = 0.1,

	-- Toasts (R19): fade in <= 0.2 s, hold >= 2.6 s, merge duplicates as "[X2]".
	ToastIn = 0.18,
	ToastHold = 2.8,
	ToastOut = 0.25,
	ToastMax = 4,

	-- Reward fly-to-counter (R17, R31): 2D sprites one by one, a single flight >= 0.15 s, at most ~30 alive on phones.
	FlyDuration = 0.55,
	FlyStep = 0.04,
	FlyMaxAlive = 30,

	-- Progress bar fill.
	BarFill = 0.25,
}

-- TweenInfo shortcuts for the common cases.
function Motion.out(duration: number): TweenInfo
	return TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

function Motion.into(duration: number): TweenInfo
	return TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
end

function Motion.pop(duration: number): TweenInfo
	return TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

return table.freeze(Motion)
