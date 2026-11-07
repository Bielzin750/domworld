-- DomWorld
-- Licensed under the GNU AGPL v3 (see LICENSE and NOTICE.md).
-- All admin operations pass through this server-only gate before input or game state is inspected.

--!strict

local AdminService = {}
AdminService.__index = AdminService

AdminService.RATE_WINDOW_S = 10
AdminService.MAX_ACTIONS_PER_WINDOW = 20
AdminService.MAX_STARS_CHANGE = 1000000
AdminService.MAX_STARS_BALANCE = 1000000000
AdminService.MAX_TROOPS = 1000000000
AdminService.MAX_GOLD = 1000000000
AdminService.MAX_LOG_ROWS = 100

local function finite_integer(value: any, minimum: number, maximum: number): boolean
	return type(value) == "number"
		and value == value
		and value % 1 == 0
		and value >= minimum
		and value <= maximum
		and value < math.huge
end

local function short_string(value: any, max_length: number): boolean
	return type(value) == "string" and #value > 0 and #value <= max_length
end

function AdminService.new(deps: { [string]: any })
	return setmetatable({
		deps = deps,
		_windows = {} :: { [any]: { started: number, count: number } },
		_denied_at = {} :: { [any]: number },
		_logs = {} :: { any },
	}, AdminService)
end

function AdminService._audit(self: any, player: any, action: string, target: string, value: string, result: string)
	local row = {
		time = (self.deps.now or os.time)(),
		actor = string.sub(tostring(player.Name or "unknown"), 1, 32),
		user_id = tonumber(player.UserId) or 0,
		action = string.sub(action, 1, 40),
		target = string.sub(target, 1, 64),
		value = string.sub(value, 1, 64),
		result = string.sub(result, 1, 64),
	}
	table.insert(self._logs, row)
	while #self._logs > AdminService.MAX_LOG_ROWS do
		table.remove(self._logs, 1)
	end
	local line = string.format(
		"[AdminAudit] %s (%d) action=%s target=%s value=%s result=%s",
		row.actor,
		row.user_id,
		row.action,
		row.target,
		row.value,
		row.result
	)
	if self.deps.log ~= nil then
		self.deps.log(line)
	else
		print(line)
	end
end

function AdminService._is_admin(self: any, player: any): boolean
	local auth = self.deps.auth
	local ok, yes = pcall(auth.is_admin, auth, player)
	if ok and yes == true then
		return true
	end
	local now = (self.deps.clock or os.clock)()
	local last = self._denied_at[player] or -math.huge
	if now - last >= 1 then
		self._denied_at[player] = now
		self:_audit(player, "authorization_denied", "", "", if ok then "not_admin" else "auth_error")
	end
	return false
end

function AdminService._rate_limited(self: any, player: any): boolean
	local now = (self.deps.clock or os.clock)()
	local entry = self._windows[player]
	if entry == nil or now - entry.started >= AdminService.RATE_WINDOW_S then
		self._windows[player] = { started = now, count = 1 }
		return false
	end
	entry.count += 1
	return entry.count > AdminService.MAX_ACTIONS_PER_WINDOW
end

function AdminService.get_state(self: any, player: any): any
	if not self:_is_admin(player) then
		return { ok = false }
	end
	if self:_rate_limited(player) then
		self:_audit(player, "state_rate_limited", "", "", "rejected:slow down")
		return { ok = false, message = "slow down" }
	end
	local players = self.deps.players()
	local target_rows = {}
	for _, target in players do
		local inventory = self.deps.purchases.inventory(target)
		table.insert(target_rows, {
			user_id = target.UserId,
			name = string.sub(target.DisplayName ~= "" and target.DisplayName or target.Name, 1, 32),
			stars = self.deps.purchases.stars(target),
			cosmetics = #inventory.owned,
		})
	end
	table.sort(target_rows, function(a, b)
		return a.user_id < b.user_id
	end)
	local match_state = self.deps.match.admin_state()
	return {
		ok = true,
		players = target_rows,
		match = match_state,
		logs = table.clone(self._logs),
	}
end

function AdminService._reject(
	self: any,
	player: any,
	action: string,
	target: string,
	value: string,
	reason: string
): any
	self:_audit(player, action, target, value, "rejected:" .. reason)
	return { ok = false, message = reason }
end

