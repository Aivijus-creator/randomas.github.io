-- Builder: tiny helpers for constructing the map from parts.
local CollectionService = game:GetService("CollectionService")

local B = {}

B.Palette = {
	Mint = Color3.fromHex("A8E6CF"),
	Lavender = Color3.fromHex("C3B1E1"),
	Peach = Color3.fromHex("FFD3B6"),
	Pink = Color3.fromHex("FFAAA5"),
	Cream = Color3.fromHex("FFF5E1"),
	Plum = Color3.fromHex("4B3F72"),
	Pumpkin = Color3.fromHex("FF9A3C"),
	Wood = Color3.fromRGB(196, 150, 105),
	DarkWood = Color3.fromRGB(120, 85, 60),
	White = Color3.fromRGB(250, 250, 250),
	Grass = Color3.fromRGB(130, 190, 110),
	Sand = Color3.fromRGB(240, 220, 170),
	Stone = Color3.fromRGB(150, 150, 160),
	DarkStone = Color3.fromRGB(80, 78, 90),
	Night = Color3.fromRGB(40, 45, 90),
	Sky = Color3.fromRGB(150, 200, 255),
	Metal = Color3.fromRGB(170, 175, 185),
	Black = Color3.fromRGB(30, 30, 35),
	Yellow = Color3.fromRGB(255, 225, 110),
	Red = Color3.fromRGB(235, 90, 90),
	Blue = Color3.fromRGB(110, 160, 235),
	Green = Color3.fromRGB(110, 190, 120),
}
local P = B.Palette

local function apply(inst: Instance, props: { [string]: any }?)
	if props then
		for k, v in props do
			(inst :: any)[k] = v
		end
	end
end

local function base(p: BasePart, parent: Instance?, color: Color3?, material: Enum.Material?)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = color or P.Cream
	p.Material = material or Enum.Material.SmoothPlastic
	p.CastShadow = true
	p.Parent = parent
end

