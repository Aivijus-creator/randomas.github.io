--[[
	Scenery – dekoracijos iš Parts: medžiai, krūmai, akmenys, gėlės, grybai, šieno kupetos,
	vežimai, fakelai, šulinys, vėjo malūnas, statinės, dėžės, vėliavos, suolai.
	Visos funkcijos: Scenery.X(parent, position, rng, ...) – position ant žemės (Y = žemės aukštis).
	Dekoracijos nedalyvauja Touched / raycast skaičiavimuose (greičiau telefonuose).
]]

local Build = require(script.Parent:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material
local CYL_UP = CFrame.Angles(0, 0, math.rad(90))

local Scenery = {}

local function deco(props)
	props.CanTouch = false
	props.CanQuery = false
	-- Šešėlius meta tik kamienai ir pastatai – smulkmenos be šešėlių (greičiau telefonuose)
	if props.CastShadow == nil and not string.find(props.Name or "", "Trunk") and not string.find(props.Name or "", "Tower") then
		props.CastShadow = false
	end
	return Build.Part(props)
end

local function vary(rng, color, amount)
	local d = (rng:NextNumber() - 0.5) * (amount or 0.15)
	return color:Lerp(d > 0 and C(255, 255, 255) or C(0, 0, 0), math.abs(d))
end

----------------------------------------------------------------------
-- Medžiai
----------------------------------------------------------------------
-- Eglė: kamienas + 4 vis siaurėjantys „aukštai“
function Scenery.Pine(parent, pos, rng, scale)
	scale = scale or (0.8 + rng:NextNumber() * 0.7)
	local model = Build.Model("Pine", parent)
	local yaw = CFrame.Angles(0, rng:NextNumber() * 6.28, 0)
	deco({ Name = "Trunk", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(6, 1.3, 1.3) * scale, CFrame = CF(pos + V(0, 3 * scale, 0)) * CYL_UP, Color = C(85, 58, 35), Material = M.Wood })
	local green = vary(rng, C(45, 95, 55), 0.25)
	local tiers = { { 9, 3.5 }, { 7.2, 6.5 }, { 5.2, 9.3 }, { 3, 11.8 } }
	for i, tier in ipairs(tiers) do
		deco({
			Name = "Needles" .. i, Parent = model, Shape = Enum.PartType.Cylinder,
			Size = V(2.6, tier[1], tier[1]) * scale,
			CFrame = CF(pos + V(0, tier[2] * scale, 0)) * yaw * CYL_UP,
			Color = green:Lerp(C(0, 0, 0), i * 0.04), Material = M.Grass, CanCollide = false,
		})
	end
	deco({ Name = "Top", Parent = model, Size = V(0.8, 2, 0.8) * scale, CFrame = CF(pos + V(0, 13.6 * scale, 0)) * yaw * CFrame.Angles(0, math.rad(45), 0), Color = green, Material = M.Grass, CanCollide = false })
	return model
end

-- Beržas: baltas kamienas su juodais brūkšniais
function Scenery.Birch(parent, pos, rng, scale)
	scale = scale or (0.8 + rng:NextNumber() * 0.6)
	local model = Build.Model("Birch", parent)
	local trunkHeight = 11 * scale
	deco({ Name = "Trunk", Parent = model, Size = V(1, trunkHeight, 1) * V(scale, 1, scale), CFrame = CF(pos + V(0, trunkHeight / 2, 0)), Color = C(235, 232, 225), Material = M.SmoothPlastic })
	for i = 1, 4 do
		deco({ Name = "Mark", Parent = model, Size = V(1.05 * scale, 0.18, 0.5 * scale), CFrame = CF(pos + V(0, i * 2.3 * scale, 0)) * CFrame.Angles(0, i * 1.7, 0) * CF(0, 0, 0.3 * scale), Color = C(40, 40, 40), Material = M.SmoothPlastic, CastShadow = false })
	end
	local leaves = vary(rng, C(120, 170, 70), 0.2)
	deco({ Name = "Leaves", Parent = model, Shape = Enum.PartType.Ball, Size = V(6, 6, 6) * scale, CFrame = CF(pos + V(0, trunkHeight + 1, 0)), Color = leaves, Material = M.Grass, CanCollide = false })
	deco({ Name = "Leaves2", Parent = model, Shape = Enum.PartType.Ball, Size = V(4.4, 4.4, 4.4) * scale, CFrame = CF(pos + V(1.6 * scale, trunkHeight - 1, 0.8 * scale)), Color = leaves:Lerp(C(255, 255, 200), 0.1), Material = M.Grass, CanCollide = false })
	deco({ Name = "Leaves3", Parent = model, Shape = Enum.PartType.Ball, Size = V(4, 4, 4) * scale, CFrame = CF(pos + V(-1.4 * scale, trunkHeight - 0.5, -1 * scale)), Color = leaves, Material = M.Grass, CanCollide = false })
	return model
end

-- Ąžuolas: storas kamienas, plati laja iš kelių kamuolių
function Scenery.Oak(parent, pos, rng, scale)
	scale = scale or (0.9 + rng:NextNumber() * 0.6)
	local model = Build.Model("Oak", parent)
	deco({ Name = "Trunk", Parent = model, Size = V(2, 8, 2) * scale, CFrame = CF(pos + V(0, 4 * scale, 0)) * CFrame.Angles(0, rng:NextNumber() * 3, 0), Color = C(90, 62, 38), Material = M.Wood })
	deco({ Name = "Branch", Parent = model, Size = V(0.8, 4, 0.8) * scale, CFrame = CF(pos + V(1.2 * scale, 7 * scale, 0)) * CFrame.Angles(0, 0, math.rad(-35)), Color = C(90, 62, 38), Material = M.Wood })
	local leaves = vary(rng, C(65, 115, 45), 0.25)
	local blobs = { { 0, 10, 0, 9 }, { 3, 9, 1.5, 6.5 }, { -3, 9.3, -1, 6.5 }, { 0.5, 12.5, -1.5, 6 }, { -1, 8.5, 3, 5.5 } }
	for i, b in ipairs(blobs) do
		deco({ Name = "Leaves" .. i, Parent = model, Shape = Enum.PartType.Ball, Size = V(b[4], b[4], b[4]) * scale, CFrame = CF(pos + V(b[1], b[2], b[3]) * scale), Color = leaves:Lerp(C(0, 0, 0), (i % 3) * 0.05), Material = M.Grass, CanCollide = false })
	end
	-- Kartais su obuoliais
	if rng:NextNumber() < 0.3 then
		for i = 1, 5 do
			local angle = i * 1.25
			deco({ Name = "Apple", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.5, 0.5, 0.5), CFrame = CF(pos + V(math.cos(angle) * 4, 8 + (i % 2), math.sin(angle) * 4) * scale), Color = C(200, 30, 30), Material = M.SmoothPlastic, CanCollide = false, CastShadow = false })
		end
	end
	return model
