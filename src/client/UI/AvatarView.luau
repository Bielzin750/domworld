--!strict
-- Modified for DomWorld, 2026 — see git history for details.
-- Reuses Roblox head-shot URLs and keeps the procedural avatar visible until an image is ready.

local AvatarView = {}

local cache: { [string]: boolean? } = {}
local pending: any = {}
local bound: { [ImageLabel]: string } = setmetatable({}, { __mode = "k" }) :: any

local function valid_user_id(user_id: any): boolean
	return type(user_id) == "number" and user_id == user_id and user_id % 1 == 0 and user_id > 0 and user_id < math.huge
end

function AvatarView.kind(user_id: any, is_bot: boolean?): string
	return if not is_bot and valid_user_id(user_id) then "real" else "generated"
end

function AvatarView.key(user_id: any, is_bot: boolean?, name: string): string
	if AvatarView.kind(user_id, is_bot) == "real" then
		return "real:" .. tostring(user_id)
	end
	return if is_bot then "bot:" .. string.lower(name) else "none"
end

function AvatarView.generated_color(name: string, colors: { [string]: Color3 }): Color3
	local palette = {
		colors.primary,
		colors.coral,
		colors.warning,
		colors.positive,
		colors.primaryDeep,
		colors.lineStrong,
	}
	local hash = 0
	for index = 1, #name do
		hash = (hash * 33 + string.byte(name, index)) % 2147483647
	end
	return palette[(hash % #palette) + 1]
end

local function show_ready(rows: any, key: string, success: boolean)
	for _, row in rows do
		local image, fallback = row[1], row[2]
		if bound[image] == key and image.Parent ~= nil and fallback.Parent ~= nil then
			image.Visible = success
			fallback.Visible = not success
		end
	end
end

function AvatarView.bind(
	image: ImageLabel,
	fallback: TextLabel,
	user_id: any,
	is_bot: boolean?,
	name: string,
	colors: { [string]: Color3 },
	team_color: Color3,
	preserve_border: boolean?
)
	local kind = AvatarView.kind(user_id, is_bot)
	fallback.Text = string.upper(string.sub(name, 1, 1))
	fallback.BackgroundColor3 = AvatarView.generated_color(name, colors)
	local border = image.Parent and image.Parent:FindFirstChildOfClass("UIStroke")
	if border ~= nil and preserve_border ~= true then
		border.Color = team_color
	end
	if kind ~= "real" then
		bound[image] = if is_bot then AvatarView.key(user_id, true, name) else "none"
		image.Image = ""
		image.Visible = false
		fallback.Visible = true
		return
	end
	local numeric_id = user_id :: number
	local key = string.format("%d:150:150", numeric_id)
	if bound[image] == key then
		return
	end
	bound[image] = key
	local url = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", numeric_id)
	image.Image = url
	image.Visible = false
	fallback.Visible = true
	if cache[key] ~= nil then
		image.Visible = cache[key] == true
		fallback.Visible = cache[key] ~= true
		return
	end
	local rows = pending[key]
	if rows ~= nil then
		table.insert(rows, { image, fallback })
		return
	end
	rows = { { image, fallback } }
	pending[key] = rows
	task.spawn(function()
		local ok, status = pcall(function()
			local result = false
			game:GetService("ContentProvider"):PreloadAsync({ image }, function(_, fetch_status)
				result = tostring(fetch_status) == "Enum.AssetFetchStatus.Success"
			end)
			return result
		end)
		local success = ok and status == true
		cache[key] = success
		local subscribers = pending[key]
		pending[key] = nil
		if subscribers ~= nil then
			show_ready(subscribers, key, success)
		end
	end)
end

return AvatarView
