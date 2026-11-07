--!nonstrict
-- Port of scripts/ui/busy_chip.gd (UIBusyChip)
-- Small centred "Deploying a new world…" pill with a spinner, shown while Session builds a match.

local UITheme = require("./UITheme")
local W = require("./Widgets")
local GlassPanel = require("./GlassPanel")

-- --- Spinner (18 px: faint ring + a rotating amber mark) -----------------------------------------

local Spinner = W.class(W.Control)

function Spinner.new()
	local self = setmetatable({}, Spinner.__mt)
	W.Control._init(self)
	self.t = 0.0
	self:set_min_size(Vector2.new(18, 18))
	self:set_mouse_filter(W.MOUSE_IGNORE)
	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.BackgroundTransparency = 1
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromScale(1, 1)
	ring.ZIndex = 1
	ring.Parent = self.gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = ring
	local edge = Instance.new("UIStroke")
	edge.Color = Color3.new(1, 1, 1)
	edge.Thickness = 1.5
	edge.Transparency = 0.55
	edge.Parent = ring
	local arc = Instance.new("Frame")
	arc.Name = "Arc"
	arc.BackgroundTransparency = 1
	arc.AnchorPoint = Vector2.new(0.5, 0.5)
	arc.Position = UDim2.fromScale(0.5, 0.5)
	arc.Size = UDim2.fromScale(1, 1)
	arc.ZIndex = 2
	arc.Parent = self.gui
	local mark = Instance.new("Frame")
	mark.Name = "ArcMark"
	mark.AnchorPoint = Vector2.new(0.5, 0)
	mark.Position = UDim2.fromScale(0.5, 0.02)
	mark.Size = UDim2.fromScale(0.2, 0.42)
	mark.BackgroundColor3 = UITheme.AMBER
	mark.BorderSizePixel = 0
	mark.ZIndex = 2
	mark.Parent = arc
	local mark_corner = Instance.new("UICorner")
	mark_corner.CornerRadius = UDim.new(0.5, 0)
	mark_corner.Parent = mark
	self._ring = ring
	self._arc = arc
	return self
end

function Spinner._process(self, delta: number)
	self.t += delta
	self._arc.Rotation = math.deg(self.t * 5.5)
end

-- --- BusyChip -------------------------------------------------------------------------------------------

local BusyChip = W.class(W.Control)
BusyChip.Spinner = Spinner

function BusyChip.new(c: any)
	local self = setmetatable({}, BusyChip.__mt)
	W.Control._init(self)
	self.ctx = c
	self:set_mouse_filter(W.MOUSE_IGNORE)
	self:set_anchors_and_offsets_preset(W.PRESET_FULL_RECT)
	self._pill = GlassPanel.new(16.0, 9.0, 999, true, 18)
	self._pill:set_mouse_filter(W.MOUSE_IGNORE)
	local h = UITheme.hbox(10)
	self._spin = Spinner.new()
	self._spin.size_flags_vertical = W.SHRINK_CENTER
	h:add_child(self._spin)
	self._label = UITheme.label("", 14, 700, UITheme.TEXT, 1)
	h:add_child(self._label)
	self._pill:add_child(h)
	self:add_child(self._pill)
	self:set_visible(false)
	return self
end

function BusyChip.show_text(self, text: string)
	self._label:set_text(text)
	local p = self._pill
	p.anchor_left, p.anchor_right, p.anchor_top, p.anchor_bottom = 0.5, 0.5, 0.5, 0.5
	p.grow_horizontal = W.GROW_BOTH
	p.grow_vertical = W.GROW_BOTH
	p.offset_left = 0.0
	p.offset_right = 0.0
	p.offset_top = -self.ctx.vp.Y * 0.18
	p.offset_bottom = p.offset_top
	p:reset_size()
	if not self.visible then
		self:set_visible(true)
		self._spin:set_process(true)
		W.pop_in(p, 0.0, 0.94, 0.25)
	end
end

function BusyChip.hide_chip(self)
	if not self.visible then
		return
	end
	self._spin:set_process(false)
	local t = self:create_tween()
	t:tween_property(self, "modulate:a", 0.0, 0.2)
	t:tween_callback(function()
		self:set_visible(false)
		self:set_modulate_a(1.0)
	end)
end

return BusyChip
