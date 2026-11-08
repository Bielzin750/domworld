-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Modified for DomWorld, 2026 — see git history for details.
-- Server-side role checks; client UI and player attributes never grant authority.

--!strict

local AdminAuth = {}
AdminAuth.__index = AdminAuth

local function is_user_id(value: any): boolean
	return type(value) == "number" and value == value and value % 1 == 0 and value > 0 and value < math.huge
end

local function read_ids(raw: any): { [number]: boolean }
	local out = {}
	if type(raw) == "table" then
		for _, user_id in raw do
			if is_user_id(user_id) then
				out[user_id] = true
			end
		end
	end
	return out
end

function AdminAuth.new(config: any, studio: boolean)
	local safe_config = if type(config) == "table" then config else {}
	return setmetatable({
		owners = read_ids(safe_config.OwnerUserIds),
		admins = read_ids(safe_config.AdminUserIds),
		roster = {} :: { [number]: boolean },
		studio_testers = studio == true and safe_config.StudioTestersAreAdmin == true,
		shortcut_key = if type(safe_config.ShortcutKey) == "string" then safe_config.ShortcutKey else "F10",
	}, AdminAuth)
end

function AdminAuth.set_roster(self: any, roster: any)
	local ids: { [number]: boolean } = {}
	if type(roster) == "table" then
		for key, value in roster do
			if value == true and is_user_id(tonumber(key)) then
				ids[tonumber(key)] = true
			elseif is_user_id(value) then
				ids[value] = true
			end
		end
	end
	self.roster = ids
end

function AdminAuth.role(self: any, player: any): string?
	if (type(player) ~= "table" and typeof(player) ~= "Instance") or not is_user_id(player.UserId) then
		return nil
	end
	local user_id = player.UserId
	if self.owners[user_id] then
		return "owner"
	end
	if self.admins[user_id] or self.roster[user_id] then
		return "admin"
	end
	if self.studio_testers then
		return "admin"
	end
	return nil
end

function AdminAuth.is_admin(self: any, player: any): boolean
	return self:role(player) ~= nil
end

function AdminAuth.is_owner(self: any, player: any): boolean
	return self:role(player) == "owner"
end

AdminAuth.isAdmin = AdminAuth.is_admin

return AdminAuth