end

function Scenery.RandomTree(parent, pos, rng, scale)
	local roll = rng:NextNumber()
	if roll < 0.45 then
		return Scenery.Pine(parent, pos, rng, scale)
	elseif roll < 0.7 then
		return Scenery.Birch(parent, pos, rng, scale)
	end
	return Scenery.Oak(parent, pos, rng, scale)
end

-- Lengvas miško medis (3 dalys) – tankiam miškui, kad nelagintų
function Scenery.ForestTree(parent, pos, rng, scale)
	scale = scale or (0.9 + rng:NextNumber() * 0.8)
	local model = Build.Model("ForestTree", parent)
	local roll = rng:NextNumber()
	if roll < 0.55 then
		-- Eglė
		local green = vary(rng, C(42, 92, 52), 0.25)
		deco({ Name = "Trunk", Parent = model, Size = V(1, 4, 1) * scale, CFrame = CF(pos + V(0, 2 * scale, 0)), Color = C(85, 58, 35), Material = M.Wood })
		deco({ Name = "Needles", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(5, 7.5, 7.5) * scale, CFrame = CF(pos + V(0, 5.5 * scale, 0)) * CYL_UP, Color = green, Material = M.Grass, CanCollide = false })
		deco({ Name = "Needles2", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(4.5, 4.4, 4.4) * scale, CFrame = CF(pos + V(0, 9.5 * scale, 0)) * CYL_UP, Color = green:Lerp(C(0, 0, 0), 0.08), Material = M.Grass, CanCollide = false })
	elseif roll < 0.8 then
		-- Beržas
		deco({ Name = "Trunk", Parent = model, Size = V(0.8, 9, 0.8) * scale, CFrame = CF(pos + V(0, 4.5 * scale, 0)), Color = C(235, 232, 225), Material = M.SmoothPlastic })
		deco({ Name = "Leaves", Parent = model, Shape = Enum.PartType.Ball, Size = V(6, 6, 6) * scale, CFrame = CF(pos + V(0, 9.5 * scale, 0)), Color = vary(rng, C(120, 170, 70), 0.2), Material = M.Grass, CanCollide = false })
		deco({ Name = "Mark", Parent = model, Size = V(0.85, 0.2, 0.4) * scale, CFrame = CF(pos + V(0, 3 * scale, 0)), Color = C(40, 40, 40), Material = M.SmoothPlastic })
	else
		-- Ąžuolas
		deco({ Name = "Trunk", Parent = model, Size = V(1.6, 6, 1.6) * scale, CFrame = CF(pos + V(0, 3 * scale, 0)), Color = C(90, 62, 38), Material = M.Wood })
		deco({ Name = "Leaves", Parent = model, Shape = Enum.PartType.Ball, Size = V(8.5, 8.5, 8.5) * scale, CFrame = CF(pos + V(0, 8 * scale, 0)), Color = vary(rng, C(65, 115, 45), 0.25), Material = M.Grass, CanCollide = false })
		deco({ Name = "Leaves2", Parent = model, Shape = Enum.PartType.Ball, Size = V(5.5, 5.5, 5.5) * scale, CFrame = CF(pos + V(2 * scale, 7 * scale, 1 * scale)), Color = vary(rng, C(70, 120, 48), 0.25), Material = M.Grass, CanCollide = false })
	end
	return model
