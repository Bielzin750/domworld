-- Small original map thumbnail built from colored UI tiles while no uploaded map art is configured.
local MapPreview = {}

local SHAPE = {
	"00011000",
	"00111100",
	"01111110",
	"01111000",
	"00111100",
	"00011000",
}

local function hash(key: string): number
	local n = 17
	for i = 1, #key do
		n = (n * 31 + string.byte(key, i)) % 360
	end
	return n
end

function MapPreview.apply(image: ImageLabel, key: string)
	local old = image:FindFirstChild("DomWorldMapPreview")
	local hue = hash(key)
	local palette = {
		Color3.fromHSV(hue / 360, 0.5, 0.82),
		Color3.fromHSV(((hue + 73) % 360) / 360, 0.52, 0.72),
		Color3.fromHSV(((hue + 151) % 360) / 360, 0.48, 0.78),
	}
	if old ~= nil then
		for _, tile in old:GetChildren() do
			if tile:IsA("Frame") and tile.Name == "Territory" then
				local region = tile:GetAttribute("Region") or 1
				tile.BackgroundColor3 = palette[region]
			end
		end
		return
	end
	local root = Instance.new("Frame")
	root.Name = "DomWorldMapPreview"
	root.BackgroundColor3 = Color3.fromRGB(15, 27, 48)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = image.ZIndex + 1
	root.Parent = image
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.06, 0)
	corner.Parent = root
	local cells = {}
	for y, row in SHAPE do
		for x = 1, #row do
			if string.sub(row, x, x) == "1" then
				local region = 1 + ((x + y + hue // 30) % #palette)
				local tile = Instance.new("Frame")
				tile.Name = "Territory"
				tile.BackgroundColor3 = palette[region]
				tile:SetAttribute("Region", region)
				tile.BackgroundTransparency = 1
				tile.BorderSizePixel = 0
				tile.Position = UDim2.fromScale((x - 1) / 8 + 0.012, (y - 1) / 6 + 0.012)
				tile.Size = UDim2.fromScale(1 / 8 - 0.024, 1 / 6 - 0.024)
				tile.ZIndex = root.ZIndex + 1
				tile.Parent = root
				local edge = Instance.new("UICorner")
				edge.CornerRadius = UDim.new(0.12, 0)
				edge.Parent = tile
				table.insert(cells, tile)
			end
		end
	end
	local capital = Instance.new("Frame")
	capital.Name = "Capital"
	capital.AnchorPoint = Vector2.new(0.5, 0.5)
	capital.Position = UDim2.fromScale(0.5, 0.48)
	capital.Size = UDim2.fromScale(0.09, 0.14)
	capital.BackgroundColor3 = Color3.fromRGB(255, 230, 151)
	capital.BackgroundTransparency = 1
	capital.BorderSizePixel = 0
	capital.ZIndex = root.ZIndex + 2
	capital.Parent = root
	local dot = Instance.new("UICorner")
	dot.CornerRadius = UDim.new(1, 0)
	dot.Parent = capital
	local function sync()
		local alpha = math.clamp(image.ImageTransparency, 0, 1)
		root.Visible = image.Image == ""
		root.BackgroundTransparency = 0.12 + alpha * 0.88
		for _, tile in cells do
			tile.BackgroundTransparency = 0.12 + alpha * 0.88
		end
		capital.BackgroundTransparency = 0.04 + alpha * 0.96
	end
	image:GetPropertyChangedSignal("ImageTransparency"):Connect(sync)
	image:GetPropertyChangedSignal("Image"):Connect(sync)
	sync()
end

return MapPreview
