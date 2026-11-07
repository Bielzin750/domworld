-- Original territory-skin preview made only from UI Frames.
local Cosmetics = require((game :: any):GetService("ReplicatedStorage"):WaitForChild("DomWorld").Data.Cosmetics)

local SkinVisual = {}
local SAND = Color3.fromRGB(221, 205, 160)
local BASE = Color3.fromRGB(64, 132, 230)
local MAX_COLS, MAX_ROWS = 6, 6

local function secondary(skin: any, index: number): Color3
	if type(skin.colors) == "table" then
		local r, g, b = Cosmetics.color(skin, index)
		if r ~= nil and g ~= nil and b ~= nil then
			return Color3.new(r, g, b)
		end
	end
	local r, g, b = Cosmetics.secondary(skin, BASE.R, BASE.G, BASE.B)
	return Color3.new(r, g, b)
end

function SkinVisual.apply(image: GuiObject, skin: any)
	local previous = image:FindFirstChild("ProceduralSkin")
	if previous ~= nil then
		previous:Destroy()
	end
	local root = Instance.new("Frame")
	root.Name = "ProceduralSkin"
	root.BackgroundColor3 = SAND
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.ClipsDescendants = true
	root.ZIndex = image.ZIndex + 1
	root.Parent = image
	local land = Instance.new("Frame")
	land.Name = "Land"
	land.AnchorPoint = Vector2.new(0.5, 0.5)
	land.Position = UDim2.fromScale(0.5, 0.5)
	land.Size = UDim2.fromScale(0.88, 0.78)
	land.BackgroundColor3 = BASE
	land.BorderSizePixel = 0
	land.ZIndex = root.ZIndex + 1
	land.Parent = root
	local land_corner = Instance.new("UICorner")
	land_corner.CornerRadius = UDim.new(0.08, 0)
	land_corner.Parent = land
	local mask, mask_w, mask_h = Cosmetics.mask(skin)
	local cols = math.min(mask_w, MAX_COLS)
	local rows = math.min(mask_h, MAX_ROWS)
	for y = 0, rows - 1 do
		for x = 0, cols - 1 do
			local sx = math.min(mask_w - 1, math.floor((x + 0.5) * mask_w / cols))
			local sy = math.min(mask_h - 1, math.floor((y + 0.5) * mask_h / rows))
			local key = buffer.readu8(mask, sy * mask_w + sx)
			if key > 0 then
				local tile = Instance.new("Frame")
				tile.Name = "Pattern"
				tile.Position = UDim2.fromScale(x / cols + 0.012, y / rows + 0.012)
				tile.Size = UDim2.fromScale(1 / cols - 0.024, 1 / rows - 0.024)
				tile.BackgroundColor3 = secondary(skin, key)
				tile.BorderSizePixel = 0
				tile.ZIndex = land.ZIndex + 1
				tile.Parent = land
			end
		end
	end
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(31, 44, 68)
	edge.Thickness = 1.5
	edge.Parent = root
end

return SkinVisual