end

-- Kalėdų eglė su žaisliukais ir žvaigžde (Kūčios, gruodis)
function Scenery.ChristmasTree(parent, pos, scale)
	scale = scale or 1
	local model = Build.Model("ChristmasTree", parent)
	deco({ Name = "Trunk", Parent = model, Size = V(1, 2, 1) * scale, CFrame = CF(pos + V(0, 1 * scale, 0)), Color = C(90, 60, 35), Material = M.Wood })
	local tiers = { { 8, 3 }, { 6.2, 5.6 }, { 4.4, 8 }, { 2.6, 10.2 } }
	for i, tier in ipairs(tiers) do
		deco({ Name = "Needles" .. i, Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2.6, tier[1], tier[1]) * scale, CFrame = CF(pos + V(0, tier[2] * scale, 0)) * CYL_UP, Color = C(35, 105, 55), Material = M.Grass })
	end
	local colors = { C(220, 40, 40), C(250, 210, 50), C(60, 120, 230), C(240, 240, 255) }
	for i = 1, 16 do
		local tier = tiers[(i % 3) + 1]
		local angle = i * 2.4
		local r = tier[1] / 2 * scale
		deco({ Name = "Ornament", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.5, 0.5, 0.5) * scale, CFrame = CF(pos + V(math.cos(angle) * r, (tier[2] - 0.6) * scale, math.sin(angle) * r)), Color = colors[(i % 4) + 1], Material = M.Neon, CanCollide = false })
	end
	local star = deco({ Name = "Star", Parent = model, Size = V(1.2, 1.2, 0.3) * scale, CFrame = CF(pos + V(0, 12 * scale, 0)) * CFrame.Angles(0, 0, math.rad(45)), Color = C(255, 215, 60), Material = M.Neon, CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color = C(255, 220, 120)
	light.Range = 16
	light.Parent = star
	return model
end

----------------------------------------------------------------------
-- Augalai ir akmenys
----------------------------------------------------------------------
function Scenery.Bush(parent, pos, rng, scale)
	scale = scale or (0.7 + rng:NextNumber() * 0.7)
	local model = Build.Model("Bush", parent)
	local green = vary(rng, C(70, 125, 50), 0.25)
	local count = 2 + rng:NextInteger(0, 2)
	for i = 1, count do
		local size = (2.2 + rng:NextNumber() * 1.6) * scale
		deco({ Name = "Leaves", Parent = model, Shape = Enum.PartType.Ball, Size = V(size, size, size), CFrame = CF(pos + V((rng:NextNumber() - 0.5) * 2.4 * scale, size * 0.35, (rng:NextNumber() - 0.5) * 2.4 * scale)), Color = green:Lerp(C(0, 0, 0), i * 0.04), Material = M.Grass, CanCollide = false, CastShadow = false })
	end
	-- Uogos
	if rng:NextNumber() < 0.35 then
		local berry = rng:NextNumber() < 0.5 and C(200, 30, 50) or C(60, 60, 160)
		for i = 1, 4 do
			deco({ Name = "Berry", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.35, 0.35, 0.35), CFrame = CF(pos + V(math.cos(i * 1.6) * 1.2 * scale, 1.4 * scale, math.sin(i * 1.6) * 1.2 * scale)), Color = berry, Material = M.SmoothPlastic, CanCollide = false, CastShadow = false })
		end
	end
	return model
end

function Scenery.Rock(parent, pos, rng, scale)
	scale = scale or (0.6 + rng:NextNumber() * 1.4)
	local model = Build.Model("Rock", parent)
	local gray = vary(rng, C(125, 122, 115), 0.2)
	deco({ Name = "Rock", Parent = model, Size = V(3, 2, 2.6) * scale, CFrame = CF(pos + V(0, 0.6 * scale, 0)) * CFrame.Angles(rng:NextNumber() * 0.5, rng:NextNumber() * 6, rng:NextNumber() * 0.5), Color = gray, Material = M.Slate })
	if rng:NextNumber() < 0.6 then
		deco({ Name = "Rock2", Parent = model, Size = V(1.6, 1.2, 1.5) * scale, CFrame = CF(pos + V(1.8 * scale, 0.4 * scale, 0.6 * scale)) * CFrame.Angles(0.3, rng:NextNumber() * 6, 0.2), Color = gray:Lerp(C(0, 0, 0), 0.1), Material = M.Slate, CastShadow = false })
	end
	if rng:NextNumber() < 0.4 then
		deco({ Name = "Moss", Parent = model, Size = V(2.2, 0.3, 1.8) * scale, CFrame = CF(pos + V(0, 1.55 * scale, 0)), Color = C(80, 130, 60), Material = M.Grass, CanCollide = false, CastShadow = false })
	end
	return model
end

local FLOWER_COLORS = { C(240, 60, 60), C(250, 220, 60), C(250, 250, 250), C(170, 90, 220), C(80, 140, 240), C(255, 140, 190) }

function Scenery.Flowers(parent, pos, rng, count)
	count = count or (4 + rng:NextInteger(0, 4))
	local model = Build.Model("Flowers", parent)
	local color = FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)]
	for _ = 1, count do
		local p = pos + V((rng:NextNumber() - 0.5) * 4, 0, (rng:NextNumber() - 0.5) * 4)
		local height = 0.8 + rng:NextNumber() * 0.6
		deco({ Name = "Stem", Parent = model, Size = V(0.12, height, 0.12), CFrame = CF(p + V(0, height / 2, 0)), Color = C(70, 140, 55), Material = M.Grass, CanCollide = false, CastShadow = false })
		deco({ Name = "Petals", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.45, 0.45, 0.45), CFrame = CF(p + V(0, height + 0.1, 0)), Color = color, Material = M.SmoothPlastic, CanCollide = false, CastShadow = false })
	end
	return model
