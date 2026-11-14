-- Indoor furniture props. Every function: (parent, cf, opts?) -> Model.
-- `cf` is at floor level, model "front" faces cf.LookVector.
local B = require(script.Parent.Parent.Builder)
local P = B.Palette
local M = Enum.Material

local F = {}

local function at(cf: CFrame, x: number, y: number, z: number): CFrame
	return cf * CFrame.new(x, y, z)
end

-- Mark a model as damageable furniture.
function F.furniture(model: Model, flammable: boolean?, maxHP: number?)
	B.tag(model, "Furniture")
	model:SetAttribute("MaxHP", maxHP or 100)
	model:SetAttribute("HP", maxHP or 100)
	if flammable then
		B.tag(model, "Flammable")
	end
	return model
end

function F.crib(parent: Instance, cf: CFrame, blanket: Color3?): Model
	local m = B.model(parent, "Crib")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	local wood = P.Wood
	B.part(m, Vector3.new(4.4, 0.6, 6.4), at(cf, 0, 1.4, 0), wood, M.Wood)
	B.part(m, Vector3.new(4, 0.6, 6), at(cf, 0, 1.95, 0), P.White, M.Fabric)
	B.part(m, Vector3.new(4.05, 0.25, 3.6), at(cf, 0, 2.3, 1.1), blanket or P.Lavender, M.Fabric)
	B.part(m, Vector3.new(2.2, 0.5, 1.2), at(cf, 0, 2.4, -2.2), P.Cream, M.Fabric)
	for _, sx in { -2.1, 2.1 } do
		for _, sz in { -3.1, 3.1 } do
			B.column(m, 4, 0.45, at(cf, sx, 2, sz).Position, wood, M.Wood)
			B.ball(m, 0.6, at(cf, sx, 4.1, sz).Position, P.Pink, M.SmoothPlastic, { CastShadow = false })
		end
	end
	for _, sx in { -2.1, 2.1 } do
		B.cyl(m, 6.2, 0.3, at(cf, sx, 3.6, 0) * CFrame.Angles(0, math.rad(90), 0), wood, M.Wood)
		for i = -2, 2 do
			B.deco(m, Vector3.new(0.15, 1.6, 0.15), at(cf, sx, 2.8, i * 1.2), wood, M.Wood)
		end
	end
	B.cyl(m, 4.2, 0.3, at(cf, 0, 3.6, -3.1), wood, M.Wood)
	B.cyl(m, 4.2, 0.3, at(cf, 0, 3.6, 3.1), wood, M.Wood)
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 3.3, 0))
	slot:SetAttribute("Slot", true)
	F.furniture(m, true)
	return m
end

-- Ceiling mobile (rotates on the client: tag "Spinner").
function F.mobile(parent: Instance, pos: Vector3): Model
	local m = B.model(parent, "Mobile")
	local hub = B.deco(m, Vector3.new(0.3, 0.3, 0.3), CFrame.new(pos), P.Wood, M.Wood)
	m.PrimaryPart = hub
	B.deco(m, Vector3.new(0.1, 2, 0.1), CFrame.new(pos + Vector3.new(0, 1, 0)), P.White)
	B.deco(m, Vector3.new(3, 0.1, 0.1), CFrame.new(pos), P.Wood, M.Wood)
	B.deco(m, Vector3.new(0.1, 0.1, 3), CFrame.new(pos), P.Wood, M.Wood)
	local colors = { P.Pink, P.Mint, P.Yellow, P.Lavender }
	local offsets = { Vector3.new(1.5, -0.8, 0), Vector3.new(-1.5, -0.8, 0), Vector3.new(0, -0.8, 1.5), Vector3.new(0, -0.8, -1.5) }
	for i, o in offsets do
		B.deco(m, Vector3.new(0.05, 0.8, 0.05), CFrame.new(pos + Vector3.new(o.X, -0.4, o.Z)), P.White)
		if i % 2 == 0 then
			B.ball(m, 0.7, pos + o, colors[i], M.SmoothPlastic, { CanCollide = false, CastShadow = false })
		else
			B.deco(m, Vector3.new(0.7, 0.7, 0.2), CFrame.new(pos + o) * CFrame.Angles(0, 0, math.rad(45)), colors[i], M.Neon)
		end
	end
	B.tag(m, "Spinner", "CeilingDecor")
	m:SetAttribute("Speed", 0.6)
	return m
end

function F.table(parent: Instance, cf: CFrame, size: Vector2?, color: Color3?): Model
	local s = size or Vector2.new(6, 4)
	local m = B.model(parent, "Table")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.part(m, Vector3.new(s.X, 0.4, s.Y), at(cf, 0, 2.8, 0), color or P.Wood, M.Wood)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.column(m, 2.6, 0.4, at(cf, sx * (s.X / 2 - 0.4), 1.3, sz * (s.Y / 2 - 0.4)).Position, P.DarkWood, M.Wood)
		end
	end
	F.furniture(m, true)
	return m
end

function F.chair(parent: Instance, cf: CFrame, color: Color3?): Model
	local m = B.model(parent, "Chair")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.part(m, Vector3.new(1.8, 0.3, 1.8), at(cf, 0, 1.6, 0), color or P.Mint, M.SmoothPlastic)
	B.part(m, Vector3.new(1.8, 1.8, 0.3), at(cf, 0, 2.6, 0.8), color or P.Mint, M.SmoothPlastic)
	for _, sx in { -0.7, 0.7 } do
		for _, sz in { -0.7, 0.7 } do
			B.column(m, 1.5, 0.25, at(cf, sx, 0.75, sz).Position, P.Wood, M.Wood, { CanCollide = false })
		end
	end
	return m
end

