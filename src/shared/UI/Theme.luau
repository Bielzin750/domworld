--!strict
-- Modified for DomWorld, 2026 — see git history for details.
-- Atlas Tático design tokens. UI chrome reads colours, spacing, radii, motion and layer order here.

local Theme = {}

Theme.Name = "Atlas Tático"

Theme.Colors = {
	canvas = Color3.fromRGB(15, 27, 31), -- #0F1B1F
	surface = Color3.fromRGB(22, 38, 43), -- #16262B
	surfaceRaised = Color3.fromRGB(30, 51, 57), -- #1E3339
	surfaceHigh = Color3.fromRGB(39, 63, 69),
	primary = Color3.fromRGB(52, 209, 191), -- #34D1BF
	primaryBright = Color3.fromRGB(91, 228, 211),
	primaryDeep = Color3.fromRGB(24, 132, 124),
	coral = Color3.fromRGB(255, 92, 122), -- #FF5C7A
	coralDeep = Color3.fromRGB(179, 56, 81),
	warning = Color3.fromRGB(245, 188, 92),
	text = Color3.fromRGB(232, 241, 242), -- #E8F1F2
	textMuted = Color3.fromRGB(143, 167, 171), -- #8FA7AB
	textDim = Color3.fromRGB(103, 130, 135),
	line = Color3.fromRGB(58, 82, 88),
	lineStrong = Color3.fromRGB(82, 111, 116),
	positive = Color3.fromRGB(100, 205, 172),
	white = Color3.fromRGB(255, 255, 255),
	black = Color3.fromRGB(0, 0, 0),
}

Theme.Spacing = { 4, 8, 12, 16, 20, 24, 32, 40, 48 }
Theme.Radii = { small = 4, medium = 5, large = 6 }
Theme.Fonts =
	{ regular = "Gotham", medium = "GothamMedium", bold = "GothamBold", heavy = "GothamBlack", numeric = "Code" }
Theme.Motion = { fast = 0.12, standard = 0.16, slow = 0.20, reduced = false }
Theme.Z = { base = 1, content = 2, nav = 5, overlay = 10, modal = 20, alert = 30 }

function Theme.duration(seconds: number): number
	return if Theme.Motion.reduced then 0 else math.clamp(seconds, 0, 0.2)
end

return Theme
