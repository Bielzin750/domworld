--!strict
-- The DomWorld Staging experience (2026-10-04: a separate game to test changes in before they go to
-- prod): its universe id, for what differs there (Data/Products' ids, the game menu's
-- "Replay as new player").
-- Modified for DomWorld, 2026 — see git history for details.
local Staging = {}

--- DomWorld Staging's universe id.
Staging.UNIVERSE = 0

--- True in the DomWorld Staging experience.
function Staging.here(): boolean
	return typeof(game) == "Instance" and (game :: any).GameId == Staging.UNIVERSE
end

return Staging
