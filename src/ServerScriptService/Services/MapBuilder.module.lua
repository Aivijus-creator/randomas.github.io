--[[
	MapBuilder – sukuria žemėlapį iš Parts serverio starte:
	  - žolės pagrindas, keliai į sklypus
	  - Lobby „Kaimo turgus“: fontanas su cepelino statula (spawn), Močiutės trobelė,
	    lyderių lentos, Gedimino pilies bokšto maketas, medžiai, gandrų lizdai, tvoros,
	    VIP šaltibarščių baseinas, vietos eventams.
	Jei Workspace jau yra modelis "Lobby" (pvz. pasidarei gražesnį), naujas nekuriamas,
	bet jame turi būti dalys: LobbySpawn, BigCepelinasSpot, Bonfire1, Bonfire2, FernSpot,
	RebirthHutDoor, VIPZone, VIPBarriers (Folder), LeaderboardTotal, LeaderboardRebirths.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Lighting = game:GetService("Lighting")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local Scenery = require(Lib:WaitForChild("Scenery"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material
local MAP = Settings.Map

local LOBBY_Y = 1           -- lobby ir sklypų grindų aukštis
local WOOD = C(122, 82, 46)
local DARK_WOOD = C(78, 50, 26)
local STONE = C(128, 126, 120)
local LEAVES = C(60, 110, 45)

local MapBuilder = {}
MapBuilder.Anchors = {}

local placed = {}               -- užimtos vietos dekoracijoms: { pozicija, spindulys }

local function polar(angleDeg, radius, y)
	local a = math.rad(angleDeg)
	return V(math.cos(a) * radius, y or LOBBY_Y, math.sin(a) * radius)
end

-- Sklypo i kampas (laipsniais)
function MapBuilder:GetPlotAngle(index)
	return (index - 1) * (360 / Settings.PlotCount)
end

-- Sklypo CFrame: centras grindų paviršiuje, -Z (LookVector) į lobby
function MapBuilder:GetPlotCFrame(index)
	local position = polar(self:GetPlotAngle(index), MAP.PlotRingRadius, LOBBY_Y)
	return CFrame.lookAt(position, V(0, LOBBY_Y, 0))
end

----------------------------------------------------------------------
-- Dekoracijos
----------------------------------------------------------------------
local function tree(parent, position, scale)
	scale = scale or 1
	table.insert(placed, { V(position.X, 0, position.Z), 5 * scale })
	local model = Build.Model("Tree", parent)
	Build.Part({ Name = "Trunk", Parent = model, Size = V(1.6, 8, 1.6) * scale, CFrame = CF(position + V(0, 4 * scale, 0)), Color = DARK_WOOD, Material = M.Wood })
	Build.Part({ Name = "Leaves", Parent = model, Shape = Enum.PartType.Ball, Size = V(8, 8, 8) * scale, CFrame = CF(position + V(0, 9.5 * scale, 0)), Color = LEAVES, Material = M.Grass })
	Build.Part({ Name = "Leaves2", Parent = model, Shape = Enum.PartType.Ball, Size = V(5.5, 5.5, 5.5) * scale, CFrame = CF(position + V(1.5, 12 * scale, 1)), Color = C(70, 125, 50), Material = M.Grass })
end

local function storkNest(parent, position)
	table.insert(placed, { V(position.X, 0, position.Z), 3 })
	local model = Build.Model("StorkNest", parent)
	Build.Part({ Name = "Pole", Parent = model, Size = V(0.8, 14, 0.8), CFrame = CF(position + V(0, 7, 0)), Color = C(90, 75, 60), Material = M.Wood })
	Build.Part({ Name = "Nest", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(1.2, 4, 4), CFrame = CF(position + V(0, 14.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(120, 95, 60), Material = M.Grass })
	-- Gandras
	Build.Part({ Name = "StorkBody", Parent = model, Size = V(1.2, 1.2, 2), CFrame = CF(position + V(0, 15.8, 0)), Color = C(245, 245, 245), Material = M.SmoothPlastic })
	Build.Part({ Name = "StorkWing", Parent = model, Size = V(1.3, 0.5, 1.4), CFrame = CF(position + V(0, 16.2, -0.4)), Color = C(25, 25, 25), Material = M.SmoothPlastic })
	Build.Part({ Name = "StorkNeck", Parent = model, Size = V(0.4, 1.4, 0.4), CFrame = CF(position + V(0, 16.8, 0.9)), Color = C(245, 245, 245), Material = M.SmoothPlastic })
	Build.Part({ Name = "StorkBeak", Parent = model, Size = V(0.25, 0.25, 1.1), CFrame = CF(position + V(0, 17.4, 1.5)), Color = C(230, 80, 40), Material = M.SmoothPlastic })
end

local function fenceSegment(parent, a, b, baseY)
	baseY = baseY or LOBBY_Y
	local mid = (a + b) / 2
	local length = (b - a).Magnitude
	for _, y in ipairs({ 1.1, 2.3 }) do
		Build.Part({ Name = "Rail", Parent = parent, Size = V(0.35, 0.35, length), CFrame = CFrame.lookAt(V(mid.X, baseY + y, mid.Z), V(b.X, baseY + y, b.Z)), Color = WOOD, Material = M.Wood, CanQuery = false, CanTouch = false })
	end
	Build.Part({ Name = "Post", Parent = parent, Size = V(0.7, 3, 0.7), CFrame = CF(a.X, baseY + 1.5, a.Z), Color = DARK_WOOD, Material = M.Wood, CanQuery = false, CanTouch = false })
end

local function gediminasTower(parent, position)
	local model = Build.Model("GediminasTower", parent)
	local brick = C(160, 70, 50)
	Build.Part({ Name = "Hill", Parent = model, Shape = Enum.PartType.Ball, Size = V(14, 14, 14), CFrame = CF(position + V(0, -3, 0)), Color = C(90, 130, 60), Material = M.Grass })
	Build.Part({ Name = "Base", Parent = model, Size = V(6, 6, 6), CFrame = CF(position + V(0, 6, 0)), Color = brick, Material = M.Brick })
	Build.Part({ Name = "Mid", Parent = model, Size = V(5, 5, 5), CFrame = CF(position + V(0, 11.5, 0)), Color = brick, Material = M.Brick })
	Build.Part({ Name = "Top", Parent = model, Size = V(4.4, 2.4, 4.4), CFrame = CF(position + V(0, 15.2, 0)), Color = brick, Material = M.Brick })
	for _, dx in ipairs({ -1.6, 0, 1.6 }) do
		for _, dz in ipairs({ -1.6, 1.6 }) do
			Build.Part({ Name = "Crenel", Parent = model, Size = V(0.9, 0.9, 0.9), CFrame = CF(position + V(dx, 16.8, dz)), Color = brick, Material = M.Brick })
		end
	end
	Build.Part({ Name = "FlagPole", Parent = model, Size = V(0.25, 4, 0.25), CFrame = CF(position + V(0, 18.4, 0)), Color = C(80, 80, 80), Material = M.Metal })
	local stripes = { C(253, 185, 19), C(0, 106, 68), C(193, 39, 45) }
	for i, color in ipairs(stripes) do
		Build.Part({ Name = "Flag" .. i, Parent = model, Size = V(0.05, 0.5, 2.2), CFrame = CF(position + V(0, 20 - (i - 1) * 0.5, 1.2)), Color = color, Material = M.Fabric })
	end
end

local function rebirthHut(parent, position)
	local model = Build.Model("RebirthHut", parent)
	local center = CFrame.lookAt(position, V(0, position.Y, 0))
	local function at(x, y, z)
		return center * CF(x, y, z)
	end
	Build.Part({ Name = "Floor", Parent = model, Size = V(12, 0.6, 10), CFrame = at(0, 0.3, 0), Color = DARK_WOOD, Material = M.WoodPlanks })
	Build.Part({ Name = "BackWall", Parent = model, Size = V(12, 7, 0.8), CFrame = at(0, 4, 4.6), Color = WOOD, Material = M.Wood })
	for _, side in ipairs({ -1, 1 }) do
		Build.Part({ Name = "SideWall", Parent = model, Size = V(0.8, 7, 10), CFrame = at(side * 5.6, 4, 0), Color = WOOD, Material = M.Wood })
		Build.Part({ Name = "FrontWall", Parent = model, Size = V(3.8, 7, 0.8), CFrame = at(side * 4.1, 4, -4.6), Color = WOOD, Material = M.Wood })
		Build.Wedge({ Name = "Roof", Parent = model, Size = V(13, 4, 6), CFrame = at(0, 9.5, side * 2.9) * CFrame.Angles(0, side == 1 and math.rad(180) or 0, 0), Color = C(150, 50, 40), Material = M.WoodPlanks })
	end
	Build.Part({ Name = "Lintel", Parent = model, Size = V(4.4, 1.6, 0.8), CFrame = at(0, 6.7, -4.6), Color = WOOD, Material = M.Wood })
	Build.Part({ Name = "Chimney", Parent = model, Size = V(1.6, 4, 1.6), CFrame = at(3.5, 11, 2), Color = STONE, Material = M.Cobblestone })
	local smoke = Instance.new("Smoke")
	smoke.Opacity = 0.1
	smoke.RiseVelocity = 4
	smoke.Parent = model:FindFirstChild("Chimney")
	local window = Build.Part({ Name = "Window", Parent = model, Size = V(2, 2, 0.2), CFrame = at(0, 5, 4.1), Color = C(255, 210, 120), Material = M.Neon })
	window.Transparency = 0.2
	local door = Build.Part({ Name = "RebirthHutDoor", Parent = model, Size = V(3.6, 5.6, 0.4), CFrame = at(0, 3.4, -4.6), Color = C(100, 60, 30), Material = M.Wood, CanCollide = false, Transparency = 0.3 })
	Build.Sign(model:FindFirstChild("Lintel"), { Name = "HutSign", TextKey = "RebirthHut", Size = UDim2.fromScale(9, 2), Offset = V(0, 6, 0), MaxDistance = 120 })
	return door
end

local function leaderboard(parent, name, position)
	local model = Build.Model(name, parent)
	local cf = CFrame.lookAt(position, V(0, position.Y, 0))
	for _, side in ipairs({ -1, 1 }) do
		Build.Part({ Name = "Post", Parent = model, Size = V(1, 14, 1), CFrame = cf * CF(side * 7.5, 7, 0.6), Color = DARK_WOOD, Material = M.Wood })
	end
	local board = Build.Part({ Name = name, Parent = model, Size = V(14, 11, 0.6), CFrame = cf * CF(0, 8, 0), Color = C(232, 211, 162), Material = M.WoodPlanks })
	Build.Part({ Name = "Roof", Parent = model, Size = V(16, 0.8, 2.4), CFrame = cf * CF(0, 14.2, 0.3), Color = C(150, 50, 40), Material = M.WoodPlanks })
	return board
end

local function vipPool(parent, position)
	local model = Build.Model("VIPPool", parent)
	local size = 9                  -- mažas, kad netrukdytų vaikščioti po turgų
	Build.Part({ Name = "PoolFloor", Parent = model, Size = V(size, 0.4, size), CFrame = CF(position + V(0, 0.2, 0)), Color = STONE, Material = M.Slate })
	local water = Build.Part({ Name = "Saltibarsciai", Parent = model, Size = V(size - 2, 1, size - 2), CFrame = CF(position + V(0, 0.9, 0)), Color = C(255, 105, 180), Material = M.Glass, Transparency = 0.25, CanCollide = false })
	water.Reflectance = 0.1
	local barriers = Build.Folder("VIPBarriers", model)
	for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
		local offset = V(d[1] * size / 2, 3, d[2] * size / 2)
		local wallSize = (d[1] ~= 0) and V(0.4, 6, size) or V(size, 6, 0.4)
		Build.Part({ Name = "Barrier", Parent = barriers, Size = wallSize, CFrame = CF(position + offset), Color = C(255, 150, 210), Material = M.ForceField, Transparency = 0.5 })
		local rimSize = (d[1] ~= 0) and V(1, 1.2, size + 1) or V(size + 1, 1.2, 1)
		Build.Part({ Name = "Rim", Parent = model, Size = rimSize, CFrame = CF(position + V(d[1] * size / 2, 0.6, d[2] * size / 2)), Color = C(235, 230, 215), Material = M.Marble })
	end
	local zone = Build.Part({ Name = "VIPZone", Parent = model, Size = V(size - 1, 6, size - 1), CFrame = CF(position + V(0, 3, 0)), Transparency = 1, CanCollide = false, CanQuery = false })
	Build.Sign(water, { Name = "VIPSign", Text = "👑 VIP", Size = UDim2.fromScale(5, 1.6), Offset = V(0, 7, 0), MaxDistance = 100 })
	return zone, barriers
end

-- Kalvė (ginklų parduotuvė): grąžina CFrame, kurio -Z žiūri į turgaus centrą
local function smithy(parent, position)
	local model = Build.Model("WeaponShop", parent)
	local cf = CFrame.lookAt(position, V(0, position.Y, 0))
	local function at(x, y, z)
		return cf * CF(x, y, z)
	end
	local stoneC = C(110, 105, 100)
	Build.Part({ Name = "Floor", Parent = model, Size = V(14, 0.6, 9), CFrame = at(0, 0.3, 0), Color = C(120, 115, 108), Material = M.Slate })
	Build.Part({ Name = "BackWall", Parent = model, Size = V(14, 7, 1), CFrame = at(0, 3.8, 4), Color = stoneC, Material = M.Cobblestone })
	for _, x in ipairs({ -6.5, 6.5 }) do
		Build.Part({ Name = "Post", Parent = model, Size = V(0.8, 7, 0.8), CFrame = at(x, 3.8, -3.8), Color = DARK_WOOD, Material = M.Wood })
	end
	Build.Part({ Name = "Roof", Parent = model, Size = V(15, 0.6, 10), CFrame = at(0, 7.6, 0) * CFrame.Angles(math.rad(-8), 0, 0), Color = C(140, 55, 40), Material = M.WoodPlanks })
	-- Žaizdras su ugnimi
	local forge = Build.Part({ Name = "Forge", Parent = model, Size = V(3.4, 2.4, 2.4), CFrame = at(-4, 1.8, 2.4), Color = C(90, 85, 80), Material = M.Cobblestone })
	local coals = Build.Part({ Name = "Coals", Parent = model, Size = V(2.6, 0.3, 1.6), CFrame = at(-4, 3.1, 2.4), Color = C(255, 110, 30), Material = M.Neon })
	local fire = Instance.new("Fire")
	fire.Size = 3
	fire.Heat = 6
	fire.Parent = coals
	local light = Instance.new("PointLight")
	light.Color = C(255, 140, 60)
	light.Range = 14
	light.Brightness = 1.5
	light.Parent = coals
	Build.Part({ Name = "Chimney", Parent = model, Size = V(1.6, 4, 1.6), CFrame = at(-4, 9, 3.4), Color = stoneC, Material = M.Cobblestone })
	-- Priekalas
	Build.Part({ Name = "AnvilBase", Parent = model, Size = V(1, 1.6, 1), CFrame = at(1, 1.4, 1.5), Color = C(70, 50, 30), Material = M.Wood })
	Build.Part({ Name = "Anvil", Parent = model, Size = V(2.4, 0.7, 1.1), CFrame = at(1, 2.55, 1.5), Color = C(55, 55, 60), Material = M.Metal })
	-- Lentyna su ginklų pavyzdžiais
	Build.Part({ Name = "Rack", Parent = model, Size = V(4.5, 0.3, 0.8), CFrame = at(4.5, 4.5, 3.3), Color = C(130, 88, 48), Material = M.WoodPlanks })
	Build.Part({ Name = "SampleSpoon", Parent = model, Size = V(0.25, 2.6, 0.25), CFrame = at(3.2, 3.2, 3.3), Color = C(205, 165, 105), Material = M.Wood })
	Build.Part({ Name = "SamplePin", Parent = model, Size = V(0.6, 3, 0.6), CFrame = at(4.5, 3.1, 3.3), Color = C(220, 185, 130), Material = M.Wood })
	Build.Part({ Name = "SamplePan", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.2, 2.2, 2.2), CFrame = at(5.9, 3.3, 3.3) * CFrame.Angles(0, math.rad(90), 0), Color = C(45, 45, 48), Material = M.Metal })
	local signPart = Build.Part({ Name = "SignBoard", Parent = model, Size = V(6, 1.4, 0.3), CFrame = at(0, 6.6, -4.3), Color = C(130, 88, 48), Material = M.WoodPlanks })
	Build.Sign(signPart, { Name = "ShopSign", TextKey = "WeaponShop", Size = UDim2.fromScale(10, 2.2), Offset = V(0, 2.2, 0), MaxDistance = 120 })
	return cf
end

local function fountain(parent)
	local model = Build.Model("Fountain", parent)
	Build.Part({ Name = "Basin", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2, 16, 16), CFrame = CF(0, LOBBY_Y + 1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = STONE, Material = M.Cobblestone })
	Build.Part({ Name = "Water", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.4, 14, 14), CFrame = CF(0, LOBBY_Y + 2.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(80, 150, 210), Material = M.Glass, Transparency = 0.3, CanCollide = false })
	Build.Part({ Name = "Pedestal", Parent = model, Size = V(3, 5, 3), CFrame = CF(0, LOBBY_Y + 4.5, 0), Color = C(200, 195, 185), Material = M.Marble })
	local statue = Build.Part({ Name = "CepelinasStatue", Parent = model, Size = V(7, 4, 4), CFrame = CF(0, LOBBY_Y + 9, 0) * CFrame.Angles(0, math.rad(30), math.rad(10)), Color = C(215, 210, 200), Material = M.Marble })
	Build.Mesh(statue, Enum.MeshType.Sphere)
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(C(170, 210, 255))
	spray.Size = NumberSequence.new(0.4, 0)
	spray.Lifetime = NumberRange.new(1, 1.5)
	spray.Rate = 25
	spray.Speed = NumberRange.new(8, 10)
	spray.SpreadAngle = Vector2.new(25, 25)
	spray.Acceleration = V(0, -18, 0)
	spray.Parent = model:FindFirstChild("Pedestal")
	Build.Sign(statue, { Name = "LobbySign", TextKey = "Lobby", Size = UDim2.fromScale(12, 2.6), Offset = V(0, 5, 0), MaxDistance = 200 })
end

local function marketStall(parent, position, color)
	local model = Build.Model("MarketStall", parent)
	local cf = CFrame.lookAt(position, V(0, position.Y, 0))
	Build.Part({ Name = "Counter", Parent = model, Size = V(6, 2.6, 2.4), CFrame = cf * CF(0, 1.3, 0), Color = WOOD, Material = M.WoodPlanks })
	for _, side in ipairs({ -1, 1 }) do
		Build.Part({ Name = "Post", Parent = model, Size = V(0.4, 6, 0.4), CFrame = cf * CF(side * 2.8, 3, 1), Color = DARK_WOOD, Material = M.Wood })
	end
	Build.Part({ Name = "Awning", Parent = model, Size = V(7, 0.3, 3.4), CFrame = cf * CF(0, 6.1, 0.4) * CFrame.Angles(math.rad(-12), 0, 0), Color = color, Material = M.Fabric })
	for i = -2, 2 do
		Build.Part({ Name = "Potato", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.9, 0.9, 0.9), CFrame = cf * CF(i * 1, 2.9, -0.3), Color = C(150, 105, 60), Material = M.Sand })
	end
end

----------------------------------------------------------------------
-- Statyba
----------------------------------------------------------------------
local function buildLobby(lobby)
	local R = MAP.LobbyRadius
	Build.Part({ Name = "Plaza", Parent = lobby, Shape = Enum.PartType.Cylinder, Size = V(1, R * 2, R * 2), CFrame = CF(0, LOBBY_Y - 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(150, 145, 135), Material = M.Cobblestone })

	fountain(lobby)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	-- Nematoma, plokščia, be kolizijos: žaidėjai atsiranda ant turgaus grindinio
	spawn.Size = V(8, 0.2, 8)
	spawn.CFrame = CF(0, LOBBY_Y + 0.1, 14)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.CastShadow = false
	spawn.Parent = lobby

	-- Objektai tarp kelių (kampai 30 + 60k)
	local door = rebirthHut(lobby, polar(30, 32))
	local total = leaderboard(lobby, "LeaderboardTotal", polar(90, 38))
	gediminasTower(lobby, polar(150, 33))
	local vipZone, vipBarriers = vipPool(lobby, polar(210, 39))
	local rebirths = leaderboard(lobby, "LeaderboardRebirths", polar(270, 38))
	MapBuilder.Anchors.WeaponShopCFrame = smithy(lobby, polar(330, 34))
	marketStall(lobby, polar(150, 18), C(60, 120, 200))

	local spots = Build.Folder("EventSpots", lobby)
	local function spot(name, position)
		return Build.Part({ Name = name, Parent = spots, Size = V(1, 1, 1), CFrame = CF(position), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	end
	spot("BigCepelinasSpot", polar(260, 24))
	spot("Bonfire1", polar(0, 26))
	spot("Bonfire2", polar(180, 26))
	spot("FernSpot", polar(120, 24))
	spot("ChristmasSpot", polar(90, 27))

	-- Tvora aplink turgų (paliekant tarpus keliams)
	local fence = Build.Folder("Fence", lobby)
	local count = Settings.PlotCount
	for i = 1, count do
		local start = MapBuilder:GetPlotAngle(i) + 9
		local finish = MapBuilder:GetPlotAngle(i) + 360 / count - 9
		local stepCount = 6
		for s = 0, stepCount - 1 do
			local a = start + (finish - start) * s / stepCount
			local b = start + (finish - start) * (s + 1) / stepCount
			fenceSegment(fence, polar(a, R - 1), polar(b, R - 1))
		end
	end

	-- Medžiai ir gandrų lizdai
	local decor = Build.Folder("Decor", lobby)
	for i = 1, count do
		local mid = MapBuilder:GetPlotAngle(i) + 180 / count
		tree(decor, polar(mid - 12, R + 10, 0), 1.1)
		tree(decor, polar(mid + 14, R + 16, 0), 0.9)
		if i % 2 == 0 then
			storkNest(decor, polar(mid + 4, R + 4, 0))
		end
	end

	MapBuilder.Anchors.LobbySpawn = spawn
	MapBuilder.Anchors.RebirthHutDoor = door
	MapBuilder.Anchors.LeaderboardTotal = total
	MapBuilder.Anchors.LeaderboardRebirths = rebirths
	MapBuilder.Anchors.VIPZone = vipZone
	MapBuilder.Anchors.VIPBarriers = vipBarriers
end

local function findAnchors(lobby)
	local function find(name)
		return lobby:FindFirstChild(name, true)
	end
	MapBuilder.Anchors.LobbySpawn = MapBuilder.Anchors.LobbySpawn or find("LobbySpawn")
	MapBuilder.Anchors.RebirthHutDoor = MapBuilder.Anchors.RebirthHutDoor or find("RebirthHutDoor")
	MapBuilder.Anchors.LeaderboardTotal = MapBuilder.Anchors.LeaderboardTotal or find("LeaderboardTotal")
	MapBuilder.Anchors.LeaderboardRebirths = MapBuilder.Anchors.LeaderboardRebirths or find("LeaderboardRebirths")
	MapBuilder.Anchors.VIPZone = MapBuilder.Anchors.VIPZone or find("VIPZone")
	MapBuilder.Anchors.VIPBarriers = MapBuilder.Anchors.VIPBarriers or find("VIPBarriers")
	local function pos(name, fallback)
		local part = find(name)
		return part and part.Position or fallback
	end
	if not MapBuilder.Anchors.WeaponShopCFrame then
		local shop = find("WeaponShop")
		local floor = shop and shop:FindFirstChild("Floor")
		if floor then
			MapBuilder.Anchors.WeaponShopCFrame = CFrame.lookAt(floor.Position, V(0, floor.Position.Y, 0))
		end
	end
	MapBuilder.Anchors.BigCepelinasSpot = pos("BigCepelinasSpot", polar(260, 24))
	MapBuilder.Anchors.Bonfires = { pos("Bonfire1", polar(0, 26)), pos("Bonfire2", polar(180, 26)) }
	MapBuilder.Anchors.FernSpot = pos("FernSpot", polar(120, 24))
	MapBuilder.Anchors.ChristmasSpot = pos("ChristmasSpot", polar(90, 27))
end

function MapBuilder:GetLobbySpawnCFrame()
	local spawn = self.Anchors.LobbySpawn
	if spawn then
		return spawn.CFrame + V(0, 3, 0)
	end
	return CF(0, LOBBY_Y + 4, 14)
end

function MapBuilder:Init() end

----------------------------------------------------------------------
-- Apšvietimas ir atmosfera
----------------------------------------------------------------------
local function setupLighting()
	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.4
	Lighting.GlobalShadows = true
	Lighting.Ambient = C(95, 85, 75)
	Lighting.OutdoorAmbient = C(140, 135, 125)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.6
	local function ensure(className, props)
		local object = Lighting:FindFirstChildOfClass(className) or Instance.new(className)
		for key, value in pairs(props) do
			object[key] = value
		end
		object.Parent = Lighting
	end
	ensure("Atmosphere", { Density = 0.28, Offset = 0.15, Color = C(200, 215, 230), Decay = C(110, 115, 130), Glare = 0.15, Haze = 1.1 })
	ensure("BloomEffect", { Intensity = 0.35, Size = 24, Threshold = 1.7 })
	ensure("ColorCorrectionEffect", { Saturation = 0.15, Contrast = 0.07, Brightness = 0.02, TintColor = C(255, 248, 235) })
	ensure("SunRaysEffect", { Intensity = 0.05, Spread = 0.6 })
	pcall(function()
		local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.6
		clouds.Parent = workspace.Terrain
	end)
end

----------------------------------------------------------------------
-- Ar vieta laisva (ne sklype, ne lobby, ne ant kelio, ne ant kitos dekoracijos)
----------------------------------------------------------------------

local function isFree(position, radius)
	local flat = V(position.X, 0, position.Z)
	local distance = flat.Magnitude
	if distance < MAP.LobbyRadius + 4 + radius or distance > MAP.GroundSize / 2 - 8 then
		return false
	end
	local half = Settings.Layout.PlotSize / 2
	for i = 1, Settings.PlotCount do
		local lp = MapBuilder:GetPlotCFrame(i):PointToObjectSpace(V(position.X, LOBBY_Y, position.Z))
		if math.abs(lp.X) < half + 5 + radius and lp.Z > -half - 20 - radius and lp.Z < half + 5 + radius then
			return false
		end
		-- kelias iš lobby į sklypą
		local angle = math.rad(MapBuilder:GetPlotAngle(i))
		local dir = V(math.cos(angle), 0, math.sin(angle))
		local along = flat:Dot(dir)
		if along > 0 and along < MAP.PlotRingRadius then
			local across = (flat - dir * along).Magnitude
			if across < MAP.PathWidth / 2 + 3 + radius then
				return false
			end
		end
	end
	for _, other in ipairs(placed) do
		if (other[1] - flat).Magnitude < other[2] + radius then
			return false
		end
	end
	return true
end

-- Atsitiktinė laisva vieta miške (laumei): ne sklype, ne kelyje, ne ant medžio
function MapBuilder:RandomFreeSpot(rng, minR, maxR)
	rng = rng or Random.new()
	minR = minR or 70
	maxR = maxR or (MAP.GroundSize / 2 - 30)
	for _ = 1, 60 do
		local position = polar(rng:NextNumber() * 360, minR + rng:NextNumber() * (maxR - minR), 0)
		if isFree(position, 2.5) then
			return position
		end
	end
	return nil
end

local function reserve(position, radius)
	table.insert(placed, { V(position.X, 0, position.Z), radius })
end

local spotCounter = 0
local function findSpot(rng, radius, minR, maxR, tries)
	-- Kas 25 dekoracijas trumpa pauzė, kad serveris nestrigtų generuojant mišką
	spotCounter = spotCounter + 1
	if spotCounter % 25 == 0 then
		task.wait()
	end
	for _ = 1, tries or 40 do
		local angle = rng:NextNumber() * 360
		local r = minR + rng:NextNumber() * (maxR - minR)
		local position = polar(angle, r, 0)
		if isFree(position, radius) then
			reserve(position, radius)
			return position
		end
	end
	return nil
end

----------------------------------------------------------------------
-- Žemė (Terrain žolė), keliai, tvenkinys
----------------------------------------------------------------------
local function buildGround(map, rng)
	local ok = pcall(function()
		local terrain = workspace.Terrain
		terrain:FillBlock(CF(0, -6, 0), V(MAP.GroundSize, 12, MAP.GroundSize), M.Grass)
		-- Žolės įvairovė
		for _ = 1, 40 do
			local p = polar(rng:NextNumber() * 360, 60 + rng:NextNumber() * (MAP.GroundSize / 2 - 80), -2)
			terrain:FillCylinder(CF(p), 4, 10 + rng:NextNumber() * 25, rng:NextNumber() < 0.6 and M.LeafyGrass or M.Ground)
		end
		pcall(function()
			terrain.Decoration = false -- žolės stiebeliai prasikiša pro sklypų grindis ir mygtukus
		end)
		terrain.WaterColor = C(60, 120, 150)
		terrain.WaterTransparency = 0.5
		terrain.WaterWaveSize = 0.1
	end)
	if not ok then
		Build.Part({ Name = "Ground", Parent = map, Size = V(MAP.GroundSize, 2, MAP.GroundSize), CFrame = CF(0, -1, 0), Color = MAP.GrassColor, Material = M.Grass })
	end

	-- Keliai iš lobby į sklypus, su tvorelėmis ir fakelais
	local fromR = MAP.LobbyRadius - 2
	local toR = MAP.PlotRingRadius - Settings.Layout.PlotSize / 2
	local pathDecor = Build.Folder("PathDecor", map)
	for i = 1, Settings.PlotCount do
		local angle = MapBuilder:GetPlotAngle(i)
		local a = polar(angle, fromR, 0.3)
		local b = polar(angle, toR, 0.3)
		Build.Part({ Name = "Path", Parent = map, Size = V(MAP.PathWidth, 0.6, (b - a).Magnitude), CFrame = CFrame.lookAt((a + b) / 2, b), Color = C(150, 120, 80), Material = M.Ground })
		-- Akmenukai kelio pakraščiuose
		for step = 0, 6 do
			local r = fromR + 6 + step * 9
			for _, side in ipairs({ -1, 1 }) do
				local p = polar(angle + side * math.deg((MAP.PathWidth / 2 + 0.8) / r), r, 0)
				Build.Part({ Name = "EdgeStone", Parent = pathDecor, Size = V(1.2, 0.6, 1), CFrame = CF(p + V(0, 0.3, 0)) * CFrame.Angles(0, rng:NextNumber() * 3, 0), Color = C(140, 135, 125), Material = M.Slate, CanQuery = false, CanTouch = false, CastShadow = false })
			end
		end
		-- Tvorelės ir fakelai
		local fenceStart, fenceEnd = fromR + 8, toR - 4
		for _, side in ipairs({ -1, 1 }) do
			local prev = nil
			for r = fenceStart, fenceEnd, 8 do
				local p = polar(angle + side * math.deg((MAP.PathWidth / 2 + 2.5) / r), r, 0)
				if prev then
					fenceSegment(pathDecor, V(prev.X, 0, prev.Z), V(p.X, 0, p.Z), 0)
				end
				prev = p
			end
			Scenery.Torch(pathDecor, polar(angle + side * math.deg((MAP.PathWidth / 2 + 2.5) / (toR - 6)), toR - 6, 0), 6)
		end
	end
end

local function buildPond(map, rng)
	local center = findSpot(rng, 28, 260, 340, 80)
	if not center then
		return nil
	end
	local radius = 20
	pcall(function()
		local terrain = workspace.Terrain
		terrain:FillCylinder(CF(center + V(0, -4, 0)), 8, radius, M.Air)
		terrain:FillCylinder(CF(center + V(0, -7.5, 0)), 3, radius + 2, M.Sand)
		terrain:FillCylinder(CF(center + V(0, -3.8, 0)), 5.4, radius, M.Water)
		terrain:FillCylinder(CF(center + V(0, -1.5, 0)), 3, radius + 3, M.Sand)
		terrain:FillCylinder(CF(center + V(0, -3.8, 0)), 5.4, radius, M.Water)
	end)
	local folder = Build.Folder("Pond", map)
	for i = 1, 7 do
		local angle = rng:NextNumber() * 6.28
		local r = rng:NextNumber() * (radius - 4)
		Build.Part({ Name = "LilyPad", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(0.15, 2.4, 2.4), CFrame = CF(center + V(math.cos(angle) * r, -1.15, math.sin(angle) * r)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(70, 150, 60), Material = M.Grass, CanCollide = false, CanQuery = false, CanTouch = false })
	end
	for i = 1, 12 do
		local angle = i * 30 + rng:NextNumber() * 10
		local p = center + V(math.cos(math.rad(angle)) * (radius + 3), 0, math.sin(math.rad(angle)) * (radius + 3))
		if i % 3 == 0 then
			Scenery.Rock(folder, p, rng, 1)
		else
			Scenery.Reeds(folder, p, rng)
		end
	end
	-- Medinis lieptas
	local dir = (V(0, 0, 0) - V(center.X, 0, center.Z)).Unit
	local start = center + dir * (radius + 2)
	local pierCF = CFrame.lookAt(start, start - dir)
	Build.Part({ Name = "Pier", Parent = folder, Size = V(3.5, 0.4, 12), CFrame = pierCF * CF(0, 0.3, -5), Color = C(140, 95, 55), Material = M.WoodPlanks })
	for _, x in ipairs({ -1.5, 1.5 }) do
		for _, z in ipairs({ -2, -6, -10 }) do
			Build.Part({ Name = "PierPost", Parent = folder, Size = V(0.5, 4, 0.5), CFrame = pierCF * CF(x, -1.5, z), Color = C(90, 62, 38), Material = M.Wood })
		end
	end
	return center
end

----------------------------------------------------------------------
-- Žemėlapio pakraščiai: kalvų žiedas, upelis, laukai (javai, linai, rapsai)
----------------------------------------------------------------------
local hillBalls = {}        -- { Center = Vector3, Radius = number }

-- Kalvų paviršiaus aukštis (x, z) – pagal sudėtus Terrain rutulius
local function hillHeight(x, z)
	local best = 0
	for _, ball in ipairs(hillBalls) do
		local dx, dz = x - ball.Center.X, z - ball.Center.Z
		local d2 = dx * dx + dz * dz
		local r2 = ball.Radius * ball.Radius
		if d2 < r2 then
			local h = ball.Center.Y + math.sqrt(r2 - d2)
			if h > best then
				best = h
			end
		end
	end
	return best
end

local function buildHills(rng)
	local E = MAP.Edges
	hillBalls = {}
	local seed = rng:NextNumber() * 100
	for row = 1, 2 do
		local baseR = row == 1 and E.HillInnerR or E.HillOuterR
		local step = row == 1 and 4 or 5
		for a = 0, 359, step do
			local n = math.noise(a * 0.05, row * 3.1, seed)
			local radius = (row == 1 and 38 or 60) + n * 18 + rng:NextNumber() * 10
			local r = baseR + n * 18 + rng:NextNumber() * 8
			local peak = (row == 1 and 0.42 or 0.62) * radius + n * 8
			local center = polar(a, r, peak - radius)
			table.insert(hillBalls, { Center = center, Radius = radius })
		end
	end
	pcall(function()
		local terrain = workspace.Terrain
		for i, ball in ipairs(hillBalls) do
			terrain:FillBall(ball.Center, ball.Radius, M.Grass)
			if i % 20 == 0 then
				task.wait()
			end
		end
		-- Pievų įvairovė ant šlaitų ir uolėtos viršūnės
		for i, ball in ipairs(hillBalls) do
			local top = ball.Center + V(0, ball.Radius, 0)
			if top.Y > E.RockyAbove then
				terrain:FillBall(top + V(0, -3, 0), 9 + rng:NextNumber() * 6, M.Rock)
			elseif i % 3 == 0 then
				terrain:FillBall(top + V(rng:NextNumber() * 20 - 10, -4, rng:NextNumber() * 20 - 10), 12, M.LeafyGrass)
			end
		end
	end)
end

local function populateHills(nature, rng)
	local E = MAP.Edges
	local placedHere = 0
	for k = 1, E.HillTrees * 3 do
		if placedHere >= E.HillTrees then
			break
		end
		local a = rng:NextNumber() * 360
		local r = E.HillInnerR - 30 + rng:NextNumber() * (E.HillOuterR - E.HillInnerR + 70)
		local p = polar(a, r, 0)
		local h = hillHeight(p.X, p.Z)
		if h > 2 and h < E.RockyAbove then
			Scenery.ForestTree(nature, V(p.X, h - 0.6, p.Z), rng, 1 + rng:NextNumber() * 0.8)
			placedHere = placedHere + 1
		end
		if k % 30 == 0 then
			task.wait()
		end
	end
	for k = 1, E.HillRocks do
		local a = rng:NextNumber() * 360
		local r = E.HillInnerR - 20 + rng:NextNumber() * (E.HillOuterR - E.HillInnerR + 50)
		local p = polar(a, r, 0)
		local h = hillHeight(p.X, p.Z)
		if h > 1 then
			Scenery.Rock(nature, V(p.X, h - 0.5, p.Z), rng, 1 + rng:NextNumber() * 1.5)
		end
		if k % 30 == 0 then
			task.wait()
		end
	end
	-- Vėjo malūnai ant kalvų viršūnių (matosi iš toli)
	for i = 0, E.HillWindmills - 1 do
		local a = 25 + i * (360 / E.HillWindmills)
		local bestP, bestH = nil, 0
		for t = 0, 8 do
			local p = polar(a + t * 1.5, E.HillInnerR + 10 + t * 6, 0)
			local h = hillHeight(p.X, p.Z)
			if h > bestH and h < E.RockyAbove + 6 then
				bestP, bestH = p, h
			end
		end
		if bestP then
			Scenery.Windmill(nature, V(bestP.X, bestH - 0.5, bestP.Z), -V(bestP.X, 0, bestP.Z).Unit)
		end
	end
end

-- Vingiuojantis upelis nuo kalvų iki tvenkinio
local function buildStream(map, rng, pondCenter)
	if not pondCenter then
		return
	end
	local E = MAP.Edges
	local outward = V(pondCenter.X, 0, pondCenter.Z).Unit
	local side = V(-outward.Z, 0, outward.X)
	local start = outward * (E.HillInnerR + 10)
	local finish = V(pondCenter.X, 0, pondCenter.Z) + outward * 16
	local length = (start - finish).Magnitude
	local steps = math.floor(length / 3)
	local folder = Build.Folder("Stream", map)
	pcall(function()
		local terrain = workspace.Terrain
		for i = 0, steps do
			local t = i / steps
			local p = finish:Lerp(start, t) + side * math.sin(t * math.pi * 3.2) * 18
			local width = 4.2 + math.sin(t * 7) * 0.8
			terrain:FillBall(V(p.X, -1.2, p.Z), width + 1.5, M.Air)
			terrain:FillBall(V(p.X, -6.2, p.Z), width + 1, M.Sand)
			terrain:FillBall(V(p.X, -4.6, p.Z), width, M.Water)
			reserve(p, width + 4)
			if i % 12 == 0 then
				task.wait()
			end
			-- Akmenukai ir švendrai pakrantėse
			if i % 9 == 4 then
				local bank = p + side * (width + 2.5) * (i % 2 == 0 and 1 or -1)
				Scenery.Reeds(folder, bank, rng)
			elseif i % 13 == 6 then
				Scenery.Rock(folder, p + side * (width + 2.2), rng, 0.6)
			end
		end
	end)
	-- Medinis tiltelis per upelio vidurį
	local t = 0.5
	local mid = finish:Lerp(start, t) + side * math.sin(t * math.pi * 3.2) * 18
	local dir = (finish:Lerp(start, t + 0.02) + side * math.sin((t + 0.02) * math.pi * 3.2) * 18 - mid).Unit
	local bridgeCF = CFrame.lookAt(mid, mid + V(-dir.Z, 0, dir.X))
	Build.Part({ Name = "Bridge", Parent = folder, Size = V(4, 0.5, 13), CFrame = bridgeCF * CF(0, 0.6, 0), Color = C(140, 95, 55), Material = M.WoodPlanks })
	for _, x in ipairs({ -2, 2 }) do
		Build.Part({ Name = "BridgeRail", Parent = folder, Size = V(0.3, 1, 13), CFrame = bridgeCF * CF(x, 1.35, 0), Color = C(110, 72, 40), Material = M.Wood })
	end
end

-- Laukai: javai, linai (mėlyni žiedai), rapsai (geltoni)
local FIELD_TYPES = {
	{ Name = "Wheat", Stem = C(215, 185, 95), Top = C(235, 205, 110), Height = 1.8 },
	{ Name = "Flax", Stem = C(110, 150, 75), Top = C(110, 140, 230), Height = 1.2 },
	{ Name = "Rapeseed", Stem = C(100, 145, 60), Top = C(250, 225, 40), Height = 1.5 },
}

local function buildField(parent, center, kind, rng)
	local model = Build.Model("Field_" .. kind.Name, parent)
	local cf = CFrame.lookAt(center, V(0, center.Y, 0))
	local w, d = 38, 26
	Build.Part({ Name = "Soil", Parent = model, Size = V(w + 2, 0.4, d + 2), CFrame = cf * CF(0, 0.2, 0), Color = C(105, 75, 45), Material = M.Ground, CanCollide = false })
	local rows = 10
	for i = 0, rows - 1 do
		local z = -d / 2 + 1.3 + i * (d - 2.6) / (rows - 1)
		Build.Part({ Name = "Row", Parent = model, Size = V(w, kind.Height, 1.5), CFrame = cf * CF(0, 0.4 + kind.Height / 2, z), Color = kind.Stem, Material = M.Grass, CanCollide = false, CastShadow = false })
		Build.Part({ Name = "RowTop", Parent = model, Size = V(w, 0.35, 1.7), CFrame = cf * CF(0, 0.4 + kind.Height + 0.1, z), Color = kind.Top, Material = M.Grass, CanCollide = false, CastShadow = false })
	end
	-- Tvorelė iš karčių aplink
	for _, x in ipairs({ -w / 2 - 1.5, w / 2 + 1.5 }) do
		Build.Part({ Name = "FenceRail", Parent = model, Size = V(0.3, 0.3, d + 3), CFrame = cf * CF(x, 1, 0), Color = C(120, 85, 50), Material = M.Wood })
	end
	if kind.Name == "Wheat" then
		-- Kaliausė ir šieno ritiniai
		local s = cf * CF(4, 0, 0)
		Build.Part({ Name = "ScarecrowPole", Parent = model, Size = V(0.35, 5, 0.35), CFrame = s * CF(0, 2.5, 0), Color = C(110, 75, 45), Material = M.Wood })
		Build.Part({ Name = "ScarecrowArms", Parent = model, Size = V(4, 0.3, 0.3), CFrame = s * CF(0, 3.8, 0), Color = C(110, 75, 45), Material = M.Wood })
		Build.Part({ Name = "ScarecrowShirt", Parent = model, Size = V(1.6, 1.6, 0.6), CFrame = s * CF(0, 3.4, 0), Color = C(180, 60, 50), Material = M.Fabric })
		Build.Part({ Name = "ScarecrowHead", Parent = model, Shape = Enum.PartType.Ball, Size = V(1, 1, 1), CFrame = s * CF(0, 4.8, 0), Color = C(220, 190, 120), Material = M.Fabric })
		Build.Part({ Name = "ScarecrowHat", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.2, 1.8, 1.8), CFrame = s * CF(0, 5.25, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(200, 170, 90), Material = M.Grass })
		for k = 1, 3 do
			Build.Part({ Name = "HayBale", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2.4, 2.6, 2.6), CFrame = cf * CF(-w / 2 - 5, 1.3, -8 + k * 4) * CFrame.Angles(0, math.rad(90), 0), Color = C(220, 190, 100), Material = M.Grass })
		end
	end
end

local function buildFields(map, rng)
	local E = MAP.Edges
	local folder = Build.Folder("Fields", map)
	for i = 1, E.Fields do
		local center = findSpot(rng, 26, E.FieldMinR, E.FieldMaxR, 60)
		if center then
			buildField(folder, center, FIELD_TYPES[(i - 1) % #FIELD_TYPES + 1], rng)
		end
	end
end

-- Žemės įvairovė: daugiau žolės atspalvių, sausos žolės ir dobilų lopų
local function groundVariety(rng)
	pcall(function()
		local terrain = workspace.Terrain
		terrain:SetMaterialColor(M.Grass, C(96, 142, 62))
		terrain:SetMaterialColor(M.LeafyGrass, C(82, 128, 52))
		terrain:SetMaterialColor(M.Ground, C(120, 95, 62))
		for i = 1, MAP.Edges.GroundPatches do
			local p = polar(rng:NextNumber() * 360, 60 + rng:NextNumber() * (MAP.Edges.HillInnerR - 80), -2)
			local roll = rng:NextNumber()
			local material = roll < 0.55 and M.LeafyGrass or (roll < 0.8 and M.Ground or M.Mud)
			if isFree(p, 2) then
				terrain:FillCylinder(CF(p), 4, 8 + rng:NextNumber() * 22, material)
			end
			if i % 40 == 0 then
				task.wait()
			end
		end
	end)
end

----------------------------------------------------------------------
-- Miškas ir kaimo detalės aplink
----------------------------------------------------------------------
local function populate(map, rng)
	local nature = Build.Folder("Nature", map)
	local half = MAP.GroundSize / 2

	-- Vėjo malūnai
	for _ = 1, 2 do
		local p = findSpot(rng, 14, 240, 320, 60)
		if p then
			Scenery.Windmill(nature, p, -V(p.X, 0, p.Z).Unit)
		end
	end
	-- Ūkio kampeliai: šieno kupetos ir vežimai
	for _ = 1, 4 do
		local p = findSpot(rng, 12, 230, 340, 40)
		if p then
			Scenery.Cart(nature, CFrame.new(p) * CFrame.Angles(0, rng:NextNumber() * 6.28, 0))
			for k = 1, 3 do
				local hp = p + V(math.cos(k * 2.1) * 8, 0, math.sin(k * 2.1) * 8)
				Scenery.Haystack(nature, hp, rng)
			end
		end
	end
	-- Labai tankus miškas visur aplink (lengvesni medžiai – mažiau dalių); toliau – kalvos
	for _ = 1, MAP.ForestTrees do
		local p = findSpot(rng, 2.6, 250, MAP.Edges.HillInnerR - 25, 6)
		if p then
			Scenery.ForestTree(nature, p, rng, 1 + rng:NextNumber() * 0.9)
		end
	end
	-- Medžiai tarp sklypų ir prie kelių
	for _ = 1, MAP.MidTrees do
		local p = findSpot(rng, 3.5, MAP.LobbyRadius + 8, 270, 6)
		if p then
			Scenery.RandomTree(nature, p, rng)
		end
	end
	-- Krūmai, akmenys, gėlės, grybai
	for _ = 1, 110 do
		local p = findSpot(rng, 2, MAP.LobbyRadius + 6, half - 10, 5)
		if p then
			Scenery.Bush(nature, p, rng)
		end
	end
	for _ = 1, 50 do
		local p = findSpot(rng, 2.5, MAP.LobbyRadius + 6, half - 10, 5)
		if p then
			Scenery.Rock(nature, p, rng)
		end
	end
	for _ = 1, 70 do
		local p = findSpot(rng, 1.5, MAP.LobbyRadius + 4, half - 20, 5)
		if p then
			Scenery.Flowers(nature, p, rng)
		end
	end
	for _ = 1, 30 do
		local p = findSpot(rng, 0.8, 200, half - 10, 5)
		if p then
			Scenery.Mushroom(nature, p, rng)
		end
	end
end

----------------------------------------------------------------------
-- Papildomos lobby detalės
----------------------------------------------------------------------
local function decorateLobby(lobby, rng)
	local folder = Build.Folder("Details", lobby)
	local R = MAP.LobbyRadius
	-- Fakelai ir vėliavos aplink turgaus aikštę
	for i = 0, 11 do
		local angle = 15 + i * 30
		if i % 2 == 0 then
			Scenery.Torch(folder, polar(angle, R - 3, LOBBY_Y), 7)
		else
			Scenery.Banner(folder, polar(angle, R - 3, LOBBY_Y), 11)
		end
	end
	-- Suolai prie fontano
	for _, angle in ipairs({ 30, 150, 210, 330 }) do
		local p = polar(angle, 12.5, LOBBY_Y)
		Scenery.Bench(folder, CFrame.lookAt(p, V(0, LOBBY_Y, 0)) * CFrame.Angles(0, math.rad(180), 0))
	end
	-- Tvarkingai išdėstyti prekystaliai (po vieną tarp kelių) su statinėmis šalia
	marketStall(folder, polar(60, 20, LOBBY_Y), C(230, 180, 40))
	marketStall(folder, polar(240, 20, LOBBY_Y), C(60, 140, 70))
	for _, angle in ipairs({ 60, 150, 240 }) do
		Scenery.Barrel(folder, polar(angle + 12, 21, LOBBY_Y), rng)
	end
	-- Gėlių vazonai
	for _, angle in ipairs({ 0, 60, 120, 180, 240, 300 }) do
		local p = polar(angle, 9.5, LOBBY_Y)
		Build.Part({ Name = "Planter", Parent = folder, Size = V(2.2, 1.2, 2.2), CFrame = CF(p + V(0, 0.6, 0)), Color = C(150, 80, 50), Material = M.Brick, CanQuery = false, CanTouch = false })
		Scenery.Flowers(folder, p + V(0, 1.2, 0), rng, 4)
	end
end

function MapBuilder:Start()
	local rng = Random.new(1987)
	setupLighting()
	local map = workspace:FindFirstChild("Map")
	if not map then
		map = Build.Folder("Map", workspace)
		buildGround(map, rng)
	end

	local lobby = workspace:FindFirstChild("Lobby")
	if not lobby then
		lobby = Build.Model("Lobby", workspace)
		buildLobby(lobby)
		decorateLobby(lobby, rng)
	end
	findAnchors(lobby)

	if not map:FindFirstChild("Nature") then
		task.spawn(function()
			local pondCenter = buildPond(map, rng)
			buildStream(map, rng, pondCenter)
			buildFields(map, rng)
			groundVariety(rng)
			buildHills(rng)
			populate(map, rng)
			populateHills(map:FindFirstChild("Nature"), rng)
		end)
	end
end

return MapBuilder