-- Solid block. `props` may override anything (CanCollide, Transparency, Name ...).
function B.part(parent: Instance?, size: Vector3, cf: CFrame, color: Color3?, material: Enum.Material?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Size = size
	p.CFrame = cf
	base(p, nil, color, material)
	apply(p, props)
	p.Parent = parent
	return p
end

-- Small decorative part: no collision, no shadow.
function B.deco(parent: Instance?, size: Vector3, cf: CFrame, color: Color3?, material: Enum.Material?, props: { [string]: any }?): Part
	local p = B.part(nil, size, cf, color, material, props)
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	if props then
		apply(p, props)
	end
	p.Parent = parent
	return p
end

-- Cylinder whose axis points along the CFrame's X axis.
function B.cyl(parent: Instance?, length: number, diameter: number, cf: CFrame, color: Color3?, material: Enum.Material?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(length, diameter, diameter)
	p.CFrame = cf
	base(p, nil, color, material)
	apply(p, props)
	p.Parent = parent
	return p
end

-- Upright cylinder (axis along Y) centred at `pos`.
function B.column(parent: Instance?, height: number, diameter: number, pos: Vector3, color: Color3?, material: Enum.Material?, props: { [string]: any }?): Part
	return B.cyl(parent, height, diameter, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, props)
end

-- Flat disc lying on the ground (axis Y), top at pos.Y.
function B.disc(parent: Instance?, diameter: number, thickness: number, pos: Vector3, color: Color3?, material: Enum.Material?, props: { [string]: any }?): Part
	return B.column(parent, thickness, diameter, pos - Vector3.new(0, thickness / 2, 0), color, material, props)
end

function B.ball(parent: Instance?, diameter: number, pos: Vector3, color: Color3?, material: Enum.Material?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.new(diameter, diameter, diameter)
	p.CFrame = CFrame.new(pos)
	base(p, nil, color, material)
	apply(p, props)
	p.Parent = parent
	return p
end

function B.wedge(parent: Instance?, size: Vector3, cf: CFrame, color: Color3?, material: Enum.Material?, props: { [string]: any }?): WedgePart
	local p = Instance.new("WedgePart")
	p.Size = size
	p.CFrame = cf
	base(p, nil, color, material)
	apply(p, props)
	p.Parent = parent
	return p
end

function B.cornerWedge(parent: Instance?, size: Vector3, cf: CFrame, color: Color3?, material: Enum.Material?): CornerWedgePart
	local p = Instance.new("CornerWedgePart")
	p.Size = size
	p.CFrame = cf
	base(p, parent, color, material)
	return p
end

function B.model(parent: Instance?, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

function B.folder(parent: Instance?, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function B.tag(inst: Instance, ...: string)
	for _, t in { ... } do
		CollectionService:AddTag(inst, t)
	end
	return inst
end

function B.attrs(inst: Instance, attrs: { [string]: any })
	for k, v in attrs do
		inst:SetAttribute(k, v)
	end
	return inst
end

-- Invisible marker part (for spawns, slots, camera points).
function B.marker(parent: Instance?, name: string, cf: CFrame, size: Vector3?): Part
	local p = B.part(nil, size or Vector3.new(1, 1, 1), cf, P.White, Enum.Material.SmoothPlastic, {
		Name = name,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	})
	p.Parent = parent
	return p
end

function B.pointLight(part: BasePart, color: Color3, range: number, brightness: number?, tagName: string?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness or 1
	l.Shadows = false
	l.Parent = part
	if tagName then
		B.tag(l, tagName)
	end
	return l
end

function B.spotLight(part: BasePart, color: Color3, range: number, angle: number, face: Enum.NormalId, brightness: number?, tagName: string?): SpotLight
	local l = Instance.new("SpotLight")
	l.Color = color
	l.Range = range
	l.Angle = angle
	l.Face = face
	l.Brightness = brightness or 1.5
	l.Parent = part
	if tagName then
		B.tag(l, tagName)
	end
	return l
end

-- Text on a part face.
function B.surfaceText(part: BasePart, face: Enum.NormalId, text: string, props: { [string]: any }?): (SurfaceGui, TextLabel)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = part
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextScaled = true
	tl.Font = Enum.Font.FredokaOne
	tl.TextColor3 = P.Cream
	tl.Parent = sg
	apply(tl, props)
	return sg, tl
end

-- Axis-aligned wall between two XZ points (must share X or Z). Openings are {at = distance from start, width, height}.
function B.wall(parent: Instance, a: Vector2, b: Vector2, y0: number, height: number, thickness: number, color: Color3, material: Enum.Material?, openings: { { at: number, width: number, height: number?, bottom: number? } }?): { Part }
	local parts = {}
	local alongX = math.abs(a.Y - b.Y) < 0.01
	local len = if alongX then math.abs(b.X - a.X) else math.abs(b.Y - a.Y)
	local dirSign = if alongX then (if b.X >= a.X then 1 else -1) else (if b.Y >= a.Y then 1 else -1)
	local ops = table.clone(openings or {})
	table.sort(ops, function(o1, o2)
		return o1.at < o2.at
	end)
	local function seg(from: number, to: number, yBottom: number, yTop: number)
		if to - from < 0.05 or yTop - yBottom < 0.05 then
			return
		end
		local mid = (from + to) / 2
		local h = yTop - yBottom
		local pos: Vector3
		local size: Vector3
		if alongX then
			pos = Vector3.new(a.X + dirSign * mid, yBottom + h / 2, a.Y)
			size = Vector3.new(to - from, h, thickness)
		else
			pos = Vector3.new(a.X, yBottom + h / 2, a.Y + dirSign * mid)
			size = Vector3.new(thickness, h, to - from)
		end
		table.insert(parts, B.part(parent, size, CFrame.new(pos), color, material or Enum.Material.SmoothPlastic))
	end
	local cursor = 0
	for _, o in ops do
		local s = o.at - o.width / 2
		local e = o.at + o.width / 2
		seg(cursor, s, y0, y0 + height)
		local ob = o.bottom or 0
		local oh = o.height or 8
		seg(s, e, y0, y0 + ob) -- sill below a window
		seg(s, e, y0 + oh, y0 + height) -- lintel above the opening
		cursor = e
	end
	seg(cursor, len, y0, y0 + height)
	return parts
end

-- Floor slab whose top surface is at `top`.
function B.floor(parent: Instance, x0: number, z0: number, x1: number, z1: number, top: number, color: Color3, material: Enum.Material?, thickness: number?): Part
	local t = thickness or 1
	return B.part(parent, Vector3.new(math.abs(x1 - x0), t, math.abs(z1 - z0)), CFrame.new((x0 + x1) / 2, top - t / 2, (z0 + z1) / 2), color, material or Enum.Material.SmoothPlastic)
end

-- Invisible volume for room detection.
function B.roomVolume(parent: Instance, name: string, x0: number, z0: number, x1: number, z1: number, y0: number, height: number): Part
	local v = B.part(parent, Vector3.new(math.abs(x1 - x0), height, math.abs(z1 - z0)), CFrame.new((x0 + x1) / 2, y0 + height / 2, (z0 + z1) / 2), P.White, Enum.Material.SmoothPlastic, {
		Name = "Room_" .. name,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	})
	B.tag(v, "RoomVolume")
	v:SetAttribute("RoomName", name)
	return v
end

-- Particle emitter helper (map ambience only; gameplay effects are made on the client).
function B.particles(part: BasePart, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	apply(e, props)
	e.Parent = part
	return e
end

-- Sets PrimaryPart of a model to a hidden root at `cf` (creates it).
function B.root(model: Model, cf: CFrame, size: Vector3?): Part
	local r = B.marker(model, "Root", cf, size)
	model.PrimaryPart = r
	return r
end

return B
