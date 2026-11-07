--!strict
-- Robux developer products (Creator Dashboard → Monetization → Developer Products). `id` is the
-- product's id; 0 = not created yet (its offer stays hidden). Each purchase is a saved credit of kind
-- `grants` (default: the key), `count` of them (default 1) (server/Purchases.luau): bought credits are
-- never lost if the moment passes. A `grants` of "unlock:<key>" is not a credit: it unlocks that
-- Arsenal item for good (Data/Arsenal).
--
-- Product ids belong to one experience. `staging` is the same product in DomWorld Staging (2026-10-04:
-- a separate experience where a build is tested before it goes to prod); in that experience it
-- replaces `id`. Create or reprice them with
-- tools/assets/make_arsenal_products.py.
-- Modified for DomWorld, 2026 — see git history for details.
local PRODUCTS: { [string]: any } = {
	--- Solo / public: take over the AI nation that eliminated you (2026-09-28).
	takeover = { id = 0, robux = 25, staging = 0 },
	--- A cosmetic crate (Data/Cosmetics; 2026-09-29: 49 Robux, the first one 15).
	crate = { id = 0, robux = 49, staging = 0 },
	--- The first crate a player buys (offered only before their first crate).
	crate_first = { id = 0, robux = 15, grants = "crate", first_only = true, staging = 0 },
	--- Three crates at once (2026-10-19: 100 Robux instead of 120,
	--- three crates being 3 x 40 at their price): `count` crate credits for one receipt.
	crate3 = { id = 0, robux = 100, grants = "crate", count = 3, staging = 0 },
	--- Ten crates at once (2026-10-27: a buy to come back to above 100 Robux; a paying player spent 89
	--- Robux on average, top experiences about 600): 299, about 30 a crate.
	crate10 = { id = 0, robux = 299, grants = "crate", count = 10, staging = 0 },
	--- The Arsenal (Data/Arsenal; 2026-10-04), at Pixel Conquest's prices.
	unlock_mega = { id = 0, robux = 39, grants = "unlock:mega", staging = 0 },
	unlock_scatter = { id = 0, robux = 67, grants = "unlock:scatter", staging = 0 },
	unlock_reinforce = { id = 0, robux = 149, grants = "unlock:reinforce", staging = 0 },
	unlock_artillery = { id = 0, robux = 99, grants = "unlock:artillery", staging = 0 },
	unlock_airfield = { id = 0, robux = 349, grants = "unlock:airfield", staging = 0 },
	unlock_railgun = { id = 0, robux = 999, grants = "unlock:railgun", staging = 0 },
	unlock_stars2x = { id = 0, robux = 59, grants = "unlock:stars2x", staging = 0 },
	unlock_reload2x = { id = 0, robux = 129, grants = "unlock:reload2x", staging = 0 },
	--- The starter pack (Data/Starter; 2026-10-15: 39 Robux, limited time): Mega Nuke, Scattershot
	--- and 2x Stars, once, for a player who never paid. Its receipt is refused outside its offer.
	starter_pack = { id = 0, robux = 39, grants = "starter", staging = 0 },
}

--- The flag shop (Data/Shop; 2026-10-22): one product per flag, made by
--- tools/assets/make_shop_flags.py (the ids live in Assets/ShopFlags), each granting "shopflag:<key>".
--- `shop_flag` marks them: UI/Prices asks Roblox for these only when the shop shows them.
local Shop: any = if typeof(game) == "Instance"
	then require((script :: any).Parent.Shop)
	else (require :: any)("./Shop")
for _, f in Shop.flags() do
	PRODUCTS["shop_" .. f.key] = {
		id = f.product or 0,
		robux = Shop.price(f),
		grants = "shopflag:" .. f.key,
		staging = f.staging or 0,
		shop_flag = f.key,
	}
end

--- A set's bundle (Data/Shop.SETS `bundle`; 2026-10-24): all its flags in one product, granting
--- "shopset:<id>".
for sid, s in Shop.SETS do
	if s.bundle ~= nil then
		local prod, staging = Shop.bundle_ids(sid)
		PRODUCTS["shopset_" .. sid] = {
			id = prod,
			robux = s.bundle,
			grants = "shopset:" .. sid,
			staging = staging,
			shop_set = sid,
		}
	end
end

--- DomWorld Staging (Data/Staging): there every product is its `staging` one.
local Staging: any = if typeof(game) == "Instance"
	then require((script :: any).Parent.Staging)
	else (require :: any)("./Staging")

if Staging.here() then
	for _, p in PRODUCTS do
		p.id = p.staging or 0
	end
end

return PRODUCTS
