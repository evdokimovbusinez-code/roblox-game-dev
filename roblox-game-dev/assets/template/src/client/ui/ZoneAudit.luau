--!strict
-- Dev check for "nothing interactive in the thumbstick / jump zones" (ui-canon, Theme.Zones). Walks screen.Hud and reports every
-- visible button whose rectangle overlaps a touch-control zone. Run it once after the HUD is built, in Studio, with the phone
-- emulator (or `force = true` on desktop): the numbers in Theme.Zones are approximations of DynamicThumbstick + jump button.
-- A button may opt out with the attribute AllowInTouchZone = true (e.g. a deliberate action button).

local Screen = require(script.Parent.Screen)
local Theme = require(script.Parent.Theme)

local ZoneAudit = {}

type Zone = { x0: number, x1: number, y0: number, y1: number }

local function visibleUpToHud(object: GuiObject, hud: Instance): boolean
	local current: Instance? = object
	while current ~= nil and current ~= hud do
		if current:IsA("GuiObject") and not current.Visible then
			return false
		end
		current = current.Parent
	end
	return true
end

local function overlaps(x0: number, y0: number, x1: number, y1: number, zone: Zone): boolean
	return x0 < zone.x1 and x1 > zone.x0 and y0 < zone.y1 and y1 > zone.y0
end

-- Returns one line per offending button ("Tile_shop overlaps thumbstick"). Empty list = clean.
-- On desktop (no touch controls) it returns {} unless `force` is true.
function ZoneAudit.check(screen: Screen.Screen, force: boolean?): { string }
	local problems: { string } = {}
	if screen.Device == "desktop" and force ~= true then
		return problems
	end
	local area = screen.Gui.AbsoluteSize
	if area.X < 1 or area.Y < 1 then
		return problems
	end
	local origin = screen.Root.AbsolutePosition
	local zones: { [string]: Zone } = { thumbstick = Theme.Zones.thumbstick, jump = Theme.Zones.jump }

	for _, object in screen.Hud:GetDescendants() do
		if not object:IsA("GuiButton") or object:GetAttribute("AllowInTouchZone") == true then
			continue
		end
		if not visibleUpToHud(object, screen.Hud) then
			continue
		end
		local position = (object.AbsolutePosition - origin) / area
		local size = object.AbsoluteSize / area
		for name, zone in zones do
			if overlaps(position.X, position.Y, position.X + size.X, position.Y + size.Y, zone) then
				table.insert(problems, string.format("%s overlaps %s", object:GetFullName(), name))
			end
		end
	end
	return problems
end

return ZoneAudit
