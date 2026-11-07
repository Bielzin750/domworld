--!nonstrict
-- The cosmetic crate's original 3D chest, built from Roblox Parts only. It is shared by the opening
-- show (CrateOpening), title screen (CrateButton) and Locker. No uploaded mesh or texture is needed.
-- pose() places the hinged lid and body from a pose table:
--   y (studs), yaw / roll / pitch (radians), sq (squash, + = flat), s (scale), lid (degrees).
-- idle() is the small views' life: a bob, and every `every` seconds a wiggle with the lid cracking.
local IS_ROBLOX = typeof(game) == "Instance"
local Model: any = if IS_ROBLOX
	then require((game :: any):GetService("ReplicatedStorage"):WaitForChild("DomWorld").Assets.CrateModel)
	else (require :: any)("../../shared/Assets/CrateModel")

local ChestView = {}

ChestView.Model = Model
-- the camera (studs): the closed chest takes about 60% of a square viewport's width
ChestView.CAM_FOV = 28
ChestView.CAM_CF = CFrame.lookAt(Vector3.new(0, 6.2, -18), Vector3.new(0, 2.3, 0))
ChestView.BASE_YAW = math.rad(24)
ChestView.AMBIENT = Color3.fromRGB(150, 146, 150)

local function v3(t: { number }): Vector3
	return Vector3.new(t[1], t[2], t[3])
end
ChestView.v3 = v3

--- A fresh pose (the chest at rest, closed).
function ChestView.rest(): { [string]: number }
	return { y = 0, yaw = 0, roll = 0, pitch = 0, sq = 0, s = 1, lid = 0 }
end

--- The camera and the chest's parts inside `vpf` (its lighting set too). Returns the chest record.
function ChestView.build(vpf: ViewportFrame): any
	vpf.Ambient = ChestView.AMBIENT
	vpf.LightColor = Color3.fromRGB(255, 244, 228)
	vpf.LightDirection = Vector3.new(0.45, -1, 0.55)
	local cam = Instance.new("Camera")
	cam.FieldOfView = ChestView.CAM_FOV
	cam.CFrame = ChestView.CAM_CF
	cam.Parent = vpf
	vpf.CurrentCamera = cam
	local hinge = CFrame.new(v3(Model.hinge))
	local chest = { parts = {}, hinge = hinge, hinge_inv = hinge:Inverse() }
	for _, p in Model.parts do
		local size = v3(p.size)
		local assembly = Instance.new("Model")
		assembly.Name = p.name
		local pieces = {}
		local function add_piece(name: string, piece_size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?)
			local part = Instance.new("Part")
			part.Name = name
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Size = piece_size
			part.CFrame = cf
			part.Color = color
			part.Material = material or Enum.Material.SmoothPlastic
			part.Parent = assembly
			table.insert(pieces, { part = part, size = piece_size })
			return part
		end
		local body_color = if p.lid == true then Color3.fromRGB(145, 75, 35) else Color3.fromRGB(91, 43, 27)
		local gold = Color3.fromRGB(245, 184, 69)
		local body = add_piece("Body", size, CFrame.new(), body_color)
		assembly.PrimaryPart = body
		local x, y, z = size.X, size.Y, size.Z
		local band = math.clamp(math.min(x, y, z) * 0.055, 0.12, 0.24)
		local front = -z * 0.5 - 0.045
		local back = z * 0.5 + 0.045
		local left = -x * 0.5 - 0.045
		local right = x * 0.5 + 0.045
		for _, side in { -1, 1 } do
			local px = side * (x * 0.5 - band * 0.5)
			add_piece(
				"FrontCorner",
				Vector3.new(band, y * 0.86, band * 0.5),
				CFrame.new(px, 0, front),
				gold,
				Enum.Material.Metal
			)
			local pz = side * (z * 0.5 - band * 0.5)
			add_piece(
				"SideCorner",
				Vector3.new(band * 0.5, y * 0.86, band),
				CFrame.new(left, 0, pz),
				gold,
				Enum.Material.Metal
			)
			add_piece(
				"SideCorner",
				Vector3.new(band * 0.5, y * 0.86, band),
				CFrame.new(right, 0, pz),
				gold,
				Enum.Material.Metal
			)
		end
		for _, yy in { -y * 0.5 + band * 0.5, y * 0.5 - band * 0.5 } do
			add_piece(
				"FrontBand",
				Vector3.new(x * 0.76, band * 0.48, 0.09),
				CFrame.new(0, yy, front),
				gold,
				Enum.Material.Metal
			)
			add_piece(
				"BackBand",
				Vector3.new(x * 0.76, band * 0.48, 0.09),
				CFrame.new(0, yy, back),
				gold,
				Enum.Material.Metal
			)
			add_piece(
				"LeftBand",
				Vector3.new(0.09, band * 0.48, z * 0.76),
				CFrame.new(left, yy, 0),
				gold,
				Enum.Material.Metal
			)
			add_piece(
				"RightBand",
				Vector3.new(0.09, band * 0.48, z * 0.76),
				CFrame.new(right, yy, 0),
				gold,
				Enum.Material.Metal
			)
		end
		if p.lid ~= true then
			add_piece(
				"Crest",
				Vector3.new(0.78, 0.78, 0.12),
				CFrame.new(0, 0.12, front - 0.04) * CFrame.Angles(0, 0, math.rad(45)),
				gold,
				Enum.Material.Metal
			)
			add_piece(
				"CrestInset",
				Vector3.new(0.28, 0.28, 0.14),
				CFrame.new(0, 0.12, front - 0.12),
				Color3.fromRGB(37, 51, 80)
			)
		else
			for _, xx in { -x * 0.22, 0, x * 0.22 } do
				add_piece(
					"LidInlay",
					Vector3.new(band * 0.6, 0.06, z * 0.58),
					CFrame.new(xx, y * 0.5 + 0.035, 0),
					gold,
					Enum.Material.Metal
				)
			end
		end
		assembly.WorldPivot = CFrame.new()
		assembly.Parent = vpf
		table.insert(chest.parts, {
			model = assembly,
			pieces = pieces,
			cf = CFrame.new(table.unpack(p.cf)),
			lid = p.lid == true,
		})
	end
	return chest
