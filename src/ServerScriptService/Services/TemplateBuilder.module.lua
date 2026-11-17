--[[
	TemplateBuilder – modelių šablonai ServerStorage/Templates.

	Kodas modelius randa PAGAL PAVADINIMĄ:
	  Templates/Plot                     – sklypas (Floor, Fence, GateBeam, ClaimPad, PlotSpawn, Zones/Zone_<Linija>)
	  Templates/Machines/Dropper_<Linija> – dropper'is (turi turėti dalį "DropPoint")
	  Templates/Machines/Conveyor_<Linija> – konvejeris (dalis "Belt")
	  Templates/Machines/Sell_<Linija>   – pardavimo langelis
	  Templates/Machines/<pirkinio ID>   – upgrader'is / statula (pvz. "Cepelinai_3")
	  Templates/Machines/GrannyTable, Shelf, Flag
	  Templates/Items/Item_<Linija>      – žaliava (viena Part)
	Jei modelio nėra – sugeneruojamas paprastas placeholder'is iš Parts.
	Norėdamas pakeisti gražesniu: įdėk savo modelį tuo pačiu pavadinimu (Pivot – apačios centre,
	konvejerio kryptis -Z).
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local ProductLines = require(Config:WaitForChild("ProductLines"))
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local Scenery = require(Lib:WaitForChild("Scenery"))
local DecorModels = require(Lib:WaitForChild("DecorModels"))

local L = Settings.Layout
local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local WOOD = C(122, 82, 46)
local DARK_WOOD = C(78, 50, 26)
local STONE = C(128, 126, 120)
local GOLD = C(255, 200, 50)

local TemplateBuilder = {}

local templates, machines, items

local function ensureFolder(parent, name, className)
	local folder = parent:FindFirstChild(name)
	if not folder then
		folder = Instance.new(className or "Folder")
		folder.Name = name
		folder.Parent = parent
	end
	return folder
end

local function finish(model, parent)
	model.WorldPivot = CF()
	model.Parent = parent
	return model
end

----------------------------------------------------------------------
-- Sklypas
----------------------------------------------------------------------
local function buildPlot(model)
	local half = L.PlotSize / 2
	local skin = Settings.Skins.Default

	Build.Part({ Name = "Floor", Parent = model, Size = V(L.PlotSize, 1, L.PlotSize), CFrame = CF(0, -0.5, 0), Color = skin.Floor, Material = skin.FloorMaterial })

	-- Tvora
	local fence = Build.Folder("Fence", model)
	local gateHalf = L.GateWidth / 2 + 2
	local step = 10
	local function post(x, z)
		Build.Part({ Name = "Post", Parent = fence, Size = V(1, 4, 1), CFrame = CF(x, 2, z), Color = skin.Fence, Material = skin.FenceMaterial })
	end
	local function rail(a, b)
		local mid = (a + b) / 2
		local length = (b - a).Magnitude
		for _, y in ipairs({ 1.4, 2.9 }) do
			Build.Part({ Name = "Rail", Parent = fence, Size = V(0.4, 0.4, length), CFrame = CFrame.lookAt(V(mid.X, y, mid.Z), V(b.X, y, b.Z)), Color = skin.Fence, Material = skin.FenceMaterial })
		end
	end
	for i = -half, half - step, step do
		-- galas (+Z), šonai (±X)
		rail(V(i, 0, half), V(i + step, 0, half))
		rail(V(half, 0, i), V(half, 0, i + step))
		rail(V(-half, 0, i), V(-half, 0, i + step))
		post(i, half)
		post(half, i)
		post(-half, i)
		-- priekis (-Z) su vartais
		if i + step <= -gateHalf or i >= gateHalf then
			rail(V(i, 0, -half), V(i + step, 0, -half))
		end
		if i <= -gateHalf or i >= gateHalf then
			post(i, -half)
		end
	end
	post(half, half)

	-- Vartų išvaizdą (rąstai → dailidės → plytos) stato PlotService:ApplyGate (Lib/GateModels).
	-- Nematoma sija lieka kaip užrašo „Laisvas sklypas / savininkas“ laikiklis.
	local beam = Build.Part({ Name = "GateBeam", Parent = model, Size = V(L.GateWidth + 8, 2, 3), CFrame = CF(0, 11, L.GateZ), Color = DARK_WOOD, Material = M.Wood, Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	Build.Sign(beam, { Name = "OwnerSign", TextKey = "FreePlot", Size = UDim2.fromScale(16, 3.2), Offset = V(0, 3.2, 0), MaxDistance = 250 })

	-- Akmeninė aikštelė prieš vartus ir Claim mygtukas ant jos
	Build.Part({ Name = "Porch", Parent = model, Size = V(L.GateWidth + 10, 1, 14), CFrame = CF(0, -0.5, -half - 7), Color = STONE, Material = M.Slate })
	local pad = Build.Part({
		Name = "ClaimPad", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.5, 7, 7),
		CFrame = CF(0, 0.25, L.ClaimPadZ) * CFrame.Angles(0, 0, math.rad(90)),
		Color = C(70, 170, 70), Material = M.Neon,
	})
	Build.Billboard(pad, { Name = "ClaimLabel", TextKey = "ClaimHere", Size = UDim2.fromScale(7, 2), Offset = V(0, 3, 0), Color = C(200, 255, 170), MaxDistance = 150 })
	-- Aukšta nematoma zona virš mygtuko: Touched suveikia vos įėjus (net užšokus)
	Build.Part({ Name = "ClaimZone", Parent = model, Size = V(8, 7, 8), CFrame = CF(0, 3.5, L.ClaimPadZ), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = true })
	-- Atsarginis būdas: paspausti „E“ / bakstelėti telefone
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ClaimPrompt"
	prompt.ActionText = "Claim / Pasiimti"
	prompt.ObjectText = "🏠"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad

	Build.Part({ Name = "PlotSpawn", Parent = model, Size = V(2, 1, 2), CFrame = CF(0, 3, L.SpawnZ), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })

	-- Dekoracijos sklype
	local decor = Build.Folder("PlotDecor", model)
	local rng = Random.new(42)
	for _, side in ipairs({ -1, 1 }) do
		-- Fakelai ant vartų bokštų
		Scenery.Torch(decor, V(side * gateHalf, 12, L.GateZ), 1.6)
		-- Kabančios trispalvės po vartų sija
		local stripes = { C(253, 185, 19), C(0, 106, 68), C(193, 39, 45) }
		for i, color in ipairs(stripes) do
			Build.Part({ Name = "Flag", Parent = decor, Size = V(2.4, 1.1, 0.1), CFrame = CF(side * 4.2, 9.5 - (i - 1) * 1.1, L.GateZ - 1.6), Color = color, Material = M.Fabric, CanCollide = false, CanQuery = false, CanTouch = false })
		end
		-- Beržiukai ir krūmai palei šonines tvoras
		for index = 0, 8 do
			local z = -34 + index * 11
			local x = side * (half - 5)
			if index % 2 == 0 then
				Scenery.Birch(decor, V(x, 0, z), rng, 0.55)
			else
				Scenery.Bush(decor, V(x, 0, z), rng, 0.9)
			end
		end
	end
	-- Krūmai palei galinę tvorą
	for x = -50, 50, 12 do
		Scenery.Bush(decor, V(x, 0, half - 2.5), rng, 0.7)
	end
	-- Ūkio kampelis kairėje nuo vartų
	Scenery.Barrel(decor, V(-16, 0, -56), rng)
	Scenery.Barrel(decor, V(-18.6, 0, -55.4), rng)
	Scenery.Crate(decor, V(-16.5, 0, -52.5), rng)
	Scenery.Crate(decor, V(-16.5, 2.2, -52.5), rng, 1.6)
	Scenery.Haystack(decor, V(-52, 0, -53), rng)
	Scenery.Cart(decor, CF(-44, 0, -50) * CFrame.Angles(0, math.rad(70), 0))
	-- Bulvių daržas
	for row = 0, 2 do
		local z = -57 + row * 3.2
		Build.Part({ Name = "GardenBed", Parent = decor, Size = V(12, 0.5, 2.2), CFrame = CF(-29, 0.25, z), Color = C(95, 65, 40), Material = M.Ground, CanQuery = false, CanTouch = false })
		for i = 0, 4 do
			Build.Part({ Name = "PotatoPlant", Parent = decor, Shape = Enum.PartType.Ball, Size = V(1.3, 1.3, 1.3), CFrame = CF(-34 + i * 2.5, 1, z), Color = C(80, 140, 60), Material = M.Grass, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
			if i % 2 == 0 then
				Build.Part({ Name = "PotatoFlower", Parent = decor, Shape = Enum.PartType.Ball, Size = V(0.35, 0.35, 0.35), CFrame = CF(-34 + i * 2.5, 1.7, z), Color = C(235, 225, 250), Material = M.SmoothPlastic, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
			end
		end
	end
	-- Gėlės prie vartų
	Scenery.Flowers(decor, V(-12, 0, -57), rng, 5)
	Scenery.Flowers(decor, V(12, 0, -57), rng, 5)

	-- Zonos
	local zones = Build.Folder("Zones", model)
	local length = L.ZoneMaxZ - L.ZoneMinZ
	for index, lineId in ipairs(ProductLines.Order) do
		local x = L.FirstLaneX - (index - 1) * L.LaneSpacing
		Build.Part({
			Name = "Zone_" .. lineId, Parent = zones, Size = V(L.LaneSpacing - 0.4, L.ZoneTopY, length),
			CFrame = CF(x, L.ZoneTopY / 2, L.ZoneMinZ + length / 2),
			Color = C(200, 200, 200), Material = M.SmoothPlastic, Transparency = 0.6,
		})
	end
end

----------------------------------------------------------------------
-- Mašinos
----------------------------------------------------------------------
local function buildDropper(model, line)
	for _, x in ipairs({ -2.9, 2.9 }) do
		Build.Part({ Name = "Post", Parent = model, Size = V(0.6, 10, 0.6), CFrame = CF(x, 5, 0), Color = WOOD, Material = M.Wood })
	end
	Build.Part({ Name = "TopBeam", Parent = model, Size = V(6.4, 0.6, 0.8), CFrame = CF(0, 10.1, 0), Color = WOOD, Material = M.Wood })
	Build.Part({ Name = "Sack", Parent = model, Size = V(3.6, 3, 3.6), CFrame = CF(0, 8.2, 0), Color = line.Theme.Machine, Material = M.Fabric })
	Build.Part({ Name = "SackTop", Parent = model, Size = V(2.2, 0.8, 2.2), CFrame = CF(0, 10, 0), Color = line.Theme.Machine, Material = M.Fabric })
	Build.Part({ Name = "Chute", Parent = model, Size = V(1.8, 1.4, 1.8), CFrame = CF(0, 6.1, 0), Color = DARK_WOOD, Material = M.Wood })
	Build.Part({ Name = "DropPoint", Parent = model, Size = V(0.5, 0.5, 0.5), CFrame = CF(0, L.DropSpawnHeight, 0), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
end

local function buildConveyor(model, line)
	local length = L.ConveyorStartZ - L.ConveyorEndZ
	Build.Part({
		Name = "Belt", Parent = model, Size = V(L.ConveyorWidth, L.ConveyorHeight, length),
		CFrame = CF(0, L.ConveyorHeight / 2, 0), Color = line.Theme.Belt, Material = line.Theme.BeltMaterial,
		Transparency = line.Theme.BeltTransparency, Tags = { "ConveyorBelt" },
	})
	for _, side in ipairs({ -1, 1 }) do
		Build.Part({ Name = "Rail", Parent = model, Size = V(0.4, 0.6, length), CFrame = CF(side * (L.ConveyorWidth / 2 + 0.2), L.ConveyorHeight + 0.1, 0), Color = line.Theme.Accent, Material = M.Wood })
	end
	Build.Part({ Name = "EndCap", Parent = model, Size = V(L.ConveyorWidth + 0.8, 0.8, 0.4), CFrame = CF(0, L.ConveyorHeight + 0.2, length / 2 + 0.2), Color = line.Theme.Accent, Material = M.Wood })
	-- Metaliniai šonai (rėmas) su varžtais
	local metal = C(85, 85, 90)
	for _, side in ipairs({ -1, 1 }) do
		Build.Part({ Name = "Skirt", Parent = model, Size = V(0.25, L.ConveyorHeight, length), CFrame = CF(side * (L.ConveyorWidth / 2 + 0.13), L.ConveyorHeight / 2, 0), Color = metal, Material = M.DiamondPlate, CanQuery = false, CanTouch = false })
		for i = 0, 4 do
			local z = -length / 2 + 4 + i * (length - 8) / 4
			Build.Part({ Name = "Bolt", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.15, 0.4, 0.4), CFrame = CF(side * (L.ConveyorWidth / 2 + 0.3), L.ConveyorHeight / 2, z), Color = C(190, 190, 195), Material = M.Metal, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		end
	end
	-- Velenai abiejuose galuose (be kolizijos, kad netrukdytų produktams)
	for _, z in ipairs({ length / 2, -length / 2 }) do
		Build.Part({ Name = "Roller", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(L.ConveyorWidth + 0.7, L.ConveyorHeight + 0.2, L.ConveyorHeight + 0.2), CFrame = CF(0, L.ConveyorHeight / 2, z), Color = metal, Material = M.Metal, CanCollide = false, CanQuery = false, CanTouch = false })
	end
end

local function buildSell(model, line)
	-- Langelis atsuktas į +Z (iš ten atvažiuoja produktai)
	Build.Part({ Name = "Back", Parent = model, Size = V(5.6, 4.4, 0.6), CFrame = CF(0, 2.2, -1.9), Color = DARK_WOOD, Material = M.Wood })
	for _, side in ipairs({ -1, 1 }) do
		Build.Part({ Name = "Side", Parent = model, Size = V(0.6, 4.4, 4.4), CFrame = CF(side * 2.5, 2.2, 0), Color = DARK_WOOD, Material = M.Wood })
	end
	Build.Part({ Name = "Roof", Parent = model, Size = V(6.4, 0.6, 5), CFrame = CF(0, 4.7, 0), Color = line.Theme.Accent, Material = M.WoodPlanks })
	Build.Part({ Name = "Inside", Parent = model, Size = V(4.4, 4, 3.6), CFrame = CF(0, 2, -0.2), Color = C(30, 20, 12), Material = M.SmoothPlastic, CanCollide = false })
	for i = 1, 3 do
		Build.Part({ Name = "Coin", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.3, 1.2, 1.2), CFrame = CF(-1.6 + i * 0.6, 5.1 + i * 0.05, 1) * CFrame.Angles(0, 0, math.rad(90)), Color = GOLD, Material = M.Metal })
	end
	local roof = model:FindFirstChild("Roof")
	Build.Sign(roof, { Name = "SellSign", TextKey = "Sell", Size = UDim2.fromScale(6, 1.6), Offset = V(0, 2.2, 0), MaxDistance = 80 })
end

local function opText(purchase)
	local amount = purchase.Amount
	if amount == math.floor(amount) then
		amount = string.format("%d", amount)
	else
		amount = string.gsub(string.format("%.1f", amount), "%.", ",")
	end
	if purchase.Op == "Mul" then
		return "×" .. amount
	end
	return "+" .. amount
end

local function buildUpgrader(model, line, purchase)
	local color = purchase.ItemColor or line.Theme.Machine
	for _, x in ipairs({ -3.1, 3.1 }) do
		Build.Part({ Name = "Post", Parent = model, Size = V(0.8, 6, 0.8), CFrame = CF(x, 3, 0), Color = WOOD, Material = M.Wood })
	end
	local beam = Build.Part({ Name = "Beam", Parent = model, Size = V(7, 0.8, 1.4), CFrame = CF(0, 6.4, 0), Color = line.Theme.Accent, Material = M.WoodPlanks })
	Build.Part({ Name = "Zone", Parent = model, Size = V(L.ConveyorWidth + 0.4, 3, 1.6), CFrame = CF(0, 2.7, 0), Color = color, Material = M.Neon, Transparency = 0.6, CanCollide = false, CanQuery = false, CanTouch = false })

	-- Viršutinė „mašinos“ dalis – skiriasi pagal tipą
	if purchase.Op == "Mul" then
		Build.Part({ Name = "Gear", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(1, 3, 3), CFrame = CF(0, 8.3, 0), Color = STONE, Material = M.Metal, Tags = { "Spinner" }, Attributes = { SpinSpeed = 1.5 } })
	else
		Build.Part({ Name = "Funnel", Parent = model, Size = V(2.4, 2, 2.4), CFrame = CF(0, 7.8, 0), Color = color, Material = M.SmoothPlastic })
	end

	-- Ypatingos detalės
	if purchase.Id == "Cepelinai_6" or purchase.Id == "AuksinisCepelinas_5" then
		local pot = Build.Part({ Name = "Pot", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2.6, 3.6, 3.6), CFrame = CF(2.2, 8.6, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(60, 60, 65), Material = M.Metal, Tags = { "Bubbling" } })
		local steam = Instance.new("Smoke")
		steam.Color = C(240, 240, 240)
		steam.Opacity = 0.15
		steam.RiseVelocity = 3
		steam.Size = 1.5
		steam.Parent = pot
	elseif purchase.Id == "Sakotis_2" then
		Build.Part({ Name = "Spit", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(6.4, 1.6, 1.6), CFrame = CF(0, 5.2, 0), Color = C(220, 170, 80), Material = M.SmoothPlastic, Tags = { "Spinner" }, Attributes = { SpinSpeed = 2 } })
	elseif purchase.Id == "Sakotis_3" or purchase.Id == "Kibinai_4" then
		local fire = Instance.new("Fire")
		fire.Size = 3
		fire.Heat = 4
		fire.Parent = beam
	end

	Build.Billboard(beam, { Name = "OpLabel", Text = opText(purchase), Size = UDim2.fromScale(3, 1.4), Offset = V(0, 3.4, 0), Color = C(255, 230, 120), MaxDistance = 70 })
	Build.Billboard(beam, { Name = "NameLabel", TextKey = purchase.Id, Size = UDim2.fromScale(8, 1.1), Offset = V(0, 2.1, 0), Font = Enum.Font.Merriweather, MaxDistance = 50 })
end

local function buildStatue(model)
	Build.Part({ Name = "Pedestal", Parent = model, Size = V(7, 3, 7), CFrame = CF(0, 1.5, 0), Color = C(235, 230, 220), Material = M.Marble })
	Build.Part({ Name = "PedestalTop", Parent = model, Size = V(6, 0.6, 6), CFrame = CF(0, 3.3, 0), Color = GOLD, Material = M.Metal })
	local body = Build.Part({ Name = "Cepelinas", Parent = model, Size = V(9, 5, 5), CFrame = CF(0, 6.1, 0), Color = GOLD, Material = M.Metal })
	Build.Mesh(body, Enum.MeshType.Sphere)
	local light = Instance.new("PointLight")
	light.Color = GOLD
	light.Range = 18
	light.Brightness = 2
	light.Parent = body
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = C(255, 230, 120)
	sparkles.Parent = body
	Build.Billboard(body, { Name = "NameLabel", TextKey = "AuksinisCepelinas_7", Size = UDim2.fromScale(12, 2), Offset = V(0, 5, 0), Color = GOLD, MaxDistance = 200 })
end

local function buildGrannyTable(model)
	Build.Part({ Name = "Top", Parent = model, Size = V(2.6, 0.4, 4.4), CFrame = CF(0, 3, 0), Color = WOOD, Material = M.WoodPlanks })
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1.8, 1.8 }) do
			Build.Part({ Name = "Leg", Parent = model, Size = V(0.4, 2.8, 0.4), CFrame = CF(x, 1.4, z), Color = DARK_WOOD, Material = M.Wood })
		end
	end
	Build.Part({ Name = "Bowl", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.8, 1.6, 1.6), CFrame = CF(0, 3.6, -0.8) * CFrame.Angles(0, 0, math.rad(90)), Color = C(200, 200, 205), Material = M.Metal })
	Build.Part({ Name = "RollingPin", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2, 0.4, 0.4), CFrame = CF(0, 3.4, 1.2) * CFrame.Angles(0, math.rad(90), 0), Color = C(210, 170, 110), Material = M.Wood })
end

local function buildShelf(model)
	for _, x in ipairs({ -6, 6 }) do
		Build.Part({ Name = "Side", Parent = model, Size = V(0.6, 7, 1.6), CFrame = CF(x, 3.5, 0), Color = DARK_WOOD, Material = M.Wood })
	end
	for _, y in ipairs({ 1, 3.4, 5.8 }) do
		Build.Part({ Name = "Board", Parent = model, Size = V(12, 0.4, 1.6), CFrame = CF(0, y, 0), Color = WOOD, Material = M.WoodPlanks })
	end
	local colors = { C(200, 60, 60), C(60, 140, 60), C(230, 200, 70), C(150, 90, 50) }
	for i = 1, 8 do
		local x = -5 + (i - 1) * 1.4
		local y = (i % 2 == 0) and 4.1 or 1.7
		Build.Part({ Name = "Jar", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(1.1, 0.9, 0.9), CFrame = CF(x, y, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = colors[(i % 4) + 1], Material = M.Glass, Transparency = 0.2 })
	end
	local top = Build.Part({ Name = "TopBoard", Parent = model, Size = V(12.6, 0.5, 2), CFrame = CF(0, 7.2, 0), Color = DARK_WOOD, Material = M.Wood })
	Build.Sign(top, { Name = "ShelfSign", TextKey = "Shelf", Size = UDim2.fromScale(10, 1.8), Offset = V(0, 2, 0), MaxDistance = 80 })
end

local function buildFlag(model)
	Build.Part({ Name = "Pole", Parent = model, Size = V(0.4, 10, 0.4), CFrame = CF(0, 5, 0), Color = C(90, 70, 50), Material = M.Wood })
	local stripes = { C(253, 185, 19), C(0, 106, 68), C(193, 39, 45) }
	for i, color in ipairs(stripes) do
		Build.Part({ Name = "Stripe" .. i, Parent = model, Size = V(0.1, 0.9, 4.5), CFrame = CF(0, 9.6 - (i - 1) * 0.9, 2.45), Color = color, Material = M.Fabric })
	end
end

----------------------------------------------------------------------
-- Žaliavos
----------------------------------------------------------------------
local MESH_TYPES = { Sphere = Enum.MeshType.Sphere, Cylinder = Enum.MeshType.Cylinder, Block = Enum.MeshType.Brick }

function TemplateBuilder:ApplyItemMesh(part, meshName)
	local old = part:FindFirstChildOfClass("SpecialMesh")
	if old then
		old:Destroy()
	end
	local meshType = MESH_TYPES[meshName]
	if meshType and meshName ~= "Block" then
		Build.Mesh(part, meshType)
	end
end

-- Smulki dekoratyvinė dalis, privirinta prie žaliavos (be fizikos)
local function addDetail(root, name, size, offset, color, material, meshType)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or root.Material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = root.CFrame * offset
	if meshType then
		Build.Mesh(part, meshType)
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	part.Parent = root
	return part
end
TemplateBuilder.AddDetail = addDetail

-- Gumbuota bulvė su „akutėmis“
local function potatoDetails(root, bumpColor, eyeColor, eyeMaterial)
	local SPHERE = Enum.MeshType.Sphere
	addDetail(root, "Detail", V(0.85, 0.75, 0.8), CF(0.42, 0.12, 0.18), bumpColor, nil, SPHERE)
	addDetail(root, "Detail", V(0.8, 0.7, 0.75), CF(-0.45, -0.08, -0.2), bumpColor, nil, SPHERE)
	addDetail(root, "Detail", V(0.6, 0.55, 0.6), CF(0.05, 0.28, -0.32), bumpColor, nil, SPHERE)
	local eyes = { CF(0.55, 0.3, 0.45), CF(-0.2, 0.45, 0.35), CF(-0.6, 0.15, -0.45), CF(0.25, -0.2, -0.58), CF(0.7, -0.15, -0.1) }
	for _, offset in ipairs(eyes) do
		addDetail(root, "Detail", V(0.16, 0.12, 0.16), offset, eyeColor, eyeMaterial or Enum.Material.SmoothPlastic, SPHERE)
	end
end

local STYLE_DETAILS = {
	Potato = function(root)
		potatoDetails(root, C(160, 113, 66), C(105, 70, 38))
	end,
	GoldenPotato = function(root)
		potatoDetails(root, C(245, 195, 55), C(255, 140, 20), Enum.Material.Neon)
	end,
	Dough = function(root)
		-- Miltų dulkės viršuje
		addDetail(root, "Detail", V(0.95, 0.22, 0.95), CF(0.08, 0.5, 0.05), C(252, 250, 244), Enum.Material.SmoothPlastic, Enum.MeshType.Sphere)
		addDetail(root, "Detail", V(0.4, 0.15, 0.4), CF(-0.4, 0.42, 0.3), C(252, 250, 244), Enum.Material.SmoothPlastic, Enum.MeshType.Sphere)
	end,
	Beet = function(root)
		-- Šaknelė apačioje ir lapai viršuje
		addDetail(root, "Detail", V(0.25, 0.5, 0.25), CF(0, -0.75, 0), C(100, 18, 45), nil, Enum.MeshType.Sphere)
		addDetail(root, "Detail", V(0.18, 0.5, 0.18), CF(0, 0.75, 0), C(110, 40, 60), Enum.Material.SmoothPlastic)
		addDetail(root, "Detail", V(0.12, 0.9, 0.5), CF(0.15, 1.1, 0) * CFrame.Angles(0, 0, math.rad(-25)), C(70, 150, 60), Enum.Material.Grass, Enum.MeshType.Sphere)
		addDetail(root, "Detail", V(0.12, 0.9, 0.5), CF(-0.15, 1.05, 0.05) * CFrame.Angles(0, math.rad(40), math.rad(25)), C(80, 165, 65), Enum.Material.Grass, Enum.MeshType.Sphere)
	end,
	Batter = function(root)
		-- Kiaušinio trynys ir sūkurys
		addDetail(root, "Detail", V(0.75, 0.35, 0.75), CF(0, 0.45, 0), C(255, 240, 170), Enum.Material.SmoothPlastic, Enum.MeshType.Sphere)
		addDetail(root, "Detail", V(0.35, 0.25, 0.35), CF(0.1, 0.62, 0.05), C(255, 170, 30), Enum.Material.SmoothPlastic, Enum.MeshType.Sphere)
	end,
}

local function buildItem(lineId)
	local def = ProductLines.Lines[lineId].Item
	local part = Instance.new("Part")
	part.Name = "Item_" .. lineId
	part.Size = def.Size
	part.Color = def.Color
	part.Material = def.Material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanQuery = false
	part.CastShadow = false
	part.CanTouch = false
	TemplateBuilder:ApplyItemMesh(part, def.Mesh)
	local details = STYLE_DETAILS[def.Style or ""]
	if details then
		details(part)
	end
	part.Parent = items
	return part
end

----------------------------------------------------------------------
-- Vieša API
----------------------------------------------------------------------
local builders = {}

local function registerMachines()
	for _, lineId in ipairs(ProductLines.Order) do
		local line = ProductLines.Lines[lineId]
		builders["Dropper_" .. lineId] = function(model) buildDropper(model, line) end
		builders["Conveyor_" .. lineId] = function(model) buildConveyor(model, line) end
		builders["Sell_" .. lineId] = function(model) buildSell(model, line) end
		for _, purchase in ipairs(line.Purchases) do
			if purchase.Type == "Upgrader" then
				builders[purchase.Id] = function(model) buildUpgrader(model, line, purchase) end
			elseif purchase.Type == "Decoration" then
				builders[purchase.Id] = function(model) buildStatue(model) end
			end
		end
	end
	builders.GrannyTable = buildGrannyTable
	builders.Shelf = buildShelf
	builders.Flag = buildFlag
	for name, builder in pairs(DecorModels) do
		builders[name] = builder
	end
end

local function ensureMachine(name)
	local existing = machines:FindFirstChild(name)
	if existing then
		return existing
	end
	local builder = builders[name]
	if not builder then
		warn("[TemplateBuilder] Nežinomas šablonas: " .. tostring(name))
		return nil
	end
	local model = Instance.new("Model")
	model.Name = name
	builder(model)
	return finish(model, machines)
end

-- Grąžina mašinos modelio kopiją (dar be Parent)
function TemplateBuilder:CloneMachine(name)
	local template = ensureMachine(name)
	if not template then
		return nil
	end
	local clone = template:Clone()
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	return clone
end

function TemplateBuilder:CloneItem(lineId)
	local template = items:FindFirstChild("Item_" .. lineId) or buildItem(lineId)
	return template:Clone()
end

function TemplateBuilder:ClonePlot()
	return templates:FindFirstChild("Plot"):Clone()
end

function TemplateBuilder:Init()
	templates = ensureFolder(ServerStorage, "Templates")
	machines = ensureFolder(templates, "Machines")
	items = ensureFolder(templates, "Items")
	registerMachines()
end

function TemplateBuilder:Start()
	local plot = templates:FindFirstChild("Plot")
	if not plot then
		plot = Instance.new("Model")
		plot.Name = "Plot"
		plot.Parent = templates
	end
	if #plot:GetChildren() == 0 then
		buildPlot(plot)
		plot.WorldPivot = CF()
	end
	-- Sukuriam trūkstamus šablonus iš anksto (kad būtų matyti ServerStorage žaidžiant)
	for name in pairs(builders) do
		ensureMachine(name)
	end
	for _, lineId in ipairs(ProductLines.Order) do
		if not items:FindFirstChild("Item_" .. lineId) then
			buildItem(lineId)
		end
	end
end

return TemplateBuilder
