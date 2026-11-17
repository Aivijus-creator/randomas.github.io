--[[
	ZoneThemes – kiekvienos linijos zonos galas (ten, kur prasideda konvejeris).
	Kiekviena linija turi vientisą „pastato fasadą“ zonos gale, o konvejeris išeina pro
	angą viduryje – atrodo, lyg produktai atkeliauja iš močiutės trobos, pilies, virtuvės...
	Šonuose nieko nemėtoma, kad netrukdytų mygtukams ir mašinoms.

	Build(lineId, parent, laneCFrame): laneCFrame – linijos centro CFrame zonos paviršiuje
	(X – skersai linijos, Z – išilgai, -Z – produktų judėjimo kryptis).
	Fasadas stovi tarp Z = 52.5 ir 56 (zonos galas), plotis ~19 studų.
]]

local Build = require(script.Parent:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local ZoneThemes = {}

local CYL_UP = CFrame.Angles(0, 0, math.rad(90))
local OPENING = 3.0          -- angos pusplotis (konvejeris ~2.5)
local OPENING_H = 4.6        -- angos aukštis
local WALL_Z = 54.8          -- fasado sienos centras
local HALF = 9.6             -- zonos pusplotis

local function part(parent, lane, props, x, y, z, rot)
	props.Parent = parent
	local cf = lane * CF(x, y, z)
	if rot then
		cf = cf * rot
	end
	props.CFrame = cf
	props.CanQuery = false
	return Build.Part(props)
end

-- Siena per visą plotį su anga konvejeriui viduryje
local function wallWithOpening(parent, lane, height, color, material, thickness)
	thickness = thickness or 1.2
	local sideWidth = HALF - OPENING
	for _, side in ipairs({ -1, 1 }) do
		part(parent, lane, { Name = "Wall", Size = V(sideWidth, height, thickness), Color = color, Material = material }, side * (OPENING + sideWidth / 2), height / 2, WALL_Z)
	end
	part(parent, lane, { Name = "WallTop", Size = V(OPENING * 2, height - OPENING_H, thickness), Color = color, Material = material }, 0, OPENING_H + (height - OPENING_H) / 2, WALL_Z)
	-- Tamsus angos vidus (gilumas)
	part(parent, lane, { Name = "OpeningShadow", Size = V(OPENING * 2, OPENING_H, 0.2), Color = C(25, 18, 12), Material = M.SmoothPlastic, CanCollide = false }, 0, OPENING_H / 2, WALL_Z + thickness / 2 + 0.1)
end

local function light(parentPart, color, range, brightness)
	local pointLight = Instance.new("PointLight")
	pointLight.Color = color
	pointLight.Range = range
	pointLight.Brightness = brightness or 1
	pointLight.Shadows = false
	pointLight.Parent = parentPart
	return pointLight
end

-- Langas su mėlynomis langinėmis (tradicinė lietuviška troba)
local function cottageWindow(parent, lane, x, y)
	part(parent, lane, { Name = "WindowFrame", Size = V(2.4, 2.2, 0.3), Color = C(245, 240, 225), Material = M.Wood }, x, y, WALL_Z - 0.65)
	part(parent, lane, { Name = "WindowGlass", Size = V(1.9, 1.7, 0.1), Color = C(255, 215, 140), Material = M.Neon, Transparency = 0.35 }, x, y, WALL_Z - 0.82)
	part(parent, lane, { Name = "WindowCross", Size = V(0.14, 1.7, 0.08), Color = C(245, 240, 225), Material = M.Wood }, x, y, WALL_Z - 0.88)
	part(parent, lane, { Name = "WindowCross", Size = V(1.9, 0.14, 0.08), Color = C(245, 240, 225), Material = M.Wood }, x, y, WALL_Z - 0.88)
	for _, side in ipairs({ -1, 1 }) do
		part(parent, lane, { Name = "Shutter", Size = V(0.9, 2.2, 0.15), Color = C(55, 95, 160), Material = M.Wood }, x + side * 1.7, y, WALL_Z - 0.7)
	end
end

----------------------------------------------------------------------
-- Cepelinai: močiutės rąstinė troba su krosnimi ir bulvių maišais
----------------------------------------------------------------------
local function cepelinai(parent, lane)
	local logColor = C(120, 80, 45)
	-- Rąstai (horizontalūs, su tamsesniais tarpais)
	wallWithOpening(parent, lane, 7.2, logColor, M.Wood)
	for row = 0, 5 do
		local y = 1.2 + row * 1.2
		if y < OPENING_H then
			local width = HALF - OPENING
			for _, side in ipairs({ -1, 1 }) do
				part(parent, lane, { Name = "LogLine", Size = V(width, 0.12, 0.1), Color = C(80, 50, 28), Material = M.Wood, CanCollide = false }, side * (OPENING + width / 2), y, WALL_Z - 0.62)
			end
		else
			part(parent, lane, { Name = "LogLine", Size = V(HALF * 2, 0.12, 0.1), Color = C(80, 50, 28), Material = M.Wood, CanCollide = false }, 0, y, WALL_Z - 0.62)
		end
	end
	-- Durų staktos ir stogelis
	for _, side in ipairs({ -1, 1 }) do
		part(parent, lane, { Name = "DoorPost", Size = V(0.5, OPENING_H + 0.4, 0.5), Color = C(90, 58, 30), Material = M.Wood }, side * (OPENING + 0.25), (OPENING_H + 0.4) / 2, WALL_Z - 0.7)
	end
	part(parent, lane, { Name = "Lintel", Size = V(OPENING * 2 + 1.2, 0.6, 0.6), Color = C(90, 58, 30), Material = M.Wood }, 0, OPENING_H + 0.3, WALL_Z - 0.7)
	part(parent, lane, { Name = "Roof", Size = V(HALF * 2 + 0.6, 0.5, 3), Color = C(150, 120, 70), Material = M.Grass }, 0, 7.6, WALL_Z - 0.4, CFrame.Angles(math.rad(-18), 0, 0))
	cottageWindow(parent, lane, -6.6, 4.2)
	-- Balta molinė krosnis kairėje, matosi ugnis
	part(parent, lane, { Name = "Oven", Size = V(3.2, 3.2, 2.2), Color = C(235, 230, 215), Material = M.Plaster }, -6.6, 1.6, WALL_Z - 1.7)
	part(parent, lane, { Name = "OvenMouthFrame", Size = V(1.6, 1.2, 0.2), Color = C(60, 45, 35), Material = M.Brick }, -6.6, 1.4, WALL_Z - 2.85)
	local fire = part(parent, lane, { Name = "OvenFire", Size = V(1.2, 0.8, 0.1), Color = C(255, 120, 30), Material = M.Neon }, -6.6, 1.3, WALL_Z - 2.92)
	light(fire, C(255, 150, 60), 10, 1.2)
	part(parent, lane, { Name = "Chimney", Size = V(1.2, 4.4, 1.2), Color = C(235, 230, 215), Material = M.Plaster }, -7.6, 9, WALL_Z)
	-- Bulvių maišai ir pintinė dešinėje
	for i = 0, 2 do
		local sack = part(parent, lane, { Name = "PotatoSack", Size = V(1.7, 2.1, 1.5), Color = C(190, 165, 115), Material = M.Fabric }, 4.6 + i * 1.75, 1.05, WALL_Z - 1.6)
		Build.Mesh(sack, Enum.MeshType.Sphere, V(1, 1, 1))
		part(parent, lane, { Name = "SackTie", Size = V(0.7, 0.4, 0.7), Color = C(160, 135, 90), Material = M.Fabric }, 4.6 + i * 1.75, 2.2, WALL_Z - 1.6)
	end
	part(parent, lane, { Name = "Basket", Shape = Enum.PartType.Cylinder, Size = V(0.9, 1.8, 1.8), Color = C(170, 125, 70), Material = M.WoodPlanks }, 4.4, 0.45, WALL_Z - 3.2, CYL_UP)
	for i = 0, 3 do
		local potato = part(parent, lane, { Name = "Potato", Size = V(0.7, 0.55, 0.6), Color = C(175, 128, 75), Material = M.Sand }, 4.1 + (i % 2) * 0.55, 1.0 + math.floor(i / 2) * 0.25, WALL_Z - 3.4 + (i % 3) * 0.3)
		Build.Mesh(potato, Enum.MeshType.Sphere)
	end
end

----------------------------------------------------------------------
-- Kibinai: Trakų pilies vartai (raudonos plytos, du bokštai, vartų grotos)
----------------------------------------------------------------------
local function castleTower(parent, lane, x, z)
	local brick = C(165, 65, 48)
	part(parent, lane, { Name = "Tower", Shape = Enum.PartType.Cylinder, Size = V(10, 4.2, 4.2), Color = brick, Material = M.Brick }, x, 5, z, CYL_UP)
	part(parent, lane, { Name = "TowerRing", Shape = Enum.PartType.Cylinder, Size = V(0.6, 4.6, 4.6), Color = C(140, 50, 38), Material = M.Brick }, x, 10.1, z, CYL_UP)
	-- Kūginis stogas iš mažėjančių cilindrų
	for i = 0, 5 do
		local d = 4.6 - i * 0.75
		part(parent, lane, { Name = "TowerRoof", Shape = Enum.PartType.Cylinder, Size = V(0.75, d, d), Color = C(120, 35, 30), Material = M.Slate }, x, 10.7 + i * 0.7, z, CYL_UP)
	end
	part(parent, lane, { Name = "TowerSpire", Size = V(0.2, 1.8, 0.2), Color = C(230, 190, 60), Material = M.Metal }, x, 15.6, z)
	part(parent, lane, { Name = "Pennant", Size = V(1.2, 0.6, 0.05), Color = C(253, 185, 19), Material = M.Fabric }, x + 0.7, 16.1, z)
	part(parent, lane, { Name = "ArrowSlit", Size = V(0.3, 1.2, 0.2), Color = C(30, 20, 15), Material = M.SmoothPlastic }, x, 6.5, z - 2.1)
end

local function kibinai(parent, lane)
	local brick = C(165, 65, 48)
	wallWithOpening(parent, lane, 7, brick, M.Brick, 1.4)
	for i = -3, 3 do
		if i ~= 0 then
			part(parent, lane, { Name = "Crenel", Size = V(1.1, 1.2, 1.4), Color = brick, Material = M.Brick }, i * 1.9, 7.6, WALL_Z)
		end
	end
	-- Arka virš vartų ir pakeltos grotos
	part(parent, lane, { Name = "Arch", Size = V(OPENING * 2 + 1, 0.8, 1.6), Color = C(200, 190, 175), Material = M.Limestone }, 0, OPENING_H + 0.4, WALL_Z - 0.1)
	for i = -2, 2 do
		part(parent, lane, { Name = "PortcullisBar", Size = V(0.18, 1.4, 0.18), Color = C(60, 60, 65), Material = M.Metal }, i * 1.2, OPENING_H - 0.6, WALL_Z - 0.75)
	end
	part(parent, lane, { Name = "PortcullisBeam", Size = V(OPENING * 2, 0.18, 0.18), Color = C(60, 60, 65), Material = M.Metal }, 0, OPENING_H - 1.25, WALL_Z - 0.75)
	castleTower(parent, lane, -7.5, WALL_Z - 0.6)
	castleTower(parent, lane, 7.5, WALL_Z - 0.6)
	-- Fakelai prie vartų
	for _, side in ipairs({ -1, 1 }) do
		part(parent, lane, { Name = "TorchHolder", Size = V(0.3, 1, 0.3), Color = C(60, 60, 65), Material = M.Metal }, side * 4, 3.4, WALL_Z - 0.85)
		local flame = part(parent, lane, { Name = "TorchFlame", Size = V(0.4, 0.5, 0.4), Color = C(255, 150, 40), Material = M.Neon, CanCollide = false }, side * 4, 4.1, WALL_Z - 0.85)
		light(flame, C(255, 160, 70), 9, 1)
	end
	-- Gedimino stulpų vėliavos ant sienos
	for _, side in ipairs({ -1, 1 }) do
		part(parent, lane, { Name = "Banner", Size = V(1.4, 2.6, 0.1), Color = C(170, 30, 35), Material = M.Fabric }, side * 4.6, 5.6, WALL_Z - 0.75)
		part(parent, lane, { Name = "BannerSign", Size = V(0.7, 0.7, 0.05), Color = C(240, 195, 60), Material = M.Metal }, side * 4.6, 5.8, WALL_Z - 0.82)
	end
end

----------------------------------------------------------------------
-- Šaltibarščiai: vasaros virtuvėlė (veranda) su stalu, dubeniu, kefyru, burokėliais
----------------------------------------------------------------------
local function saltibarsciai(parent, lane)
	local plank = C(235, 225, 200)
	wallWithOpening(parent, lane, 6.4, plank, M.WoodPlanks, 0.8)
	part(parent, lane, { Name = "Trim", Size = V(HALF * 2, 0.4, 0.3), Color = C(100, 160, 95), Material = M.Wood }, 0, 6.5, WALL_Z - 0.45)
	part(parent, lane, { Name = "Awning", Size = V(HALF * 2 + 0.4, 0.25, 2.6), Color = C(230, 110, 170), Material = M.Fabric }, 0, 7.1, WALL_Z - 1.2, CFrame.Angles(math.rad(-15), 0, 0))
	for i = -4, 4 do
		part(parent, lane, { Name = "AwningStripe", Size = V(1, 0.27, 2.62), Color = C(250, 245, 245), Material = M.Fabric }, i * 2.1, 7.1, WALL_Z - 1.2, CFrame.Angles(math.rad(-15), 0, 0))
	end
	-- Langas su languota užuolaida
	part(parent, lane, { Name = "WindowGlass", Size = V(2.6, 2, 0.1), Color = C(180, 220, 240), Material = M.Glass, Transparency = 0.2 }, 6.4, 4.2, WALL_Z - 0.45)
	part(parent, lane, { Name = "Curtain", Size = V(2.6, 0.7, 0.12), Color = C(220, 60, 70), Material = M.Fabric }, 6.4, 4.9, WALL_Z - 0.55)
	-- Stalas kairėje su dideliu šaltibarščių dubeniu
	part(parent, lane, { Name = "TableTop", Size = V(4.4, 0.3, 2.2), Color = C(140, 95, 55), Material = M.WoodPlanks }, -6.5, 2.6, WALL_Z - 1.8)
	for _, x in ipairs({ -8.4, -4.6 }) do
		part(parent, lane, { Name = "TableLeg", Size = V(0.3, 2.5, 0.3), Color = C(110, 72, 40), Material = M.Wood }, x, 1.25, WALL_Z - 1.8)
	end
	part(parent, lane, { Name = "Tablecloth", Size = V(4.5, 0.06, 2.3), Color = C(250, 250, 250), Material = M.Fabric }, -6.5, 2.78, WALL_Z - 1.8)
	local bowl = part(parent, lane, { Name = "BigBowl", Size = V(2, 0.9, 2), Color = C(245, 245, 240), Material = M.SmoothPlastic }, -7, 3.15, WALL_Z - 1.8)
	Build.Mesh(bowl, Enum.MeshType.Sphere, V(1, 1, 1))
	part(parent, lane, { Name = "Soup", Shape = Enum.PartType.Cylinder, Size = V(0.1, 1.75, 1.75), Color = C(240, 105, 170), Material = M.SmoothPlastic }, -7, 3.5, WALL_Z - 1.8, CYL_UP)
	local egg = part(parent, lane, { Name = "EggHalf", Size = V(0.45, 0.2, 0.35), Color = C(255, 250, 240), Material = M.SmoothPlastic }, -7.3, 3.58, WALL_Z - 1.7)
	Build.Mesh(egg, Enum.MeshType.Sphere)
	part(parent, lane, { Name = "Yolk", Shape = Enum.PartType.Ball, Size = V(0.2, 0.2, 0.2), Color = C(255, 200, 40), Material = M.SmoothPlastic }, -7.3, 3.66, WALL_Z - 1.7)
	part(parent, lane, { Name = "Dill", Size = V(0.5, 0.06, 0.4), Color = C(80, 160, 70), Material = M.Grass }, -6.7, 3.57, WALL_Z - 1.9)
	-- Kefyro ąsotis ir burokėliai
	part(parent, lane, { Name = "KefirJug", Shape = Enum.PartType.Cylinder, Size = V(1.3, 0.8, 0.8), Color = C(250, 250, 245), Material = M.SmoothPlastic }, -5.3, 3.4, WALL_Z - 1.6, CYL_UP)
	part(parent, lane, { Name = "KefirLid", Shape = Enum.PartType.Cylinder, Size = V(0.15, 0.6, 0.6), Color = C(60, 120, 200), Material = M.SmoothPlastic }, -5.3, 4.1, WALL_Z - 1.6, CYL_UP)
	part(parent, lane, { Name = "BeetCrate", Size = V(2.6, 1.1, 1.6), Color = C(170, 125, 70), Material = M.WoodPlanks }, 5.8, 0.55, WALL_Z - 1.4)
	for i = 0, 5 do
		local bx = 4.9 + (i % 3) * 0.9
		local bz = WALL_Z - 1.75 + math.floor(i / 3) * 0.7
		part(parent, lane, { Name = "Beet", Shape = Enum.PartType.Ball, Size = V(0.75, 0.75, 0.75), Color = C(130, 20, 55), Material = M.SmoothPlastic }, bx, 1.35, bz)
		part(parent, lane, { Name = "BeetLeaf", Size = V(0.12, 0.6, 0.35), Color = C(80, 150, 60), Material = M.Grass, CanCollide = false }, bx, 1.95, bz)
	end
	-- Agurkai ir krapai indelyje
	part(parent, lane, { Name = "DillPot", Shape = Enum.PartType.Cylinder, Size = V(0.8, 0.8, 0.8), Color = C(190, 100, 60), Material = M.Brick }, 8.4, 0.4, WALL_Z - 1.4, CYL_UP)
	for i = 0, 2 do
		part(parent, lane, { Name = "DillSprig", Size = V(0.15, 1.1, 0.15), Color = C(90, 170, 70), Material = M.Grass, CanCollide = false }, 8.25 + i * 0.15, 1.3, WALL_Z - 1.4, CFrame.Angles(0, 0, math.rad(-15 + i * 15)))
	end
end

----------------------------------------------------------------------
-- Šakotis: šventinė kepykla – židinys su sukamu iešmu ir šakočiai ant stalo
----------------------------------------------------------------------
local function sakotisCake(parent, lane, x, y, z, scale)
	local dough = C(220, 165, 75)
	local crust = C(170, 105, 40)
	local layers = 6
	for i = 0, layers - 1 do
		local d = (1.5 - i * 0.18) * scale
		local ly = y + (0.25 + i * 0.45) * scale
		part(parent, lane, { Name = "SakotisLayer", Shape = Enum.PartType.Cylinder, Size = V(0.45 * scale, d, d), Color = i % 2 == 0 and dough or crust, Material = M.SmoothPlastic, CanCollide = false }, x, ly, z, CYL_UP)
		-- „Šakos“ – išsikišę traškūs dygliai aplink
		local spikes = 7 - math.floor(i / 2)
		for k = 0, spikes - 1 do
			local a = math.rad(k * 360 / spikes + i * 23)
			local r = d / 2 + 0.15 * scale
			part(parent, lane, { Name = "SakotisSpike", Size = V(0.18 * scale, 0.18 * scale, 0.45 * scale), Color = crust, Material = M.SmoothPlastic, CanCollide = false },
				x + math.cos(a) * r, ly - 0.05 * scale, z + math.sin(a) * r, CFrame.Angles(0, -a + math.rad(90), 0) * CFrame.Angles(math.rad(-25), 0, 0))
		end
	end
	part(parent, lane, { Name = "SakotisTop", Shape = Enum.PartType.Ball, Size = V(0.35, 0.35, 0.35) * scale, Color = crust, Material = M.SmoothPlastic, CanCollide = false }, x, y + (0.25 + layers * 0.45) * scale, z)
end

local function sakotis(parent, lane)
	-- Fachverkinė kepyklos siena: kreminis tinkas ir tamsios sijos
	wallWithOpening(parent, lane, 7, C(240, 228, 200), M.Plaster, 1)
	for _, x in ipairs({ -9.2, -6.2, 6.2, 9.2 }) do
		part(parent, lane, { Name = "Beam", Size = V(0.45, 7, 0.2), Color = C(85, 55, 30), Material = M.Wood }, x, 3.5, WALL_Z - 0.55)
	end
	part(parent, lane, { Name = "BeamTop", Size = V(HALF * 2, 0.45, 0.2), Color = C(85, 55, 30), Material = M.Wood }, 0, 6.9, WALL_Z - 0.55)
	part(parent, lane, { Name = "BeamMid", Size = V(HALF * 2, 0.35, 0.2), Color = C(85, 55, 30), Material = M.Wood }, 0, OPENING_H + 0.2, WALL_Z - 0.55)
	-- Kairėje: plytinis židinys su ugnimi ir sukamu iešmu (šakotis kepamas sukant virš ugnies)
	part(parent, lane, { Name = "Hearth", Size = V(5, 1, 2.6), Color = C(120, 60, 45), Material = M.Brick }, -6.4, 0.5, WALL_Z - 1.9)
	part(parent, lane, { Name = "HearthBack", Size = V(5, 4, 0.6), Color = C(120, 60, 45), Material = M.Brick }, -6.4, 2.5, WALL_Z - 0.8)
	local fireBase = part(parent, lane, { Name = "Fire", Size = V(1, 1, 1), Transparency = 1, CanCollide = false }, -6.4, 1.3, WALL_Z - 1.9)
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 5
	fire.Parent = fireBase
	light(fireBase, C(255, 150, 60), 10, 1.2)
	for _, x in ipairs({ -8.6, -4.2 }) do
		part(parent, lane, { Name = "SpitPost", Size = V(0.3, 3.4, 0.3), Color = C(60, 60, 65), Material = M.Metal }, x, 2.7, WALL_Z - 1.9)
	end
	part(parent, lane, {
		Name = "Spit", Shape = Enum.PartType.Cylinder, Size = V(3.6, 1.5, 1.5), Color = C(225, 170, 80), Material = M.SmoothPlastic,
		Tags = { "Spinner" }, Attributes = { SpinSpeed = 1.2 },
	}, -6.4, 3.6, WALL_Z - 1.9)
	-- Dešinėje: stalas su šakočiais ant padėklų ir šventiniu kaspinu
	part(parent, lane, { Name = "TableTop", Size = V(5, 0.3, 2.2), Color = C(140, 95, 55), Material = M.WoodPlanks }, 6.3, 2.6, WALL_Z - 1.8)
	for _, x in ipairs({ 4.1, 8.5 }) do
		part(parent, lane, { Name = "TableLeg", Size = V(0.3, 2.5, 0.3), Color = C(110, 72, 40), Material = M.Wood }, x, 1.25, WALL_Z - 1.8)
	end
	part(parent, lane, { Name = "Tablecloth", Size = V(5.1, 0.06, 2.3), Color = C(250, 250, 245), Material = M.Fabric }, 6.3, 2.78, WALL_Z - 1.8)
	part(parent, lane, { Name = "ClothStripe", Size = V(5.12, 0.07, 0.4), Color = C(200, 50, 50), Material = M.Fabric }, 6.3, 2.79, WALL_Z - 2.6)
	sakotisCake(parent, lane, 5.2, 2.81, WALL_Z - 1.8, 1)
	sakotisCake(parent, lane, 7.5, 2.81, WALL_Z - 1.8, 0.8)
end

----------------------------------------------------------------------
-- Auksinis Cepelinas: karališka auksinė salė su Vytauto Didžiojo statula
----------------------------------------------------------------------
local function auksinis(parent, lane)
	local gold = C(240, 195, 60)
	local marble = C(240, 235, 225)
	wallWithOpening(parent, lane, 7.6, marble, M.Marble, 1.2)
	part(parent, lane, { Name = "GoldTrim", Size = V(HALF * 2, 0.4, 0.3), Color = gold, Material = M.Metal }, 0, 7.4, WALL_Z - 0.7)
	part(parent, lane, { Name = "GoldBase", Size = V(HALF * 2, 0.5, 0.3), Color = gold, Material = M.Metal }, 0, 0.25, WALL_Z - 0.7)
	-- Dvi auksinės kolonos prie angos
	for _, side in ipairs({ -1, 1 }) do
		local x = side * (OPENING + 0.9)
		part(parent, lane, { Name = "Column", Shape = Enum.PartType.Cylinder, Size = V(6.6, 1.2, 1.2), Color = gold, Material = M.Metal }, x, 3.6, WALL_Z - 1, CYL_UP)
		part(parent, lane, { Name = "ColumnCap", Size = V(1.6, 0.4, 1.6), Color = gold, Material = M.Metal }, x, 7.1, WALL_Z - 1)
		part(parent, lane, { Name = "ColumnBase", Size = V(1.6, 0.4, 1.6), Color = gold, Material = M.Metal }, x, 0.2, WALL_Z - 1)
	end
	-- Gintariniai langai šonuose
	for _, x in ipairs({ -7, 7 }) do
		local amber = part(parent, lane, { Name = "AmberWindow", Size = V(2, 3, 0.15), Color = C(255, 160, 40), Material = M.Neon, Transparency = 0.25 }, x, 4, WALL_Z - 0.68)
		part(parent, lane, { Name = "AmberFrame", Size = V(2.4, 3.4, 0.1), Color = gold, Material = M.Metal }, x, 4, WALL_Z - 0.62)
		light(amber, C(255, 180, 80), 10, 0.8)
	end
	-- Vytauto Didžiojo statula ant sienos viršaus, virš angos
	part(parent, lane, { Name = "StatuePedestal", Size = V(3, 1, 2), Color = marble, Material = M.Marble }, 0, 8.1, WALL_Z)
	part(parent, lane, { Name = "StatueLegs", Size = V(1.4, 1.8, 0.8), Color = gold, Material = M.Metal }, 0, 9.5, WALL_Z)
	part(parent, lane, { Name = "StatueBody", Size = V(1.9, 2, 1), Color = gold, Material = M.Metal }, 0, 11.4, WALL_Z)
	local head = part(parent, lane, { Name = "StatueHead", Shape = Enum.PartType.Ball, Size = V(1.1, 1.1, 1.1), Color = gold, Material = M.Metal }, 0, 12.95, WALL_Z)
	part(parent, lane, { Name = "StatueCrown", Size = V(1.1, 0.45, 1.1), Color = C(255, 220, 90), Material = M.Neon }, 0, 13.65, WALL_Z)
	part(parent, lane, { Name = "StatueCape", Size = V(2.1, 2.8, 0.25), Color = C(160, 30, 40), Material = M.Fabric }, 0, 11, WALL_Z + 0.6)
	part(parent, lane, { Name = "StatueSword", Size = V(0.25, 3, 0.25), Color = C(220, 220, 230), Material = M.Metal }, 1.4, 11.4, WALL_Z - 0.5, CFrame.Angles(0, 0, math.rad(-20)))
	light(head, C(255, 210, 120), 18, 1)
end

local BUILDERS = {
	Cepelinai = cepelinai,
	Kibinai = kibinai,
	Saltibarsciai = saltibarsciai,
	Sakotis = sakotis,
	AuksinisCepelinas = auksinis,
}

-- Šakočio modelis (naudojamas ir kitur)
ZoneThemes.SakotisCake = sakotisCake

function ZoneThemes.Build(lineId, parent, laneCFrame)
	local builder = BUILDERS[lineId]
	if builder then
		builder(parent, laneCFrame)
	end
end

return ZoneThemes
