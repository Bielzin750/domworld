-- Lune test prelude: expose the Roblox datatypes shared code may use as globals.
local roblox = require("@lune/roblox")
local globals = getfenv(0) :: any
local shared_globals = _G :: any
for _, name in ipairs({
	"Vector2",
	"Vector3",
	"Color3",
	"CFrame",
	"Vector2int16",
	"Vector3int16",
	"Rect",
	"UDim",
	"UDim2",
	"NumberRange",
}) do
	globals[name] = (roblox :: any)[name]
	shared_globals[name] = (roblox :: any)[name]
end
-- the test-only maps (after the globals: WorldMap uses them)
require("./fixtures/fixture_maps")
return roblox
