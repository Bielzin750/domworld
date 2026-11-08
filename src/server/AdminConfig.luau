-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Production roles are configured by Roblox UserId; the owner is fixed in code.

return {
	OwnerUserIds = {
		-- Existing verified account candidate from the previous allowlist; confirm this UserId before publishing.
		33980672,
	},
	AdminUserIds = {},
	-- Studio Team Create exposes the owner panel to every local tester when enabled.
	StudioTestersAreAdmin = true,
	ShortcutKey = "F10",
}
