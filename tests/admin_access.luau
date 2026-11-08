--!nocheck
-- DomWorld — client must not construct admin UI without explicit server authorization.
require("./prelude")
local AdminAccess = require("../src/shared/Core/AdminAccess")

local fails = 0
local function expect(condition: any, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

local builds = 0
local function maybe_build(state: any): boolean
	if not AdminAccess.confirmed(state) then
		return false
	end
	builds += 1
	return true
end

expect(not maybe_build({ ok = false, role = "admin" }), "denied server response never builds the interface")
expect(not maybe_build({ ok = true }), "an incomplete response never builds the interface")
expect(not maybe_build({ ok = true, role = "player" }), "an unauthorized role never builds the interface")
expect(builds == 0, "non-admin responses create no interface instances")
expect(maybe_build({ ok = true, role = "owner" }), "confirmed owner response opens the interface")
expect(maybe_build({ ok = true, role = "admin" }), "confirmed admin response opens the interface")
expect(builds == 2, "only explicitly authorized roles reach the constructor")

if fails > 0 then
	error(string.format("AdminAccess: %d failure(s)", fails))
end
print("AdminAccess: all checks passed")
