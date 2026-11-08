--!strict
-- Sprite positions are generated from docs/ICONS_NEEDED.md; missing icons keep the UI glyph fallback.
-- Modified for DomWorld, 2026 — see git history for details.

local IS_ROBLOX = (game :: any) ~= nil
local IconSpriteMap = if IS_ROBLOX then require(script.Parent.IconSpriteMap) else (require :: any)("./IconSpriteMap")

local Icons = {}

Icons.SPRITESHEET_ID = "YOUR_SPRITESHEET_ID"
Icons.CELL_SIZE = 128
Icons.COLUMNS = 8

local aliases: { [string]: string } = {
	account_balance_wallet = "wallet",
	admin_panel_settings = "settings",
	groups = "group",
	public = "globe",
	storefront = "shop",
}

function Icons.image_enabled(): boolean
	local id = Icons.SPRITESHEET_ID
	return type(id) == "string" and id ~= "" and id ~= "YOUR_SPRITESHEET_ID" and string.match(id, "^%d+$") ~= nil
end

function Icons.get(name: string): { Image: string, ImageRectOffset: Vector2, ImageRectSize: Vector2 }?
	if not Icons.image_enabled() then
		return nil
	end
	local canonical = aliases[name] or name
	local sprite = IconSpriteMap[canonical]
	if sprite == nil or not sprite.available or sprite.index < 0 then
		return nil
	end
	local index = sprite.index
	local x = index % Icons.COLUMNS
	local y = math.floor(index / Icons.COLUMNS)
	local id = Icons.SPRITESHEET_ID
	return {
		Image = "rbxassetid://" .. id,
		ImageRectOffset = Vector2.new(x * Icons.CELL_SIZE, y * Icons.CELL_SIZE),
		ImageRectSize = Vector2.new(Icons.CELL_SIZE, Icons.CELL_SIZE),
	}
end

return Icons