end

function Scenery.Mushroom(parent, pos, rng)
	local model = Build.Model("Mushroom", parent)
	local red = rng:NextNumber() < 0.6
	deco({ Name = "Stem", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.8, 0.4, 0.4), CFrame = CF(pos + V(0, 0.4, 0)) * CYL_UP, Color = C(240, 235, 220), Material = M.SmoothPlastic, CanCollide = false, CastShadow = false })
	local cap = deco({ Name = "Cap", Parent = model, Size = V(1, 0.5, 1), CFrame = CF(pos + V(0, 0.85, 0)), Color = red and C(200, 40, 35) or C(150, 100, 60), Material = M.SmoothPlastic, CanCollide = false, CastShadow = false })
	Build.Mesh(cap, Enum.MeshType.Sphere)
	if red then
		for i = 1, 3 do
			deco({ Name = "Dot", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.15, 0.15, 0.15), CFrame = CF(pos + V(math.cos(i * 2.1) * 0.3, 1.05, math.sin(i * 2.1) * 0.3)), Color = C(255, 255, 255), Material = M.SmoothPlastic, CanCollide = false, CastShadow = false })
		end
	end
	return model
end

function Scenery.Reeds(parent, pos, rng)
	local model = Build.Model("Reeds", parent)
	for _ = 1, 5 do
		local p = pos + V((rng:NextNumber() - 0.5) * 2, 0, (rng:NextNumber() - 0.5) * 2)
		local h = 2 + rng:NextNumber() * 1.5
		deco({ Name = "Reed", Parent = model, Size = V(0.12, h, 0.12), CFrame = CF(p + V(0, h / 2, 0)) * CFrame.Angles(rng:NextNumber() * 0.2, 0, rng:NextNumber() * 0.2), Color = C(110, 140, 60), Material = M.Grass, CanCollide = false, CastShadow = false })
		deco({ Name = "Cattail", Parent = model, Size = V(0.25, 0.6, 0.25), CFrame = CF(p + V(0, h, 0)), Color = C(110, 70, 40), Material = M.Fabric, CanCollide = false, CastShadow = false })
	end
	return model
