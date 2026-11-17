--[[
	TitleItems – atributika pagal rebirth titulą (dėvima ant veikėjo, matoma visiems).
	Kuo aukštesnis titulas, tuo daugiau daiktų atrakinta (jie kaupiasi):
	  Virtuvės padavėjas (0)    – baltas prijuostė su tautiniu raštu (iki Bajoro)
	  Cepelinų meistras (1)     – medinis šaukštas prie diržo
	  Kaimo šefas (3)           – aukšta šefo kepurė (iki karūnos)
	  Močiutės anūkas (5)       – megztas šalikas su tautiniu raštu
	  Bajoras (10)              – raudonas apsiaustas (prijuostė nusiimama)
	  Kunigaikštis (25)         – auksinė grandinė su Vyčio medalionu ir kardas prie šono
	  Vytautas Didysis (50)     – auksu apvadžiotas apsiaustas (+ karūna iš RebirthService)

	TitleItems.Apply(character, rebirths) – perpiešia aplanką "TitleItems" veikėjuje.
	TitleItems.Unlocked(rebirths) – sąrašas { Key = "TitleItem_..." } (pranešimams).
]]

local Build = require(script.Parent:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local RED = C(193, 39, 45)
local GREEN = C(0, 106, 68)
local YELLOW = C(253, 185, 19)
local GOLD = C(240, 195, 60)

local TitleItems = {}

-- Daiktų sąrašas: nuo kiek rebirth ir iki kiek (Until – neįskaitant)
TitleItems.List = {
	{ Id = "Apron", At = 0, Until = 10, Key = "TitleItem_Apron" },
	{ Id = "Spoon", At = 1, Key = "TitleItem_Spoon" },
	{ Id = "ChefHat", At = 3, Until = 50, Key = "TitleItem_ChefHat" },
	{ Id = "Scarf", At = 5, Key = "TitleItem_Scarf" },
	{ Id = "Cape", At = 10, Key = "TitleItem_Cape" },
	{ Id = "Medallion", At = 25, Key = "TitleItem_Medallion" },
	{ Id = "Sword", At = 25, Key = "TitleItem_Sword" },
}

local function attach(folder, anchor, name, size, offset, color, material, shape, meshType)
	local part = Build.Part({
		Name = name, Parent = folder, Size = size, CFrame = anchor.CFrame * offset, Color = color,
		Material = material or M.SmoothPlastic, Shape = shape, Anchored = false, CanCollide = false,
		CanQuery = false, CanTouch = false, Massless = true, CastShadow = false,
	})
	if meshType then
		Build.Mesh(part, meshType)
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = part
	weld.Parent = part
	return part
end

local BUILD = {}

BUILD.Apron = function(folder, torso, lower)
	local anchor = lower or torso
	local y = lower and 0 or -0.6
	attach(folder, anchor, "TitleApron", V(1.5, 1.3, 0.08), CF(0, y - 0.15, -anchor.Size.Z / 2 - 0.05), C(248, 246, 238), M.Fabric)
	for i = 0, 4 do
		local color = i % 2 == 0 and RED or GREEN
		attach(folder, anchor, "TitleApronPattern", V(0.2, 0.2, 0.04), CF(-0.5 + i * 0.25, y - 0.65, -anchor.Size.Z / 2 - 0.1) * CFrame.Angles(0, 0, math.rad(45)), color, M.Fabric)
	end
	attach(folder, torso, "TitleApronStrap", V(1.2, 0.12, 0.06), CF(0, -0.2, -torso.Size.Z / 2 - 0.04), C(248, 246, 238), M.Fabric)
end

BUILD.Spoon = function(folder, torso, lower)
	local anchor = lower or torso
	local side = anchor.Size.X / 2 + 0.08
	local y = lower and 0 or -0.7
	attach(folder, anchor, "TitleSpoonHandle", V(0.12, 1.4, 0.12), CF(side, y, 0.1) * CFrame.Angles(0, 0, math.rad(-12)), C(190, 140, 80), M.Wood)
	attach(folder, anchor, "TitleSpoonBowl", V(0.38, 0.5, 0.16), CF(side + 0.15, y - 0.75, 0.1), C(190, 140, 80), M.Wood, nil, Enum.MeshType.Sphere)
end

BUILD.ChefHat = function(folder, _, _, head)
	if not head then
		return
	end
	attach(folder, head, "TitleChefBand", V(0.5, 1.3, 1.3), CF(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), C(250, 250, 250), M.Fabric, Enum.PartType.Cylinder)
	attach(folder, head, "TitleChefPuff", V(1.6, 1.3, 1.6), CF(0, 1.45, 0), C(255, 255, 255), M.Fabric, nil, Enum.MeshType.Sphere)
end

BUILD.Scarf = function(folder, torso)
	local top = torso.Size.Y / 2
	attach(folder, torso, "TitleScarf", V(1.4, 0.35, 1.15), CF(0, top - 0.05, 0), RED, M.Fabric)
	attach(folder, torso, "TitleScarfEnd", V(0.35, 1.1, 0.1), CF(0.35, top - 0.65, -torso.Size.Z / 2 - 0.08), RED, M.Fabric)
	for i = 0, 2 do
		attach(folder, torso, "TitleScarfStripe", V(0.36, 0.1, 0.11), CF(0.35, top - 0.35 - i * 0.3, -torso.Size.Z / 2 - 0.09), i == 1 and GREEN or YELLOW, M.Fabric)
	end
end

local function cape(folder, torso, trim)
	local top = torso.Size.Y / 2
	attach(folder, torso, "TitleCape", V(1.9, 2.8, 0.1), CF(0, top - 1.45, torso.Size.Z / 2 + 0.12) * CFrame.Angles(math.rad(6), 0, 0), C(150, 25, 35), M.Fabric)
	attach(folder, torso, "TitleCapeCollar", V(1.9, 0.3, 0.5), CF(0, top - 0.05, torso.Size.Z / 2 - 0.05), trim and GOLD or C(245, 240, 230), trim and M.Metal or M.Fabric)
	if trim then
		attach(folder, torso, "TitleCapeTrim", V(1.92, 0.18, 0.12), CF(0, top - 2.85, torso.Size.Z / 2 + 0.27) * CFrame.Angles(math.rad(6), 0, 0), GOLD, M.Metal)
	end
end

BUILD.Cape = function(folder, torso, _, _, rebirths)
	cape(folder, torso, rebirths >= 50)
end

BUILD.Medallion = function(folder, torso)
	local top = torso.Size.Y / 2
	local front = -torso.Size.Z / 2 - 0.07
	for i = -3, 3 do
		attach(folder, torso, "TitleChain", V(0.14, 0.14, 0.06), CF(i * 0.16, top - 0.25 - (3 - math.abs(i)) * 0.09, front), GOLD, M.Metal)
	end
	attach(folder, torso, "TitleMedallion", V(0.12, 0.5, 0.5), CF(0, top - 0.75, front - 0.02) * CFrame.Angles(0, math.rad(90), 0), GOLD, M.Metal, Enum.PartType.Cylinder)
	attach(folder, torso, "TitleMedallionVytis", V(0.25, 0.28, 0.04), CF(0, top - 0.75, front - 0.1), RED, M.SmoothPlastic)
end

BUILD.Sword = function(folder, torso, lower)
	local anchor = lower or torso
	local side = -(anchor.Size.X / 2 + 0.1)
	local y = lower and -0.3 or -1
	attach(folder, anchor, "TitleScabbard", V(0.2, 2.2, 0.3), CF(side, y - 0.6, 0.15) * CFrame.Angles(math.rad(-15), 0, math.rad(8)), C(70, 40, 25), M.Wood)
	attach(folder, anchor, "TitleHilt", V(0.6, 0.12, 0.14), CF(side, y + 0.55, -0.15) * CFrame.Angles(math.rad(-15), 0, math.rad(8)), GOLD, M.Metal)
	attach(folder, anchor, "TitleGrip", V(0.12, 0.45, 0.12), CF(side, y + 0.8, -0.22) * CFrame.Angles(math.rad(-15), 0, math.rad(8)), C(110, 60, 30), M.Fabric)
end

local function isActive(item, rebirths)
	return rebirths >= item.At and (not item.Until or rebirths < item.Until)
end

function TitleItems.Apply(character, rebirths)
	rebirths = rebirths or 0
	local old = character:FindFirstChild("TitleItems")
	if old then
		old:Destroy()
	end
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not torso then
		return
	end
	local lower = character:FindFirstChild("LowerTorso")
	local head = character:FindFirstChild("Head")
	local folder = Instance.new("Model")
	folder.Name = "TitleItems"
	for _, item in ipairs(TitleItems.List) do
		if isActive(item, rebirths) and BUILD[item.Id] then
			pcall(BUILD[item.Id], folder, torso, lower, head, rebirths)
		end
	end
	folder.Parent = character
end

-- Daiktai, atrakinti būtent šiuo rebirth (kai titulas pasikeičia)
function TitleItems.NewlyUnlocked(oldRebirths, newRebirths)
	local list = {}
	for _, item in ipairs(TitleItems.List) do
		if item.At > (oldRebirths or 0) and item.At <= newRebirths then
			table.insert(list, item)
		end
	end
	return list
end

return TitleItems
