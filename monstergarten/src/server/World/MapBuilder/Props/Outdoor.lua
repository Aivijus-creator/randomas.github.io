-- Outdoor props for the yard and the lobby street.
local B = require(script.Parent.Parent.Builder)
local Furniture = require(script.Parent.Furniture)
local P = B.Palette
local M = Enum.Material

local O = {}

local function at(cf: CFrame, x: number, y: number, z: number): CFrame
	return cf * CFrame.new(x, y, z)
end

function O.tree(parent: Instance, cf: CFrame, scale: number?, leafColor: Color3?): Model
	local s = scale or 1
	local m = B.model(parent, "Tree")
	B.root(m, cf * CFrame.new(0, 3 * s, 0))
	B.column(m, 8 * s, 1.6 * s, at(cf, 0, 4 * s, 0).Position, Color3.fromRGB(130, 90, 60), M.Wood)
	local leaf = leafColor or Color3.fromRGB(120, 190, 120)
	B.ball(m, 7 * s, at(cf, 0, 9.5 * s, 0).Position, leaf, M.Grass, { CastShadow = true })
	B.ball(m, 5 * s, at(cf, 2.4 * s, 8.4 * s, 1 * s).Position, leaf:Lerp(P.Mint, 0.3), M.Grass)
	B.ball(m, 5 * s, at(cf, -2.2 * s, 8.8 * s, -1.2 * s).Position, leaf:Lerp(P.Green, 0.3), M.Grass)
	B.ball(m, 4 * s, at(cf, 0.5 * s, 12 * s, -0.5 * s).Position, leaf:Lerp(P.Mint, 0.5), M.Grass)
	return m
end

function O.bush(parent: Instance, cf: CFrame, berries: boolean?): Model
	local m = B.model(parent, if berries then "BerryBush" else "Bush")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	local g = Color3.fromRGB(100, 175, 100)
	B.ball(m, 3.4, at(cf, 0, 1.5, 0).Position, g, M.Grass)
	B.ball(m, 2.6, at(cf, 1.4, 1.2, 0.4).Position, g:Lerp(P.Mint, 0.3), M.Grass)
	B.ball(m, 2.6, at(cf, -1.3, 1.1, -0.3).Position, g:Lerp(P.Mint, 0.15), M.Grass)
	if berries then
		local folder = B.folder(m, "Berries")
		for i = 1, 8 do
			local a = i * math.pi * 2 / 8
			B.ball(folder, 0.5, at(cf, math.cos(a) * 1.6, 1.6 + (i % 3) * 0.4, math.sin(a) * 1.6).Position, P.Blue, M.SmoothPlastic, { CanCollide = false, CastShadow = false })
		end
		B.tag(m, "IngredientSource")
		m:SetAttribute("Ingredient", "Berries")
		m:SetAttribute("Regrow", 20)
		m:SetAttribute("Ready", true)
	end
	return m
end

function O.rockPile(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "RockPile")
	B.root(m, cf * CFrame.new(0, 1, 0))
	local r = Random.new(9)
	for i = 1, 9 do
		local sz = r:NextNumber(0.8, 1.8)
		B.part(m, Vector3.new(sz, sz * 0.8, sz), at(cf, r:NextNumber(-1.6, 1.6), sz * 0.4 + (if i > 6 then 0.8 else 0), r:NextNumber(-1.6, 1.6)) * CFrame.Angles(r:NextNumber(0, 1), r:NextNumber(0, 3), r:NextNumber(0, 1)), P.Stone:Lerp(P.DarkStone, r:NextNumber(0, 0.5)), M.Slate, { CanCollide = i <= 4 })
	end
	B.tag(m, "IngredientSource")
	m:SetAttribute("Ingredient", "Rocks")
	return m
end

