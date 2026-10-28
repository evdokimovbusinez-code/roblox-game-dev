--!strict
-- Pure easing math (no Roblox APIs, unit-testable with the plain Luau CLI).

local Curves = {}

local CREEP_END = 0.25 -- first quarter of the time ...
local CREEP_SHARE = 0.08 -- ... covers at most 8% of the distance (the "creeping" phase while sprites are still flying)

-- Count-up curve for big rewards (animation.md R16): creep -> fast sweep -> soft tail. t in [0, 1] -> progress in [0, 1].
-- Monotonic, continuous, countCurve(0) = 0, countCurve(1) = 1, countCurve(0.25) <= 0.1.
function Curves.countCurve(t: number): number
	if t ~= t then
		return 1
	end
	t = math.clamp(t, 0, 1)
	if t < CREEP_END then
		local u = t / CREEP_END
		return CREEP_SHARE * u * u -- ease-in: slow start
	end
	local u = (t - CREEP_END) / (1 - CREEP_END)
	return CREEP_SHARE + (1 - CREEP_SHARE) * (1 - (1 - u) * (1 - u)) -- quad ease-out: fast sweep, soft tail
end

-- Linear interpolation, a convenience for sprite paths.
function Curves.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Quadratic ease-in (sprites accelerate into the counter).
function Curves.easeIn(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t
end

-- Quadratic ease-out.
function Curves.easeOut(t: number): number
	t = math.clamp(t, 0, 1)
	return 1 - (1 - t) * (1 - t)
end

return table.freeze(Curves)
