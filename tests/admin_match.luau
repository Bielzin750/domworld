--!nocheck
-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- MatchServer's private admin mutation path checks match state and resynchronizes mirrors.
require("./prelude")
local MatchServer = require("../src/server/MatchServer")

local fails = 0
local function expect(condition: any, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

local alive = { [1] = 1, [2] = 1, [3] = 1 }
local bot = { [1] = 0, [2] = 1 }
local sim
sim = {
	owner_total = 3,
	o_name = { [1] = "Human", [2] = "Bot", [3] = "Nation" },
	o_alive = alive,
	o_bot = bot,
	o_troops = { [1] = 100, [2] = 100, [3] = 400 },
	o_gold = { [1] = 20, [2] = 20, [3] = 50 },
	o_tiles = { [1] = 2, [2] = 1, [3] = 4 },
	N = 10,
	is_human = function(_, id)
		return id == 1 or id == 2
	end,
	map = {
		is_contestable = function(_, tile)
			return tile < 8
		end,
	},
	set_owner = function(_, tile, id)
		sim.last_tile = tile
		sim.last_owner = id
	end,
	_eliminate = function(_, id, killer)
		alive[id] = 0
		sim.last_eliminated = id
		sim.last_killer = killer
	end,
	add_bot_player = function(_, name)
		sim.added_bot = name
		return 3
	end,
}
local server = setmetatable({
	_stage = MatchServer.STAGE_PLAYING,
	_mp_sim = sim,
	_admin_paused = false,
	_admin_speed = 1,
	_resyncs = 0,
	_resync_everyone = function(self)
		self._resyncs += 1
	end,
}, MatchServer)

local troops_ok = server:admin_action("set_troops", { owner_id = 1, amount = 900 })
expect(troops_ok and sim.o_troops[1] == 900, "troop total can be set by the server")
expect(
	server:admin_action("set_gold", { owner_id = 1, amount = 700 }) and sim.o_gold[1] == 700,
	"match gold can be set"
)
expect(
	server:admin_action("set_tile_owner", { tile = 4, owner_id = 2 }) and sim.last_tile == 4 and sim.last_owner == 2,
	"claimable land ownership is updated through Sim"
)
expect(not server:admin_action("set_tile_owner", { tile = 9, owner_id = 1 }), "non-claimable tile is rejected")
expect(server:admin_action("pause", { paused = true }) and server._admin_paused, "match pause is server controlled")
expect(server:admin_action("speed", { speed = 3 }) and server._admin_speed == 3, "match speed is server controlled")
expect(server:admin_action("remove_bot", { owner_id = 1 }) == false, "non-bot cannot be removed as an admin bot")
expect(
	server:admin_action("remove_bot", { owner_id = 2 }) and sim.last_eliminated == 2,
	"admin bot removal eliminates the chosen bot"
)
expect(server._resyncs >= 4, "every map state mutation requests fresh snapshots")
local state = server:admin_state()
expect(state.owners[1].human and state.owners[2].bot, "admin state identifies controllable players and bots")
expect(not server:admin_action("eliminate", { owner_id = 3 }), "ordinary NPCs cannot be eliminated as players")
expect(server:admin_action("focus_owner", { owner_id = 1 }), "camera focus resolves through server state")
expect(
	server:admin_action("eliminate", { owner_id = 1 }) and sim.last_eliminated == 1,
	"player elimination uses Sim cleanup"
)

server._stage = MatchServer.STAGE_IDLE
expect(not server:admin_action("speed", { speed = 2 }), "speed cannot be changed without a running match")
server._stage = MatchServer.STAGE_SPAWN
expect(
	server:admin_action("add_bot", { name = "Test Bot" }) and sim.added_bot == "Test Bot",
	"bot can be added in the spawn phase"
)
server._stage = MatchServer.STAGE_PLAYING
expect(not server:admin_action("add_bot", { name = "Late Bot" }), "bots cannot be added after the spawn phase")

if fails > 0 then
	error(string.format("Admin match: %d failure(s)", fails))
end
print("Admin match: all checks passed")