end

----------------------------------------------------------------------
-- Kaimo daiktai
----------------------------------------------------------------------
function Scenery.Haystack(parent, pos, rng)
	local model = Build.Model("Haystack", parent)
	local hay = C(220, 185, 95)
	local base = deco({ Name = "Hay", Parent = model, Size = V(5, 4, 5), CFrame = CF(pos + V(0, 2, 0)), Color = hay, Material = M.Grass })
	Build.Mesh(base, Enum.MeshType.Sphere)
	local top = deco({ Name = "HayTop", Parent = model, Size = V(3.4, 3, 3.4), CFrame = CF(pos + V(0, 4.2, 0)), Color = hay:Lerp(C(255, 255, 255), 0.08), Material = M.Grass })
	Build.Mesh(top, Enum.MeshType.Sphere)
	deco({ Name = "Pole", Parent = model, Size = V(0.25, 3, 0.25), CFrame = CF(pos + V(0, 6, 0)), Color = C(110, 75, 45), Material = M.Wood })
	return model
end

function Scenery.Barrel(parent, pos, rng)
	local model = Build.Model("Barrel", parent)
	deco({ Name = "Body", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2.6, 2, 2), CFrame = CF(pos + V(0, 1.3, 0)) * CYL_UP, Color = C(130, 85, 45), Material = M.WoodPlanks })
	for _, y in ipairs({ 0.4, 2.2 }) do
		deco({ Name = "Hoop", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.2, 2.08, 2.08), CFrame = CF(pos + V(0, y, 0)) * CYL_UP, Color = C(70, 70, 75), Material = M.Metal, CastShadow = false })
	end
	return model
end

function Scenery.Crate(parent, pos, rng, size)
	size = size or 2.2
	local model = Build.Model("Crate", parent)
	deco({ Name = "Crate", Parent = model, Size = V(size, size, size), CFrame = CF(pos + V(0, size / 2, 0)) * CFrame.Angles(0, rng:NextNumber() * 1.5, 0), Color = C(160, 115, 65), Material = M.WoodPlanks })
	return model
end

