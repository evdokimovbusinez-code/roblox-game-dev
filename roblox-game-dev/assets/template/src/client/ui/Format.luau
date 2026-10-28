--!strict
-- Text formatting for UI. Number abbreviation lives in Shared/NumberFormat (K/M/B/T/Qa..., TRUNCATED, never rounded);
-- this module re-exports it and adds durations, multipliers and Robux prices. No Roblox APIs except the require.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local Format = {}

-- 1_234 -> "1.2K", 1_500_000 -> "1.5M", 2.5e12 -> "2.5T". `decimals` 0..3 (default 1).
Format.abbreviate = NumberFormat.abbreviate
-- 1234567 -> "1,234,567" (tooltips, receipts)
Format.commas = NumberFormat.commas
-- 75 -> "1:15", 3725 -> "1:02:05" (cooldown timers, canon "0:05")
Format.clock = NumberFormat.clock

local UNITS: { { name: string, seconds: number } } = {
	{ name = "d", seconds = 86400 },
	{ name = "h", seconds = 3600 },
	{ name = "m", seconds = 60 },
	{ name = "s", seconds = 1 },
}

-- Human duration: duration(8375) = "2h 19m 35s", duration(93600, 2) = "1d 2h", duration(0) = "0s".
-- Shows at most `maxParts` units (default 3), starting from the largest non-zero one; negative/NaN -> "0s".
function Format.duration(totalSeconds: number, maxParts: number?): string
	if totalSeconds ~= totalSeconds or totalSeconds < 1 then
		return "0s"
	end
	if totalSeconds == math.huge then
		return "0s"
	end
	local limit = math.max(1, math.floor(maxParts or 3))
	local remaining = math.floor(totalSeconds)
	local parts: { string } = {}
	for _, unit in UNITS do
		if #parts >= limit then
			break
		end
		local amount = remaining // unit.seconds
		if amount > 0 or #parts > 0 then
			remaining -= amount * unit.seconds
			-- once started, keep consecutive units (a zero in the middle is shown, "1h 0m 5s")
			table.insert(parts, tostring(amount) .. unit.name)
		end
	end
	-- trim trailing zero units: 7200 -> "2h", not "2h 0m 0s"
	while #parts > 1 and string.sub(parts[#parts], 1, 1) == "0" do
		table.remove(parts)
	end
	return table.concat(parts, " ")
end

-- Multiplier tag: multiplier(2) = "x2", multiplier(1.5) = "x1.5", multiplier(1.25) = "x1.25".
function Format.multiplier(value: number): string
	if value ~= value or value == math.huge or value == -math.huge then
		return "x1"
	end
	local text = string.format("%.2f", value)
	text = string.gsub(text, "0+$", "")
	text = string.gsub(text, "%.$", "")
	return "x" .. text
end

-- Percent for UI chips: percent(0.125) = "12.5%", percent(1) = "100%". Input is a 0..1 fraction.
function Format.percent(fraction: number): string
	if fraction ~= fraction or fraction == math.huge or fraction == -math.huge then
		return "0%"
	end
	local text = string.format("%.1f", fraction * 100)
	text = string.gsub(text, "%.0$", "")
	return text .. "%"
end

-- "<Robux glyph> 99". The price string should come from MarketplaceService/ProductInfo, never hardcode it in the game.
-- `glyph` is injected so this stays testable: Theme.RobuxGlyph in the game.
function Format.robux(price: number | string, glyph: string?): string
	local sign = glyph or utf8.char(0xE002)
	if typeof(price) == "number" then
		return sign .. " " .. NumberFormat.commas(price)
	end
	return sign .. " " .. price
end

return Format
