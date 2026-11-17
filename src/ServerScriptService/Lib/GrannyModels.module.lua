--[[
	GrannyModels – trijų lygių močiučių modeliai iš Parts (pagal pateiktus dizaino paveikslėlius):
	  1 – Paprasta močiutė: raudona taškuota skarelė, rudi akiniai, žalias megztinis,
	      balta palaidinė su tautiniu raštu, ruda sijonas, prijuostė, krepšys su musmirėmis, žolės pagrindas.
	  2 – Superinė močiutė: geltoni plaukai, raudoni akiniai, žalias kostiumas su „M“ ženklu,
	      raudonas apsiaustas, raudonos kelnės ir batai, iškeltas kočėlas, mėlynas pagrindas su geltonu žiedu.
	  3 – Legendinė močiutė: violetinė kepurė su aukso taškais ir karūna, auksinė mantija,
	      bordo suknelė su auksiniais rombais, vėrinys, gintarinė lazda, sklandantys aukso kubeliai,
	      violetinis pagrindas su auksiniu žiedu.
	Modelio priekis – -Z. Kojos ant Y = 0, pagrindas žemiau (Y nuo -0,4 iki 0).
	Rankos sujungtos Motor6D (RightShoulder / LeftShoulder) – klientas jas animuoja.
]]

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material
local NormalId = Enum.NormalId

local GrannyModels = {}

local LT_YELLOW = C(253, 185, 19)
local LT_GREEN = C(0, 106, 68)
local LT_RED = C(193, 39, 45)
local AMBER = C(255, 150, 30)
local SKIN = C(240, 200, 165)
local TORSO_CF = CF(0, 2.75, 0)
local TORSO_SIZE = V(2, 1.9, 1)
local ARM_SIZE = V(0.95, 1.9, 0.95)
local HEAD_CF = CF(0, 4.6, 0)
local HEAD_SIZE = V(1.8, 1.8, 1.8)