-- Shelf with random little items; tagged "Shelf" (golem stomps knock items off).
function F.shelf(parent: Instance, cf: CFrame, width: number?, color: Color3?, rng: Random?): Model
	local w = width or 6
	local r = rng or Random.new(7)
	local m = B.model(parent, "Shelf")
	B.root(m, cf * CFrame.new(0, 3, 0))
	local c = color or P.Wood
	B.part(m, Vector3.new(0.3, 7, 1.6), at(cf, -w / 2, 3.5, 0), c, M.Wood)
	B.part(m, Vector3.new(0.3, 7, 1.6), at(cf, w / 2, 3.5, 0), c, M.Wood)
	B.part(m, Vector3.new(w, 7, 0.2), at(cf, 0, 3.5, 0.7), c, M.Wood)
	local itemColors = { P.Pink, P.Mint, P.Lavender, P.Peach, P.Yellow, P.Blue, P.Red }
	for level = 0, 3 do
		local y = 0.3 + level * 2.1
		B.part(m, Vector3.new(w, 0.25, 1.6), at(cf, 0, y, 0), c, M.Wood)
		if level > 0 then
			local x = -w / 2 + 0.6
			while x < w / 2 - 0.6 do
				local kind = r:NextInteger(1, 3)
				local col = itemColors[r:NextInteger(1, #itemColors)]
				if kind == 1 then
					local h = r:NextNumber(0.6, 1.3)
					B.deco(m, Vector3.new(0.6, h, 0.6), at(cf, x, y + h / 2 + 0.12, 0), col)
				elseif kind == 2 then
					B.ball(m, 0.7, at(cf, x, y + 0.47, 0).Position, col, M.SmoothPlastic, { CanCollide = false, CastShadow = false })
				else
					B.column(m, 0.9, 0.7, at(cf, x, y + 0.57, 0).Position, col, M.SmoothPlastic, { CanCollide = false, CastShadow = false })
				end
				x += r:NextNumber(0.8, 1.3)
			end
		end
	end
	B.tag(m, "Shelf")
	F.furniture(m, true)
	return m
end

function F.rug(parent: Instance, cf: CFrame, size: Vector2, color: Color3, pattern: string?)
	local m = B.model(parent, "Rug")
	B.deco(m, Vector3.new(size.X, 0.1, size.Y), at(cf, 0, 0.25, 0), color, M.Fabric)
	if pattern == "puzzle" then
		local colors = { P.Pink, P.Mint, P.Lavender, P.Yellow, P.Peach, P.Blue }
		local n = 0
		for x = -size.X / 2 + 2, size.X / 2 - 2, 4 do
			for z = -size.Y / 2 + 2, size.Y / 2 - 2, 4 do
				n += 1
				B.deco(m, Vector3.new(3.8, 0.12, 3.8), at(cf, x, 0.3, z), colors[(n % #colors) + 1], M.Fabric)
			end
		end
	elseif pattern == "round" then
		B.disc(m, math.min(size.X, size.Y) * 0.7, 0.12, at(cf, 0, 0.32, 0).Position, P.Cream, M.Fabric, { CanCollide = false, CastShadow = false })
	end
	return m
end

function F.couch(parent: Instance, cf: CFrame, color: Color3?): Model
	local c = color or P.Lavender
	local m = B.model(parent, "Couch")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.part(m, Vector3.new(8, 1.6, 3.2), at(cf, 0, 1, 0), c, M.Fabric)
	B.part(m, Vector3.new(8, 2.6, 1), at(cf, 0, 2.4, 1.3), c, M.Fabric)
	for _, sx in { -4, 4 } do
		B.cyl(m, 3.2, 1.6, at(cf, sx, 2, 0) * CFrame.Angles(0, math.rad(90), 0), c, M.Fabric)
	end
	B.part(m, Vector3.new(3.6, 0.5, 2.6), at(cf, -1.9, 2, -0.2), P.Cream, M.Fabric)
	B.part(m, Vector3.new(3.6, 0.5, 2.6), at(cf, 1.9, 2, -0.2), P.Cream, M.Fabric)
	B.part(m, Vector3.new(1.4, 1.4, 0.5), at(cf, 2.6, 2.8, 0.6) * CFrame.Angles(math.rad(-15), 0, math.rad(10)), P.Pink, M.Fabric, { CanCollide = false })
	F.furniture(m, true)
	return m
end

function F.floorLamp(parent: Instance, cf: CFrame, shade: Color3?, tagName: string?): Model
	local m = B.model(parent, "FloorLamp")
	B.root(m, cf * CFrame.new(0, 3, 0))
	B.disc(m, 1.6, 0.3, at(cf, 0, 0.3, 0).Position, P.Plum, M.SmoothPlastic)
	B.column(m, 5, 0.25, at(cf, 0, 2.7, 0).Position, P.Plum, M.Metal, { CanCollide = false })
	local bulb = B.ball(m, 0.9, at(cf, 0, 5.4, 0).Position, P.Yellow, M.Neon, { CanCollide = false, CastShadow = false })
	B.cyl(m, 1.4, 2.2, at(cf, 0, 5.6, 0) * CFrame.Angles(0, 0, math.rad(90)), shade or P.Peach, M.Fabric, { CanCollide = false, Transparency = 0.15 })
	B.pointLight(bulb, Color3.fromRGB(255, 210, 160), 18, 1, tagName or "RoomLight")
	return m
end

-- Ceiling lamp; light tagged RoomLight so a blackout turns it off.
function F.ceilingLamp(parent: Instance, pos: Vector3, color: Color3?, range: number?): Model
	local m = B.model(parent, "CeilingLamp")
	B.deco(m, Vector3.new(0.15, 1.5, 0.15), CFrame.new(pos + Vector3.new(0, 0.75, 0)), P.Black)
	local shade = B.wedge(m, Vector3.new(2.4, 1, 1.2), CFrame.new(pos + Vector3.new(0, 0, 0.6)), color or P.Peach, M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	B.wedge(m, Vector3.new(2.4, 1, 1.2), CFrame.new(pos + Vector3.new(0, 0, -0.6)) * CFrame.Angles(0, math.rad(180), 0), color or P.Peach, M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	local bulb = B.ball(m, 0.8, pos - Vector3.new(0, 0.6, 0), P.Yellow, M.Neon, { CanCollide = false, CastShadow = false })
	B.tag(bulb, "LampBulb")
	B.pointLight(bulb, Color3.fromRGB(255, 220, 180), range or 26, 1.1, "RoomLight")
	m.PrimaryPart = shade
	B.tag(m, "CeilingDecor")
	return m
end

function F.plant(parent: Instance, cf: CFrame, potColor: Color3?, size: number?): Model
	local s = size or 1
	local m = B.model(parent, "Plant")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.cyl(m, 1.6 * s, 1.8 * s, at(cf, 0, 0.8 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), potColor or P.Pumpkin, M.SmoothPlastic)
	B.disc(m, 1.6 * s, 0.1, at(cf, 0, 1.55 * s, 0).Position, P.DarkWood, M.Ground, { CanCollide = false })
	for i = 1, 5 do
		local a = i * math.pi * 2 / 5
		B.ball(m, 1.3 * s, at(cf, math.cos(a) * 0.5 * s, (2.2 + (i % 2) * 0.5) * s, math.sin(a) * 0.5 * s).Position, P.Green, M.Grass, { CanCollide = false, CastShadow = false })
	end
	B.ball(m, 1.4 * s, at(cf, 0, 3.1 * s, 0).Position, Color3.fromRGB(100, 180, 105), M.Grass, { CanCollide = false, CastShadow = false })
	F.furniture(m, true, 60)
	return m
end

function F.coatRack(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "CoatRack")
	B.root(m, cf * CFrame.new(0, 3, 0))
	B.part(m, Vector3.new(6, 0.4, 0.4), at(cf, 0, 5.5, 0), P.DarkWood, M.Wood)
	local colors = { P.Pink, P.Mint, P.Lavender, P.Peach }
	for i = 1, 4 do
		local x = -2.25 + (i - 1) * 1.5
		B.deco(m, Vector3.new(0.15, 0.6, 0.15), at(cf, x, 5.3, -0.2), P.Metal, M.Metal)
		B.deco(m, Vector3.new(1.2, 1.6, 0.4), at(cf, x, 4.3, -0.4), colors[i], M.Fabric)
		B.deco(m, Vector3.new(0.5, 0.5, 0.45), at(cf, x, 5.15, -0.4), colors[i], M.Fabric)
	end
	return m
end

function F.shoeRack(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "ShoeRack")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.part(m, Vector3.new(5, 0.3, 1.5), at(cf, 0, 0.3, 0), P.Wood, M.Wood)
	B.part(m, Vector3.new(5, 0.3, 1.5), at(cf, 0, 1.4, 0), P.Wood, M.Wood)
	B.part(m, Vector3.new(0.3, 1.4, 1.5), at(cf, -2.5, 0.85, 0), P.Wood, M.Wood)
	B.part(m, Vector3.new(0.3, 1.4, 1.5), at(cf, 2.5, 0.85, 0), P.Wood, M.Wood)
	local colors = { P.Red, P.Blue, P.Yellow, P.Pink, P.Mint }
	for i = 1, 5 do
		B.deco(m, Vector3.new(0.6, 0.4, 1), at(cf, -2 + (i - 1) * 1, 1.75, 0), colors[i])
		B.deco(m, Vector3.new(0.6, 0.4, 1), at(cf, -2 + (i - 1) * 1, 0.65, 0), colors[6 - i])
	end
	return m
end

-- Wall clock with hands that the client rotates (tags ClockHandHour / ClockHandMinute).
function F.wallClock(parent: Instance, cf: CFrame, diameter: number?): Model
	local d = diameter or 4
	local m = B.model(parent, "WallClock")
	local face = B.cyl(m, 0.3, d, cf * CFrame.Angles(0, math.rad(90), 0), P.Cream, M.SmoothPlastic, { CanCollide = false })
	m.PrimaryPart = face
	B.cyl(m, 0.2, d + 0.5, cf * CFrame.new(0, 0, 0.1) * CFrame.Angles(0, math.rad(90), 0), P.Plum, M.SmoothPlastic, { CanCollide = false })
	for i = 0, 11 do
		local a = i * math.pi / 6
		B.deco(m, Vector3.new(0.2, 0.5, 0.1), cf * CFrame.new(math.sin(a) * d * 0.4, math.cos(a) * d * 0.4, -0.2) * CFrame.Angles(0, 0, -a), P.Plum)
	end
	local pivot = cf * CFrame.new(0, 0, -0.3)
	local hour = B.deco(m, Vector3.new(0.25, d * 0.25, 0.08), pivot * CFrame.new(0, d * 0.125, 0), P.Black)
	local minute = B.deco(m, Vector3.new(0.15, d * 0.4, 0.08), pivot * CFrame.new(0, d * 0.2, -0.05), P.Red)
	B.tag(hour, "ClockHandHour")
	B.tag(minute, "ClockHandMinute")
	hour:SetAttribute("PivotCF", pivot)
	minute:SetAttribute("PivotCF", pivot * CFrame.new(0, 0, -0.05))
	hour:SetAttribute("Length", d * 0.25)
	minute:SetAttribute("Length", d * 0.4)
	B.ball(m, 0.4, pivot.Position, P.Black, M.SmoothPlastic, { CanCollide = false })
	return m
end

-- Window set into a wall (glass + frame + sill). cf faces into the room.
function F.window(parent: Instance, cf: CFrame, w: number, h: number, curtains: Color3?): Model
	local m = B.model(parent, "Window")
	local glass = B.part(m, Vector3.new(w, h, 0.2), cf, P.Sky, M.Glass, { Transparency = 0.55, CanCollide = true })
	m.PrimaryPart = glass
	B.part(m, Vector3.new(w + 0.6, 0.4, 0.8), cf * CFrame.new(0, h / 2, 0), P.White)
	B.part(m, Vector3.new(w + 1, 0.4, 1.4), cf * CFrame.new(0, -h / 2, -0.4), P.White)
	B.part(m, Vector3.new(0.4, h, 0.8), cf * CFrame.new(-w / 2, 0, 0), P.White)
	B.part(m, Vector3.new(0.4, h, 0.8), cf * CFrame.new(w / 2, 0, 0), P.White)
	B.deco(m, Vector3.new(0.2, h, 0.3), cf, P.White)
	B.deco(m, Vector3.new(w, 0.2, 0.3), cf, P.White)
	if curtains then
		for _, sx in { -1, 1 } do
			B.deco(m, Vector3.new(w * 0.22, h + 0.8, 0.2), cf * CFrame.new(sx * (w / 2 + 0.3), 0, -0.6), curtains, M.Fabric)
		end
	end
	return m
end

function F.drawingWall(parent: Instance, cf: CFrame, w: number, rng: Random?): Model
	local r = rng or Random.new(3)
	local m = B.model(parent, "Drawings")
	local colors = { P.Pink, P.Mint, P.Lavender, P.Yellow, P.Peach, P.Blue }
	local x = -w / 2 + 1.5
	while x < w / 2 - 1.5 do
		local pw, ph = r:NextNumber(1.8, 2.6), r:NextNumber(1.6, 2.4)
		local y = r:NextNumber(-0.6, 0.6)
		local paper = B.deco(m, Vector3.new(pw, ph, 0.05), cf * CFrame.new(x, y, 0) * CFrame.Angles(0, 0, math.rad(r:NextNumber(-8, 8))), P.White)
		-- little scribble: sun / monster / house
		local c = colors[r:NextInteger(1, #colors)]
		B.ball(m, 0.7, (paper.CFrame * CFrame.new(-0.3, 0.2, -0.05)).Position, c, M.SmoothPlastic, { CanCollide = false, CastShadow = false, Size = Vector3.new(0.7, 0.7, 0.05) })
		B.deco(m, Vector3.new(pw * 0.6, 0.15, 0.06), paper.CFrame * CFrame.new(0, -ph * 0.3, -0.03), colors[r:NextInteger(1, #colors)])
		x += pw + r:NextNumber(0.4, 1.0)
	end
	return m
end

-- String of coloured neon bulbs between two points.
function F.garland(parent: Instance, a: Vector3, b: Vector3, count: number?): Model
	local m = B.model(parent, "Garland")
	local n = count or 12
	local colors = { P.Pink, P.Mint, P.Yellow, P.Lavender, P.Pumpkin }
	local mid = (a + b) / 2 - Vector3.new(0, 1.2, 0)
	local prev = a
	for i = 1, n do
		local t = i / (n + 1)
		local p = (1 - t) ^ 2 * a + 2 * (1 - t) * t * mid + t ^ 2 * b
		B.ball(m, 0.45, p, colors[(i % #colors) + 1], M.Neon, { CanCollide = false, CastShadow = false })
		local len = (p - prev).Magnitude
		B.deco(m, Vector3.new(0.06, 0.06, len), CFrame.lookAt((p + prev) / 2, p), P.Black)
		prev = p
	end
	local len = (b - prev).Magnitude
	B.deco(m, Vector3.new(0.06, 0.06, len), CFrame.lookAt((b + prev) / 2, b), P.Black)
	return m
end

function F.toyBlocks(parent: Instance, cf: CFrame, height: number?): Model
	local m = B.model(parent, "BlockTower")
	B.root(m, cf * CFrame.new(0, 1, 0))
	local colors = { P.Red, P.Blue, P.Yellow, P.Mint, P.Pink }
	for i = 1, (height or 5) do
		local c = colors[(i % #colors) + 1]
		B.part(m, Vector3.new(1.4, 1.4, 1.4), at(cf, (i % 2) * 0.2 - 0.1, 0.7 + (i - 1) * 1.4, 0) * CFrame.Angles(0, math.rad(i * 13), 0), c, M.SmoothPlastic, { CanCollide = false })
	end
	B.tag(m, "Shelf") -- falls on golem stomp
	return m
end

function F.toyShelf(parent: Instance, cf: CFrame): Model
	local m = F.shelf(parent, cf, 6, P.Mint, Random.new(11))
	m.Name = "ToyShelf"
	return m
end

function F.ballPit(parent: Instance, cf: CFrame, size: number?): Model
	local s = size or 8
	local m = B.model(parent, "BallPit")
	B.root(m, cf * CFrame.new(0, 1, 0))
	for _, side in { { 0, s / 2 }, { 0, -s / 2 }, { s / 2, 0 }, { -s / 2, 0 } } do
		local alongX = side[2] ~= 0
		local size3 = if alongX then Vector3.new(s + 0.8, 1.8, 0.8) else Vector3.new(0.8, 1.8, s + 0.8)
		B.part(m, size3, at(cf, side[1], 0.9, side[2]), P.Lavender, M.Fabric)
	end
	B.part(m, Vector3.new(s, 0.6, s), at(cf, 0, 0.3, 0), P.Plum, M.Fabric)
	local colors = { P.Red, P.Blue, P.Yellow, P.Mint, P.Pink, P.Pumpkin }
	local r = Random.new(5)
	for _ = 1, 70 do
		B.ball(m, 0.7, at(cf, r:NextNumber(-s / 2 + 0.8, s / 2 - 0.8), r:NextNumber(0.8, 1.5), r:NextNumber(-s / 2 + 0.8, s / 2 - 0.8)).Position, colors[r:NextInteger(1, #colors)], M.SmoothPlastic, { CanCollide = false, CastShadow = false })
	end
	F.furniture(m, false, 120)
	return m
end

function F.slide(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Slide")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(3, 4, 3), at(cf, 0, 2, 3), P.Peach, M.SmoothPlastic)
	B.part(m, Vector3.new(3.4, 0.4, 3.4), at(cf, 0, 4.2, 3), P.Pink, M.SmoothPlastic)
	for i = 0, 3 do
		B.part(m, Vector3.new(2.6, 0.3, 0.7), at(cf, 0, 0.5 + i, 5 + (3 - i) * 0.45), P.Mint, M.SmoothPlastic)
	end
	B.wedge(m, Vector3.new(2.6, 4, 6), at(cf, 0, 2, -2), P.Yellow, M.SmoothPlastic)
	B.part(m, Vector3.new(0.3, 1, 6.2), at(cf, -1.4, 2.7, -2) * CFrame.Angles(math.rad(-33.7), 0, 0), P.Pink, M.SmoothPlastic, { CanCollide = false })
	B.part(m, Vector3.new(0.3, 1, 6.2), at(cf, 1.4, 2.7, -2) * CFrame.Angles(math.rad(-33.7), 0, 0), P.Pink, M.SmoothPlastic, { CanCollide = false })
	F.furniture(m, false, 120)
	return m
end

function F.bathtub(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Bathtub")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.part(m, Vector3.new(5, 0.6, 8), at(cf, 0, 0.5, 0), P.White)
	B.part(m, Vector3.new(0.6, 2.4, 8), at(cf, -2.2, 1.8, 0), P.White)
	B.part(m, Vector3.new(0.6, 2.4, 8), at(cf, 2.2, 1.8, 0), P.White)
	B.part(m, Vector3.new(5, 2.4, 0.6), at(cf, 0, 1.8, -3.7), P.White)
	B.part(m, Vector3.new(5, 2.4, 0.6), at(cf, 0, 1.8, 3.7), P.White)
	for _, sx in { -2, 2 } do
		for _, sz in { -3.4, 3.4 } do
			B.ball(m, 0.7, at(cf, sx, 0.2, sz).Position, P.Metal, M.Metal, { CanCollide = false })
		end
	end
	local water = B.part(m, Vector3.new(3.8, 0.2, 6.8), at(cf, 0, 2.4, 0), Color3.fromRGB(150, 210, 255), M.Glass, { Transparency = 0.4, CanCollide = false, CastShadow = false })
	B.tag(water, "BathWater")
	for i = 1, 6 do
		B.ball(m, 0.9 + (i % 3) * 0.3, at(cf, ((i % 3) - 1) * 1.1, 2.6, -2.5 + i * 0.8).Position, P.White, M.SmoothPlastic, { CanCollide = false, CastShadow = false, Transparency = 0.1 })
	end
	B.column(m, 1.6, 0.3, at(cf, 0, 3.4, 3.7).Position, P.Metal, M.Metal, { CanCollide = false })
	B.cyl(m, 1, 0.3, at(cf, 0, 4.2, 3.3) * CFrame.Angles(0, math.rad(90), 0), P.Metal, M.Metal, { CanCollide = false })
	-- Rubber duck.
	local duckPos = at(cf, 1.2, 2.75, 1.5)
	B.ball(m, 0.7, duckPos.Position, P.Yellow, M.SmoothPlastic, { CanCollide = false })
	B.ball(m, 0.45, (duckPos * CFrame.new(0, 0.4, -0.25)).Position, P.Yellow, M.SmoothPlastic, { CanCollide = false })
	B.deco(m, Vector3.new(0.2, 0.12, 0.3), duckPos * CFrame.new(0, 0.38, -0.55), P.Pumpkin)
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 2.6, 0))
	slot:SetAttribute("Slot", true)
	F.furniture(m, false, 150)
	return m
end

function F.sink(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Sink")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(4, 3, 2.4), at(cf, 0, 1.5, 0), P.Mint)
	B.part(m, Vector3.new(4.2, 0.4, 2.6), at(cf, 0, 3.2, 0), P.White)
	B.disc(m, 1.8, 0.1, at(cf, 0, 3.42, -0.1).Position, P.Metal, M.Metal, { CanCollide = false })
	B.column(m, 1, 0.25, at(cf, 0, 3.9, 0.8).Position, P.Metal, M.Metal, { CanCollide = false })
	return m
end

function F.mirror(parent: Instance, cf: CFrame, w: number?, h: number?): Model
	local m = B.model(parent, "Mirror")
	local glass = B.deco(m, Vector3.new(w or 3, h or 4, 0.1), cf, Color3.fromRGB(210, 230, 240), M.Glass, { Reflectance = 0.5, Transparency = 0 })
	B.deco(m, Vector3.new((w or 3) + 0.4, (h or 4) + 0.4, 0.08), cf * CFrame.new(0, 0, 0.06), P.Pink)
	m.PrimaryPart = glass
	return m
end

function F.towelRack(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Towels")
	B.cyl(m, 4, 0.2, cf, P.Metal, M.Metal, { CanCollide = false })
	local colors = { P.Pink, P.Mint, P.Lavender }
	for i = 1, 3 do
		B.deco(m, Vector3.new(1.1, 2.2, 0.2), cf * CFrame.new(-1.3 + (i - 1) * 1.3, -1.1, -0.15), colors[i], M.Fabric)
	end
	return m
end

function F.toolRack(parent: Instance, cf: CFrame, room: string): Model
	local m = B.model(parent, "ToolRack")
	B.root(m, cf * CFrame.new(0, 3, 0))
	B.part(m, Vector3.new(4, 5, 0.4), at(cf, 0, 3, 0.6), P.DarkWood, M.WoodPlanks)
	B.part(m, Vector3.new(4.4, 0.4, 1), at(cf, 0, 5.7, 0.4), P.Plum)
	B.part(m, Vector3.new(4.4, 0.3, 1.2), at(cf, 0, 0.6, 0.3), P.Plum)
	for i = -1, 1 do
		B.deco(m, Vector3.new(0.2, 0.2, 0.6), at(cf, i * 1.2, 4.6, 0.2), P.Metal, M.Metal)
	end
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 3.2, -0.3))
	slot:SetAttribute("Slot", true)
	B.tag(m, "ToolRack")
	m:SetAttribute("Room", room)
	return m
end

function F.trashBin(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "TrashBin")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.cyl(m, 3.2, 2.6, at(cf, 0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90)), P.Green, M.SmoothPlastic)
	B.cyl(m, 0.4, 2.9, at(cf, 0, 3.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(80, 150, 90), M.SmoothPlastic)
	B.deco(m, Vector3.new(1, 0.3, 0.3), at(cf, 0, 3.6, 0), P.Black)
	B.tag(m, "TrashBin")
	return m
end

-- Shift board in the hall: SurfaceGui list updated by the server (babies + state).
function F.shiftBoard(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "ShiftBoard")
	local board = B.part(m, Vector3.new(8, 5, 0.3), cf, P.Plum, M.SmoothPlastic, { CanCollide = false })
	m.PrimaryPart = board
	B.part(m, Vector3.new(8.5, 5.5, 0.2), cf * CFrame.new(0, 0, 0.15), P.Wood, M.Wood, { CanCollide = false })
	local sg = Instance.new("SurfaceGui")
	sg.Name = "BoardGui"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 50
	sg.LightInfluence = 0
	sg.Parent = board
	local list = Instance.new("TextLabel")
	list.Name = "List"
	list.Size = UDim2.fromScale(1, 1)
	list.BackgroundTransparency = 1
	list.TextColor3 = P.Cream
	list.Font = Enum.Font.FredokaOne
	list.TextScaled = true
	list.Text = "🍼"
	list.RichText = true
	list.Parent = sg
	B.tag(m, "ShiftBoard")
	return m
end

function F.electricPanel(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "ElectricPanel")
	B.root(m, cf * CFrame.new(0, 3.5, 0))
	B.part(m, Vector3.new(4, 5, 1), at(cf, 0, 4, 0.5), Color3.fromRGB(120, 125, 135), M.DiamondPlate)
	B.part(m, Vector3.new(3.4, 4.4, 0.2), at(cf, 0, 4, -0.05), Color3.fromRGB(150, 155, 165), M.Metal)
	for i = -1, 1 do
		B.deco(m, Vector3.new(0.5, 0.8, 0.2), at(cf, i * 0.9, 4.8, -0.2), P.Black)
	end
	B.deco(m, Vector3.new(3, 0.6, 0.1), at(cf, 0, 6, -0.16), P.Yellow, M.SmoothPlastic)
	local lever = B.part(m, Vector3.new(0.4, 2, 0.4), at(cf, 1.8, 3.6, -0.5) * CFrame.Angles(math.rad(-30), 0, 0), P.Red, M.SmoothPlastic, { CanCollide = false, Name = "Lever" })
	B.ball(m, 0.7, (lever.CFrame * CFrame.new(0, 1, 0)).Position, P.Black, M.SmoothPlastic, { CanCollide = false })
	local led = B.ball(m, 0.4, at(cf, -1.2, 2.4, -0.2).Position, P.Green, M.Neon, { CanCollide = false, Name = "Led" })
	led.CastShadow = false
	B.tag(m, "ElectricPanel")
	return m
end

function F.curtainSwitch(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "CurtainSwitch")
	B.root(m, cf * CFrame.new(0, 4, 0))
	B.part(m, Vector3.new(1.2, 1.8, 0.3), at(cf, 0, 4, 0), P.Cream)
	B.deco(m, Vector3.new(0.4, 0.7, 0.3), at(cf, 0, 4, -0.2), P.Plum, M.SmoothPlastic, { Name = "Toggle" })
	B.tag(m, "CurtainSwitch")
	return m
end

-- Curtain panel that can be drawn (client/server tweens size): tag "Curtain".
function F.curtain(parent: Instance, cf: CFrame, w: number, h: number, color: Color3): Part
	local c = B.deco(parent, Vector3.new(w * 0.2, h, 0.3), cf * CFrame.new(-w * 0.4, 0, 0), color, M.Fabric, { Name = "Curtain" })
	c:SetAttribute("OpenCF", c.CFrame)
	c:SetAttribute("OpenSize", c.Size)
	c:SetAttribute("ClosedCF", cf)
	c:SetAttribute("ClosedSize", Vector3.new(w, h, 0.3))
	B.tag(c, "Curtain")
	return c
end

function F.workbench(parent: Instance, cf: CFrame): Model
	local m = F.table(parent, cf, Vector2.new(7, 3.5), P.DarkWood)
	m.Name = "Workbench"
	B.deco(m, Vector3.new(0.4, 0.4, 2), at(cf, -2, 3.2, 0), P.Metal, M.Metal)
	B.deco(m, Vector3.new(1.4, 0.6, 1), at(cf, 1.5, 3.3, 0), P.Red)
	B.part(m, Vector3.new(7, 3, 0.3), at(cf, 0, 4.5, 1.6), Color3.fromRGB(150, 120, 90), M.WoodPlanks, { CanCollide = false })
	for i = -2, 2 do
		B.deco(m, Vector3.new(0.2, 1.2, 0.2), at(cf, i * 1.2, 4.8, 1.4), P.Metal, M.Metal)
	end
	return m
end

function F.pipes(parent: Instance, a: Vector3, b: Vector3, d: number?, color: Color3?)
	local len = (b - a).Magnitude
	local cf = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	return B.cyl(parent, len, d or 0.8, cf, color or Color3.fromRGB(140, 110, 90), M.Metal, { CanCollide = false, CastShadow = false })
end

function F.cobweb(parent: Instance, cornerPos: Vector3, facing: CFrame)
	local m = B.model(parent, "Cobweb")
	for i = 1, 4 do
		B.deco(m, Vector3.new(0.05, 0.05, 2.5 + i * 0.3), facing * CFrame.new(0, -i * 0.3, 0) * CFrame.Angles(0, math.rad(i * 22), 0) + (cornerPos - facing.Position), Color3.fromRGB(230, 230, 240), M.SmoothPlastic, { Transparency = 0.4 })
	end
	return m
end

function F.coffinCrib(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "CoffinCrib")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.part(m, Vector3.new(3.6, 1.4, 6.5), at(cf, 0, 0.7, 0), Color3.fromRGB(90, 50, 70), M.Wood)
	B.part(m, Vector3.new(3, 0.3, 5.9), at(cf, 0, 1.45, 0), Color3.fromRGB(170, 40, 70), M.Fabric)
	B.part(m, Vector3.new(3.8, 0.3, 2), at(cf, 0, 2.2, 3.3) * CFrame.Angles(math.rad(70), 0, 0), Color3.fromRGB(110, 60, 85), M.Wood, { CanCollide = false })
	B.deco(m, Vector3.new(0.3, 1.2, 0.1), at(cf, 0, 1.6, -3.3), P.Yellow, M.Neon)
	B.deco(m, Vector3.new(0.8, 0.3, 0.1), at(cf, 0, 1.8, -3.3), P.Yellow, M.Neon)
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 2.6, 0))
	slot:SetAttribute("Slot", true)
	B.tag(m, "DarkZone")
	m:SetAttribute("Need", "Darkness")
	m:SetAttribute("Rate", 10)
	m:SetAttribute("Radius", 4)
	m:SetAttribute("Active", true)
	m:SetAttribute("Station", true)
	F.furniture(m, true)
	return m
end

function F.chargingStation(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "ChargingStation")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.disc(m, 4, 0.5, at(cf, 0, 0.6, 0).Position, Color3.fromRGB(70, 70, 90), M.Metal)
	local ring = B.disc(m, 3.2, 0.1, at(cf, 0, 0.66, 0).Position, P.Yellow, M.Neon, { CanCollide = false })
	ring.CastShadow = false
	B.part(m, Vector3.new(0.6, 4, 0.6), at(cf, 0, 2, 2.2), Color3.fromRGB(70, 70, 90), M.Metal)
	local bolt = B.deco(m, Vector3.new(1, 1.4, 0.2), at(cf, 0, 3.6, 1.9) * CFrame.Angles(0, 0, math.rad(15)), P.Yellow, M.Neon)
	B.pointLight(bolt, P.Yellow, 10, 0.8, "RoomLight")
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 1.8, 0))
	slot:SetAttribute("Slot", true)
	B.tag(m, "ChargingStation")
	m:SetAttribute("Need", "Charge")
	m:SetAttribute("Rate", 12)
	m:SetAttribute("Radius", 3)
	m:SetAttribute("Electric", true)
	m:SetAttribute("Station", true)
	return m
end

-- Fireplace with a safety grate; fire visuals are made by the client (tag FireplaceFlame).
function F.fireplace(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Fireplace")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(9, 8, 2.5), at(cf, 0, 4, 1.8), Color3.fromRGB(190, 110, 95), M.Brick)
	B.part(m, Vector3.new(10, 0.6, 3.2), at(cf, 0, 7.8, 1.4), P.DarkWood, M.Wood)
	B.part(m, Vector3.new(5, 4, 1.4), at(cf, 0, 2, 1.2), P.Black, M.Slate)
	B.part(m, Vector3.new(7, 0.4, 3), at(cf, 0, 0.2, -0.8), Color3.fromRGB(150, 90, 80), M.Brick)
	for i = -2, 2 do
		B.cyl(m, 3, 0.4, at(cf, i * 0.6, 0.9, 0.9) * CFrame.Angles(0, math.rad(90 + i * 20), 0), Color3.fromRGB(110, 70, 45), M.Wood, { CanCollide = false })
	end
	local flame = B.marker(m, "Flame", cf * CFrame.new(0, 1.4, 0.8), Vector3.new(2, 1, 1))
	B.tag(flame, "FireplaceFlame")
	local light = B.pointLight(flame, Color3.fromRGB(255, 150, 70), 16, 1.6)
	B.tag(light, "FireLight")
	-- grate
	for i = -3, 3 do
		B.deco(m, Vector3.new(0.12, 2.2, 0.12), at(cf, i * 0.85, 1.1, -1.8), P.Black, M.Metal)
	end
	B.cyl(m, 6, 0.15, at(cf, 0, 2.2, -1.8), P.Black, M.Metal, { CanCollide = false })
	B.part(m, Vector3.new(6, 2.2, 0.2), at(cf, 0, 1.1, -1.8), P.Black, M.Metal, { Transparency = 1 })
	-- mantel decorations
	B.ball(m, 0.8, at(cf, -3.5, 8.5, 1.3).Position, P.Pumpkin, M.SmoothPlastic, { CanCollide = false })
	B.column(m, 1, 0.5, at(cf, 3.2, 8.6, 1.3).Position, P.Cream, M.SmoothPlastic, { CanCollide = false })
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 2, -3))
	slot:SetAttribute("Slot", true)
	B.tag(m, "Fireplace")
	m:SetAttribute("Need", "Warmth")
	m:SetAttribute("Rate", 10)
	m:SetAttribute("Radius", 6)
	m:SetAttribute("Station", true)
	return m
end

function F.iceMat(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "IceMat")
	B.root(m, cf * CFrame.new(0, 1, 0))
	local mat = B.part(m, Vector3.new(6, 0.3, 6), at(cf, 0, 0.35, 0), Color3.fromRGB(190, 235, 255), M.Ice, { CanCollide = false })
	mat.Transparency = 0.2
	for i = 1, 5 do
		B.deco(m, Vector3.new(0.6, 0.8 + i % 3 * 0.4, 0.6), at(cf, math.cos(i) * 2.4, 0.8, math.sin(i) * 2.4) * CFrame.Angles(0, i, math.rad(10)), Color3.fromRGB(210, 245, 255), M.Ice, { Transparency = 0.3 })
	end
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 1.6, 0))
	slot:SetAttribute("Slot", true)
	B.tag(m, "ColdSpot")
	m:SetAttribute("Need", "Cold")
	m:SetAttribute("Rate", 10)
	m:SetAttribute("Radius", 4)
	m:SetAttribute("Station", true)
	return m
end

function F.bandageBox(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "BandageBox")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.part(m, Vector3.new(3, 2, 2), at(cf, 0, 3.6, 0), P.White)
	B.deco(m, Vector3.new(0.4, 1.2, 0.1), at(cf, 0, 3.6, -1.02), P.Red, M.Neon)
	B.deco(m, Vector3.new(1.2, 0.4, 0.1), at(cf, 0, 3.6, -1.02), P.Red, M.Neon)
	for i = -1, 1 do
		B.cyl(m, 0.7, 0.8, at(cf, i * 0.9, 4.95, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(245, 240, 225), M.Fabric, { CanCollide = false })
	end
	return m
end

function F.heater(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "Heater")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.part(m, Vector3.new(4, 3, 1), at(cf, 0, 1.6, 0), P.White, M.Metal)
	for i = -1, 1 do
		local bar = B.deco(m, Vector3.new(3.2, 0.25, 0.2), at(cf, 0, 1.6 + i * 0.7, -0.55), P.Pumpkin, M.Neon)
		bar.CastShadow = false
	end
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 1.6, -2.5))
	slot:SetAttribute("Slot", true)
	B.tag(m, "Fireplace")
	m:SetAttribute("Need", "Warmth")
	m:SetAttribute("Rate", 10)
	m:SetAttribute("Radius", 5)
	m:SetAttribute("Electric", true)
	m:SetAttribute("Station", true)
	return m
end

-- Squashy bean bag.
function F.beanBag(parent: Instance, cf: CFrame, color: Color3?): Model
	local m = B.model(parent, "BeanBag")
	B.root(m, cf * CFrame.new(0, 1, 0))
	local c = color or P.Pink
	local body = B.part(m, Vector3.new(3.6, 2.2, 3.6), at(cf, 0, 1.1, 0), c, M.Fabric)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = body
	local top = B.part(m, Vector3.new(2.6, 1.2, 2.2), at(cf, 0, 2.2, 0.5) * CFrame.Angles(math.rad(-20), 0, 0), c:Lerp(P.White, 0.15), M.Fabric, { CanCollide = false })
	local mesh2 = Instance.new("SpecialMesh")
	mesh2.MeshType = Enum.MeshType.Sphere
	mesh2.Parent = top
	F.furniture(m, true, 60)
	return m
end

function F.toyChest(parent: Instance, cf: CFrame, color: Color3?): Model
	local m = B.model(parent, "ToyChest")
	B.root(m, cf * CFrame.new(0, 1, 0))
	local c = color or P.Peach
	B.part(m, Vector3.new(5, 2.4, 2.8), at(cf, 0, 1.2, 0), c, M.WoodPlanks)
	B.part(m, Vector3.new(5.2, 0.4, 3), at(cf, 0, 2.6, 0.3) * CFrame.Angles(math.rad(-25), 0, 0), c:Lerp(P.Plum, 0.2), M.WoodPlanks, { CanCollide = false })
	B.ball(m, 1, at(cf, -1.2, 2.6, 0).Position, P.Red, M.SmoothPlastic, { CanCollide = false })
	B.part(m, Vector3.new(0.9, 0.9, 0.9), at(cf, 0.3, 2.7, -0.2) * CFrame.Angles(0.4, 0.5, 0), P.Blue, M.SmoothPlastic, { CanCollide = false })
	B.cyl(m, 1.4, 0.5, at(cf, 1.4, 2.7, 0) * CFrame.Angles(0, 0, 0.6), P.Yellow, M.SmoothPlastic, { CanCollide = false })
	B.deco(m, Vector3.new(1.4, 0.8, 0.05), at(cf, 0, 1.4, -1.42), P.Yellow, M.SmoothPlastic)
	F.furniture(m, true, 80)
	return m
end

-- Play tent (two cloth slopes + flag).
function F.playTent(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "PlayTent")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.wedge(m, Vector3.new(6, 4.5, 2.6), at(cf, 0, 2.25, -1.3), P.Mint, M.Fabric, { CanCollide = false })
	B.wedge(m, Vector3.new(6, 4.5, 2.6), at(cf, 0, 2.25, 1.3) * CFrame.Angles(0, math.pi, 0), P.Lavender, M.Fabric, { CanCollide = false })
	B.part(m, Vector3.new(0.15, 2.4, 0.15), at(cf, 3, 5.6, 0), P.Wood, M.Wood, { CanCollide = false })
	B.wedge(m, Vector3.new(0.1, 0.8, 1.2), at(cf, 3, 6.4, 0.6) * CFrame.Angles(0, math.rad(90), math.rad(90)), P.Pink, M.Fabric, { CanCollide = false })
	B.deco(m, Vector3.new(5.6, 0.1, 4.8), at(cf, 0, 0.27, 0), P.Cream, M.Fabric)
	F.furniture(m, true, 60)
	return m
end

function F.changingTable(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "ChangingTable")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(6, 3.4, 2.6), at(cf, 0, 1.7, 0), P.White, M.Wood)
	B.part(m, Vector3.new(6, 0.5, 2.6), at(cf, 0, 3.65, 0), P.Mint, M.Fabric)
	for i = -1, 1 do
		B.deco(m, Vector3.new(1.6, 1.2, 0.05), at(cf, i * 1.9, 1.7, -1.32), P.Lavender)
		B.ball(m, 0.25, at(cf, i * 1.9, 1.7, -1.4).Position, P.Plum, M.SmoothPlastic, { CanCollide = false })
	end
	for i = 0, 3 do
		B.cyl(m, 0.9, 0.7, at(cf, -2.2 + i * 0.6, 4.35, 0.6) * CFrame.Angles(0, 0, math.rad(90)), P.White, M.Fabric, { CanCollide = false })
	end
	F.furniture(m, true, 80)
	return m
end

function F.armchair(parent: Instance, cf: CFrame, color: Color3?): Model
	local c = color or P.Peach
	local m = B.model(parent, "Armchair")
	B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.part(m, Vector3.new(3.6, 1.6, 3.2), at(cf, 0, 1, 0), c, M.Fabric)
	B.part(m, Vector3.new(3.6, 2.6, 0.9), at(cf, 0, 2.4, 1.2), c, M.Fabric)
	for _, sx in { -1.9, 1.9 } do
		B.part(m, Vector3.new(0.8, 1.8, 3.2), at(cf, sx, 1.7, 0), c:Lerp(P.Plum, 0.12), M.Fabric)
	end
	B.part(m, Vector3.new(2.8, 0.5, 2.4), at(cf, 0, 2, -0.2), P.Cream, M.Fabric, { CanCollide = false })
	F.furniture(m, true, 70)
	return m
end

-- Row of kid cubbies with name tags and little coats.
function F.cubbies(parent: Instance, cf: CFrame, count: number?): Model
	local n = count or 4
	local m = B.model(parent, "Cubbies")
	B.root(m, cf * CFrame.new(0, 3, 0))
	local w = n * 2.2
	B.part(m, Vector3.new(w + 0.4, 6, 1.8), at(cf, 0, 3, 0.4), P.Wood, M.WoodPlanks)
	local colors = { P.Pink, P.Mint, P.Lavender, P.Peach, P.Yellow, P.Blue }
	for i = 1, n do
		local x = -w / 2 + 1.1 + (i - 1) * 2.2
		B.part(m, Vector3.new(1.9, 2.4, 0.3), at(cf, x, 4, -0.45), P.Cream, M.SmoothPlastic, { CanCollide = false })
		B.deco(m, Vector3.new(1.3, 1.6, 0.3), at(cf, x, 3.9, -0.65), colors[(i - 1) % #colors + 1], M.Fabric)
		B.deco(m, Vector3.new(1.4, 0.45, 0.05), at(cf, x, 5.5, -0.52), P.White, M.SmoothPlastic)
		B.part(m, Vector3.new(1.9, 1.2, 0.3), at(cf, x, 1.2, -0.45), P.Cream, M.SmoothPlastic, { CanCollide = false })
		B.deco(m, Vector3.new(0.8, 0.5, 1), at(cf, x - 0.4, 0.55, -0.4), colors[(i + 2) % #colors + 1], M.SmoothPlastic)
	end
	return m
end

function F.noticeBoard(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "NoticeBoard")
	local b = B.deco(m, Vector3.new(6, 3.6, 0.2), cf, Color3.fromRGB(205, 160, 110), M.Wood)
	m.PrimaryPart = b
	B.deco(m, Vector3.new(6.4, 4, 0.15), cf * CFrame.new(0, 0, 0.1), P.Plum, M.SmoothPlastic)
	local r = Random.new(5)
	for _ = 1, 6 do
		local c = ({ P.White, P.Yellow, P.Pink, P.Mint })[r:NextInteger(1, 4)]
		B.deco(m, Vector3.new(r:NextNumber(1, 1.6), r:NextNumber(1, 1.4), 0.05), cf * CFrame.new(r:NextNumber(-2.2, 2.2), r:NextNumber(-1.1, 1.1), -0.12) * CFrame.Angles(0, 0, math.rad(r:NextNumber(-10, 10))), c, M.SmoothPlastic)
	end
	return m
end

function F.laundryBasket(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "LaundryBasket")
	B.root(m, cf * CFrame.new(0, 1, 0))
	B.cyl(m, 2, 2.2, at(cf, 0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), P.Wood, M.Fabric)
	B.ball(m, 1, at(cf, 0.3, 2.1, 0).Position, P.Pink, M.Fabric, { CanCollide = false })
	B.ball(m, 0.9, at(cf, -0.4, 2.15, 0.3).Position, P.Mint, M.Fabric, { CanCollide = false })
	return m
end

function F.potty(parent: Instance, cf: CFrame, color: Color3?): Model
	local m = B.model(parent, "Potty")
	B.root(m, cf * CFrame.new(0, 0.8, 0))
	B.cyl(m, 1.3, 1.8, at(cf, 0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), color or P.Yellow, M.SmoothPlastic)
	B.cyl(m, 0.25, 1.9, at(cf, 0, 1.4, 0) * CFrame.Angles(0, 0, math.rad(90)), P.White, M.SmoothPlastic, { CanCollide = false })
	B.part(m, Vector3.new(1.6, 1.4, 0.3), at(cf, 0, 1.9, 0.8), color or P.Yellow, M.SmoothPlastic, { CanCollide = false })
	return m
end

function F.cabinet(parent: Instance, cf: CFrame, w: number?, color: Color3?): Model
	local width = w or 4
	local m = B.model(parent, "Cabinet")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(width, 4.4, 2), at(cf, 0, 2.2, 0), color or P.White, M.Wood)
	B.deco(m, Vector3.new(0.08, 4, 0.05), at(cf, 0, 2.2, -1.02), P.Plum)
	for _, sx in { -0.4, 0.4 } do
		B.ball(m, 0.3, at(cf, sx, 2.6, -1.1).Position, P.Yellow, M.Metal, { CanCollide = false })
	end
	B.column(m, 0.9, 0.6, at(cf, -width / 4, 4.85, 0).Position, P.Mint, M.SmoothPlastic, { CanCollide = false })
	B.ball(m, 0.7, at(cf, width / 4, 4.75, 0).Position, P.Pink, M.SmoothPlastic, { CanCollide = false })
	F.furniture(m, true, 80)
	return m
end

function F.highChair(parent: Instance, cf: CFrame, color: Color3?): Model
	local c = color or P.Mint
	local m = B.model(parent, "HighChair")
	B.root(m, cf * CFrame.new(0, 2, 0))
	for _, sx in { -0.7, 0.7 } do
		for _, sz in { -0.7, 0.7 } do
			B.part(m, Vector3.new(0.25, 3.4, 0.25), at(cf, sx, 1.7, sz), P.Wood, M.Wood, { CanCollide = false })
		end
	end
	B.part(m, Vector3.new(1.9, 0.3, 1.9), at(cf, 0, 3.4, 0), c, M.SmoothPlastic)
	B.part(m, Vector3.new(1.9, 1.6, 0.25), at(cf, 0, 4.2, 0.85), c, M.SmoothPlastic, { CanCollide = false })
	B.part(m, Vector3.new(2.2, 0.2, 1), at(cf, 0, 4, -1), P.White, M.SmoothPlastic, { CanCollide = false })
	return m
end

return F
