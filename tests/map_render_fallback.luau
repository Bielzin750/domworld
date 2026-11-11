-- The map surface must retain valid terrain colours and a safe renderer when EditableImage is blocked.
require("./prelude")
local MapSurface = require("../src/client/Map/MapSurface")

local fails = 0
local function expect(condition: boolean, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

local cols, rows = MapSurface.fallback_grid_size(2000, 1000)
expect(cols == 64 and rows == 32, "World fallback is 64x32 cells")
expect(cols * rows <= MapSurface.FRAME_FALLBACK_MAX_CELLS, "fallback instance count stays bounded")

local pixels = buffer.create(2 * 2 * 4)
buffer.writeu32(pixels, 0, MapSurface.pack(20, 40, 60, 255))
buffer.writeu32(pixels, 4, MapSurface.pack(40, 60, 80, 255))
buffer.writeu32(pixels, 8, MapSurface.pack(60, 80, 100, 255))
buffer.writeu32(pixels, 12, MapSurface.pack(80, 100, 120, 255))
local averaged = MapSurface.fallback_pixel(pixels, 2, 2, 0, 0, 1, 1)
expect(
	averaged % 256 == 50 and (averaged // 256) % 256 == 70 and (averaged // 65536) % 256 == 90,
	"fallback samples produce the expected RGB average"
)
expect(averaged // 16777216 == 255, "fallback pixels are opaque and valid")

local fallback_called = false
local mode, value, image_error = MapSurface.choose_renderer(function()
	error("EditableImage is not accessible")
end, function()
	fallback_called = true
	return "frames"
end)
expect(mode == "frames" and value == "frames", "blocked EditableImage selects the Frame fallback")
expect(
	fallback_called and string.find(image_error or "", "not accessible", 1, true) ~= nil,
	"fallback keeps the API failure reason"
)

local edit_mode, edit_value = MapSurface.choose_renderer(function()
	return "editable"
end, function()
	error("fallback should not run")
end)
expect(
	edit_mode == "editable" and edit_value == "editable",
	"available EditableImage keeps the full-resolution renderer"
)

local failed_mode, _, failed_image_error, failed_frame_error = MapSurface.choose_renderer(function()
	error("image denied")
end, function()
	error("frame creation failed")
end)
expect(failed_mode == "unavailable", "both renderer failures resolve to neutral mode without throwing")
expect(
	string.find(failed_image_error or "", "image denied", 1, true) ~= nil
		and string.find(failed_frame_error or "", "frame creation failed", 1, true) ~= nil,
	"neutral mode retains both failure causes"
)

print(if fails == 0 then "map_render_fallback: all passed" else string.format("map_render_fallback: %d FAILED", fails))
if fails > 0 then
	error("map_render_fallback failed")
end