function O.sandbox(parent: Instance, cf: CFrame, size: number?): Model
	local s = size or 10
	local m = B.model(parent, "Sandbox")
	B.root(m, cf * CFrame.new(0, 1, 0))
	for _, side in { { 0, s / 2 }, { 0, -s / 2 }, { s / 2, 0 }, { -s / 2, 0 } } do
		local alongX = side[2] ~= 0
		B.part(m, if alongX then Vector3.new(s + 1, 1, 1) else Vector3.new(1, 1, s + 1), at(cf, side[1], 0.5, side[2]), P.Wood, M.WoodPlanks)
	end
	B.part(m, Vector3.new(s, 0.6, s), at(cf, 0, 0.3, 0), P.Sand, M.Sand, { CanCollide = false })
	-- bucket + spade + sand castle
	B.cyl(m, 1, 1, at(cf, 2, 1.1, 2) * CFrame.Angles(0, 0, math.rad(90)), P.Red, M.SmoothPlastic, { CanCollide = false })
	B.deco(m, Vector3.new(0.3, 0.1, 1.6), at(cf, -2, 0.7, 1.5) * CFrame.Angles(0, 0.6, 0), P.Blue)
	B.part(m, Vector3.new(2, 1.2, 2), at(cf, -1, 1.2, -1.5), P.Sand, M.Sand, { CanCollide = false })
	for _, o in { { -1.7, -2.2 }, { -0.3, -2.2 }, { -1.7, -0.8 }, { -0.3, -0.8 } } do
		B.column(m, 1.2, 0.6, at(cf, o[1], 2.2, o[2]).Position, P.Sand, M.Sand, { CanCollide = false })
	end
	return m
end

-- Swing set; the seat model is rotated by the client (tag "Swing").
function O.swing(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Swings")
	B.root(m, cf * CFrame.new(0, 4, 0))
	for _, sx in { -4, 4 } do
		B.part(m, Vector3.new(0.5, 9, 0.5), at(cf, sx, 4.2, -1.4) * CFrame.Angles(math.rad(-12), 0, 0), P.Pink)
		B.part(m, Vector3.new(0.5, 9, 0.5), at(cf, sx, 4.2, 1.4) * CFrame.Angles(math.rad(12), 0, 0), P.Pink)
	end
	B.cyl(m, 9, 0.5, at(cf, 0, 8.6, 0), P.Plum, M.Metal)
	for _, sx in { -2, 2 } do
		local seat = B.model(m, "Seat")
		local pivot = cf * CFrame.new(sx, 8.4, 0)
		local p1 = B.deco(seat, Vector3.new(0.1, 6, 0.1), pivot * CFrame.new(-0.8, -3, 0), P.Metal, M.Metal)
		B.deco(seat, Vector3.new(0.1, 6, 0.1), pivot * CFrame.new(0.8, -3, 0), P.Metal, M.Metal)
		B.part(seat, Vector3.new(2, 0.3, 1), pivot * CFrame.new(0, -6, 0), if sx < 0 then P.Mint else P.Yellow, M.SmoothPlastic, { CanCollide = false })
		seat.PrimaryPart = p1
		seat:SetAttribute("PivotCF", pivot)
		B.tag(seat, "Swing")
		seat:SetAttribute("Phase", sx)
	end
	return m
end

function O.fence(parent: Instance, a: Vector3, b: Vector3, color: Color3?, gap: number?): Model
	local m = B.model(parent, "Fence")
	local c = color or P.White
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local n = math.max(1, math.floor(len / (gap or 2.5)))
	for i = 0, n do
		local p = a + dir * (len * i / n)
		B.part(m, Vector3.new(0.5, 3.2, 0.5), CFrame.lookAt(p + Vector3.new(0, 1.6, 0), p + Vector3.new(0, 1.6, 0) + dir), c, M.WoodPlanks, { CanCollide = false })
		B.wedge(m, Vector3.new(0.5, 0.5, 0.5), CFrame.lookAt(p + Vector3.new(0, 3.45, 0), p + Vector3.new(0, 3.45, 0) + dir), c, M.WoodPlanks, { CanCollide = false })
	end
	for _, y in { 1, 2.4 } do
		B.part(m, Vector3.new(0.3, 0.5, len), CFrame.lookAt((a + b) / 2 + Vector3.new(0, y, 0), b + Vector3.new(0, y, 0)), c, M.WoodPlanks, { CanCollide = false })
	end
	-- One invisible collider for the whole run.
	B.part(m, Vector3.new(0.6, 6, len), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 3, 0), b + Vector3.new(0, 3, 0)), c, M.SmoothPlastic, { Transparency = 1, CastShadow = false })
	return m
end

