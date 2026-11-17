--[[
	DecorModels – lentynos puošmenų modeliai sklype (Settings.GlobalUpgrades.Decor).
	Kiekviena funkcija(model) sudeda dalis vietinėmis koordinatėmis: (0,0,0) – apačios centras,
	priekis -Z kryptimi (į vartus / lobby).
]]

local Build = require(script.Parent:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local WOOD = C(122, 82, 46)
local DARK_WOOD = C(78, 50, 26)
local GOLD = C(240, 195, 60)
local CYL_UP = CFrame.Angles(0, 0, math.rad(90))

local function p(model, name, size, cf, color, material, shape)
	return Build.Part({ Name = name, Parent = model, Size = size, CFrame = cf, Color = color, Material = material or M.SmoothPlastic, Shape = shape })
end

local DecorModels = {}

-- Gandralizdis: aukštas stulpas, lizdas, gandras ant vienos kojos
function DecorModels.StorkNest(model)
	p(model, "Pole", V(0.8, 12, 0.8), CF(0, 6, 0), DARK_WOOD, M.Wood)
	p(model, "Wheel", V(0.5, 4.4, 4.4), CF(0, 12.2, 0) * CYL_UP, C(110, 75, 45), M.Wood, Enum.PartType.Cylinder)
	-- Šakų lizdas
	for i = 0, 9 do
		local a = math.rad(i * 36)
		p(model, "Twig", V(0.25, 0.25, 2.6), CF(math.cos(a) * 1.6, 12.8, math.sin(a) * 1.6) * CFrame.Angles(0, -a, math.rad(8)), C(120, 90, 55), M.Wood)
	end
	p(model, "NestFill", V(0.6, 3.4, 3.4), CF(0, 12.7, 0) * CYL_UP, C(140, 105, 65), M.Grass, Enum.PartType.Cylinder)
	-- Gandras
	local white = C(245, 245, 240)
	local body = p(model, "StorkBody", V(1.2, 1.1, 2), CF(0, 14.4, 0) * CFrame.Angles(math.rad(-12), 0, 0), white)
	Build.Mesh(body, Enum.MeshType.Sphere)
	p(model, "StorkWingL", V(0.2, 0.7, 1.6), CF(-0.62, 14.5, 0.2), C(25, 25, 25))
	p(model, "StorkWingR", V(0.2, 0.7, 1.6), CF(0.62, 14.5, 0.2), C(25, 25, 25))
	p(model, "StorkNeck", V(0.3, 1.3, 0.3), CF(0, 15.3, -0.8) * CFrame.Angles(math.rad(-15), 0, 0), white)
	p(model, "StorkHead", V(0.5, 0.5, 0.5), CF(0, 16, -0.95), white, nil, Enum.PartType.Ball)
	p(model, "StorkBeak", V(0.15, 0.15, 1.1), CF(0, 15.9, -1.6) * CFrame.Angles(math.rad(12), 0, 0), C(225, 60, 40))
	p(model, "StorkLeg", V(0.12, 1.2, 0.12), CF(0.15, 13.4, 0), C(225, 60, 40))
	p(model, "StorkEyeL", V(0.08, 0.08, 0.08), CF(-0.22, 16.08, -1.1), C(10, 10, 10), nil, Enum.PartType.Ball)
	p(model, "StorkEyeR", V(0.08, 0.08, 0.08), CF(0.22, 16.08, -1.1), C(10, 10, 10), nil, Enum.PartType.Ball)
end

-- Rūtų darželis: tvorelė iš statinių ir žalios rūtos su geltonais žiedeliais
function DecorModels.RueGarden(model)
	p(model, "Bed", V(9, 0.5, 5), CF(0, 0.25, 0), C(95, 65, 40), M.Ground)
	for i = 0, 17 do
		local x = -4.5 + (i % 9) * 1.125
		local z = i < 9 and -2.5 or 2.5
		p(model, "Picket", V(0.3, 1.4, 0.3), CF(x, 0.7, z), WOOD, M.Wood)
	end
	for _, x in ipairs({ -4.5, 4.5 }) do
		for k = 0, 3 do
			p(model, "Picket", V(0.3, 1.4, 0.3), CF(x, 0.7, -1.5 + k), WOOD, M.Wood)
		end
	end
	p(model, "Rail", V(9, 0.2, 0.2), CF(0, 1.1, -2.5), DARK_WOOD, M.Wood)
	p(model, "Rail", V(9, 0.2, 0.2), CF(0, 1.1, 2.5), DARK_WOOD, M.Wood)
	for row = 0, 1 do
		for i = 0, 5 do
			local x = -3.4 + i * 1.36
			local z = -0.9 + row * 1.8
			local bush = p(model, "Rue", V(1.1, 0.9, 1.1), CF(x, 0.95, z), C(95, 140, 90), M.Grass)
			Build.Mesh(bush, Enum.MeshType.Sphere)
			p(model, "RueFlower", V(0.22, 0.22, 0.22), CF(x + 0.2, 1.45, z - 0.1), C(240, 210, 60), nil, Enum.PartType.Ball)
		end
	end
end

-- Šulinys su svirtimi (lietuviškas „svirtis“)
function DecorModels.Well(model)
	local stone = C(130, 125, 115)
	p(model, "WellRing", V(2.6, 3.6, 3.6), CF(0, 1.3, 0) * CYL_UP, stone, M.Cobblestone, Enum.PartType.Cylinder)
	p(model, "Water", V(0.1, 2.9, 2.9), CF(0, 2.45, 0) * CYL_UP, C(60, 110, 150), M.Glass, Enum.PartType.Cylinder)
	-- Svirties stulpas ir ilga svirtis
	p(model, "Post", V(0.6, 7, 0.6), CF(3.5, 3.5, 0), DARK_WOOD, M.Wood)
	p(model, "Fork", V(0.2, 0.8, 0.8), CF(3.5, 7.2, 0), DARK_WOOD, M.Wood)
	local lever = CF(3.5, 7.2, 0) * CFrame.Angles(0, 0, math.rad(-28))
	p(model, "Lever", V(11, 0.35, 0.35), lever * CF(-1.5, 0, 0), WOOD, M.Wood)
	p(model, "Weight", V(0.9, 0.9, 0.9), lever * CF(3.6, -0.3, 0), stone, M.Slate)
	local tip = (lever * CF(-7, 0, 0)).Position
	p(model, "Rope", V(0.12, tip.Y - 3.4, 0.12), CF(tip.X, (tip.Y + 3.4) / 2, 0), C(170, 140, 90), M.Fabric)
	p(model, "Bucket", V(0.9, 0.8, 0.8), CF(tip.X, 3.3, 0) * CYL_UP, C(110, 80, 50), M.Wood, Enum.PartType.Cylinder)
end

-- Gintariniai žibintai abipus įėjimo
function DecorModels.AmberLanterns(model)
	for _, x in ipairs({ -10.5, 10.5 }) do
		for _, z in ipairs({ -4, 4 }) do
			p(model, "LanternPost", V(0.5, 6, 0.5), CF(x, 3, z), C(45, 40, 38), M.Metal)
			p(model, "LanternCap", V(1.4, 0.3, 1.4), CF(x, 7.3, z), C(45, 40, 38), M.Metal)
			local amber = p(model, "Amber", V(1, 1.2, 1), CF(x, 6.55, z), C(255, 160, 40), M.Neon)
			amber.Transparency = 0.15
			local light = Instance.new("PointLight")
			light.Color = C(255, 170, 70)
			light.Range = 14
			light.Brightness = 1.4
			light.Shadows = false
			light.Parent = amber
		end
	end
end

-- Auksinis Vytis: raitelis su kardu ir skydu ant marmurinio postamento
function DecorModels.VytisStatue(model)
	local marble = C(235, 230, 220)
	p(model, "Pedestal", V(6, 2.4, 3.6), CF(0, 1.2, 0), marble, M.Marble)
	p(model, "PedestalTop", V(6.4, 0.3, 4), CF(0, 2.55, 0), marble, M.Marble)
	-- Žirgas (stovi šonu, galva į kairę, šuolio poza)
	p(model, "HorseBody", V(4, 1.6, 1.4), CF(0, 4.6, 0) * CFrame.Angles(0, 0, math.rad(8)), GOLD, M.Metal)
	p(model, "HorseNeck", V(0.9, 1.8, 0.9), CF(-2, 5.8, 0) * CFrame.Angles(0, 0, math.rad(30)), GOLD, M.Metal)
	p(model, "HorseHead", V(1.5, 0.7, 0.7), CF(-2.7, 6.6, 0) * CFrame.Angles(0, 0, math.rad(-20)), GOLD, M.Metal)
	for _, leg in ipairs({ { -1.4, -0.45, 25 }, { -1.4, 0.45, 40 }, { 1.4, -0.45, -10 }, { 1.4, 0.45, 5 } }) do
		p(model, "HorseLeg", V(0.35, 1.9, 0.35), CF(leg[1], 3.4, leg[2]) * CFrame.Angles(0, 0, math.rad(leg[3])), GOLD, M.Metal)
	end
	p(model, "HorseTail", V(0.3, 1.6, 0.3), CF(2.2, 4.6, 0) * CFrame.Angles(0, 0, math.rad(-35)), GOLD, M.Metal)
	-- Raitelis
	p(model, "RiderBody", V(1, 1.6, 0.9), CF(0.2, 6.1, 0), GOLD, M.Metal)
	p(model, "RiderHead", V(0.7, 0.7, 0.7), CF(0.2, 7.25, 0), GOLD, M.Metal, Enum.PartType.Ball)
	p(model, "RiderHelmet", V(0.75, 0.4, 0.75), CF(0.2, 7.6, 0), GOLD, M.Metal)
	p(model, "Sword", V(0.2, 2.6, 0.2), CF(-0.6, 7.9, -0.3) * CFrame.Angles(0, 0, math.rad(30)), C(230, 230, 240), M.Metal)
	-- Skydas su dvigubu kryžiumi (priekyje, -Z)
	p(model, "Shield", V(1.1, 1.3, 0.15), CF(0.25, 6.0, -0.55), C(190, 35, 40), M.Metal)
	p(model, "CrossV", V(0.14, 0.9, 0.05), CF(0.25, 6.0, -0.65), GOLD, M.Neon)
	p(model, "CrossH1", V(0.6, 0.12, 0.05), CF(0.25, 6.2, -0.65), GOLD, M.Neon)
	p(model, "CrossH2", V(0.45, 0.12, 0.05), CF(0.25, 5.95, -0.65), GOLD, M.Neon)
	local light = Instance.new("PointLight")
	light.Color = C(255, 210, 120)
	light.Range = 16
	light.Brightness = 1.2
	light.Parent = model:FindFirstChild("RiderHead")
end

return DecorModels
