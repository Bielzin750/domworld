--!nocheck
-- DomWorld — real Roblox users use their own head shot; bots stay procedurally generated.
require("./prelude")
local AvatarView = require("../src/client/UI/AvatarView")
local Theme = require("../src/shared/UI/Theme")

local fails = 0
local function expect(condition: any, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

expect(AvatarView.kind(123456, false) == "real", "a real player UserId selects Roblox head shot")
expect(AvatarView.kind(123456, true) == "generated", "a bot never borrows a real user's head shot")
expect(AvatarView.kind(nil, false) == "generated", "missing UserId selects procedural fallback")
expect(AvatarView.kind(-1, false) == "generated", "invalid UserId selects procedural fallback")
expect(
	AvatarView.key(42, false, "Alice") == AvatarView.key(42, false, "Renamed"),
	"real avatar cache key is UserId based"
)
expect(AvatarView.key(nil, true, "Bot A") ~= AvatarView.key(nil, true, "Bot B"), "bot avatar identity is name based")
expect(
	AvatarView.generated_color("Bot A", Theme.Colors) == AvatarView.generated_color("Bot A", Theme.Colors),
	"generated bot color is stable"
)

if fails > 0 then
	error(string.format("AvatarView: %d failure(s)", fails))
end
print("AvatarView: all checks passed")