end

function ChestView.root_cf(P: any): CFrame
	return CFrame.new(0, P.y, 0) * CFrame.Angles(0, ChestView.BASE_YAW + P.yaw, 0) * CFrame.Angles(P.pitch, 0, P.roll)
end

--- Place the chest's parts from pose P (squash in the parts' own axes, the lid about its hinge).
function ChestView.pose(chest: any, P: any)
	local sy = (1 - P.sq) * P.s
	local sxz = (1 + P.sq * 0.55) * P.s
	local root = ChestView.root_cf(P)
	local lid = chest.hinge * CFrame.Angles(math.rad(P.lid), 0, 0) * chest.hinge_inv
	for _, rec in chest.parts do
		local rel: CFrame = if rec.lid then lid * rec.cf else rec.cf
		for _, piece in rec.pieces do
			piece.part.Size = piece.size * Vector3.new(sxz, sy, sxz)
		end
		rec.model:PivotTo(root * rel)
	end
end

--- Viewport px (from its centre, y down) of a chest-space point in pose P, for a square viewport of
--- side `side` px.
function ChestView.project(P: any, p: Vector3, side: number): Vector2
	local c = ChestView.CAM_CF:PointToObjectSpace(ChestView.root_cf(P) * p)
	local th = math.tan(math.rad(ChestView.CAM_FOV / 2))
	local depth = math.max(-c.Z, 0.1)
	local half = side * 0.5
	return Vector2.new(c.X / (depth * th) * half, -c.Y / (depth * th) * half)
end

--- The small views' idle at time t (seconds): a bob, a wiggle with a lid crack every `every` seconds
--- (`strength` 0..1 scales it). Returns how open the lid's crack is (0..1), for a light leak.
function ChestView.idle(P: any, t: number, every: number, strength: number?): number
	local k0 = strength or 1
	P.y = math.sin(t * 2.4) * 0.08
	local phase = t % every
	local k = phase / 0.42
	if k < 1 then
		local wig = math.sin(k * math.pi * 3) * (1 - k) * math.rad(6) * k0
		P.roll = wig
		P.yaw = wig * 0.6
		P.lid = math.sin(k * math.pi) * 8 * k0
		return math.sin(k * math.pi)
	end
	P.roll, P.yaw, P.lid = 0, 0, 0
	return 0
end

return ChestView
