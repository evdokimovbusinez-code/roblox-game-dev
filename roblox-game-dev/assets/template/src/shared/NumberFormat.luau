--!strict
-- Display formatting for big numbers. Pure functions, no Roblox APIs: easy to unit test.
-- Rule: TRUNCATE, never round. 1_999 -> "1.9K" (rounding would show "2K" while the player is 1 coin short of it).

local NumberFormat = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function trimZeros(text: string): string
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text
end

-- abbreviate(950) = "950", abbreviate(1_234) = "1.2K", abbreviate(1_500_000, 2) = "1.5M", abbreviate(-2_500) = "-2.5K".
-- Non-finite input (NaN / inf) returns "0": never show garbage to the player.
function NumberFormat.abbreviate(value: number, decimals: number?): string
	if value ~= value or value == math.huge or value == -math.huge then
		return "0"
	end
	local places = math.clamp(math.floor(decimals or 1), 0, 3)
	local sign = if value < 0 then "-" else ""
	local scaled = math.abs(value)
	if scaled < 1000 then
		return sign .. tostring(math.floor(scaled))
	end
	local tier = 0
	while scaled >= 1000 and tier < #SUFFIXES - 1 do
		scaled /= 1000
		tier += 1
	end
	local factor = 10 ^ places
	local truncated = math.floor(scaled * factor) / factor
	return sign .. trimZeros(string.format("%." .. places .. "f", truncated)) .. SUFFIXES[tier + 1]
end

-- commas(1234567) = "1,234,567" (full precision, for tooltips and receipts)
function NumberFormat.commas(value: number): string
	if value ~= value or value == math.huge or value == -math.huge then
		return "0"
	end
	local text = string.format("%d", math.floor(math.abs(value)))
	local formatted = text
	repeat
		local replaced
		formatted, replaced = string.gsub(formatted, "^(%d+)(%d%d%d)", "%1,%2")
	until replaced == 0
	return (if value < 0 then "-" else "") .. formatted
end

-- clock(75) = "1:15", clock(3725) = "1:02:05" (cooldown timers)
function NumberFormat.clock(totalSeconds: number): string
	local seconds = math.max(0, math.floor(totalSeconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

return NumberFormat
