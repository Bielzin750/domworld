-- Primitive dimensions and hinge points for DomWorld's original cosmetic chest.
-- `ChestView` builds its body, metal trim, crest and inlay from basic Parts at runtime.
-- The pivot is at the bottom centre, front = -Z, lid closed; the lid rotates around `hinge` on X.
return {
	size = { 5, 4.6666, 5 },
	hinge = { 0, 1.6667, 2.5 },
	-- the open chest's mouth (the card comes out here) and the lid's front seam (light leaks there)
	mouth = { 0, 2.1, 0 },
	seam = { 0, 1.6667, -2.5 },
	lid_open = 140,
	parts = {
		{
			name = "Lid",
			lid = true,
			size = { 5, 3, 5 },
			cf = { 0, 3.1666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 },
		},
		{
			name = "Bottom",
			lid = false,
			size = { 4.6666, 2.3333, 4.6666 },
			cf = { 0, 1.1667, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 },
		},
	},
}
