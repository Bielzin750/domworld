-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- Modified for DomWorld, 2026 — see git history for details.
-- Persistent, server-only roster for admins managed by the configured owner.

--!strict

local AdminRoster = {}
AdminRoster.__index = AdminRoster
AdminRoster.MAX_ADMINS = 20
AdminRoster.KEY = "team"
AdminRoster.ATTEMPTS = 3

local function valid_user_id(value: any): boolean
	return type(value) == "number" and value == value and value % 1 == 0 and value > 0 and value <= 9007199254740991
end

local function normalize(raw: any): { [string]: any }
	local rows = {}
	if type(raw) ~= "table" then
		return rows
	end
	for key, value in raw do
		local user_id = tonumber(key)
		if valid_user_id(user_id) and type(value) == "table" then
			rows[tostring(user_id)] = {
				user_id = user_id,
				username = string.sub(tostring(value.username or "Unknown"), 1, 32),
				added_at = math.max(0, math.floor(tonumber(value.added_at) or 0)),
				added_by_user_id = math.max(0, math.floor(tonumber(value.added_by_user_id) or 0)),
				added_by_name = string.sub(tostring(value.added_by_name or "Unknown"), 1, 32),
			}
		end
	end
	return rows
end

function AdminRoster.new(store: any?, wait_fn: ((number) -> ())?, owner_ids: any?)
	local owners = {}
	if type(owner_ids) == "table" then
		for _, id in owner_ids do
			if valid_user_id(id) then
				owners[id] = true
			end
		end
	end
	return setmetatable({
		store = store,
		wait = wait_fn,
		owners = owners,
		entries = {} :: { [string]: any },
		loaded = false,
	}, AdminRoster)
end

function AdminRoster.is_available(self: any): boolean
	return self.store ~= nil and self.loaded == true
end

function AdminRoster.is_owner(self: any, user_id: any): boolean
	return valid_user_id(user_id) and self.owners[user_id] == true
end

function AdminRoster.member_ids(self: any): { [number]: boolean }
	local ids = {}
	for _, entry in self.entries do
		ids[entry.user_id] = true
	end
	return ids
end

function AdminRoster.list(self: any): { any }
	local rows = {}
	for _, row in self.entries do
		table.insert(rows, table.clone(row))
	end
	table.sort(rows, function(a, b)
		return a.user_id < b.user_id
	end)
	return rows
end

function AdminRoster.load(self: any): (boolean, string?)
	if self.store == nil then
		return false, "AdminRoster DataStore indisponível"
	end
	local last_error = "DataStore indisponível"
	for attempt = 1, AdminRoster.ATTEMPTS do
		local ok, result = pcall(function()
			return self.store:GetAsync(AdminRoster.KEY)
		end)
		if ok then
			self.entries = normalize(result)
			self.loaded = true
			return true, nil
		end
		last_error = tostring(result)
		if attempt < AdminRoster.ATTEMPTS and self.wait ~= nil then
			self.wait(0.2 * attempt)
		end
	end
	return false, last_error
end

function AdminRoster._mutate(self: any, transform: (any) -> (any, string?)): (boolean, string?)
	if self.store == nil then
		return false, "AdminRoster DataStore indisponível"
	end
	local last_error = "DataStore indisponível"
	for attempt = 1, AdminRoster.ATTEMPTS do
		local refusal: string? = nil
		local ok, result = pcall(function()
			return self.store:UpdateAsync(AdminRoster.KEY, function(old: any): any
				local rows = normalize(old)
				rows, refusal = transform(rows)
				return rows
			end)
		end)
		if ok then
			self.entries = normalize(result)
			self.loaded = true
			return refusal == nil, refusal
		end
		last_error = tostring(result)
		if attempt < AdminRoster.ATTEMPTS and self.wait ~= nil then
			self.wait(0.2 * attempt)
		end
	end
	return false, "AdminRoster DataStore indisponível: " .. last_error
end

function AdminRoster.add(self: any, entry: any): (boolean, string?)
	if type(entry) ~= "table" or not valid_user_id(entry.user_id) then
		return false, "UserId inválido"
	end
	if self.owners[entry.user_id] then
		return false, "O dono já tem acesso permanente"
	end
	local user_id = entry.user_id
	return self:_mutate(function(rows: any): (any, string?)
		local key = tostring(user_id)
		if rows[key] ~= nil then
			return rows, "Esta pessoa já está na equipe"
		end
		local count = 0
		for _ in rows do
			count += 1
		end
		if count >= AdminRoster.MAX_ADMINS then
			return rows, "Limite de 20 administradores atingido"
		end
		rows[key] = {
			user_id = user_id,
			username = string.sub(tostring(entry.username), 1, 32),
			added_at = math.max(0, math.floor(tonumber(entry.added_at) or os.time())),
			added_by_user_id = math.max(0, math.floor(tonumber(entry.added_by_user_id) or 0)),
			added_by_name = string.sub(tostring(entry.added_by_name or "Unknown"), 1, 32),
		}
		return rows, nil
	end)
end

function AdminRoster.remove(self: any, user_id: any): (boolean, string?)
	if not valid_user_id(user_id) then
		return false, "UserId inválido"
	end
	if self.owners[user_id] then
		return false, "O dono não pode ser removido"
	end
	return self:_mutate(function(rows: any): (any, string?)
		local key = tostring(user_id)
		if rows[key] == nil then
			return rows, "Administrador não encontrado"
		end
		rows[key] = nil
		return rows, nil
	end)
end

return AdminRoster