function Scenery.Torch(parent, pos, height)
	height = height or 7
	local model = Build.Model("Torch", parent)
	deco({ Name = "Pole", Parent = model, Size = V(0.5, height, 0.5), CFrame = CF(pos + V(0, height / 2, 0)), Color = C(80, 55, 32), Material = M.Wood })
	deco({ Name = "Bowl", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.6, 1.3, 1.3), CFrame = CF(pos + V(0, height + 0.2, 0)) * CYL_UP, Color = C(60, 60, 65), Material = M.Metal })
	local flame = deco({ Name = "Flame", Parent = model, Size = V(0.5, 0.5, 0.5), CFrame = CF(pos + V(0, height + 0.8, 0)), Transparency = 1, CanCollide = false })
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 5
	fire.Parent = flame
	local light = Instance.new("PointLight")
	light.Color = C(255, 160, 70)
	light.Range = 16
	light.Brightness = 1.6
	light.Shadows = false
	light.Parent = flame
	return model
end

function Scenery.Banner(parent, pos, height)
	height = height or 10
	local model = Build.Model("Banner", parent)
	deco({ Name = "Pole", Parent = model, Size = V(0.4, height, 0.4), CFrame = CF(pos + V(0, height / 2, 0)), Color = C(90, 70, 50), Material = M.Wood })
	deco({ Name = "Finial", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.7, 0.7, 0.7), CFrame = CF(pos + V(0, height + 0.3, 0)), Color = C(230, 190, 60), Material = M.Metal })
	local stripes = { C(253, 185, 19), C(0, 106, 68), C(193, 39, 45) }
	for i, color in ipairs(stripes) do
		deco({ Name = "Stripe" .. i, Parent = model, Size = V(0.1, 1, 3.2), CFrame = CF(pos + V(0, height - 0.6 - (i - 1), 1.8)), Color = color, Material = M.Fabric, CanCollide = false })
	end
	return model
end

function Scenery.Bench(parent, cframe)
	local model = Build.Model("Bench", parent)
	deco({ Name = "Seat", Parent = model, Size = V(5, 0.4, 1.4), CFrame = cframe * CF(0, 1.4, 0), Color = C(140, 95, 55), Material = M.WoodPlanks })
	deco({ Name = "Back", Parent = model, Size = V(5, 1.2, 0.3), CFrame = cframe * CF(0, 2.3, 0.6), Color = C(140, 95, 55), Material = M.WoodPlanks })
	for _, x in ipairs({ -2.1, 2.1 }) do
		deco({ Name = "Leg", Parent = model, Size = V(0.4, 1.4, 1.2), CFrame = cframe * CF(x, 0.7, 0), Color = C(80, 55, 32), Material = M.Wood })
	end
	return model
end

function Scenery.Cart(parent, cframe)
	local model = Build.Model("Cart", parent)
	deco({ Name = "Bed", Parent = model, Size = V(4, 0.5, 6), CFrame = cframe * CF(0, 2, 0), Color = C(130, 88, 48), Material = M.WoodPlanks })
	for _, x in ipairs({ -2, 2 }) do
		deco({ Name = "Side", Parent = model, Size = V(0.3, 1.2, 6), CFrame = cframe * CF(x, 2.8, 0), Color = C(110, 72, 40), Material = M.WoodPlanks })
		deco({ Name = "Wheel", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.4, 3.2, 3.2), CFrame = cframe * CF(x * 1.12, 1.6, 0.8), Color = C(80, 55, 32), Material = M.Wood })
	end
	deco({ Name = "Handle", Parent = model, Size = V(0.3, 0.3, 4), CFrame = cframe * CF(0, 2, -4.5), Color = C(110, 72, 40), Material = M.Wood })
	for i = 1, 6 do
		deco({ Name = "Potato", Parent = model, Size = V(1.1, 0.85, 0.9), CFrame = cframe * CF(-1 + (i % 3), 2.7 + math.floor(i / 4) * 0.5, -1.5 + i * 0.5), Color = C(170, 122, 72), Material = M.Sand, CastShadow = false })
	end
	for _, part in ipairs(model:GetChildren()) do
		if part.Name == "Potato" then
			Build.Mesh(part, Enum.MeshType.Sphere)
		end
	end
	return model
end

