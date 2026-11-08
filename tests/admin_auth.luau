--!nocheck
-- DomWorld — server role hierarchy and Studio-only tester access.
require("./prelude")
local AdminAuth = require("../src/server/AdminAuth")

local fails = 0
local function expect(condition: any, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

local auth = AdminAuth.new({
	OwnerUserIds = { 1001, 0, "1003", math.huge },
	AdminUserIds = { 1002, 1004 },
	StudioTestersAreAdmin = false,
}, false)
auth:set_roster({ [1005] = true, [0] = true })
expect(auth:role({ UserId = 1001 }) == "owner", "configured owner receives the owner role")
expect(auth:role({ UserId = 1002 }) == "admin", "static admin receives the admin role")
expect(auth:role({ UserId = 1005 }) == "admin", "persistent roster member receives the admin role")
expect(auth:is_owner({ UserId = 1001 }), "only owner role passes the owner check")
expect(not auth:is_owner({ UserId = 1002 }), "ordinary admin is not an owner")
expect(auth:role({ UserId = 1003 }) == nil, "invalid static IDs are ignored")
expect(auth:role({ UserId = 0 }) == nil, "invalid player IDs are denied")

local disabled_studio = AdminAuth.new({ StudioTestersAreAdmin = false }, true)
expect(not disabled_studio:is_admin({ UserId = 9999 }), "Studio tester access is configurable off")
local enabled_studio = AdminAuth.new({ StudioTestersAreAdmin = true }, true)
expect(enabled_studio:role({ UserId = 9999 }) == "admin", "Studio testers are admins only when explicitly enabled")
local published = AdminAuth.new({ StudioTestersAreAdmin = true }, false)
expect(not published:is_admin({ UserId = 9999 }), "Studio tester access never applies to published servers")

if fails > 0 then
	error(string.format("AdminAuth: %d failure(s)", fails))
end
print("AdminAuth: all checks passed")
