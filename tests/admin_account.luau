--!nocheck
-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Persistent account tools use the live Purchases schema and its UpdateAsync write path.
require("./prelude")
local Purchases = require("../src/server/Purchases")
local Cosmetics = require("../src/shared/Data/Cosmetics")
local Arsenal = require("../src/shared/Data/Arsenal")

local fails = 0
local function expect(condition: any, message: string)
	if condition then
		print("  ok   " .. message)
	else
		fails += 1
		print("FAIL " .. message)
	end
end

local rows = {
	u77 = {
		stars = 320,
		stars_earned = 500,
		credits = { crate = 3 },
		receipts = { "receipt-preserved" },
		paid = true,
		owned = {},
		unlocks = {},
		equipped = {},
	},
}
local store = {}
function store:GetAsync(key: string)
	return rows[key]
end
function store:UpdateAsync(key: string, transform: (any) -> any)
	local next_value = transform(rows[key])
	if next_value ~= nil then
		rows[key] = next_value
	end
	return next_value
end

local player = { UserId = 77, Name = "AccountTester" }
local function configure()
	Purchases.configure({
		datastore = store,
		players = {
			GetPlayerByUserId = function(_, user_id)
				return if user_id == 77 then player else nil
			end,
		},
		notify = function() end,
		inventory = function() end,
	})
end

configure()
Purchases.load(player)
local initial = Purchases.admin_account(player)
expect(
	initial ~= nil and initial.stars == 320 and initial.stars_earned == 500,
	"loaded account view includes current and earned Stars"
)
expect(
	initial.credits.crate == 3 and initial.receipt_count == 1,
	"loaded account view includes crate credits and receipt count"
)
local catalog = Purchases.admin_catalog(player)
expect(
	#catalog.cosmetics > 0 and #catalog.arsenal == #Arsenal.ITEMS,
	"search catalog lists cosmetics and Arsenal unlocks"
)
local has_crate_credit = false
for _, item in catalog.credits do
	if item.id == "crate" then
		has_crate_credit = true
	end
end
expect(has_crate_credit, "search catalog includes crate credits")

local skin = Cosmetics.all()[1]
local grant_skin = Purchases.admin_item(player, "cosmetic", skin.id, "grant")
expect(grant_skin and table.find(Purchases.admin_account(player).owned, skin.id) ~= nil, "cosmetic grant is persisted")
local arsenal_item = Arsenal.ITEMS[1]
local grant_unlock = Purchases.admin_item(player, "arsenal", arsenal_item.key, "grant")
expect(grant_unlock and rows.u77.unlocks[arsenal_item.key] == true, "Arsenal unlock grant is persisted")
local add_crates = Purchases.admin_item(player, "credit", "crate", "add", 2)
expect(add_crates and rows.u77.credits.crate == 5, "crate credits are added using the persistent credit inventory")
local remove_crates = Purchases.admin_item(player, "credit", "crate", "remove", 1)
expect(remove_crates and rows.u77.credits.crate == 4, "crate credits can be removed using the persistent inventory")
local revoke_skin = Purchases.admin_item(player, "cosmetic", skin.id, "revoke")
expect(
	revoke_skin and table.find(Purchases.admin_account(player).owned, skin.id) == nil,
	"cosmetic revocation clears owned inventory"
)
local revoke_unlock = Purchases.admin_item(player, "arsenal", arsenal_item.key, "revoke")
expect(revoke_unlock and rows.u77.unlocks[arsenal_item.key] == nil, "Arsenal revocation clears its saved unlock")

expect(not Purchases.admin_item(player, "cosmetic", "missing", "grant"), "unknown cosmetic is rejected")
expect(not Purchases.admin_item(player, "arsenal", "missing", "grant"), "unknown Arsenal item is rejected")
expect(not Purchases.admin_item(player, "credit", "missing", "add", 1), "unknown credit type is rejected")
expect(not Purchases.admin_item(player, "credit", "crate", "add", 0 / 0), "NaN credit amount is rejected")
expect(not Purchases.admin_item(player, "credit", "crate", "add", -1), "negative credit amount is rejected")
expect(not Purchases.admin_item(player, "credit", "crate", "add", 1001), "credit amount over the cap is rejected")
expect(not Purchases.admin_item(player, "credit", "crate", "add", "2"), "wrong credit amount type is rejected")

Purchases.reset()
configure()
local reloaded = { UserId = 77, Name = "AccountReloaded" }
player = reloaded
Purchases.load(reloaded)
local after_reload = Purchases.admin_account(reloaded)
expect(
	after_reload.stars == 320 and after_reload.credits.crate == 4,
	"saved balances remain consistent after loading a new session"
)
expect(
	after_reload.receipt_count == 1 and rows.u77.paid == true,
	"Roblox receipt idempotency and paid status survive reload"
)
local reset_ok = Purchases.admin_reset(reloaded)
expect(
	reset_ok and rows.u77.stars == 0 and rows.u77.credits.crate == nil,
	"account reset clears progression after saving a snapshot"
)
expect(
	type(rows.u77.admin_backup) == "table"
		and rows.u77.admin_backup.data.stars == 320
		and rows.u77.admin_backup.data.credits.crate == 4,
	"reset snapshot contains the pre-reset persistent purchase record"
)
expect(
	rows.u77.receipts[1] == "receipt-preserved" and rows.u77.paid == true,
	"reset preserves receipt history and paid status"
)
Purchases.reset()
configure()
local after_reset = { UserId = 77, Name = "AccountResetReload" }
player = after_reset
Purchases.load(after_reset)
local reset_reload = Purchases.admin_account(after_reset)
expect(
	reset_reload.stars == 0 and #reset_reload.owned == 0 and #reset_reload.unlocks == 0,
	"reset state remains cleared after loading a new session"
)
expect(
	reset_reload.receipt_count == 1 and rows.u77.admin_backup.created_at > 0,
	"reset backup and receipt identity remain saved"
)

if fails > 0 then
	error(string.format("Admin account: %d failure(s)", fails))
end
print("Admin account: all checks passed")
