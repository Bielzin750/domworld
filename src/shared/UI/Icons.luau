--!strict
-- Material Icons Outlined atlas metadata; image mode stays off until the owner uploads the sheet.

local Icons = {}

Icons.SPRITESHEET_ID = "YOUR_SPRITESHEET_ID"
Icons.CELL_SIZE = 128
Icons.COLUMNS = 5

local names = {
	"play",
	"matches",
	"shop",
	"inventory",
	"profile",
	"settings",
	"globe",
	"group",
	"help",
	"schedule",
	"flag",
	"rank",
	"shield",
	"attack",
	"wallet",
	"star",
	"close",
	"check",
	"info",
	"map",
}

local indexByName: { [string]: number } = {}
for index, name in ipairs(names) do
	indexByName[name] = index - 1
end

local aliases = {
	app_icon = nil,
	account_balance_wallet = "wallet",
	admin_panel_settings = "settings",
	attack = "attack",
	clock = "schedule",
	defense = "shield",
	groups = "group",
	hud_leaderboard = "matches",
	leaderboard = "matches",
	map = "map",
	public = "globe",
	storefront = "shop",
	users = "group",
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
	local index = indexByName[canonical]
	if index == nil then
		return nil
	end
	local id = Icons.SPRITESHEET_ID
	local x = index % Icons.COLUMNS
	local y = math.floor(index / Icons.COLUMNS)
	return {
		Image = "rbxassetid://" .. id,
		ImageRectOffset = Vector2.new(x * Icons.CELL_SIZE, y * Icons.CELL_SIZE),
		ImageRectSize = Vector2.new(Icons.CELL_SIZE, Icons.CELL_SIZE),
	}
end

return Icons
