--!nocheck
-- Percentage troop orders use one shared whole-troop calculation in preview and authority.
require("./prelude")

local TroopMath = require("../src/shared/Core/TroopMath")
local UICtx = require("../src/client/UI/UICtx")
local Protocol = require("../src/shared/Net/Protocol")
local MatchServer = require("../src/server/MatchServer")
local Sim = require("../src/shared/Core/Sim")
local Defs = require("../src/shared/Core/Defs")

local fails = 0
local function expect(ok: any, label: string)
	if ok then
		print("  ok   " .. label)
	else
		fails += 1
		print("FAIL " .. label)
	end
end

local samples = {
	{ 10, 100000, 10000 },
	{ 25, 100000, 25000 },
	{ 35, 100000, 35000 },
	{ 50, 100000, 50000 },
	{ 75, 100000, 75000 },
	{ 100, 100000, 100000 },
}
for _, sample in samples do
	expect(
		TroopMath.compute_send(sample[2], sample[1]) == sample[3],
		("%d%% of 100K = %d"):format(sample[1], sample[3])
	)
end

expect(TroopMath.compute_send(268000, 75) == 201000, "268,000 at 75% = 201,000")
expect(TroopMath.compute_send(12345678, 25) == 3086419, "large totals use floor rounding")
expect(TroopMath.compute_send(0, 75) == 0, "zero troops sends zero")
expect(TroopMath.compute_send(1, 10) == 1, "one troop sends at least one")
expect(TroopMath.compute_send(1, 100) == 1, "100% of one troop is one")

for _, percent in { 0 / 0, -1, 0, 101, 25.5, math.huge, -math.huge, "75" } do
	expect(TroopMath.compute_send(1000, percent) == nil, "invalid percentage is rejected: " .. tostring(percent))
end
for _, total in { -1, 0 / 0, math.huge, -math.huge, "268000" } do
	expect(TroopMath.compute_send(total, 75) == nil, "invalid troop total is rejected: " .. tostring(total))
end

local ctx = {
	ratio = 0.75,
	my = function()
		return { troops = 268000, max_troops = 900000 }
	end,
}
expect(UICtx.attack_percent(ctx) == 75, "the client previews the selected integer percentage")
expect(UICtx.troops_for_ratio(ctx) == 201000, "the client preview uses TroopMath")

local attack = Protocol.decode_intent(Protocol.encode_intent({ type = "attack", tile = 7, percent = 75 }))
expect(attack ~= nil and attack.percent == 75, "attack percentage uses the wire protocol")
local boat = Protocol.decode_intent(Protocol.encode_intent({ type = "boat", tile = 9, percent = 35 }))
expect(boat ~= nil and boat.percent == 35, "boat percentage uses the same wire field")
expect(Protocol.encode_intent({ type = "attack", tile = 7 }) == nil, "an attack without a percentage is rejected")
expect(
	Protocol.encode_intent({ type = "attack", tile = 7, percent = 75, troops = 201000 }) == nil,
	"a client cannot supply troop results"
)
local malformed = Protocol.encode_intent({ type = "attack", tile = 7, percent = 75 }) :: buffer
buffer.writeu8(malformed, buffer.len(malformed) - 1, 101)
expect(Protocol.decode_intent(malformed) == nil, "wire percentage above 100 is rejected")

local submitted: any = nil
local peer = {}
local server = MatchServer.new({
	now_ms = function()
		return 1000
	end,
})
server._mp_sim = {
	o_troops = { [1] = 268000 },
	submit = function(_, owner, intent)
		submitted = { owner, intent }
	end,
}
server._participants[peer] = { owner = 1, active_msec = 0, spectator = false, voted = false }
expect(
	server:intent(peer, Protocol.encode_intent({ type = "attack", tile = 7, percent = 75 })),
	"server accepts a valid attack percentage"
)
expect(submitted ~= nil and submitted[2].troops == 201000, "server computes the authoritative whole-troop result")
expect(submitted ~= nil and submitted[2].percent == nil, "the server sends only its computed amount to Sim")
expect(
	server:intent(peer, Protocol.encode_intent({ type = "boat", tile = 9, percent = 35 })),
	"server accepts a valid boat percentage"
)
expect(submitted ~= nil and submitted[2].troops == 93800, "server computes the transport amount with the same helper")

local exact_attack = 0
local sim_stub = {
	phase = Defs.PHASE_PLAYING,
	o_alive = { [1] = 1 },
	o_spawned = { [1] = 1 },
	o_troops = { [1] = 268000 },
	intent_attack_troops = function(_, _, _, amount)
		exact_attack = amount
	end,
}
Sim._apply_intent(sim_stub, 1, { type = "attack", tile = 7, percent = 75 })
expect(exact_attack == 201000, "solo Sim uses the same shared percentage calculation")

local exact_boat = 0
sim_stub.launch_boat_troops = function(_, _, _, amount)
	exact_boat = amount
end
Sim._apply_intent(sim_stub, 1, { type = "boat", tile = 9, percent = 35 })
expect(exact_boat == 93800, "solo transport uses the shared percentage calculation")

print(if fails == 0 then "troop_math: all passed" else ("troop_math: " .. fails .. " failed"))
if fails > 0 then
	error("troop_math failed")
end
