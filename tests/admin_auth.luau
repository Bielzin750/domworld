--!nocheck
-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Server-side UserId admin allowlist: production is explicit, Studio grants access to testers.
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

local auth = AdminAuth.new({ UserIds = { 1001, 1002, 0, "1003", math.huge } }, false)
expect(auth:is_admin({ UserId = 1001 }), "allowlisted UserId is an admin")
expect(auth:is_admin({ UserId = 1002 }), "multiple UserIds are supported")
expect(not auth:is_admin({ UserId = 1003 }), "a non-allowlisted UserId is not an admin")
expect(not auth:is_admin({ UserId = 0 }), "invalid IDs are ignored")

local empty = AdminAuth.new({ UserIds = {} }, false)
expect(not empty:is_admin({ UserId = 1001 }), "production default denies everyone")
local studio = AdminAuth.new({ UserIds = {} }, true)
expect(studio:is_admin({ UserId = 9999 }), "Studio permits the playtester without configuration")

if fails > 0 then
	error(string.format("AdminAuth: %d failure(s)", fails))
end
print("AdminAuth: all checks passed")
