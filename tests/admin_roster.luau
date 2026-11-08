--!nocheck
-- DomWorld — owner-controlled persistent AdminRoster and authorization gates.
require("./prelude")
local AdminAuth = require("../src/server/AdminAuth")
local AdminRoster = require("../src/server/AdminRoster")
local AdminService = require("../src/server/AdminService")

local fails = 0
local function expect(condition: any, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

local rows = {}
local store = {}
function store:GetAsync(key: string)
	return rows[key]
end
function store:UpdateAsync(key: string, transform: (any) -> any)
	local next_value = transform(rows[key])
	rows[key] = next_value
	return next_value
end

local roster = AdminRoster.new(store, function(_seconds) end, { 1001 })
expect(roster:load(), "roster loads from AdminRoster DataStore")
local auth = AdminAuth.new({ OwnerUserIds = { 1001 }, AdminUserIds = { 1002 } }, false)
auth:set_roster(roster:member_ids())
local owner = { UserId = 1001, Name = "Owner" }
local regular_admin = { UserId = 1002, Name = "StaticAdmin" }
local target = { UserId = 3001, Name = "TargetUser" }
local username_to_id = { NewAdmin = 2001, Exists = 2001 }
local names = { [1001] = "Owner", [2001] = "NewAdmin", [3001] = "TargetUser" }
local calls = { roster = 0, resolver = 0 }
local username_lookup_available = true

local service = AdminService.new({
	auth = auth,
	roster = roster,
	user_id_from_name = function(name: string)
		calls.resolver += 1
		local found = username_to_id[name]
		if found == nil then
			error("username does not exist")
		end
		return found
	end,
	name_from_user_id = function(user_id: number)
		calls.resolver += 1
		if not username_lookup_available then
			error("Roblox username service is unavailable")
		end
		local found = names[user_id]
		if found == nil then
			error("user does not exist")
		end
		return found
	end,
	players = function()
		return { target }
	end,
	player_by_user_id = function(user_id: number)
		return if user_id == target.UserId then target else nil
	end,
	purchases = {
		inventory = function()
			return { owned = {} }
		end,
		stars = function()
			return 0
		end,
		admin_account = function()
			return nil
		end,
		admin_catalog = function()
			return nil
		end,
	},
	match = {
		admin_state = function()
			return { owners = {} }
		end,
	},
	clock = function()
		return os.clock()
	end,
	now = function()
		return 1700000000
	end,
	log = function(_line) end,
})

local denied = service:execute(regular_admin, { action = "team_add", username = "NewAdmin" })
expect(not denied.ok and calls.resolver == 0 and #roster:list() == 0, "admin cannot add or promote team members")
local username_add = service:execute(owner, { action = "team_add", username = "NewAdmin" })
expect(
	username_add.ok and auth:role({ UserId = 2001 }) == "admin",
	"owner adds by username and server immediately authorizes the member"
)
expect(
	rows.team["2001"].added_by_user_id == 1001 and rows.team["2001"].added_at == 1700000000,
	"audit metadata is persisted with the roster entry"
)
local reload = AdminRoster.new(store, function(_seconds) end, { 1001 })
expect(reload:load() and reload:member_ids()[2001], "saved roster survives a new server instance")

local user_id_add = service:execute(owner, { action = "team_add", user_id = 3001 })
expect(user_id_add.ok and auth:role({ UserId = 3001 }) == "admin", "owner adds a validated UserId")
local missing_name = service:execute(owner, { action = "team_add", username = "Missing" })
expect(not missing_name.ok and missing_name.message == "username not found", "unknown username is rejected clearly")
local missing_id = service:execute(owner, { action = "team_add", user_id = 999999 })
expect(not missing_id.ok and missing_id.message == "Roblox username not found", "unknown numeric UserId is rejected")
local invalid_id = service:execute(owner, { action = "team_add", user_id = 0 })
expect(not invalid_id.ok and invalid_id.message == "invalid UserId", "invalid numeric UserId is rejected")
local owner_remove = service:execute(owner, { action = "team_remove", user_id = 1001 })
expect(
	not owner_remove.ok and owner_remove.message == "O dono não pode ser removido",
	"owner is protected from removal"
)
local remove_by_name = service:execute(owner, { action = "team_remove", username = "NewAdmin" })
expect(remove_by_name.ok and auth:role({ UserId = 2001 }) == nil, "owner removes by username")
username_lookup_available = false
local remove_by_id = service:execute(owner, { action = "team_remove", user_id = 3001 })
expect(
	remove_by_id.ok and auth:role({ UserId = 3001 }) == nil,
	"owner removes by UserId even when the Roblox username lookup is unavailable"
)

for id = 4000, 4019 do
	local ok = roster:add({ user_id = id, username = "User" .. tostring(id), added_by_user_id = 1001 })
	expect(ok, "roster accepts member within the 20-person limit")
end
local over_limit, limit_error = roster:add({ user_id = 4020, username = "OverLimit" })
expect(not over_limit and limit_error == "Limite de 20 administradores atingido", "roster enforces the maximum of 20")

if fails > 0 then
	error(string.format("AdminRoster: %d failure(s)", fails))
end
print("AdminRoster: all checks passed")
