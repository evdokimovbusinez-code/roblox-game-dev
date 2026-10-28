--!strict
-- Design tokens for the code-only UI library: colors, fonts, stroke/shadow values and per-device sizes.
-- Dialect: "bright simulator" (references/builder/ui-canon.md section 4): cream panels, thick dark strokes, round display font.
-- Change identity here (palette, font, panel color); keep the SEMANTICS (green = buy, red = close/cancel, gold = special).
--
-- All sizes are DESIGN UNITS. Screen.luau multiplies them with a UIScale chosen per device, see Sizes[device].refHeight.

local Theme = {}

export type Variant = "primary" | "secondary" | "danger" | "gold" | "info"
export type Device = "phone" | "tablet" | "desktop"

export type VariantStyle = {
	fill: Color3, -- body color (multiplied by the white-to-grey button gradient)
	stroke: Color3, -- border: a very dark shade of the fill, never pure black
	text: Color3,
}

export type Sizes = {
	refHeight: number, -- ScreenGui.AbsoluteSize.Y (after insets) that maps to UIScale 1
	margin: number, -- distance of HUD groups from the safe-area edge
	tile: number, -- left-menu / offer tile edge
	tileGap: number,
	tileLabel: number, -- text size under a tile icon (>= 11 on phone)
	buttonHeight: number,
	buttonText: number,
	currencyHeight: number,
	currencyText: number,
	tabWidth: number,
	tabHeight: number,
	tabText: number,
	close: number, -- red square close button edge (touch target >= 44 on phone)
	title: number, -- window title text
	body: number, -- body text
	small: number, -- captions, timers
	toastText: number,
	badge: number, -- notification badge diameter
	flySprite: number, -- reward sprite edge (about 1.5% of screen height on phone)
}

Theme.Colors = {
	Ink = Color3.fromHex("1F2547"), -- generic outline, tinted navy instead of black
	White = Color3.fromHex("FFFFFF"),
	PanelBody = Color3.fromHex("FFF6E3"), -- cream panel
	PanelInner = Color3.fromHex("FFFFFF"),
	PanelStroke = Color3.fromHex("2A2F5C"),
	Header = Color3.fromHex("3DA5F5"),
	HeaderStroke = Color3.fromHex("12467A"),
	Gold = Color3.fromHex("FFC93C"),
	GoldDark = Color3.fromHex("7A4B00"),
	Gem = Color3.fromHex("3DA5F5"),
	Green = Color3.fromHex("3FCB4E"),
	Red = Color3.fromHex("F2453D"),
	Disabled = Color3.fromHex("9AA0AE"),
	DisabledStroke = Color3.fromHex("4B5060"),
	Dim = Color3.fromHex("000000"),
	TextDark = Color3.fromHex("2A2F5C"), -- body text on the cream panel (contrast about 11:1)
	TextMuted = Color3.fromHex("5C6286"),
	Pill = Color3.fromHex("26305E"), -- dark currency/progress track
}

Theme.Variants = {
	primary = { fill = Color3.fromHex("3FCB4E"), stroke = Color3.fromHex("14572A"), text = Color3.fromHex("FFFFFF") },
	secondary = { fill = Color3.fromHex("8FA3BF"), stroke = Color3.fromHex("2E3A4D"), text = Color3.fromHex("FFFFFF") },
	danger = { fill = Color3.fromHex("F2453D"), stroke = Color3.fromHex("6E1613"), text = Color3.fromHex("FFFFFF") },
	gold = { fill = Color3.fromHex("FFC93C"), stroke = Color3.fromHex("7A4B00"), text = Color3.fromHex("FFFFFF") },
	info = { fill = Color3.fromHex("3DA5F5"), stroke = Color3.fromHex("12467A"), text = Color3.fromHex("FFFFFF") },
} :: { [string]: VariantStyle }