----------------------------------------------------------------------
-- Pagalbinės
----------------------------------------------------------------------
local function part(model, name, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.Parent = model
	return p
end

local function weld(base, p)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = p
	w.Parent = p
end

local function mesh(p, meshType)
	local m = Instance.new("SpecialMesh")
	m.MeshType = meshType
	m.Parent = p
end

local function faceSize(p, face)
	local s = p.Size
	if face == NormalId.Front or face == NormalId.Back then
		return s.X, s.Y
	elseif face == NormalId.Left or face == NormalId.Right then
		return s.Z, s.Y
	end
	return s.X, s.Z
end

-- Plona plokštelė ant detalės paviršiaus (veidai, raštai, taškai – tikros 3D dalys).
-- u – į dešinę žiūrint į paviršių, v – aukštyn (studais nuo paviršiaus centro).
local function decal(base, face, u, v, w, h, color, opts)
	opts = opts or {}
	local t = opts.Thickness or 0.04
	local s = base.Size
	local angle = math.rad(opts.Rotation or 0)
	local offset, size, spin
	if face == NormalId.Front then
		offset, size, spin = CF(-u, v, -s.Z / 2 - t / 2), V(w, h, t), CFrame.Angles(0, 0, angle)
	elseif face == NormalId.Back then
		offset, size, spin = CF(u, v, s.Z / 2 + t / 2), V(w, h, t), CFrame.Angles(0, 0, angle)
	elseif face == NormalId.Right then
		offset, size, spin = CF(s.X / 2 + t / 2, v, -u), V(t, h, w), CFrame.Angles(angle, 0, 0)
	elseif face == NormalId.Left then
		offset, size, spin = CF(-s.X / 2 - t / 2, v, u), V(t, h, w), CFrame.Angles(angle, 0, 0)
	else -- Top
		offset, size, spin = CF(u, s.Y / 2 + t / 2, v), V(w, t, h), CFrame.Angles(0, angle, 0)
	end
	local shape = nil
	if opts.Round then
		shape = Enum.PartType.Cylinder
		if face == NormalId.Front or face == NormalId.Back then
			size, spin = V(t, h, w), CFrame.Angles(0, math.rad(90), 0)
		elseif face == NormalId.Top or face == NormalId.Bottom then
			size, spin = V(t, w, h), CFrame.Angles(0, 0, math.rad(90))
		else
			size, spin = V(t, h, w), CFrame.new()
		end
	end
	local d = part(base.Parent, opts.Name or "Detail", size, base.CFrame * offset * spin, color, opts.Material or M.SmoothPlastic, shape)
	d.CastShadow = false
	if opts.WeldTo then
		weld(opts.WeldTo, d)
	end
	return d
end

-- Linija ant priekinio paviršiaus nuo taško a iki b (Vector2: u, v)
local function frontLine(base, a, b, width, color, thickness, weldTo)
	-- Priekiniame paviršiuje u atitinka -X, todėl skaičiuojam detalės koordinatėmis
	local ax, bx = -a.X, -b.X
	local dx, dy = bx - ax, b.Y - a.Y
	local length = math.sqrt(dx * dx + dy * dy)
	local angle = math.atan2(-dx, dy)
	local t = thickness or 0.04
	local s = base.Size
	local cf = base.CFrame * CF((ax + bx) / 2, (a.Y + b.Y) / 2, -s.Z / 2 - t / 2) * CFrame.Angles(0, 0, angle)
	local d = part(base.Parent, "Detail", V(width, length + width * 0.6, t), cf, color, M.SmoothPlastic)
	d.CastShadow = false
	if weldTo then
		weld(weldTo, d)
	end
	return d
end

-- Taškai (skarelė, kepurė)
local function dots(p, faces, color, spacing, dotSize, weldTo)
	for _, faceId in ipairs(faces) do
		local w, h = faceSize(p, faceId)
		local cols = math.max(1, math.floor(w / spacing))
		local rows = math.max(1, math.floor(h / spacing))
		for j = 1, rows do
			local stagger = (j % 2 == 0) and 0.5 or 0
			for i = 1, cols do
				local u = -w / 2 + (i - 0.5 + stagger) * w / cols
				if u < w / 2 - dotSize / 2 then
					decal(p, faceId, u, h / 2 - (j - 0.5) * h / rows, dotSize, dotSize, color, { Round = true, Name = "Dot", Thickness = 0.03, WeldTo = weldTo })
				end
			end
		end
	end
end

-- Rombų juosta (tautinis raštas); y – 0 viršus … 1 apačia
local function diamondRow(p, faceId, color, count, y, size, weldTo)
	local w, h = faceSize(p, faceId)
	for i = 1, count do
		decal(p, faceId, -w / 2 + (i - 0.5) * w / count, h / 2 - y * h, size, size, color, { Rotation = 45, Name = "Pattern", WeldTo = weldTo })
	end
end

-- Rombų stulpelis (palaidinės juosta)
local function diamondColumn(p, faceId, color, count, size, weldTo)
	local w, h = faceSize(p, faceId)
	for i = 1, count do
		decal(p, faceId, 0, h / 2 - (i - 0.5) * h / count, size, size, color, { Rotation = 45, Name = "Pattern", WeldTo = weldTo })
	end
end

-- Veidas: akys, skruostai, šypsena ir (nebūtini) akiniai – tikros 3D dalys
local function face(head, glassesColor)
	local F = NormalId.Front
	local ink = C(40, 28, 22)
	local smile = C(150, 45, 50)
	for _, u in ipairs({ -0.32, 0.32 }) do
		decal(head, F, u, 0.02, 0.17, 0.21, ink, { Name = "Eye", Thickness = 0.03 })
		decal(head, F, u + 0.04, 0.07, 0.05, 0.05, C(255, 255, 255), { Name = "EyeShine", Thickness = 0.045 })
	end
	for _, u in ipairs({ -0.58, 0.58 }) do
		decal(head, F, u, -0.3, 0.3, 0.16, C(255, 140, 150), { Name = "Cheek", Thickness = 0.025 })
	end
	frontLine(head, Vector2.new(-0.16, -0.48), Vector2.new(0.16, -0.48), 0.08, smile)
	frontLine(head, Vector2.new(-0.16, -0.48), Vector2.new(-0.29, -0.38), 0.08, smile)
	frontLine(head, Vector2.new(0.16, -0.48), Vector2.new(0.29, -0.38), 0.08, smile)
	if glassesColor then
		local t = 0.06
		for _, u in ipairs({ -0.32, 0.32 }) do
			decal(head, F, u, 0.21, 0.5, 0.07, glassesColor, { Name = "Glasses", Thickness = t })
			decal(head, F, u, -0.17, 0.5, 0.07, glassesColor, { Name = "Glasses", Thickness = t })
			decal(head, F, u - 0.215, 0.02, 0.07, 0.38, glassesColor, { Name = "Glasses", Thickness = t })
			decal(head, F, u + 0.215, 0.02, 0.07, 0.38, glassesColor, { Name = "Glasses", Thickness = t })
		end
		decal(head, F, 0, 0.08, 0.12, 0.06, glassesColor, { Name = "Glasses", Thickness = t })
	end
end

-- Ranka su Motor6D. side: 1 = +X, -1 = -X. pose – pasukimas peties taške.
local function arm(model, torso, side, sleeveColor, handColor, pose, swingAmp, cuffColor)
	local jointName = side == 1 and "RightShoulder" or "LeftShoulder"
	local c0 = CF(side * 1.475, 0.85, 0) * pose
	local c1 = CF(0, 0.85, 0)
	local armCF = TORSO_CF * c0 * c1:Inverse()
	local sleeve = part(model, side == 1 and "RightArm" or "LeftArm", ARM_SIZE, armCF, sleeveColor, M.Fabric)
	local hand = part(model, "Hand", V(0.98, 0.45, 0.98), armCF * CF(0, -0.725, 0), handColor)
	weld(sleeve, hand)
	if cuffColor then
		local cuff = part(model, "Cuff", V(1.02, 0.16, 1.02), armCF * CF(0, -0.45, 0), cuffColor, M.Metal)
		weld(sleeve, cuff)
	end
	local motor = Instance.new("Motor6D")
	motor.Name = jointName
	motor.Part0 = torso
	motor.Part1 = sleeve
	motor.C0 = c0
	motor.C1 = c1
	motor:SetAttribute("SwingAmp", swingAmp or 0.2)
	motor:SetAttribute("SwingBias", 0)
	motor.Parent = sleeve
	return sleeve, armCF
end

local function newRig(name)
	local model = Instance.new("Model")
	model.Name = name
	local root = part(model, "HumanoidRootPart", V(2, 2, 1), TORSO_CF, C(255, 255, 255))
	root.Transparency = 1
	root.Anchored = true
	model.PrimaryPart = root
	return model, root
end

local function finish(model, root)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root and not d:FindFirstChildOfClass("WeldConstraint") and not d:FindFirstChildOfClass("Motor6D") then
			weld(root, d)
		end
	end
	model.WorldPivot = CF()
	return model
end

----------------------------------------------------------------------
-- 1. Paprasta močiutė
----------------------------------------------------------------------
local function simple()
	local model, root = newRig("Granny_1")
	local green = C(62, 120, 72)
	local red = C(200, 38, 40)
	local white = C(248, 242, 230)

	-- Pagrindas: žolė ant žemės
	part(model, "BaseDirt", V(3.2, 0.32, 3.2), CF(0, -0.24, 0), C(122, 82, 46), M.Ground)
	part(model, "BaseGrass", V(3.2, 0.1, 3.2), CF(0, -0.05, 0), C(118, 178, 84), M.Grass)

	-- Batai, sijonas, prijuostė
	for _, x in ipairs({ -0.5, 0.5 }) do
		part(model, "Shoe", V(0.95, 0.42, 1.05), CF(x, 0.21, -0.05), C(85, 52, 32))
	end
	part(model, "Skirt", V(2.1, 1.4, 1.15), CF(0, 1.1, 0), C(118, 74, 42), M.Fabric)
	local apron = part(model, "Apron", V(1.5, 1.3, 0.06), CF(0, 1.12, -0.6), white, M.Fabric)
	diamondRow(apron, NormalId.Front, red, 6, 0.82, 0.16)
	diamondRow(apron, NormalId.Front, red, 6, 0.12, 0.12)

	-- Liemuo: žalias megztinis, balta palaidinė su tautiniu raštu, sagos
	local torso = part(model, "Torso", TORSO_SIZE, TORSO_CF, green, M.Fabric)
	local blouse = part(model, "Blouse", V(0.8, 1.85, 0.06), CF(0, 2.75, -0.53), white, M.Fabric)
	diamondColumn(blouse, NormalId.Front, red, 7, 0.18)
	for i = 0, 3 do
		part(model, "Button", V(0.14, 0.14, 0.14), CF(0.55, 3.35 - i * 0.38, -0.53), white, M.SmoothPlastic, Enum.PartType.Ball)
	end
	local waist = part(model, "WaistBand", V(2.04, 0.24, 1.04), CF(0, 1.9, 0), white, M.Fabric)
	diamondRow(waist, NormalId.Front, red, 9, 0.5, 0.15)

	-- Rankos: viena į priekį, kita laiko krepšį
	arm(model, torso, 1, green, SKIN, CFrame.Angles(math.rad(30), 0, 0), 0.25)
	local basketArm, basketCF = arm(model, torso, -1, green, SKIN, CFrame.Angles(math.rad(20), 0, 0), 0.06)
	local handCF = basketCF * CF(0, -1.05, -0.2)
	local basket = part(model, "Basket", V(1.25, 0.75, 1.0), CF(handCF.Position + V(-0.35, -0.35, 0)), C(205, 160, 90), M.WoodPlanks)
	weld(basketArm, basket)
	-- Pinto krepšio raštas
	for i = 1, 3 do
		decal(basket, NormalId.Front, 0, 0.375 - i * 0.1875, 1.25, 0.06, C(150, 105, 50), { WeldTo = basketArm })
	end
	for i = 1, 4 do
		decal(basket, NormalId.Front, -0.625 + i * 0.25, 0, 0.06, 0.75, C(150, 105, 50), { WeldTo = basketArm })
	end
	local handle = part(model, "BasketHandle", V(0.12, 0.8, 0.12), basket.CFrame * CF(0, 0.7, 0), C(150, 105, 50), M.Wood)
	weld(basketArm, handle)
	for i, offset in ipairs({ V(-0.3, 0.45, -0.15), V(0.15, 0.48, 0.1), V(0.35, 0.42, -0.2) }) do
		local base = basket.CFrame * CF(offset)
		local stem = part(model, "MushroomStem", V(0.14, 0.22, 0.14), base, white)
		local cap = part(model, "MushroomCap", V(0.42, 0.24, 0.42), base * CF(0, 0.16, 0), red)
		mesh(cap, Enum.MeshType.Sphere)
		local dot = part(model, "MushroomDot", V(0.07, 0.07, 0.07), base * CF(0.06 * i - 0.1, 0.28, -0.08), white, M.SmoothPlastic, Enum.PartType.Ball)
		for _, p in ipairs({ stem, cap, dot }) do
			weld(basketArm, p)
		end
	end

	-- Galva: veidas su rudais akiniais, raudona taškuota skarelė su mazgu
	local head = part(model, "Head", HEAD_SIZE, HEAD_CF, SKIN)
	face(head, C(110, 70, 40))
	local scarfTop = part(model, "ScarfTop", V(2.0, 0.45, 2.0), CF(0, 5.6, 0.02), red, M.Fabric)
	local scarfBack = part(model, "ScarfBack", V(2.0, 1.95, 0.22), CF(0, 4.62, 0.98), red, M.Fabric)
	local scarfL = part(model, "ScarfSide", V(0.14, 1.55, 1.95), CF(0.97, 4.82, 0.02), red, M.Fabric)
	local scarfR = part(model, "ScarfSide", V(0.14, 1.55, 1.95), CF(-0.97, 4.82, 0.02), red, M.Fabric)
	dots(scarfTop, { NormalId.Top }, white, 0.42, 0.13)
	dots(scarfBack, { NormalId.Back }, white, 0.42, 0.13)
	dots(scarfL, { NormalId.Right }, white, 0.42, 0.13)
	dots(scarfR, { NormalId.Left }, white, 0.42, 0.13)
	-- Taškeliai ir ant skarelės krašto virš kaktos
	for i = 1, 5 do
		decal(scarfTop, NormalId.Front, -0.8 + (i - 1) * 0.4, 0, 0.13, 0.13, white, { Round = true, Thickness = 0.03 })
	end
	part(model, "ScarfKnot", V(0.42, 0.42, 0.2), CF(0, 3.62, -0.62) * CFrame.Angles(0, 0, math.rad(45)), C(170, 30, 35), M.Fabric)
	-- Lietuviška atributika: gintarinė sagė ir trispalvis kaspinėlis ant krepšio rankenos
	part(model, "AmberBrooch", V(0.26, 0.3, 0.1), CF(0.42, 3.35, -0.58) * CFrame.Angles(0, 0, math.rad(45)), AMBER, M.Glass)
	part(model, "BroochRim", V(0.32, 0.36, 0.06), CF(0.42, 3.35, -0.55) * CFrame.Angles(0, 0, math.rad(45)), C(200, 160, 60), M.Metal)
	local bowCF = handle.CFrame * CF(0, 0.38, -0.08)
	for i, color in ipairs({ LT_YELLOW, LT_GREEN, LT_RED }) do
		local stripe = part(model, "RibbonStripe", V(0.5, 0.07, 0.05), bowCF * CF(0, 0.07 - (i - 1) * 0.07, -0.02), color, M.Fabric)
		weld(basketArm, stripe)
	end
	for _, side in ipairs({ -1, 1 }) do
		local tail = part(model, "RibbonTail", V(0.08, 0.32, 0.04), bowCF * CF(side * 0.12, -0.2, -0.02) * CFrame.Angles(0, 0, side * math.rad(15)), LT_RED, M.Fabric)
		weld(basketArm, tail)
	end
	return finish(model, root)
end

----------------------------------------------------------------------
-- 2. Superinė močiutė
----------------------------------------------------------------------
local function super()
	local model, root = newRig("Granny_2")
	local green = C(38, 140, 72)
	local red = C(205, 42, 42)
	local darkRed = C(150, 25, 32)
	local yellow = C(255, 196, 30)

	-- Pagrindas: mėlynas su geltonu žiedu
	part(model, "Base", V(3.4, 0.36, 3.4), CF(0, -0.22, 0), C(42, 58, 100), M.SmoothPlastic)
	part(model, "BaseRing", V(0.04, 3.0, 3.0), CF(0, -0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), yellow, M.Neon, Enum.PartType.Cylinder)
	part(model, "BaseRingInner", V(0.05, 2.7, 2.7), CF(0, -0.015, 0) * CFrame.Angles(0, 0, math.rad(90)), C(42, 58, 100), M.SmoothPlastic, Enum.PartType.Cylinder)
	part(model, "BaseStripe", V(3.42, 0.08, 0.1), CF(0, -0.12, -1.68), yellow, M.Neon)

	-- Batai, kelnės, diržas
	for _, x in ipairs({ -0.5, 0.5 }) do
		part(model, "Boot", V(0.95, 0.55, 1.05), CF(x, 0.275, -0.03), red)
	end
	part(model, "BootBand", V(2.02, 0.1, 1.08), CF(0, 0.6, 0), yellow, M.SmoothPlastic)
	part(model, "Legs", V(2.0, 1.1, 1.05), CF(0, 1.2, 0), red, M.Fabric)
	part(model, "LegStripe", V(2.02, 0.08, 1.07), CF(0, 0.95, 0), yellow, M.SmoothPlastic)
	part(model, "Belt", V(2.04, 0.18, 1.06), CF(0, 1.78, 0), yellow, M.SmoothPlastic)

	-- Liemuo su „M“ ženklu ir apsiaustas
	local torso = part(model, "Torso", TORSO_SIZE, TORSO_CF, green, M.Fabric)
	part(model, "EmblemRim", V(0.05, 1.3, 1.3), CF(0, 2.9, -0.52) * CFrame.Angles(0, math.rad(90), 0), red, M.SmoothPlastic, Enum.PartType.Cylinder)
	local emblem = part(model, "Emblem", V(0.07, 1.12, 1.12), CF(0, 2.9, -0.54) * CFrame.Angles(0, math.rad(90), 0), yellow, M.SmoothPlastic, Enum.PartType.Cylinder)
	-- Raudona raidė „M“ ant geltono apskritimo (tikros dalys)
	local plate = part(model, "EmblemPlate", V(1.0, 1.0, 0.02), CF(0, 2.9, -0.58), yellow, M.SmoothPlastic)
	plate.Transparency = 1
	frontLine(plate, Vector2.new(-0.26, -0.3), Vector2.new(-0.26, 0.28), 0.12, red, 0.05)
	frontLine(plate, Vector2.new(0.26, -0.3), Vector2.new(0.26, 0.28), 0.12, red, 0.05)
	frontLine(plate, Vector2.new(-0.26, 0.28), Vector2.new(0, -0.05), 0.12, red, 0.05)
	frontLine(plate, Vector2.new(0.26, 0.28), Vector2.new(0, -0.05), 0.12, red, 0.05)
	part(model, "Collar", V(2.2, 0.22, 1.2), CF(0, 3.75, 0.05), darkRed, M.Fabric)
	local cape = part(model, "Cape", V(2.15, 3.2, 0.14), CF(0, 2.15, 0.66) * CFrame.Angles(math.rad(-9), 0, 0), darkRed, M.Fabric)
	-- Lietuviška atributika: trispalvė diržo sagtis ir trispalvės juostos ant apsiausto
	part(model, "BuckleRim", V(0.82, 0.56, 0.05), CF(0, 1.78, -0.565), C(220, 180, 60), M.Metal)
	for i, color in ipairs({ LT_YELLOW, LT_GREEN, LT_RED }) do
		part(model, "BuckleStripe", V(0.7, 0.15, 0.05), CF(0, 1.93 - (i - 1) * 0.15, -0.6), color, M.SmoothPlastic)
		decal(cape, NormalId.Back, 0, -0.9 - (i - 1) * 0.22, 2.15, 0.22, color, { Name = "CapeStripe", Thickness = 0.03 })
	end

	-- Rankos: viena iškelta su kočėlu, kita nuleista; raudonos pirštinės
	local raised, raisedCF = arm(model, torso, 1, green, red, CFrame.Angles(0, 0, math.rad(155)), 0.3)
	arm(model, torso, -1, green, red, CFrame.Angles(math.rad(15), 0, math.rad(-12)), 0.2)
	-- Kočėlas skersai iškeltos rankos (kaip kortelėje)
	local pinCF = raisedCF * CF(0, -1.2, 0) * CFrame.Angles(0, 0, math.rad(-10))
	local pin = part(model, "RollingPin", V(2.4, 0.42, 0.42), pinCF, C(225, 180, 120), M.Wood, Enum.PartType.Cylinder)
	weld(raised, pin)
	for _, x in ipairs({ -1.45, 1.45 }) do
		local h = part(model, "PinHandle", V(0.5, 0.2, 0.2), pinCF * CF(x, 0, 0), C(140, 90, 50), M.Wood, Enum.PartType.Cylinder)
		weld(raised, h)
	end

	-- Galva: raudoni akiniai, geltoni plaukai
	local head = part(model, "Head", HEAD_SIZE, HEAD_CF, SKIN)
	face(head, C(220, 40, 40))
	part(model, "HairTop", V(2.0, 0.5, 2.0), CF(0, 5.55, 0.02), yellow, M.SmoothPlastic)
	part(model, "HairBack", V(2.0, 1.75, 0.3), CF(0, 4.7, 0.95), yellow, M.SmoothPlastic)
	part(model, "HairSide", V(0.15, 1.1, 1.9), CF(0.96, 5.0, 0.05), yellow, M.SmoothPlastic)
	part(model, "HairSide", V(0.15, 1.1, 1.9), CF(-0.96, 5.0, 0.05), yellow, M.SmoothPlastic)
	part(model, "HairBangs", V(2.0, 0.3, 0.14), CF(0, 5.33, -0.93), yellow, M.SmoothPlastic)
	return finish(model, root)
end

----------------------------------------------------------------------
-- 3. Legendinė močiutė
----------------------------------------------------------------------
local function legendary()
	local model, root = newRig("Granny_3")
	local maroon = C(125, 28, 50)
	local gold = C(240, 190, 55)
	local purple = C(88, 40, 145)
	local cream = C(248, 238, 218)
	local amber = C(255, 150, 30)

	-- Pagrindas: tamsiai violetinis su auksiniu žiedu ir švytėjimu
	local base = part(model, "Base", V(3.4, 0.36, 3.4), CF(0, -0.22, 0), C(48, 32, 75), M.SmoothPlastic)
	part(model, "BaseRing", V(0.04, 3.0, 3.0), CF(0, -0.02, 0) * CFrame.Angles(0, 0, math.rad(90)), gold, M.Neon, Enum.PartType.Cylinder)
	part(model, "BaseRingInner", V(0.05, 2.7, 2.7), CF(0, -0.015, 0) * CFrame.Angles(0, 0, math.rad(90)), C(48, 32, 75), M.SmoothPlastic, Enum.PartType.Cylinder)
	local glow = Instance.new("PointLight")
	glow.Color = C(255, 200, 90)
	glow.Range = 12
	glow.Brightness = 1.6
	glow.Parent = base

	-- Suknelė su auksiniais rombais
	local dress = part(model, "Dress", V(2.3, 1.8, 1.35), CF(0, 0.9, 0), maroon, M.Fabric)
	local panel = part(model, "DressPanel", V(1.1, 1.5, 0.06), CF(0, 1.0, -0.7), cream, M.Fabric)
	diamondRow(panel, NormalId.Front, maroon, 4, 0.85, 0.16)

	local hem = part(model, "DressHem", V(2.34, 0.36, 1.39), CF(0, 0.2, 0), maroon, M.Fabric)
	for _, faceId in ipairs({ NormalId.Front, NormalId.Back, NormalId.Left, NormalId.Right }) do
		diamondRow(hem, faceId, gold, 9, 0.5, 0.2)
	end
	part(model, "Belt", V(2.1, 0.2, 1.1), CF(0, 1.85, 0), gold, M.Metal)

	-- Liemuo, auksinė mantija, vėrinys
	local torso = part(model, "Torso", TORSO_SIZE, TORSO_CF, maroon, M.Fabric)
	part(model, "Mantle", V(2.45, 2.9, 0.2), CF(0, 2.45, 0.64) * CFrame.Angles(math.rad(-6), 0, 0), gold, M.Fabric)
	-- Lietuviška atributika: auksiniai Gedimino stulpai ant raudono skydo (atviroje liemens pusėje)
	do
		local F = NormalId.Front
		local u0, v0 = -0.42, -0.32
		decal(torso, F, u0, v0 + 0.04, 0.66, 0.66, gold, { Name = "ShieldRim", Thickness = 0.03 })
		decal(torso, F, u0, v0 + 0.04, 0.58, 0.58, LT_RED, { Name = "Shield", Thickness = 0.05 })
		decal(torso, F, u0, v0 - 0.28, 0.3, 0.3, LT_RED, { Name = "Shield", Thickness = 0.05, Rotation = 45 })
		local g = { Name = "Gediminas", Thickness = 0.09 }
		decal(torso, F, u0, v0 - 0.12, 0.42, 0.07, gold, g)            -- pagrindas
		decal(torso, F, u0, v0 + 0.06, 0.08, 0.32, gold, g)            -- vidurinis stulpas
		decal(torso, F, u0, v0 + 0.24, 0.26, 0.07, gold, g)            -- jo viršus
		decal(torso, F, u0 - 0.15, v0 - 0.01, 0.08, 0.2, gold, g)      -- šoniniai stulpai
		decal(torso, F, u0 + 0.15, v0 - 0.01, 0.08, 0.2, gold, g)
		decal(torso, F, u0 - 0.15, v0 + 0.11, 0.15, 0.06, gold, g)
		decal(torso, F, u0 + 0.15, v0 + 0.11, 0.15, 0.06, gold, g)
	end
	part(model, "Yoke", V(2.5, 0.34, 1.25), CF(0, 3.72, 0.05), gold, M.Fabric)
	-- Didelė auksinė mantijos dalis per priekį iki suknelės apačios
	part(model, "MantleFront", V(1.05, 3.4, 0.1), CF(-0.6, 2.0, -0.72) * CFrame.Angles(0, 0, math.rad(-4)), gold, M.Fabric)
	part(model, "Chain", V(0.9, 0.07, 0.06), CF(-0.25, 3.35, -0.53) * CFrame.Angles(0, 0, math.rad(-35)), gold, M.Metal)
	part(model, "Chain", V(0.9, 0.07, 0.06), CF(0.25, 3.35, -0.53) * CFrame.Angles(0, 0, math.rad(35)), gold, M.Metal)
	part(model, "Pendant", V(0.32, 0.32, 0.1), CF(0, 3.05, -0.56) * CFrame.Angles(0, 0, math.rad(45)), C(150, 30, 70), M.Glass)

	-- Rankos: viena laiko lazdą, kita mosteli
	local staffArm, staffArmCF = arm(model, torso, 1, maroon, SKIN, CFrame.Angles(math.rad(35), 0, 0), 0.04, gold)
	arm(model, torso, -1, maroon, SKIN, CFrame.Angles(math.rad(40), 0, math.rad(-25)), 0.22, gold)
	local handPos = (staffArmCF * CF(0, -0.75, 0)).Position
	local staff = part(model, "Staff", V(0.24, 6.3, 0.24), CF(handPos.X + 0.1, 2.95, handPos.Z), gold, M.Metal)
	weld(staffArm, staff)
	local topCF = staff.CFrame * CF(0, 3.35, 0)
	local cage = part(model, "StaffTop", V(0.75, 0.12, 0.75), topCF * CF(0, -0.4, 0), gold, M.Metal)
	local gem = part(model, "AmberGem", V(0.55, 0.65, 0.55), topCF, amber, M.Neon)
	weld(staffArm, cage)
	weld(staffArm, gem)
	for _, offset in ipairs({ V(0.32, 0, 0.32), V(-0.32, 0, 0.32), V(0.32, 0, -0.32), V(-0.32, 0, -0.32) }) do
		local bar = part(model, "StaffBar", V(0.08, 0.8, 0.08), topCF * CF(offset), gold, M.Metal)
		weld(staffArm, bar)
	end

	-- Galva: violetinė kepurė su aukso taškais ir karūna
	local head = part(model, "Head", HEAD_SIZE, HEAD_CF, SKIN)
	face(head, nil)
	local hat = part(model, "Hat", V(1.9, 1.35, 1.9), CF(0, 6.2, 0), purple, M.Fabric)
	dots(hat, { NormalId.Front, NormalId.Back, NormalId.Left, NormalId.Right }, gold, 0.38, 0.12)
	part(model, "CrownGem", V(0.34, 0.34, 0.1), CF(0, 7.05, -0.98), amber, M.Neon)
	for i = 0, 7 do
		local angle = i * math.pi / 4
		local r = 0.85
		part(model, "CrownPoint", V(0.32, 0.4, 0.32), CF(math.cos(angle) * r, 7.05, math.sin(angle) * r), gold, M.Metal)
	end
	part(model, "CrownRim", V(2.0, 0.14, 2.0), CF(0, 6.88, 0), gold, M.Metal)

	-- Sklandantys aukso kubeliai (juos judina klientas)
	local bits = { V(-1.9, 1.4, -0.6), V(1.9, 2.6, -0.4), V(-1.6, 4.2, 0.8), V(1.7, 5.4, 0.6), V(-0.8, 6.4, -1.2), V(1.2, 1.0, 1.2) }
	for i, offset in ipairs(bits) do
		local bit = part(model, "FloatBit", V(0.26, 0.26, 0.26), CF(offset) * CFrame.Angles(i, i * 0.5, 0), gold, M.Neon)
		bit.Anchored = true
		bit.CastShadow = false
	end
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new(C(255, 220, 100))
	sparkles.Size = NumberSequence.new(0.35, 0)
	sparkles.Lifetime = NumberRange.new(0.8, 1.4)
	sparkles.Rate = 6
	sparkles.Speed = NumberRange.new(0.5, 1.5)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.LightEmission = 1
	sparkles.Parent = torso

	model = finish(model, root)
	-- Sklandantys kubeliai neprivirinami (klientas juos judina atskirai)
	for _, d in ipairs(model:GetDescendants()) do
		if d.Name == "FloatBit" then
			local w = d:FindFirstChildOfClass("WeldConstraint")
			if w then
				w:Destroy()
			end
		end
	end
	return model
end

local BUILDERS = { simple, super, legendary }

function GrannyModels.Build(level)
	local builder = BUILDERS[level] or simple
	return builder()
end

return GrannyModels
