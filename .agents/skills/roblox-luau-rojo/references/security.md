# Remote and data security checklist (DomWorld)

Use this checklist for every RemoteEvent, RemoteFunction and UnreliableRemoteEvent that crosses the client/server boundary.

## 1. Remote handler template (server)

```lua
local MAX_CALLS_PER_SECOND = 8
local callLog: { [Player]: { count: number, windowStart: number } } = {}

local function rateLimited(player: Player): boolean
	local now = os.clock()
	local entry = callLog[player]
	if not entry or now - entry.windowStart >= 1 then
		callLog[player] = { count = 1, windowStart = now }
		return false
	end
	entry.count += 1
	return entry.count > MAX_CALLS_PER_SECOND
end

AttackRemote.OnServerEvent:Connect(function(player: Player, tileId: unknown)
	if rateLimited(player) then
		return
	end
	if typeof(tileId) ~= "number" or tileId ~= tileId or tileId % 1 ~= 0
		or tileId < 1 or tileId > MAX_TILE_ID then
		return
	end
	-- 1) the player must be in an active match
	-- 2) the player must own an adjacent tile
	-- 3) cooldown and resources are checked on the server
	-- 4) apply the result on the server, then replicate to clients
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
	callLog[player] = nil
end)
```

## 2. Checklist

- [ ] Argument count, `typeof`, finite number (reject NaN and `math.huge`), integer where required, range, string length and charset.
- [ ] Instances sent by the client are never trusted (they may be nil, destroyed, or somewhere unexpected). Prefer IDs that the server resolves.
- [ ] State, ownership, cooldown and resource checks happen on the server before any effect.
- [ ] Per-player rate limit; clean up on `PlayerRemoving`.
- [ ] No remote lets the client set money, XP, territory, rank or timers directly.
- [ ] RemoteFunctions invoked from the server toward a client have a timeout and never stall the server loop.
- [ ] Remote names stay consistent on both sides after any rename.

## 3. Data persistence

- [ ] `pcall` around every `GetAsync` / `UpdateAsync` / `SetAsync`; prefer `UpdateAsync` for read-modify-write.
- [ ] Retry with backoff; stop retrying on shutdown.
- [ ] `game:BindToClose` saves all players before the server closes.
- [ ] Stored data has a `version` field and a migration path.
- [ ] Do not rename DataStore names or keys casually: it orphans existing player data. If a rename is required, write a migration and note it in `CHANGELOG.md`.

## 4. Purchases

- [ ] `MarketplaceService.ProcessReceipt` is idempotent (record `PurchaseId` before granting).
- [ ] Items are granted from the server only, never from a client request.
- [ ] Return `NotProcessedYet` when persistence fails so Roblox retries.

## 5. HTTP and external services

- [ ] Secrets stay on the server in secure configuration; never in client modules or place files.
- [ ] Timeouts, error handling and size limits on every `HttpService` call.
- [ ] Validate and size-limit everything received from the lobby service as well.
