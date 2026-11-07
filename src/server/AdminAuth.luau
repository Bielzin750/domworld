-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Server-side admin authorization. Public source code and client UI are never trusted as a secret.

--!strict

local AdminAuth = {}
AdminAuth.__index = AdminAuth

local function is_user_id(value: any): boolean
	return type(value) == "number" and value == value and value % 1 == 0 and value > 0 and value < math.huge
end

function AdminAuth.new(config: any, studio: boolean)
	local ids: { [number]: boolean } = {}
	local raw = if type(config) == "table" then config.UserIds else nil
	if type(raw) == "table" then
		for _, user_id in raw do
			if is_user_id(user_id) then
				ids[user_id] = true
			end
		end
	end
	return setmetatable({ user_ids = ids, studio = studio == true }, AdminAuth)
end

function AdminAuth.is_admin(self: any, player: any): boolean
	if self.studio then
		return true
	end
	if type(player) ~= "table" and typeof(player) ~= "Instance" then
		return false
	end
	local user_id = player.UserId
	return is_user_id(user_id) and self.user_ids[user_id] == true
end

--! Compatibility spelling for code that follows Roblox's isAdmin convention.
AdminAuth.isAdmin = AdminAuth.is_admin

return AdminAuth
