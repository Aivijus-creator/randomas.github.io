--[[
	FoodLooks – kaip atrodo produktas po kiekvieno apdorojimo (upgrader'io) konvejeryje.
	ProductLines upgrader'iuose nurodomas ItemLook = "<pavadinimas>" – tada produktas
	visiškai perpiešiamas: šaknis (fizikos dalis) tampa nematoma pagrindo plokštele,
	o viskas, kas matosi, – privirintos smulkios dalys ("Detail").

	FoodLooks.Apply(root, lookName) – grąžina true, jei toks vaizdas yra.
]]

local Build = require(script.Parent:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local SPHERE = "sphere"
local CYL = "cyl"          -- stačias cilindras (Part.Shape = Cylinder, pasuktas aukštyn)
local BALL = "ball"
local CYL_UP = CFrame.Angles(0, 0, math.rad(90))

local FoodLooks = {}

-- Privirinta dekoratyvi dalis (be fizikos). offset – nuo šaknies apačios centro.
local function d(root, size, offset, color, material, kind, rot)
	local part = Instance.new("Part")
	part.Name = "Detail"
	part.Color = color
	part.Material = material or M.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	local cf = root.CFrame * CF(0, -root.Size.Y / 2, 0) * offset
	if kind == CYL then
		part.Shape = Enum.PartType.Cylinder
		part.Size = V(size.Y, size.X, size.Z)
		cf = cf * CYL_UP
	elseif kind == BALL then
		part.Shape = Enum.PartType.Ball
		part.Size = size
	else
		part.Size = size
	end
	if rot then
		cf = cf * rot
	end
	part.CFrame = cf
	if kind == SPHERE then
		Build.Mesh(part, Enum.MeshType.Sphere)
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = root
	return part
end

-- Šaknis – nematomas pagrindas nurodyto dydžio
local function base(root, size, color)
	root.Transparency = 1
	root.Size = size
	root.Color = color
	local mesh = root:FindFirstChildOfClass("SpecialMesh")
	if mesh then
		mesh:Destroy()
	end
end

----------------------------------------------------------------------
-- Bendros dalys
----------------------------------------------------------------------
local WHITE_PLATE = C(248, 248, 244)

local function plate(root, diameter, color)
	d(root, V(diameter, 0.14, diameter), CF(0, 0.07, 0), color or WHITE_PLATE, M.SmoothPlastic, CYL)
end

-- Gilus baltas dubenėlis su sriubos paviršiumi
local function bowl(root, soupColor, rimColor)
	rimColor = rimColor or C(250, 250, 248)
	d(root, V(1.4, 0.42, 1.4), CF(0, 0.21, 0), rimColor, M.SmoothPlastic, CYL)
	d(root, V(1.85, 0.35, 1.85), CF(0, 0.6, 0), rimColor, M.SmoothPlastic, CYL)
	d(root, V(1.95, 0.08, 1.95), CF(0, 0.76, 0), C(70, 120, 190), M.SmoothPlastic, CYL)        -- mėlynas kraštas
	d(root, V(1.7, 0.06, 1.7), CF(0, 0.81, 0), soupColor, M.SmoothPlastic, CYL)              -- sriubos paviršius (virš krašto)
end

local function cepelinas(root, color, material, y, length)
	length = length or 1.9
	d(root, V(length, 0.95, 1.05), CF(0, y or 0.5, 0), color, material or M.SmoothPlastic, SPHERE)
end

local function sourCream(root, x, y, z)
	d(root, V(0.75, 0.3, 0.6), CF(x, y, z), C(252, 252, 246), M.SmoothPlastic, SPHERE)
end

local function spirgai(root, y)
	for i, off in ipairs({ { -0.35, 0.1 }, { 0.3, -0.12 }, { 0.05, 0.2 } }) do
		d(root, V(0.16, 0.12, 0.16), CF(off[1], y + (i % 2) * 0.04, off[2]), C(150, 85, 40), M.SmoothPlastic)
	end
end

local function dill(root, y, spots)
	for i = 1, math.min(spots or 2, 2) do
		local a = i * 2.3
		d(root, V(0.22, 0.03, 0.1), CF(math.cos(a) * 0.45, y, math.sin(a) * 0.4), C(70, 150, 60), M.Grass, nil, CFrame.Angles(0, a, 0))
	end
end

local function shreds(root, color, y, count, spread)
	for i = 1, math.min(count, 4) do
		local a = i * 2.4
		local r = (i % 3) * 0.18 + 0.05
		d(root, V(0.5, 0.06, 0.08), CF(math.cos(a) * r * spread, y + (i % 4) * 0.05, math.sin(a) * r * spread), color, M.SmoothPlastic, nil, CFrame.Angles(0, a, math.rad(10)))
	end
end

----------------------------------------------------------------------
-- Cepelinai
----------------------------------------------------------------------
local L = {}

L.GratedPotato = function(root)
	base(root, V(1.5, 0.4, 1.5), C(232, 218, 170))
	d(root, V(1.5, 0.55, 1.4), CF(0, 0.25, 0), C(232, 218, 170), M.Sand, SPHERE)
	shreds(root, C(240, 228, 185), 0.48, 9, 1)
end

L.PotatoMeat = function(root)
	base(root, V(1.4, 0.5, 1.4), C(225, 212, 175))
	d(root, V(1.45, 0.95, 1.35), CF(0, 0.45, 0), C(225, 212, 175), M.Sand, SPHERE)
	d(root, V(0.7, 0.35, 0.6), CF(0.05, 0.88, 0), C(190, 110, 95), M.Sand, SPHERE)               -- mėsos įdaras viršuje
end

L.CepelinasRaw = function(root)
	base(root, V(1.8, 0.5, 1.0), C(205, 200, 185))
	cepelinas(root, C(205, 200, 185), M.Sand, 0.45)
end

L.CepelinasBoiled = function(root)
	base(root, V(1.8, 0.5, 1.0), C(228, 224, 210))
	cepelinas(root, C(228, 224, 210), M.SmoothPlastic, 0.45)
end

L.CepelinasServed = function(root)
	base(root, V(2.2, 0.2, 2.2), WHITE_PLATE)
	plate(root, 2.3)
	cepelinas(root, C(228, 224, 210), M.SmoothPlastic, 0.62, 1.8)
	sourCream(root, 0.15, 1.08, 0)
	spirgai(root, 1.05)
	dill(root, 1.12, 3)
end

----------------------------------------------------------------------
-- Kibinai (pusmėnulio formos pyragėliai su „kasele“ viršuje)
----------------------------------------------------------------------
local function kibinas(root, color, crimpColor, y)
	d(root, V(1.9, 0.75, 1.05), CF(0, y, 0), color, M.SmoothPlastic, SPHERE)
	for i = -1.5, 1.5 do
		d(root, V(0.32, 0.22, 0.28), CF(i * 0.36, y + 0.35 - math.abs(i) * 0.03, 0), crimpColor, M.SmoothPlastic, SPHERE, CFrame.Angles(0, 0, math.rad(35)))
	end
end

L.DoughSheet = function(root)
	base(root, V(1.7, 0.25, 1.7), C(240, 232, 212))
	d(root, V(1.8, 0.18, 1.8), CF(0, 0.12, 0), C(240, 232, 212), M.Sand, CYL)
	d(root, V(0.9, 0.04, 0.7), CF(-0.3, 0.22, 0.2), C(252, 250, 244), M.Sand, SPHERE)             -- miltai
end

L.DoughFilled = function(root)
	L.DoughSheet(root)
	d(root, V(0.95, 0.35, 0.75), CF(0.25, 0.32, 0), C(175, 105, 85), M.Sand, SPHERE)              -- aviena
	d(root, V(0.2, 0.06, 0.2), CF(0.35, 0.48, 0.1), C(240, 230, 200), M.SmoothPlastic, BALL)       -- svogūnas
end

L.KibinasRaw = function(root)
	base(root, V(1.8, 0.4, 1.0), C(235, 215, 175))
	kibinas(root, C(235, 215, 175), C(225, 200, 160), 0.38)
end

L.KibinasBaked = function(root)
	base(root, V(1.8, 0.4, 1.0), C(200, 135, 60))
	kibinas(root, C(205, 140, 62), C(160, 95, 38), 0.38)
end

L.KibinasServed = function(root)
	base(root, V(2.2, 0.2, 1.7), C(245, 240, 230))
	d(root, V(2.2, 0.08, 1.7), CF(0, 0.04, 0), C(245, 240, 230), M.Fabric)                      -- lininė servetėlė
	kibinas(root, C(205, 140, 62), C(160, 95, 38), 0.45)
	d(root, V(0.28, 0.06, 0.28), CF(0.55, 0.8, 0.1), C(200, 40, 40), M.SmoothPlastic, CYL)        -- Trakų antspaudas
end

----------------------------------------------------------------------
-- Šaltibarščiai (sriuba dubenėlyje)
----------------------------------------------------------------------
local PINK = C(240, 105, 170)

L.GratedBeet = function(root)
	base(root, V(1.4, 0.4, 1.4), C(150, 25, 70))
	d(root, V(1.4, 0.5, 1.3), CF(0, 0.22, 0), C(150, 25, 70), M.SmoothPlastic, SPHERE)
	shreds(root, C(175, 35, 85), 0.42, 10, 1)
end

L.SoupBowl = function(root)
	base(root, V(1.8, 0.5, 1.8), PINK)
	bowl(root, PINK)
	shreds(root, C(200, 60, 120), 0.84, 2, 0.8)
end

L.SoupCucumber = function(root)
	L.SoupBowl(root)
	for i = 1, 2 do
		local a = i * 2.3
		d(root, V(0.3, 0.08, 0.16), CF(math.cos(a) * 0.45, 0.85, math.sin(a) * 0.45), C(120, 190, 90), M.SmoothPlastic)
	end
	dill(root, 0.85, 2)
end

local function eggHalves(root, y)
	d(root, V(0.5, 0.18, 0.38), CF(0.1, y, 0.15), C(255, 252, 245), M.SmoothPlastic, SPHERE)
	d(root, V(0.22, 0.08, 0.22), CF(0.1, y + 0.07, 0.15), C(255, 195, 40), M.SmoothPlastic, SPHERE)
end

L.SoupEgg = function(root)
	L.SoupCucumber(root)
	eggHalves(root, 0.88)
end

L.SoupChilled = function(root)
	base(root, V(1.8, 0.5, 1.8), PINK)
	bowl(root, C(245, 120, 180), C(235, 245, 255))
	eggHalves(root, 0.88)
	dill(root, 0.85, 2)
	for i = 1, 1 do
		local ice = d(root, V(0.28, 0.24, 0.28), CF(-0.5 + i * 0.35, 0.88, -0.35), C(220, 240, 255), M.Glass, nil, CFrame.Angles(0, i, 0.3))
		ice.Transparency = 0.35
	end
end

L.SoupWithPotatoes = function(root)
	base(root, V(2.3, 0.2, 2.3), WHITE_PLATE)
	plate(root, 2.4)
	-- Dubenėlis ant lėkštės (šiek tiek į šoną)
	d(root, V(1.2, 0.4, 1.2), CF(-0.35, 0.36, 0), C(250, 250, 248), M.SmoothPlastic, CYL)
	d(root, V(1.55, 0.3, 1.55), CF(-0.35, 0.68, 0), C(250, 250, 248), M.SmoothPlastic, CYL)
	d(root, V(1.62, 0.06, 1.62), CF(-0.35, 0.81, 0), C(70, 120, 190), M.SmoothPlastic, CYL)
	d(root, V(1.42, 0.06, 1.42), CF(-0.35, 0.86, 0), PINK, M.SmoothPlastic, CYL)
	d(root, V(0.4, 0.15, 0.3), CF(-0.35, 0.93, 0.1), C(255, 252, 245), M.SmoothPlastic, SPHERE)
	d(root, V(0.18, 0.07, 0.18), CF(-0.35, 0.99, 0.1), C(255, 195, 40), M.SmoothPlastic, SPHERE)
	-- Karštos bulvės su krapais šalia
	for i, off in ipairs({ { 0.75, 0.35 }, { 0.8, -0.3 }, { 0.45, -0.75 } }) do
		d(root, V(0.55, 0.42, 0.48), CF(off[1], 0.38, off[2]), C(240, 205, 120), M.SmoothPlastic, SPHERE, CFrame.Angles(0, i, 0))
	end
end

----------------------------------------------------------------------
-- Šakotis (kūgis su traškiomis „šakomis“)
----------------------------------------------------------------------
local DOUGH = C(225, 172, 80)
local CRUST = C(165, 100, 38)

local function sakotisCone(root, y0, height, width, spikeLen, sugar)
	-- 3 sluoksniai po 2–3 „šakas“ (nedaug dalių – konvejeryje jų daug)
	local layers = 3
	local spikeColor = sugar and C(235, 215, 185) or CRUST   -- cukraus pudra ant šakų
	for i = 0, layers - 1 do
		local t = i / (layers - 1)
		local diameter = width * (1 - t * 0.6)
		local ly = y0 + (i + 0.5) * height / layers
		d(root, V(diameter, height / layers * 0.95, diameter), CF(0, ly, 0), i % 2 == 0 and DOUGH or CRUST, M.SmoothPlastic, CYL)
		local spikes = i < 2 and 3 or 2
		for k = 0, spikes - 1 do
			local a = k * (2 * math.pi / spikes) + i * 0.9
			local r = diameter / 2 + spikeLen * 0.3
			d(root, V(0.16, 0.16, spikeLen), CF(math.cos(a) * r, ly, math.sin(a) * r), spikeColor, M.SmoothPlastic, nil, CFrame.Angles(0, -a + math.pi / 2, 0) * CFrame.Angles(math.rad(-28), 0, 0))
		end
	end
	d(root, V(0.25, 0.2, 0.25), CF(0, y0 + height + 0.05, 0), CRUST, M.SmoothPlastic, SPHERE)
end

L.BatterWhipped = function(root)
	base(root, V(1.6, 0.4, 1.6), C(250, 235, 160))
	d(root, V(1.2, 0.3, 1.2), CF(0, 0.15, 0), C(200, 200, 205), M.Metal, CYL)
	d(root, V(1.55, 0.35, 1.55), CF(0, 0.45, 0), C(200, 200, 205), M.Metal, CYL)
	d(root, V(1.4, 0.55, 1.4), CF(0, 0.7, 0), C(252, 238, 170), M.SmoothPlastic, SPHERE)     -- puri tešla
end

L.SakotisSpit = function(root)
	base(root, V(1.2, 0.3, 1.2), C(235, 200, 110))
	d(root, V(0.16, 2.0, 0.16), CF(0, 1.0, 0), C(120, 85, 50), M.Wood, CYL)                      -- iešmas
	for i = 0, 3 do
		local w = 1.1 - i * 0.18
		d(root, V(w, 0.32, w), CF(0, 0.35 + i * 0.32, 0), C(240, 210, 120), M.SmoothPlastic, CYL)
	end
end

L.SakotisBaked = function(root)
	base(root, V(1.3, 0.2, 1.3), DOUGH)
	sakotisCone(root, 0, 1.7, 1.25, 0.4, false)
end

L.SakotisSugar = function(root)
	base(root, V(1.3, 0.2, 1.3), DOUGH)
	sakotisCone(root, 0, 1.7, 1.25, 0.4, true)
end

L.SakotisBranches = function(root)
	base(root, V(1.4, 0.2, 1.4), DOUGH)
	sakotisCone(root, 0, 2.1, 1.35, 0.6, true)
end

L.SakotisFestive = function(root)
	base(root, V(1.9, 0.2, 1.9), C(150, 105, 60))
	d(root, V(1.9, 0.16, 1.9), CF(0, 0.08, 0), C(150, 105, 60), M.Wood, CYL)                     -- medinis padėklas
	sakotisCone(root, 0.16, 2.1, 1.35, 0.6, true)
	-- Šventinis kaspinas su kilpa
	d(root, V(1.42, 0.14, 1.42), CF(0, 0.45, 0), C(200, 30, 40), M.Fabric, CYL)
	d(root, V(0.4, 0.35, 0.14), CF(0, 0.5, -0.72), C(200, 30, 40), M.Fabric, nil, CFrame.Angles(0, 0, math.rad(45)))
end

----------------------------------------------------------------------
-- Auksinis Cepelinas
----------------------------------------------------------------------
local GOLD = C(255, 205, 60)

L.GoldenGrated = function(root)
	base(root, V(1.5, 0.4, 1.5), GOLD)
	d(root, V(1.5, 0.55, 1.4), CF(0, 0.25, 0), GOLD, M.Metal, SPHERE)
	shreds(root, C(255, 225, 110), 0.48, 9, 1)
end

L.GoldenAmber = function(root)
	base(root, V(1.4, 0.5, 1.4), GOLD)
	d(root, V(1.45, 0.95, 1.35), CF(0, 0.45, 0), GOLD, M.Metal, SPHERE)
	local amber = d(root, V(0.55, 0.45, 0.5), CF(0.1, 0.9, 0), C(255, 150, 30), M.Glass, nil, CFrame.Angles(0.4, 0.7, 0.2))
	amber.Transparency = 0.15
end

L.GoldenCepelinas = function(root)
	base(root, V(1.8, 0.5, 1.0), GOLD)
	cepelinas(root, C(255, 215, 80), M.Metal, 0.45)
end

L.GoldenRoyal = function(root)
	base(root, V(2.2, 0.2, 2.2), GOLD)
	plate(root, 2.3, C(240, 190, 50))
	cepelinas(root, C(255, 215, 0), M.Neon, 0.62, 1.8)
	-- Maža karūnėlė ant viršaus
	d(root, V(0.6, 0.18, 0.6), CF(0, 1.15, 0), C(255, 200, 40), M.Metal, CYL)
	for k = 0, 2 do
		local a = k * 2 * math.pi / 3
		d(root, V(0.1, 0.22, 0.1), CF(math.cos(a) * 0.26, 1.33, math.sin(a) * 0.26), C(255, 200, 40), M.Metal)
	end
	d(root, V(0.14, 0.14, 0.14), CF(0, 1.3, 0), C(200, 30, 40), M.Neon, BALL)
end

function FoodLooks.Apply(root, lookName)
	local look = L[lookName]
	if not look then
		return false
	end
	for _, child in ipairs(root:GetChildren()) do
		if child.Name == "Detail" or child.Name == "Topping" then
			child:Destroy()
		end
	end
	look(root)
	return true
end

FoodLooks.Names = L

return FoodLooks
