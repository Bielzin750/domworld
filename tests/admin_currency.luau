--!nocheck
-- DomWorld — currency request → server action → balance → client-facing updates.
require("./prelude")
local AdminAuth = require("../src/server/AdminAuth")
local AdminService = require("../src/server/AdminService")
local MatchServer = require("../src/server/MatchServer")
local Purchases = require("../src/server/Purchases")

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
local store = { down = false }
function store:UpdateAsync(key: string, transform: (any) -> any)
	if self.down then
		error("DataStore API access disabled")
	end
	local next_value = transform(rows[key])
	rows[key] = next_value
	return next_value
end
function store:GetAsync(key: string)
	if self.down then
		error("DataStore API access disabled")
	end
	return rows[key]
end

local owner = { UserId = 99, Name = "Owner" }
local target = { UserId = 42, Name = "Target", DisplayName = "Target" }
local client =
	{ stars_hud = 0, stars_shop = 0, stars_panel = 0, gold_hud = 20, gold_shop = 20, gold_panel = 20, status = "" }
local function update_inventory(_player: any, inv: any)
	client.stars_hud = inv.stars
	client.stars_shop = inv.stars
end

Purchases.reset()
Purchases.configure({
	datastore = store,
	datastore_available = true,
	studio = false,
	players = {
		GetPlayerByUserId = function(_, id: number)
			return if id == 42 then target else nil
		end,
	},
	notify = function(_player: any, _credits: any) end,
	inventory = update_inventory,
})
Purchases.load(target)

local sim = {
	owner_total = 1,
	o_name = { [1] = "Target" },
	o_alive = { [1] = 1 },
	o_bot = { [1] = 0 },
	o_troops = { [1] = 100 },
	o_gold = { [1] = 20 },
	o_tiles = { [1] = 1 },
	is_human = function(_, id: number)
		return id == 1
	end,
}
local server = setmetatable({
	_stage = MatchServer.STAGE_PLAYING,
	_mp_sim = sim,
	_admin_paused = false,
	_admin_speed = 1,
	_participants = { [target] = { uid = "42", owner = 1 } },
	_order = { target },
	_resync_everyone = function()
		client.gold_hud = sim.o_gold[1]
		client.gold_shop = sim.o_gold[1]
	end,
}, MatchServer)

local service = AdminService.new({
	auth = AdminAuth.new({ OwnerUserIds = { 99 } }, false),
	players = function()
		return { target }
	end,
	player_by_user_id = function(id: number)
		return if id == 42 then target else nil
	end,
	purchases = Purchases,
	match = {
		admin_state = function()
			return server:admin_state()
		end,
		admin_action = function(action: string, args: any)
			return server:admin_action(action, args)
		end,
	},
	clock = function()
		return 1
	end,
	now = function()
		return 1700000000
	end,
	log = function(_line: string) end,
})

local function invoke(request: any): any
	local response = service:execute(owner, request)
	client.status = if type(response.message) == "string" then response.message else "A ação foi recusada."
	if response.ok then
		local state = service:get_state(owner, 42)
		client.stars_panel = state.account.stars
		client.gold_panel = state.account.match_gold or 0
	end
	return response
end

local stars_add = invoke({ action = "stars", user_id = 42, mode = "add", amount = 1000 })
expect(
	stars_add.ok and stars_add.balance == 1000 and rows.u42.stars == 1000,
	"Stars add writes through the admin remote"
)
expect(
	client.stars_hud == 1000 and client.stars_shop == 1000 and client.stars_panel == 1000,
	"Stars immediately refresh inventory, HUD, shop and panel"
)
local stars_remove = invoke({ action = "stars", user_id = 42, mode = "remove", amount = 200 })
expect(
	stars_remove.ok and stars_remove.balance == 800 and client.stars_panel == 800,
	"Stars remove returns and displays the new balance"
)
local stars_set = invoke({ action = "stars", user_id = 42, mode = "set", amount = 850 })
expect(
	stars_set.ok and stars_set.balance == 850 and rows.u42.stars == 850,
	"Stars set is persisted with the reported balance"
)

local gold_add = invoke({ action = "gold", user_id = 42, owner_id = 1, mode = "add", amount = 1000 })
expect(
	gold_add.ok and gold_add.balance == 1020 and sim.o_gold[1] == 1020,
	"match Gold add changes the authoritative simulation"
)
expect(
	client.gold_hud == 1020 and client.gold_shop == 1020 and client.gold_panel == 1020,
	"Gold snapshot refreshes HUD, shop and panel immediately"
)
local gold_remove = invoke({ action = "gold", user_id = 42, owner_id = 1, mode = "remove", amount = 200 })
expect(
	gold_remove.ok and gold_remove.balance == 820 and client.gold_panel == 820,
	"match Gold remove returns and displays the new balance"
)
local gold_set = invoke({ action = "gold", user_id = 42, owner_id = 1, mode = "set", amount = 900 })
expect(gold_set.ok and gold_set.balance == 900 and sim.o_gold[1] == 900, "match Gold set returns the exact balance")
expect(
	not invoke({ action = "gold", user_id = 42, owner_id = 1, mode = "add", amount = 1000000001 }).ok,
	"Gold rejects adjustments beyond the safe maximum"
)

Purchases.reset()
Purchases.configure({ studio = false, datastore_available = true })
Purchases.load(target)
expect(Purchases.stars(target) == 850, "persistent Stars survive loading a new profile instance")

store.down = true
Purchases.reset()
Purchases.configure({ studio = true, datastore_available = true })
Purchases.load(target)
local fallback = invoke({ action = "stars", user_id = 42, mode = "add", amount = 50 })
expect(
	fallback.ok and fallback.session_only and Purchases.stars(target) == 50,
	"Studio DataStore outage falls back to this session's memory"
)
expect(
	client.stars_hud == 50 and client.stars_shop == 50 and client.stars_panel == 50,
	"memory fallback still updates live Stars UI"
)
local degraded = service:get_state(owner, 42)
expect(not degraded.persistence_available, "server state reports unavailable persistence")
expect(
	string.find("Sem acesso ao DataStore: alteração válida só nesta sessão", "só nesta sessão", 1, true) ~= nil,
	"the exact session-only warning text is available to the account panel"
)

if fails > 0 then
	error(string.format("Admin currencies: %d failure(s)", fails))
end
print("Admin currencies: all checks passed")