-- Rarity ladder (ui-canon 3.5): grey, green, blue, purple, orange/gold, red/pink. Always show the tier NAME as text too.
Theme.Rarity = {
	Common = Color3.fromHex("B8BCC8"),
	Uncommon = Color3.fromHex("5FD068"),
	Rare = Color3.fromHex("3D8BFF"),
	Epic = Color3.fromHex("A55CFF"),
	Legendary = Color3.fromHex("FFA724"),
	Mythic = Color3.fromHex("FF4A6B"),
}

-- Fonts. FredokaOne (round display) for everything the player reads in a glance, BuilderSans for small dense text.
-- If you pick another family keep a thick dark UIStroke on it, the canon depends on that outline.
Theme.Font = {
	Display = Font.fromEnum(Enum.Font.FredokaOne),
	Body = Font.fromEnum(Enum.Font.BuilderSansBold),
}

Theme.Stroke = {
	Text = 2, -- UIStroke thickness on text (design units)
	Panel = 3,
	Button = 2.5,
	Pill = 2,
}

Theme.Radius = {
	Panel = 14,
	Button = 10,
	Pill = 999,
	Tile = 12,
}

-- Soft drop shadow used under buttons/panels: a darker offset copy instead of UIShadow (beta).
Theme.Shadow = {
	Color = Color3.fromHex("0E1230"),
	Transparency = 0.55,
	Offset = 3,
}

-- Official Robux glyph (private-use code point rendered by Roblox fonts). Do not restyle or substitute it (ui-canon 3.2).
Theme.RobuxGlyph = utf8.char(0xE002)

-- Areas where the touch controls live, as fractions of the usable screen. The HUD must keep interactive elements out of them.
-- Approximate values for DynamicThumbstick + jump button; verify with the Studio device emulator.
Theme.Zones = {
	thumbstick = { x0 = 0, x1 = 0.4, y0 = 0.5, y1 = 1 },
	jump = { x0 = 0.68, x1 = 1, y0 = 0.52, y1 = 1 },
	-- bottom edge of the left menu stack and the right offer column, as a fraction of screen height
	leftStackBottom = 0.58,
	rightColumnBottom = 0.55,
}

Theme.Sizes = {
	phone = {
		refHeight = 350,
		margin = 8,
		tile = 46,
		tileGap = 4,
		tileLabel = 11,
		buttonHeight = 40,
		buttonText = 18,
		currencyHeight = 32,
		currencyText = 20,
		tabWidth = 76,
		tabHeight = 32,
		tabText = 16,
		close = 44,
		title = 22,
		body = 16,
		small = 13,
		toastText = 18,
		badge = 20,
		flySprite = 24,
	},
	tablet = {
		refHeight = 560,
		margin = 12,
		tile = 54,
		tileGap = 6,
		tileLabel = 12,
		buttonHeight = 44,
		buttonText = 20,
		currencyHeight = 36,
		currencyText = 22,
		tabWidth = 90,
		tabHeight = 36,
		tabText = 18,
		close = 44,
		title = 26,
		body = 18,
		small = 14,
		toastText = 20,
		badge = 22,
		flySprite = 28,
	},
	desktop = {
		refHeight = 720,
		margin = 14,
		tile = 56,
		tileGap = 6,
		tileLabel = 13,
		buttonHeight = 46,
		buttonText = 22,
		currencyHeight = 38,
		currencyText = 24,
		tabWidth = 100,
		tabHeight = 38,
		tabText = 20,
		close = 40,
		title = 28,
		body = 18,
		small = 14,
		toastText = 22,
		badge = 22,
		flySprite = 28,
	},
} :: { [string]: Sizes }

-- Allowed UIScale range per device (a tiny window or a 4K monitor must not break the layout).
Theme.ScaleRange = {
	phone = { min = 0.8, max = 1.6 },
	tablet = { min = 0.8, max = 1.8 },
	desktop = { min = 0.6, max = 2.2 },
} :: { [string]: { min: number, max: number } }

-- Lighten/darken helpers used for hover and gradients.
function Theme.lighten(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(1, 1, 1), math.clamp(amount, 0, 1))
end

function Theme.darken(color: Color3, amount: number): Color3
	return color:Lerp(Color3.new(0, 0, 0), math.clamp(amount, 0, 1))
end

return Theme
