--!strict
-- Icon registry. Components ask for icons by KEY ("shop", "rebirth", "coin"); this module decides what is drawn.
--  1. If ASSETS[key] holds an image id, an ImageLabel shows it (production: AI-generated icons, see ai-art-generation.md).
--  2. Otherwise a text/emoji glyph placeholder is drawn, so the demo and prototypes work with ZERO uploaded assets.
--
-- Keys mirror the file names of assets/starter-art/pet-legends (ic_shop.png -> "shop"). Upload the PNGs, put the
-- resulting ids into ASSETS (or call Icons.setAssets from your art/ui-assets.json manifest at startup), done.

local Theme = require(script.Parent.Theme)

local Icons = {}

export type IconInfo = {
	glyph: string, -- placeholder shown until an image id exists
	tint: Color3, -- default tile color for menu tiles using this icon (ui-canon 3.1 colors)
	file: string, -- starter-art file name, for the manifest
}

-- key -> "rbxassetid://<id>". Empty string = not uploaded yet (placeholder glyph is used).
local ASSETS: { [string]: string } = {
	-- shop = "rbxassetid://0", -- ic_shop.png (red basket)
	-- rebirth = "rbxassetid://0", -- ic_rebirth.png (red + white circular arrows)
	-- coin = "rbxassetid://0", -- ic_coin.png
}

local INFO: { [string]: IconInfo } = {
	shop = { glyph = utf8.char(0x1F6D2), tint = Color3.fromHex("F2453D"), file = "ic_shop.png" },
	pass = { glyph = utf8.char(0x1F451), tint = Color3.fromHex("FFC93C"), file = "shop_vip.png" },
	rebirth = { glyph = utf8.char(0x1F504), tint = Color3.fromHex("F2453D"), file = "ic_rebirth.png" },
	index = { glyph = utf8.char(0x1F4D6), tint = Color3.fromHex("3DA5F5"), file = "ic_index.png" },
	pets = { glyph = utf8.char(0x1F43E), tint = Color3.fromHex("FF8A2B"), file = "ic_paw.png" },
	daily = { glyph = utf8.char(0x1F381), tint = Color3.fromHex("FF8A2B"), file = "shop_gift.png" },
	quests = { glyph = utf8.char(0x1F3C6), tint = Color3.fromHex("FFC93C"), file = "ic_quest.png" },
	trade = { glyph = utf8.char(0x1F501), tint = Color3.fromHex("3FCB4E"), file = "ic_trade.png" },
	codes = { glyph = utf8.char(0x1F3AB), tint = Color3.fromHex("27C2C2"), file = "ic_codes.png" },
	settings = { glyph = utf8.char(0x2699), tint = Color3.fromHex("8FA3BF"), file = "ic_settings.png" },
	coin = { glyph = utf8.char(0x1F4B0), tint = Color3.fromHex("FFC93C"), file = "ic_coin.png" },
	gem = { glyph = utf8.char(0x1F48E), tint = Color3.fromHex("3DA5F5"), file = "ic_gem.png" },
	star = { glyph = utf8.char(0x2B50), tint = Color3.fromHex("FFC93C"), file = "ic_star.png" },
	lock = { glyph = utf8.char(0x1F512), tint = Color3.fromHex("8A8FA0"), file = "ic_lock.png" },
	luck = { glyph = utf8.char(0x1F340), tint = Color3.fromHex("3FCB4E"), file = "ic_luck.png" },
	speed = { glyph = utf8.char(0x26A1), tint = Color3.fromHex("FFC93C"), file = "ic_speed.png" },
	x2 = { glyph = "x2", tint = Color3.fromHex("3FCB4E"), file = "shop_2xcoins.png" },
	starter = { glyph = utf8.char(0x1F4E6), tint = Color3.fromHex("FF8A2B"), file = "shop_gems_chest.png" },
	egg = { glyph = utf8.char(0x1F95A), tint = Color3.fromHex("FFC93C"), file = "ic_egg.png" },
}

local FALLBACK: IconInfo = { glyph = "?", tint = Color3.fromHex("8FA3BF"), file = "" }

function Icons.info(key: string): IconInfo
	return INFO[key] or FALLBACK
end

-- Default tile color for an icon key (menu tiles).
function Icons.tint(key: string): Color3
	return Icons.info(key).tint
end

-- Register or override image ids at runtime: Icons.setAssets({ shop = "rbxassetid://123", coin = "rbxassetid://456" }).
function Icons.setAssets(map: { [string]: string })
	for key, id in map do
		ASSETS[key] = id
	end
end

-- Registers a new icon key (game-specific) with its placeholder glyph and tint.
function Icons.register(key: string, glyph: string, tint: Color3, assetId: string?)
	INFO[key] = { glyph = glyph, tint = tint, file = "" }
	if assetId then
		ASSETS[key] = assetId
	end
end

-- Skins an existing ImageLabel (created by Icons.new) with another key. Safe to call repeatedly (pools reuse labels).
function Icons.apply(label: ImageLabel, key: string)
	local info = Icons.info(key)
	local id = ASSETS[key]
	local glyph = label:FindFirstChild("Glyph")
	if id ~= nil and id ~= "" then
		label.Image = id
		if glyph and glyph:IsA("TextLabel") then
			glyph.Visible = false
		end
	else
		label.Image = ""
		if glyph and glyph:IsA("TextLabel") then
			glyph.Text = info.glyph
			glyph.Visible = true
		end
	end
	label:SetAttribute("IconKey", key)
end

-- Creates an icon: ImageLabel (+ a hidden-when-real "Glyph" TextLabel child for the placeholder).
function Icons.new(parent: Instance?, key: string, size: UDim2?): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name = "Icon"
	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	image.ScaleType = Enum.ScaleType.Fit
	image.Size = size or UDim2.fromScale(1, 1)
	image.SizeConstraint = Enum.SizeConstraint.RelativeYY

	local glyph = Instance.new("TextLabel")
	glyph.Name = "Glyph"
	glyph.BackgroundTransparency = 1
	glyph.Size = UDim2.fromScale(1, 1)
	glyph.FontFace = Theme.Font.Display
	glyph.TextScaled = true
	glyph.TextColor3 = Theme.Colors.White
	glyph.Parent = image
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 64
	limit.MinTextSize = 8
	limit.Parent = glyph

	Icons.apply(image, key)
	image.Parent = parent
	return image
end

-- Names of the starter-art PNGs by key, for building the upload manifest (art/ui-assets.json).
function Icons.manifest(): { [string]: string }
	local out: { [string]: string } = {}
	for key, info in INFO do
		if info.file ~= "" then
			out[key] = info.file
		end
	end
	return out
end

return Icons
