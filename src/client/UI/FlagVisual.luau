-- Procedural DomWorld flag marker used while original flag art has not been uploaded.
-- The marker is built only from Frames, UICorner and UIStroke; it never requests an image asset.
local FlagVisual = {}

local function colors_for(key: string): { Color3 }
	local seed = 0
	for i = 1, #key do
		seed = (seed * 33 + string.byte(key, i)) % 360
	end
	local a = seed / 360
	local b = ((seed * 7 + 113) % 360) / 360
	local c = ((seed * 13 + 227) % 360) / 360
	return {
		Color3.fromHSV(a, 0.72, 0.94),
		Color3.fromHSV(b, 0.68, 0.72),
		Color3.fromHSV(c, 0.3, 1),
	}
end

local function make_flag(parent: ImageLabel): Frame
	local root = Instance.new("Frame")
	root.Name = "ProceduralFlag"
	root.AnchorPoint = Vector2.zero
	root.Position = UDim2.fromScale(0, 0)
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.fromRGB(17, 24, 39)
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.ZIndex = parent.ZIndex + 1
	root.Parent = parent
	local radius = Instance.new("UICorner")
	radius.CornerRadius = UDim.new(0.08, 0)
	radius.Parent = root
	local bands = {}
	for i = 1, 3 do
		local band = Instance.new("Frame")
		band.Name = "Band" .. i
		band.Position = UDim2.fromScale(0, (i - 1) / 3)
		band.Size = UDim2.fromScale(1, 1 / 3 + 0.002)
		band.BorderSizePixel = 0
		band.ZIndex = root.ZIndex + 1
		band.Parent = root
		bands[i] = band
	end
	local diamond = Instance.new("Frame")
	diamond.Name = "CenterDiamond"
	diamond.AnchorPoint = Vector2.new(0.5, 0.5)
	diamond.Position = UDim2.fromScale(0.5, 0.5)
	diamond.Size = UDim2.fromScale(0.2, 0.34)
	diamond.Rotation = 45
	diamond.BackgroundColor3 = Color3.fromRGB(248, 235, 190)
	diamond.BorderSizePixel = 0
	diamond.ZIndex = root.ZIndex + 2
	diamond.Parent = root
	local dot = Instance.new("Frame")
	dot.Name = "CenterDot"
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromScale(0.055, 0.12)
	dot.BackgroundColor3 = Color3.fromRGB(27, 38, 63)
	dot.BorderSizePixel = 0
	dot.ZIndex = root.ZIndex + 3
	dot.Parent = root
	local dot_corner = Instance.new("UICorner")
	dot_corner.CornerRadius = UDim.new(1, 0)
	dot_corner.Parent = dot
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(9, 14, 27)
	edge.Thickness = 1
	edge.Parent = root
	return root
end

--- Draw a deterministic, original three-band flag token inside an image slot.
function FlagVisual.apply(image: ImageLabel, key: string, enabled: boolean?): Frame?
	local root = image:FindFirstChild("ProceduralFlag") :: Frame?
	if enabled == false or key == "" then
		if root ~= nil then
			root.Visible = false
		end
		return root
	end
	local source_image = image.Image
	if source_image ~= "" then
		if root ~= nil then
			root.Visible = false
		end
		return root
	end
	if root == nil then
		root = make_flag(image)
	end
	root.Visible = image.Visible
	if root:GetAttribute("FlagKey") == key then
		return root
	end
	root:SetAttribute("FlagKey", key)
	local colors = colors_for(key)
	for i, color in colors do
		local band = root:FindFirstChild("Band" .. i) :: Frame
		band.BackgroundColor3 = color
	end
	return root
end

return FlagVisual
