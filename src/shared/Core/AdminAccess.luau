--!strict
-- Modified for DomWorld, 2026 — see git history for details.
-- Client gate: an admin interface is built only after the server returns an authorized role.

local AdminAccess = {}

function AdminAccess.confirmed(state: any): boolean
	return type(state) == "table" and state.ok == true and (state.role == "owner" or state.role == "admin")
end

return AdminAccess