-- Yard gate: two doors; `Door` parts are moved by GateService/EventService via the Open attribute.
function O.gate(parent: Instance, cf: CFrame, width: number): Model
	local m = B.model(parent, "Gate")
	B.root(m, cf * CFrame.new(0, 3, 0))
	for _, sx in { -1, 1 } do
		B.part(m, Vector3.new(1, 6, 1), at(cf, sx * (width / 2 + 0.5), 3, 0), P.Plum)
		B.ball(m, 1.2, at(cf, sx * (width / 2 + 0.5), 6.4, 0).Position, P.Pumpkin, M.SmoothPlastic)
	end
	local doors = B.folder(m, "Doors")
	for _, sx in { -1, 1 } do
		local hinge = cf * CFrame.new(sx * width / 2, 2, 0)
		local door = B.part(doors, Vector3.new(width / 2, 3.6, 0.4), hinge * CFrame.new(-sx * width / 4, 0, 0), P.White, M.WoodPlanks, { Name = "Door" })
		door:SetAttribute("ClosedCF", door.CFrame)
		door:SetAttribute("OpenCF", hinge * CFrame.Angles(0, sx * math.rad(100), 0) * CFrame.new(-sx * width / 4, 0, 0))
	end
	local outside = B.marker(m, "Outside", cf * CFrame.new(0, 2, -16))
	outside:SetAttribute("Outside", true)
	local sensor = B.marker(m, "Sensor", cf * CFrame.new(0, 3, -1.5), Vector3.new(width, 6, 2))
	sensor:SetAttribute("Sensor", true)
	B.tag(m, "Gate")
	m:SetAttribute("Open", false)
	m:SetAttribute("Width", width)
	return m
end

-- Sunny spot on the ground. The client drifts it with the sun (tag "SunSpot" + Moving attribute).
function O.sunSpot(parent: Instance, pos: Vector3, diameter: number?): Model
	local m = B.model(parent, "SunSpot")
	local d = diameter or 6
	local disc = B.disc(m, d, 0.08, pos + Vector3.new(0, 0.12, 0), Color3.fromRGB(255, 240, 160), M.Neon, { CanCollide = false, Transparency = 0.55, Name = "Glow" })
	disc.CastShadow = false
	m.PrimaryPart = disc
	local slot = B.marker(m, "Slot", CFrame.new(pos + Vector3.new(0, 1.5, 0)))
	slot:SetAttribute("Slot", true)
	B.tag(m, "SunSpot")
	m:SetAttribute("Need", "Sun")
	m:SetAttribute("Rate", 10)
	m:SetAttribute("Radius", d / 2)
	m:SetAttribute("Moving", true)
	m:SetAttribute("Origin", pos)
	m:SetAttribute("Station", true)
	return m
end

-- Greenhouse corner with a grow lamp (an electric SunSpot).
function O.greenhouse(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Greenhouse")
	B.root(m, cf * CFrame.new(0, 3, 0))
	local glass = Color3.fromRGB(200, 240, 220)
	for _, sx in { -5, 5 } do
		B.part(m, Vector3.new(0.3, 7, 10), at(cf, sx, 3.5, 0), glass, M.Glass, { Transparency = 0.6 })
	end
	B.part(m, Vector3.new(10, 7, 0.3), at(cf, 0, 3.5, 5), glass, M.Glass, { Transparency = 0.6 })
	B.wedge(m, Vector3.new(10.4, 2.5, 5.2), at(cf, 0, 8.25, 2.5), glass, M.Glass, { Transparency = 0.5 })
	B.wedge(m, Vector3.new(10.4, 2.5, 5.2), at(cf, 0, 8.25, -2.5) * CFrame.Angles(0, math.rad(180), 0), glass, M.Glass, { Transparency = 0.5 })
	for i = -2, 2 do
		B.part(m, Vector3.new(1.2, 1, 1.2), at(cf, i * 1.8, 0.5, 3.5), P.Pumpkin, M.SmoothPlastic)
		B.ball(m, 1.2, at(cf, i * 1.8, 1.5, 3.5).Position, P.Green, M.Grass, { CanCollide = false })
	end
	local lamp = B.part(m, Vector3.new(4, 0.4, 2), at(cf, 0, 6.5, 0), P.Black, M.Metal, { CanCollide = false })
	local glow = B.deco(m, Vector3.new(3.6, 0.1, 1.6), at(cf, 0, 6.25, 0), Color3.fromRGB(255, 120, 230), M.Neon)
	B.spotLight(lamp, Color3.fromRGB(255, 160, 230), 14, 70, Enum.NormalId.Bottom, 2, "RoomLight")
	glow.Name = "Glow"
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 1.5, 0))
	slot:SetAttribute("Slot", true)
	B.tag(m, "SunSpot")
	m:SetAttribute("Need", "Sun")
	m:SetAttribute("Rate", 10)
	m:SetAttribute("Radius", 4)
	m:SetAttribute("Electric", true)
	m:SetAttribute("Station", true)
	m:SetAttribute("RequiresUnlock", "Room:Greenhouse")
	return m