function Scenery.Well(parent, pos)
	local model = Build.Model("Well", parent)
	deco({ Name = "Wall", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(3, 5, 5), CFrame = CF(pos + V(0, 1.5, 0)) * CYL_UP, Color = C(130, 128, 120), Material = M.Cobblestone })
	deco({ Name = "Water", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.2, 4, 4), CFrame = CF(pos + V(0, 2.6, 0)) * CYL_UP, Color = C(60, 110, 160), Material = M.Glass, Transparency = 0.2, CanCollide = false })
	for _, x in ipairs({ -2.2, 2.2 }) do
		deco({ Name = "Post", Parent = model, Size = V(0.4, 5, 0.4), CFrame = CF(pos + V(x, 4.5, 0)), Color = C(90, 62, 38), Material = M.Wood })
	end
	deco({ Name = "Roof1", Parent = model, Size = V(5.6, 0.3, 2.4), CFrame = CF(pos + V(0, 7.4, -0.9)) * CFrame.Angles(math.rad(35), 0, 0), Color = C(150, 50, 40), Material = M.WoodPlanks })
	deco({ Name = "Roof2", Parent = model, Size = V(5.6, 0.3, 2.4), CFrame = CF(pos + V(0, 7.4, 0.9)) * CFrame.Angles(math.rad(-35), 0, 0), Color = C(150, 50, 40), Material = M.WoodPlanks })
	deco({ Name = "Crank", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(4.4, 0.4, 0.4), CFrame = CF(pos + V(0, 5.5, 0)), Color = C(110, 72, 40), Material = M.Wood })
	deco({ Name = "Bucket", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.9, 0.9, 0.9), CFrame = CF(pos + V(0, 4.2, 0)) * CYL_UP, Color = C(120, 80, 45), Material = M.WoodPlanks })
	return model
end

-- Vėjo malūnas: sparnai sukasi (kliente, žymė "Spinner"). facing – kryptis, į kurią atsukti sparnai
function Scenery.Windmill(parent, pos, facing)
	local model = Build.Model("Windmill", parent)
	local look = CFrame.lookAt(pos, pos + V(facing.X, 0, facing.Z))
	local tiers = { { 9, 5 }, { 7.6, 13 }, { 6.2, 20 } }
	for i, tier in ipairs(tiers) do
		deco({ Name = "Tower" .. i, Parent = model, Size = V(tier[1], 8, tier[1]), CFrame = look * CF(0, tier[2] - 1, 0), Color = C(235, 228, 210), Material = M.Plaster })
	end
	deco({ Name = "Door", Parent = model, Size = V(2.6, 4, 0.3), CFrame = look * CF(0, 2, -4.6), Color = C(100, 62, 32), Material = M.Wood })
	deco({ Name = "Roof", Parent = model, Size = V(7, 4, 7), CFrame = look * CF(0, 25.5, 0), Color = C(140, 50, 40), Material = M.WoodPlanks })
	deco({ Name = "RoofTop", Parent = model, Size = V(4, 2.5, 4), CFrame = look * CF(0, 28.5, 0), Color = C(140, 50, 40), Material = M.WoodPlanks })
	local hubPos = (look * CF(0, 22, -4.4)).Position
	local hub = deco({
		Name = "Hub", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(1.6, 2.4, 2.4),
		CFrame = CFrame.lookAt(hubPos, hubPos + look.LookVector) * CFrame.Angles(0, math.rad(90), 0),
		Color = C(90, 62, 38), Material = M.Wood, Tags = { "Spinner" }, Attributes = { SpinSpeed = 0.8 },
	})
	local blades = {
		{ V(0.3, 15, 2.4), CF(0.6, 8, 0) }, { V(0.3, 15, 2.4), CF(0.6, -8, 0) },
		{ V(0.3, 2.4, 15), CF(0.6, 0, 8) }, { V(0.3, 2.4, 15), CF(0.6, 0, -8) },
	}
	for i, blade in ipairs(blades) do
		local part = deco({ Name = "Blade" .. i, Parent = model, Size = blade[1], CFrame = hub.CFrame * blade[2], Color = C(225, 215, 190), Material = M.Fabric, Anchored = false, CanCollide = false, Massless = true })
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hub
		weld.Part1 = part
		weld.Parent = part
	end
	return model
end

return Scenery