function AdminService.execute(self: any, player: any, request: any): any
	-- Authorization is intentionally the first check on every untrusted admin request.
	if not self:_is_admin(player) then
		return { ok = false }
	end
	if self:_rate_limited(player) then
		return self:_reject(player, "rate_limited", "", "", "slow down")
	end
	if type(request) ~= "table" or not short_string(request.action, 40) then
		return self:_reject(player, "invalid_request", "", "", "invalid request")
	end
	local action = request.action
	local match = self.deps.match
	local result: any = nil
	local target = ""
	local value = ""
	if action == "stars" then
		local user_id = request.user_id
		local mode = request.mode
		local amount = request.amount
		if
			not finite_integer(user_id, 1, 9007199254740991)
			or (mode ~= "add" and mode ~= "remove" and mode ~= "set")
			or not finite_integer(amount, 0, AdminService.MAX_STARS_BALANCE)
		then
			return self:_reject(player, action, "", tostring(amount), "invalid stars change")
		end
		local selected = self.deps.player_by_user_id(user_id)
		if selected == nil then
			return self:_reject(player, action, tostring(user_id), tostring(amount), "player must be online")
		end
		if mode ~= "set" and amount > AdminService.MAX_STARS_CHANGE then
			return self:_reject(player, action, tostring(user_id), tostring(amount), "adjustment exceeds 1,000,000")
		end
		local ok, balance_or_reason = self.deps.purchases.admin_stars(selected, mode, amount)
		if not ok then
			return self:_reject(player, action, tostring(user_id), tostring(amount), tostring(balance_or_reason))
		end
		target = string.format("%s (%d)", selected.Name, user_id)
		value = string.format("%s %d => %d Stars", mode, amount, balance_or_reason)
		result = { ok = true, message = "Balance updated", balance = balance_or_reason }
	elseif action == "set_troops" or action == "set_gold" then
		local owner_id = request.owner_id
		local cap = if action == "set_troops" then AdminService.MAX_TROOPS else AdminService.MAX_GOLD
		if not finite_integer(owner_id, 1, 1023) or not finite_integer(request.amount, 0, cap) then
			return self:_reject(player, action, tostring(owner_id), tostring(request.amount), "invalid owner or amount")
		end
		local ok, message = match.admin_action(action, { owner_id = owner_id, amount = request.amount })
		target, value = "owner " .. tostring(owner_id), tostring(request.amount)
		result = if ok then { ok = true, message = message or "Match updated" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	elseif action == "set_tile_owner" then
		if not finite_integer(request.tile, 0, 16777215) or not finite_integer(request.owner_id, 0, 1023) then
			return self:_reject(
				player,
				action,
				tostring(request.tile),
				tostring(request.owner_id),
				"invalid tile or owner"
			)
		end
		local ok, message = match.admin_action(action, { tile = request.tile, owner_id = request.owner_id })
		target, value = "tile " .. tostring(request.tile), "owner " .. tostring(request.owner_id)
		result = if ok then { ok = true, message = message or "Tile updated" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	elseif action == "eliminate" then
		if not finite_integer(request.owner_id, 1, 1023) then
			return self:_reject(player, action, tostring(request.owner_id), "", "invalid owner")
		end
		local killer = if finite_integer(request.killer_id, 0, 1023) then request.killer_id else 0
		local ok, message = match.admin_action(action, { owner_id = request.owner_id, killer_id = killer })
		target, value = "owner " .. tostring(request.owner_id), "killer " .. tostring(killer)
		result = if ok then { ok = true, message = message or "Player eliminated" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	elseif action == "focus_owner" then
		if not finite_integer(request.owner_id, 1, 1023) then
			return self:_reject(player, action, tostring(request.owner_id), "", "invalid owner")
		end
		local ok, message = match.admin_action(action, { owner_id = request.owner_id })
		target, value = "owner " .. tostring(request.owner_id), "camera focus"
		result = if ok then { ok = true, message = message or "Camera target confirmed" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	elseif action == "remove_bot" then
		if not finite_integer(request.owner_id, 1, 1023) then
			return self:_reject(player, action, tostring(request.owner_id), "", "invalid owner")
		end
		local ok, message = match.admin_action(action, { owner_id = request.owner_id })
		target, value = "owner " .. tostring(request.owner_id), "removed"
		result = if ok then { ok = true, message = message or "Bot removed" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	elseif action == "add_bot" then
		local name = if type(request.name) == "string" then request.name else "Admin Bot"
		if #name > 20 or string.match(name, "^[%w _%-]+$") == nil then
			return self:_reject(player, action, name, "", "invalid bot name")
		end
		local ok, owner_id = match.admin_action(action, { name = name })
		target, value = name, "owner " .. tostring(owner_id)
		result = if ok then { ok = true, message = "Bot queued for spawn", owner_id = owner_id } else nil
		if not ok then
			return self:_reject(player, action, name, "", tostring(owner_id or "spawn phase only"))
		end
	elseif action == "pause" then
		if type(request.paused) ~= "boolean" then
			return self:_reject(player, action, "match", tostring(request.paused), "pause must be boolean")
		end
		local ok, message = match.admin_action(action, { paused = request.paused })
		target, value = "match", if request.paused then "paused" else "resumed"
		result = if ok then { ok = true, message = message or "Match state updated" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	elseif action == "speed" then
		local speed = request.speed
		if type(speed) ~= "number" or speed ~= speed or speed < 0.5 or speed > 5 or speed == math.huge then
			return self:_reject(player, action, "match", tostring(speed), "speed must be 0.5x to 5x")
		end
		local ok, message = match.admin_action(action, { speed = speed })
		target, value = "match", tostring(speed) .. "x"
		result = if ok then { ok = true, message = message or "Match speed updated" } else nil
		if not ok then
			return self:_reject(player, action, target, value, tostring(message or "match unavailable"))
		end
	else
		return self:_reject(player, action, "", "", "action is not available")
	end
	self:_audit(player, action, target, value, "ok")
	return result
end

function AdminService.remove_player(self: any, player: any)
	self._windows[player] = nil
	self._denied_at[player] = nil
end

return AdminService