end

function O.lampPost(parent: Instance, cf: CFrame, tagName: string?): Model
	local m = B.model(parent, "LampPost")
	B.root(m, cf * CFrame.new(0, 4, 0))
	B.column(m, 0.6, 1.6, at(cf, 0, 0.3, 0).Position, P.Plum, M.Metal)
	B.column(m, 9, 0.5, at(cf, 0, 4.8, 0).Position, P.Plum, M.Metal)
	B.cyl(m, 1.6, 0.25, at(cf, 0.7, 9.1, 0), P.Plum, M.Metal, { CanCollide = false })
	local bulb = B.ball(m, 1.3, at(cf, 1.4, 8.6, 0).Position, Color3.fromRGB(255, 190, 110), M.Neon, { CanCollide = false })
	bulb.CastShadow = false
	B.wedge(m, Vector3.new(1.6, 0.8, 0.8), at(cf, 1.4, 9.3, 0.4), P.Plum, M.Metal, { CanCollide = false })
	B.wedge(m, Vector3.new(1.6, 0.8, 0.8), at(cf, 1.4, 9.3, -0.4) * CFrame.Angles(0, math.pi, 0), P.Plum, M.Metal, { CanCollide = false })
	B.pointLight(bulb, Color3.fromRGB(255, 170, 90), 26, 1.4, tagName)
	return m
end

function O.bench(parent: Instance, cf: CFrame, color: Color3?): Model
	local m = B.model(parent, "Bench")
	B.root(m, cf * CFrame.new(0, 1, 0))
	local c = color or P.Wood
	for i = -1, 1 do
		B.part(m, Vector3.new(6, 0.25, 0.6), at(cf, 0, 1.7, i * 0.65), c, M.WoodPlanks)
	end
	for i = 0, 1 do
		B.part(m, Vector3.new(6, 0.6, 0.25), at(cf, 0, 2.4 + i * 0.75, 1.05), c, M.WoodPlanks, { CanCollide = false })
	end
	for _, sx in { -2.6, 2.6 } do
		B.part(m, Vector3.new(0.3, 1.6, 2), at(cf, sx, 0.8, 0), P.Black, M.Metal)
		B.part(m, Vector3.new(0.3, 2, 0.3), at(cf, sx, 2.6, 1.05), P.Black, M.Metal, { CanCollide = false })
	end
	return m
end

function O.pumpkin(parent: Instance, cf: CFrame, size: number?, lit: boolean?): Model
	local s = size or 2
	local m = B.model(parent, "Pumpkin")
	B.root(m, cf * CFrame.new(0, s / 2, 0))
	local body = B.ball(m, s, at(cf, 0, s * 0.45, 0).Position, P.Pumpkin, M.SmoothPlastic, { Size = Vector3.new(s, s, s) })
	for i = 1, 4 do
		local a = i * math.pi / 4
		B.ball(m, s * 0.95, at(cf, math.cos(a) * s * 0.18, s * 0.45, math.sin(a) * s * 0.18).Position, P.Pumpkin:Lerp(Color3.fromRGB(230, 120, 40), 0.3), M.SmoothPlastic, { CanCollide = false })
	end
	B.column(m, s * 0.3, s * 0.15, at(cf, 0, s * 1.0, 0).Position, P.Green, M.Wood, { CanCollide = false })
	if lit then
		local eyeL = B.deco(m, Vector3.new(s * 0.18, s * 0.18, 0.1), at(cf, -s * 0.18, s * 0.55, -s * 0.5) * CFrame.Angles(0, 0, math.rad(45)), P.Yellow, M.Neon)
		B.deco(m, Vector3.new(s * 0.18, s * 0.18, 0.1), at(cf, s * 0.18, s * 0.55, -s * 0.5) * CFrame.Angles(0, 0, math.rad(45)), P.Yellow, M.Neon)
		B.deco(m, Vector3.new(s * 0.5, s * 0.1, 0.1), at(cf, 0, s * 0.3, -s * 0.5), P.Yellow, M.Neon)
		B.pointLight(eyeL, Color3.fromRGB(255, 160, 60), 10, 1)
	end
	m.PrimaryPart = body
	return m
end

