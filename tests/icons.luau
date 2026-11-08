local Icons = require("../src/shared/UI/Icons")

local function expect(value: boolean, message: string)
	if not value then
		error("FAIL: " .. message, 2)
	end
	print("  ok   " .. message)
end

expect(Icons.image_enabled() == false, "an unconfigured spritesheet keeps icons disabled")
expect(Icons.get("attack") == nil, "a missing icon returns nil for its procedural fallback")
expect(Icons.get("account_balance_wallet") == nil, "legacy aliases keep the same fallback")

print("Icons: all checks passed")
