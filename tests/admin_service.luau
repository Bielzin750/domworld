--!nocheck
-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Admin remotes authenticate before inspecting input or touching player, purchase or match state.
require("./prelude")
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

local allowed = false
local player = { UserId = 41, Name = "AdminTester", DisplayName = "Admin Tester" }
local calls = { players = 0, purchases = 0, match = 0, audit = 0 }
local target = { UserId = 52, Name = "Target", DisplayName = "Target" }
local svc = AdminService.new({
	auth = {
		is_admin = function(_, _player)
			return allowed
		end,
	},
	players = function()
		calls.players += 1
		return { target }
	end,
	player_by_user_id = function(id)
		calls.players += 1
		return if id == target.UserId then target else nil
	end,
	purchases = {
		inventory = function()
			calls.purchases += 1
			return { owned = {} }
		end,
		stars = function()
			calls.purchases += 1
			return 75
		end,
		admin_stars = function(_, mode, amount)
			calls.purchases += 1
			return true, if mode == "set" then amount else 75 + (if mode == "add" then amount else -amount)
		end,
	},
	match = {
		admin_state = function()
			calls.match += 1
			return { stage = "playing", active = true, paused = false, speed = 1, tick = 10, owners = {} }
		end,
		admin_action = function(action, _args)
			calls.match += 1
			return true, action
		end,
	},
	clock = function()
		return 1
	end,
	now = function()
		return 123
	end,
	log = function(_line)
		calls.audit += 1
	end,
})

local actions = {
	{ action = "stars", user_id = 52, mode = "add", amount = 5 },
	{ action = "set_troops", owner_id = 1, amount = 500 },
	{ action = "set_gold", owner_id = 1, amount = 500 },
	{ action = "set_tile_owner", tile = 1, owner_id = 1 },
	{ action = "eliminate", owner_id = 1, killer_id = 0 },
	{ action = "focus_owner", owner_id = 1 },
	{ action = "remove_bot", owner_id = 1 },
	{ action = "add_bot", name = "Test Bot" },
	{ action = "pause", paused = true },
	{ action = "speed", speed = 2 },
}
expect(not svc:get_state(player).ok, "non-admin cannot read state through Admin.GetState")
for _, request in actions do
	expect(not svc:execute(player, request).ok, "non-admin action rejected: " .. request.action)
end
expect(
	calls.players == 0 and calls.purchases == 0 and calls.match == 0,
	"unauthorized calls cause no data or match effects"
)

allowed = true
local state = svc:get_state(player)
expect(state.ok and #state.players == 1 and state.players[1].user_id == 52, "admin state lists connected accounts")
local stars = svc:execute(player, actions[1])
expect(stars.ok and stars.balance == 80, "Stars adjustment routes to the server purchase store")
local set_troops = svc:execute(player, actions[2])
expect(set_troops.ok, "validated map actions reach MatchServer")
expect(not svc:execute(player, { action = "speed", speed = math.huge }).ok, "non-finite speed is rejected")
expect(
	not svc:execute(player, { action = "stars", user_id = 52, mode = "add", amount = -1 }).ok,
	"negative Stars adjustment is rejected"
)
expect(not svc:execute(player, { action = "add_bot", name = "Bad!" }).ok, "bot names are allowlisted characters only")
expect(svc:execute(player, { action = "unknown" }).ok == false, "unlisted actions are rejected")

if fails > 0 then
	error(string.format("AdminService: %d failure(s)", fails))
end
print("AdminService: all checks passed")