function O.mailbox(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Mailbox")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(0.5, 3.5, 0.5), at(cf, 0, 1.75, 0), P.DarkWood, M.Wood)
	B.part(m, Vector3.new(1.8, 1.6, 2.6), at(cf, 0, 4.2, 0), P.Lavender, M.SmoothPlastic)
	B.cyl(m, 2.6, 1.8, at(cf, 0, 5, 0) * CFrame.Angles(0, math.rad(90), 0), P.Lavender, M.SmoothPlastic)
	B.deco(m, Vector3.new(0.15, 1.2, 0.3), at(cf, 1, 5, 0.6), P.Red)
	for _, sx in { -0.4, 0.4 } do
		B.ball(m, 0.6, at(cf, sx, 5.3, -1.35).Position, P.White, M.SmoothPlastic, { CanCollide = false })
		local pupil = B.ball(m, 0.28, at(cf, sx, 5.3, -1.6).Position, P.Black, M.SmoothPlastic, { CanCollide = false })
		B.tag(pupil, "LookingEye")
		pupil:SetAttribute("Center", pupil.Position)
	end
	B.deco(m, Vector3.new(1, 0.1, 0.1), at(cf, 0, 4.4, -1.31), P.Plum)
	return m
end

-- Floating hot-air balloon that drifts around (client tag "Drifter").
function O.balloon(parent: Instance, pos: Vector3): Model
	local m = B.model(parent, "Balloon")
	local env = B.ball(m, 14, pos, P.Pink, M.SmoothPlastic, { CanCollide = false })
	m.PrimaryPart = env
	for i = 0, 5 do
		local a = i * math.pi / 3
		B.deco(m, Vector3.new(1.4, 11, 1.4), CFrame.new(pos + Vector3.new(math.cos(a) * 6.4, 0, math.sin(a) * 6.4)), if i % 2 == 0 then P.Yellow else P.Mint, M.SmoothPlastic)
	end
	B.part(m, Vector3.new(4, 3, 4), CFrame.new(pos - Vector3.new(0, 11, 0)), P.Wood, M.WoodPlanks, { CanCollide = false })
	for _, o in { { 1.8, 1.8 }, { -1.8, 1.8 }, { 1.8, -1.8 }, { -1.8, -1.8 } } do
		B.deco(m, Vector3.new(0.1, 5, 0.1), CFrame.new(pos + Vector3.new(o[1], -7.5, o[2])), P.Black)
	end
	B.tag(m, "Drifter")
	m:SetAttribute("Center", pos)
	return m
end

function O.flowers(parent: Instance, cf: CFrame, count: number?, rng: Random?)
	local r = rng or Random.new(4)
	local m = B.model(parent, "Flowers")
	local colors = { P.Pink, P.Yellow, P.Lavender, P.White, P.Pumpkin }
	for _ = 1, (count or 8) do
		local o = at(cf, r:NextNumber(-2.5, 2.5), 0, r:NextNumber(-2.5, 2.5))
		B.deco(m, Vector3.new(0.12, 1, 0.12), o * CFrame.new(0, 0.5, 0), P.Green)
		B.ball(m, 0.55, (o * CFrame.new(0, 1.05, 0)).Position, colors[r:NextInteger(1, #colors)], M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	end
	return m
end

function O.path(parent: Instance, a: Vector3, b: Vector3, width: number, color: Color3?)
	local len = (b - a).Magnitude
	return B.part(parent, Vector3.new(width, 0.2, len), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)), color or Color3.fromRGB(225, 200, 160), M.Cobblestone, { CanCollide = false })
end

function O.dropoffWindow(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "ParentWindow")
	B.root(m, cf)
	B.part(m, Vector3.new(7, 0.6, 2), cf * CFrame.new(0, -1.8, -0.5), P.Wood, M.Wood)
	B.part(m, Vector3.new(7, 4, 0.2), cf, P.Sky, M.Glass, { Transparency = 0.7, CanCollide = false })
	local bell = B.ball(m, 0.8, (cf * CFrame.new(2.8, -1.1, -0.8)).Position, P.Yellow, M.Metal, { CanCollide = false })
	B.deco(m, Vector3.new(1.4, 0.15, 1.4), cf * CFrame.new(2.8, -1.5, -0.8), P.Plum)
	bell.Name = "Bell"
	local outside = B.marker(m, "ParentSpot", cf * CFrame.new(0, -2, 14))
	outside:SetAttribute("ParentSpot", true)
	local cam = B.marker(m, "CameraPoint", cf * CFrame.new(0, 2, -14))
	cam:SetAttribute("CameraPoint", true)
	B.tag(m, "ParentDropoff")
	return m
end

return O
