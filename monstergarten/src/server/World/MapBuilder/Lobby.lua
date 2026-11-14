-- Lobby "Monster Lane": a cosy street at dusk around the Monstergarten building.
local B = require(script.Parent.Builder)
local F = require(script.Parent.Props.Furniture)
local O = require(script.Parent.Props.Outdoor)
local ServerUtil = require(script.Parent.Parent.Parent.ServerUtil)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModelRegistry = require(ReplicatedStorage:WaitForChild("Shared").World.ModelRegistry)
local BabiesConfig = require(ReplicatedStorage:WaitForChild("Shared").Config.Babies)
local P = B.Palette
local M = Enum.Material

local Lobby = {}

local function cfAt(x: number, y: number, z: number, dx: number?, dz: number?): CFrame
	local pos = Vector3.new(x, y, z)
	return CFrame.lookAt(pos, pos + Vector3.new(dx or 0, 0, dz or -1))
end

local function building(parent: Instance)
	local m = B.model(parent, "MonstergartenHouse")
	local base = CFrame.new(0, 0, -62) * CFrame.Angles(0, math.pi, 0) -- front faces the street (+Z)
	B.root(m, base * CFrame.new(0, 10, 0))
	-- body
	B.part(m, Vector3.new(56, 22, 28), base * CFrame.new(0, 11, 0), P.Peach, M.SmoothPlastic)
	B.part(m, Vector3.new(58, 2, 30), base * CFrame.new(0, 1, 0), P.Lavender, M.SmoothPlastic)
	-- bonnet roof: big rounded top + frill of balls + pom-pom
	B.cyl(m, 60, 30, base * CFrame.new(0, 22, 0), P.Pink, M.Fabric)
	for i = -14, 14 do
		B.ball(m, 2.2, (base * CFrame.new(i * 2.05, 21.6, -15.2)).Position, P.White, M.Fabric, { CanCollide = false })
	end
	B.ball(m, 6, (base * CFrame.new(0, 38.5, 0)).Position, P.Cream, M.Fabric)
	-- bonnet ribbons
	B.part(m, Vector3.new(2, 14, 0.4), base * CFrame.new(-31, 16, -6) * CFrame.Angles(0, 0, math.rad(8)), P.Lavender, M.Fabric, { CanCollide = false })
	B.part(m, Vector3.new(2, 14, 0.4), base * CFrame.new(31, 16, -6) * CFrame.Angles(0, 0, math.rad(-8)), P.Lavender, M.Fabric, { CanCollide = false })
	-- windows that glow
	for _, x in { -20, -10, 10, 20 } do
		for _, y in { 7, 15 } do
			local w = B.part(m, Vector3.new(5, 5, 0.4), base * CFrame.new(x, y, -14.1), Color3.fromRGB(255, 220, 140), M.Neon, { CanCollide = false })
			w.CastShadow = false
			B.deco(m, Vector3.new(5.8, 0.5, 0.8), base * CFrame.new(x, y - 2.8, -14.3), P.White)
			B.deco(m, Vector3.new(0.3, 5, 0.6), base * CFrame.new(x, y, -14.35), P.White)
			B.deco(m, Vector3.new(5, 0.3, 0.6), base * CFrame.new(x, y, -14.35), P.White)
		end
	end
	-- front door
	B.part(m, Vector3.new(8, 12, 1), base * CFrame.new(0, 6, -14.2), P.Plum, M.Wood)
	B.cyl(m, 1, 8, base * CFrame.new(0, 12, -14.2) * CFrame.Angles(0, math.rad(90), 0), P.Plum, M.Wood)
	B.ball(m, 0.8, (base * CFrame.new(2.6, 6, -14.9)).Position, P.Yellow, M.Metal, { CanCollide = false })
	-- sign
	local sign = B.part(m, Vector3.new(34, 5, 0.6), base * CFrame.new(0, 26.5, -15.5), P.Plum, M.SmoothPlastic, { CanCollide = false, Name = "Sign" })
	local _, label = B.surfaceText(sign, Enum.NormalId.Front, "MONSTERGARTEN", { TextColor3 = Color3.fromRGB(255, 220, 140) })
	label.Name = "SignText"
	local light = Instance.new("SurfaceLight")
	light.Face = Enum.NormalId.Front
	light.Color = Color3.fromRGB(255, 200, 140)
	light.Range = 14
	light.Brightness = 2
	light.Parent = sign
	B.tag(sign, "LobbySign")
	-- porch lamps
	for _, x in { -6, 6 } do
		local lamp = B.ball(m, 1.4, (base * CFrame.new(x, 10, -15.2)).Position, Color3.fromRGB(255, 190, 110), M.Neon, { CanCollide = false })
		B.pointLight(lamp, Color3.fromRGB(255, 170, 90), 18, 1.5)
	end
	-- chimney with smoke
	B.part(m, Vector3.new(4, 10, 4), base * CFrame.new(18, 34, 6), Color3.fromRGB(190, 110, 95), M.Brick)
	local smoke = B.marker(m, "Smoke", base * CFrame.new(18, 39.5, 6))
	B.particles(smoke, {
		Color = ColorSequence.new(Color3.fromRGB(220, 215, 230)),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 5) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }),
		Rate = 3,
		Lifetime = NumberRange.new(5, 7),
		Speed = NumberRange.new(2, 3),
		SpreadAngle = Vector2.new(12, 12),
	})
	return m
end

local function shiftDoor(parent: Instance, x: number, z: number, doorId: string, mode: string, color: Color3, scale: number)
	local m = B.model(parent, "Door_" .. doorId)
	local base = CFrame.new(x, 0, z)
	B.root(m, base * CFrame.new(0, 5, 0))
	local w, h = 9 * scale, 12 * scale
	for _, sx in { -1, 1 } do
		B.part(m, Vector3.new(1.6, h, 1.6), base * CFrame.new(sx * w / 2, h / 2, 0), P.Cream, M.SmoothPlastic)
		B.ball(m, 2.2, (base * CFrame.new(sx * w / 2, h + 0.5, 0)).Position, color, M.SmoothPlastic)
	end
	B.part(m, Vector3.new(w + 1.6, 1.6, 1.6), base * CFrame.new(0, h, 0), P.Cream, M.SmoothPlastic)
	B.cyl(m, 1.6, w * 0.7, base * CFrame.new(0, h + 0.6, 0) * CFrame.Angles(0, math.rad(90), 0), color, M.SmoothPlastic, { CanCollide = false })
	local portal = B.part(m, Vector3.new(w - 1.6, h - 1, 0.3), base * CFrame.new(0, (h - 1) / 2 + 0.2, 0), color, M.Neon, { CanCollide = false, Transparency = 0.35, Name = "Portal" })
	portal.CastShadow = false
	B.pointLight(portal, color, 16, 1.2)
	B.particles(portal, {
		Color = ColorSequence.new(color, P.White),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) }),
		Rate = 10,
		Lifetime = NumberRange.new(1, 2),
		Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(40, 40),
		LightEmission = 0.6,
	})
	-- screen above
	local screen = B.part(m, Vector3.new(w + 1, 4.5 * scale, 0.5), base * CFrame.new(0, h + 3.6 * scale, 0), P.Plum, M.SmoothPlastic, { CanCollide = false, Name = "Screen" })
	local sg = Instance.new("SurfaceGui")
	sg.Name = "ScreenGui"
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = screen
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromScale(1, 0.45)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 230, 160)
	title.Text = mode
	title.Parent = sg
	local info = title:Clone()
	info.Name = "Info"
	info.Position = UDim2.fromScale(0, 0.45)
	info.Size = UDim2.fromScale(1, 0.55)
	info.TextColor3 = P.Cream
	info.Text = "0/6"
	info.Parent = sg
	-- pad (players stand on it to join)
	local pad = B.part(m, Vector3.new(w - 1, 0.4, 6), base * CFrame.new(0, 0.3, 4.5), color, M.Neon, { CanCollide = false, CanTouch = true, Transparency = 0.25, Name = "Pad" })
	pad.CastShadow = false
	B.part(m, Vector3.new(w + 0.4, 0.3, 7), base * CFrame.new(0, 0.15, 4.5), P.Cream, M.SmoothPlastic)
	B.tag(pad, "QueuePad")
	pad:SetAttribute("DoorId", doorId)
	pad:SetAttribute("Mode", mode)
	m:SetAttribute("DoorId", doorId)
	B.tag(m, "QueueDoor")
	return m
end

local function kiosk(parent: Instance, cf: CFrame)
	local m = B.model(parent, "ShopKiosk")
	B.root(m, cf * CFrame.new(0, 4, 0))
	B.part(m, Vector3.new(12, 4, 4), cf * CFrame.new(0, 2, -2), P.Mint, M.WoodPlanks)
	B.part(m, Vector3.new(12.4, 0.5, 4.6), cf * CFrame.new(0, 4.2, -2.2), P.Wood, M.Wood)
	B.part(m, Vector3.new(12, 10, 0.6), cf * CFrame.new(0, 5, 3), P.Peach, M.WoodPlanks)
	for _, sx in { -5.8, 5.8 } do
		B.part(m, Vector3.new(0.6, 10, 0.6), cf * CFrame.new(sx, 5, -3.6), P.White, M.Wood)
	end
	-- striped awning
	for i = 0, 7 do
		B.wedge(m, Vector3.new(1.6, 1.4, 7), cf * CFrame.new(-5.6 + i * 1.6, 10.6, 0) * CFrame.Angles(0, math.pi, 0), if i % 2 == 0 then P.Pink else P.White, M.Fabric, { CanCollide = false })
	end
	local sign = B.part(m, Vector3.new(8, 2, 0.4), cf * CFrame.new(0, 12.4, -3.4), P.Plum, M.SmoothPlastic, { CanCollide = false })
	B.surfaceText(sign, Enum.NormalId.Front, "🛒 SHOP", { TextColor3 = P.Yellow })
	-- goods on the counter
	for i, x in { -4.5, -2.6, 2.6, 4.5 } do
		B.ball(m, 0.9, (cf * CFrame.new(x, 4.9, -2.2)).Position, ({ P.Red, P.Yellow, P.Mint, P.Pumpkin })[i], M.SmoothPlastic, { CanCollide = false })
	end
	local npc = B.marker(m, "ShopkeeperSpot", cf * CFrame.new(0, 3, 1))
	npc:SetAttribute("NPC", "Shopkeeper")
	B.tag(npc, "NPCSpot")
	local lamp = B.ball(m, 1, (cf * CFrame.new(0, 9.5, -1)).Position, Color3.fromRGB(255, 200, 130), M.Neon, { CanCollide = false })
	B.pointLight(lamp, Color3.fromRGB(255, 190, 120), 16, 1.2)
	ServerUtil.prompt(sign.Parent:FindFirstChild("Root") :: BasePart, "OpenShop", { Text = "Shop", Distance = 12 })
	return m
end

local function wardrobe(parent: Instance, cf: CFrame)
	local m = B.model(parent, "Wardrobe")
	local root = B.root(m, cf * CFrame.new(0, 4, 0))
	B.part(m, Vector3.new(7, 10, 3), cf * CFrame.new(0, 5, 0), P.Lavender, M.Wood)
	B.part(m, Vector3.new(7.6, 0.8, 3.4), cf * CFrame.new(0, 10.4, 0), P.Plum, M.Wood)
	B.deco(m, Vector3.new(0.1, 9, 0.2), cf * CFrame.new(0, 5, -1.55), P.Plum)
	for _, sx in { -0.5, 0.5 } do
		B.ball(m, 0.5, (cf * CFrame.new(sx, 5.5, -1.7)).Position, P.Yellow, M.Metal, { CanCollide = false })
	end
	-- mirror next to it
	B.part(m, Vector3.new(0.6, 9, 0.6), cf * CFrame.new(6, 4.5, 0), P.Wood, M.Wood)
	B.deco(m, Vector3.new(3.2, 7, 0.2), cf * CFrame.new(6, 5, -0.4), Color3.fromRGB(210, 230, 240), M.Glass, { Reflectance = 0.4 })
	B.deco(m, Vector3.new(3.6, 7.4, 0.15), cf * CFrame.new(6, 5, -0.3), P.Pink)
	local sign = B.part(m, Vector3.new(6, 1.6, 0.3), cf * CFrame.new(0, 11.8, -1), P.Cream, M.SmoothPlastic, { CanCollide = false })
	B.surfaceText(sign, Enum.NormalId.Front, "👗 WARDROBE", { TextColor3 = P.Plum })
	ServerUtil.prompt(root, "OpenWardrobe", { Text = "Wardrobe", Distance = 12 })
	return m
end

local function petPen(parent: Instance, center: Vector3)
	local m = B.model(parent, "PetPen")
	local w, d = 30, 18
	O.fence(m, center + Vector3.new(-w / 2, 0, -d / 2), center + Vector3.new(w / 2, 0, -d / 2), P.Pink)
	O.fence(m, center + Vector3.new(-w / 2, 0, d / 2), center + Vector3.new(w / 2, 0, d / 2), P.Pink)
	O.fence(m, center + Vector3.new(-w / 2, 0, -d / 2), center + Vector3.new(-w / 2, 0, d / 2), P.Pink)
	O.fence(m, center + Vector3.new(w / 2, 0, -d / 2), center + Vector3.new(w / 2, 0, d / 2), P.Pink)
	B.part(m, Vector3.new(w, 0.2, d), CFrame.new(center + Vector3.new(0, 0.1, 0)), Color3.fromRGB(150, 210, 120), M.Grass, { CanCollide = false })
	local area = B.marker(m, "PetArea", CFrame.new(center + Vector3.new(0, 1.5, 0)), Vector3.new(w - 4, 1, d - 4))
	B.tag(area, "PetArea")
	O.sandbox(m, cfAt(center.X - 9, 0, center.Z), 6)
	B.ball(m, 1.6, center + Vector3.new(6, 0.8, 3), P.Red, M.SmoothPlastic)
	B.ball(m, 1.2, center + Vector3.new(9, 0.6, -4), P.Blue, M.SmoothPlastic)
	local sign = B.part(m, Vector3.new(6, 2, 0.4), CFrame.new(center + Vector3.new(0, 4.5, -d / 2 - 0.6)), P.Cream, M.SmoothPlastic, { CanCollide = false })
	B.part(m, Vector3.new(0.5, 4, 0.5), CFrame.new(center + Vector3.new(0, 2, -d / 2 - 0.6)), P.Wood, M.Wood)
	B.surfaceText(sign, Enum.NormalId.Front, "🐾 PETS", { TextColor3 = P.Plum })
	ServerUtil.prompt(sign, "OpenPets", { Text = "Pets", Distance = 10 })
	return m
end

local function leaderboard(parent: Instance, cf: CFrame, board: string, title: string)
	local m = B.model(parent, "Leaderboard_" .. board)
	B.root(m, cf * CFrame.new(0, 6, 0))
	for _, sx in { -4.5, 4.5 } do
		B.part(m, Vector3.new(0.8, 14, 0.8), cf * CFrame.new(sx, 7, 0.6), P.DarkWood, M.Wood)
	end
	local panel = B.part(m, Vector3.new(9, 11, 0.6), cf * CFrame.new(0, 8, 0), P.Plum, M.SmoothPlastic, { Name = "Panel" })
	B.part(m, Vector3.new(10, 1, 1.4), cf * CFrame.new(0, 14, 0.2), P.Pink, M.SmoothPlastic)
	local sg = Instance.new("SurfaceGui")
	sg.Name = "BoardGui"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	sg.Parent = panel
	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.Size = UDim2.fromScale(1, 0.14)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 220, 140)
	t.Text = title
	t.Parent = sg
	local list = Instance.new("TextLabel")
	list.Name = "List"
	list.Position = UDim2.fromScale(0.05, 0.16)
	list.Size = UDim2.fromScale(0.9, 0.82)
	list.BackgroundTransparency = 1
	list.Font = Enum.Font.GothamBold
	list.TextScaled = true
	list.TextColor3 = P.Cream
	list.TextXAlignment = Enum.TextXAlignment.Left
	list.TextYAlignment = Enum.TextYAlignment.Top
	list.Text = "..."
	list.Parent = sg
	B.tag(m, "Leaderboard")
	m:SetAttribute("Board", board)
	return m
end

local function giftBox(parent: Instance, cf: CFrame)
	local m = B.model(parent, "DailyGift")
	local root = B.root(m, cf * CFrame.new(0, 1.5, 0))
	B.part(m, Vector3.new(3.4, 3, 3.4), cf * CFrame.new(0, 1.5, 0), P.Pink, M.SmoothPlastic)
	B.part(m, Vector3.new(3.8, 0.8, 3.8), cf * CFrame.new(0, 3.2, 0), P.Lavender, M.SmoothPlastic)
	B.deco(m, Vector3.new(0.6, 3.9, 3.9), cf * CFrame.new(0, 1.9, 0), P.Yellow)
	B.deco(m, Vector3.new(3.9, 3.9, 0.6), cf * CFrame.new(0, 1.9, 0), P.Yellow)
	B.ball(m, 1, (cf * CFrame.new(-0.6, 4, 0)).Position, P.Yellow, M.SmoothPlastic, { CanCollide = false })
	B.ball(m, 1, (cf * CFrame.new(0.6, 4, 0)).Position, P.Yellow, M.SmoothPlastic, { CanCollide = false })
	B.tag(m, "DailyGift")
	local sparkle = B.particles(root, {
		Color = ColorSequence.new(P.Yellow),
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) }),
		Rate = 6,
		Lifetime = NumberRange.new(1, 1.5),
		Speed = NumberRange.new(1, 3),
		SpreadAngle = Vector2.new(180, 180),
		LightEmission = 1,
	})
	sparkle.Name = "Sparkle"
	ServerUtil.prompt(root, "OpenDaily", { Text = "Daily gift", Distance = 10 })
	return m
end

function Lobby.build(parent: Instance): Model
	local m = B.model(nil, "Lobby")
	local floors = B.folder(m, "Floors")
	local decor = B.folder(m, "Decor")
	-- ground + street
	B.floor(floors, -130, -110, 130, 100, 0, Color3.fromRGB(110, 160, 105), M.Grass, 2)
	B.part(floors, Vector3.new(120, 0.2, 24), CFrame.new(0, 0.1, -24), Color3.fromRGB(150, 140, 160), M.Cobblestone)
	B.part(floors, Vector3.new(24, 0.2, 80), CFrame.new(0, 0.13, 20), Color3.fromRGB(150, 140, 160), M.Cobblestone)
	B.part(floors, Vector3.new(18, 0.2, 14), CFrame.new(0, 0.16, -42), Color3.fromRGB(200, 180, 150), M.Cobblestone)

	building(m)

	-- Spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(10, 0.4, 10)
	spawn.CFrame = CFrame.new(0, 0.3, 18)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = P.Lavender
	spawn.Material = M.Neon
	spawn.Transparency = 0.6
	spawn.CanCollide = false
	spawn.Parent = m
	local spawnDecal = spawn:FindFirstChildOfClass("Decal")
	if spawnDecal then
		spawnDecal:Destroy()
	end

	-- Shift doors, solo + tutorial doors
	local doors = B.folder(m, "Doors")
	local doorColors = { P.Lavender, P.Pink, P.Peach, P.Mint }
	for i, x in { -27, -9, 9, 27 } do
		shiftDoor(doors, x, -30, "Shift" .. i, "Shift", doorColors[i], 1)
	end
	shiftDoor(doors, 46, -26, "Solo", "Solo", Color3.fromRGB(120, 220, 130), 0.75)
	local tut = shiftDoor(doors, -46, -26, "Tutorial", "Tutorial", P.Yellow, 0.75)
	local arrow = B.wedge(tut, Vector3.new(2, 2, 3), CFrame.new(-46, 16, -26) * CFrame.Angles(math.rad(90), 0, 0), P.Yellow, M.Neon, { CanCollide = false, Name = "Arrow" })
	B.tag(arrow, "Bobber")

	kiosk(m, cfAt(-52, 0, 14, 1, 0))
	-- Shopkeeper behind the kiosk counter (the author's model when available)
	local okNpc, keeper = pcall(ModelRegistry.getNPC, "Shopkeeper")
	if okNpc and keeper then
		B.part(m, Vector3.new(2.6, 2.6, 8), CFrame.new(-53.8, 1.3, 14), P.DarkWood, M.WoodPlanks) -- platform behind the counter
		local pos = Vector3.new(-53.8, 2.6 + (keeper:GetAttribute("FloorOffset") or 3), 14)
		keeper:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(1, 0, 0)))
		keeper:SetAttribute("Anim", "Idle")
		B.tag(keeper, "NPCModel")
		keeper.Parent = m
	end
	-- Monster gallery: every baby on a little pedestal with its name
	local gallery = B.model(m, "MonsterGallery")
	for i, id in BabiesConfig.Order do
		local def = BabiesConfig.Defs[id]
		local x = -84 + (i - 1) * 6.4
		local base = CFrame.new(x, 0, 54)
		B.column(gallery, 1.2, 4.6, (base * CFrame.new(0, 0.6, 0)).Position, P.Lavender, M.SmoothPlastic)
		B.column(gallery, 0.3, 5, (base * CFrame.new(0, 1.35, 0)).Position, P.Cream, M.SmoothPlastic)
		local plate = B.part(gallery, Vector3.new(3.6, 1, 0.2), base * CFrame.new(0, 0.7, -2.35), P.Cream, M.SmoothPlastic, { CanCollide = false })
		B.surfaceText(plate, Enum.NormalId.Front, def.Name.en .. " / " .. def.Name.lt, { TextColor3 = P.Plum })
		local okB, statue = pcall(ModelRegistry.getBaby, id)
		if okB and statue then
			local pos = Vector3.new(x, 1.5 + (statue:GetAttribute("FloorOffset") or 1.5), 54)
			statue:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1)))
			statue.Name = id .. "Statue"
			statue:SetAttribute("Anim", "Happy")
			B.tag(statue, "NPCModel")
			statue.Parent = gallery
		end
	end
	local gsign = B.part(gallery, Vector3.new(14, 2.4, 0.4), CFrame.new(-55, 6, 59), P.Plum, M.SmoothPlastic, { CanCollide = false })
	B.surfaceText(gsign, Enum.NormalId.Front, "👾 MONSTER GALLERY", { TextColor3 = Color3.fromRGB(255, 220, 140) })
	B.part(gallery, Vector3.new(0.5, 6, 0.5), CFrame.new(-61, 3, 59.3), P.DarkWood, M.Wood)
	B.part(gallery, Vector3.new(0.5, 6, 0.5), CFrame.new(-49, 3, 59.3), P.DarkWood, M.Wood)
	wardrobe(m, cfAt(52, 0, 14, -1, 0))
	petPen(m, Vector3.new(0, 0, 52))
	leaderboard(m, cfAt(-30, 0, 34, 0.5, -1), "Stars", "⭐ TOP NANNIES")
	leaderboard(m, cfAt(30, 0, 34, -0.5, -1), "Weekly", "🏆 BEST SHIFT (WEEK)")
	giftBox(m, cfAt(9, 0, 8))

	-- Decorations
	for _, p in { { -14, -12 }, { 14, -12 }, { -14, 30 }, { 14, 30 }, { -40, -6 }, { 40, -6 }, { -60, -30 }, { 60, -30 } } do
		O.lampPost(decor, cfAt(p[1], 0, p[2]))
	end
	local r = Random.new(99)
	for _ = 1, 16 do
		local x = r:NextNumber(-70, 70)
		local z = r:NextNumber(-48, 70)
		if math.abs(x) > 16 or z > 70 then
			O.pumpkin(decor, cfAt(x, 0, z, r:NextNumber(-1, 1), -1), r:NextNumber(1.4, 2.6), r:NextNumber() > 0.4)
		end
	end
	for _, p in { { -70, 0 }, { 70, 0 }, { -78, 40 }, { 78, 40 }, { -80, -60 }, { 80, -60 }, { -45, 70 }, { 45, 70 } } do
		O.tree(decor, cfAt(p[1], 0, p[2]), r:NextNumber(1, 1.4), Color3.fromRGB(200, 150, 220):Lerp(Color3.fromRGB(255, 160, 90), r:NextNumber()))
	end
	for _, p in { { -20, 8 }, { 20, 8 }, { -36, -44 }, { 36, -44 }, { -26, 46 }, { 26, 46 } } do
		O.bush(decor, cfAt(p[1], 0, p[2]))
	end
	O.bench(decor, cfAt(-18, 0, 20, 1, 0), P.Lavender)
	O.bench(decor, cfAt(18, 0, 20, -1, 0), P.Mint)
	O.mailbox(decor, cfAt(-16, 0, 10, 1, 0))
	O.balloon(decor, Vector3.new(40, 70, -10))
	O.fence(decor, Vector3.new(-90, 0, -50), Vector3.new(-90, 0, 80), P.White)
	O.fence(decor, Vector3.new(90, 0, -50), Vector3.new(90, 0, 80), P.White)
	O.fence(decor, Vector3.new(-90, 0, 80), Vector3.new(90, 0, 80), P.White)
	for _, p in { { -35, 0 }, { 35, 0 }, { -10, 62 }, { 10, 62 } } do
		O.flowers(decor, cfAt(p[1], 0, p[2]), 12, Random.new(p[1] + p[2] * 3))
	end
	-- Trees all around: big ones at the edge of the map, small ones near the centre.
	O.forest(decor, -125, -105, 125, 95, Vector3.new(0, 0, -10), 130, {
		{ -36, -82, 36, -42 }, -- Monstergarten house
		{ -62, -40, 62, -12 }, -- shift doors + street
		{ -14, -12, 14, 62 }, -- main street to the pet pen
		{ -62, 2, -40, 26 }, -- shop kiosk
		{ 40, 2, 62, 26 }, -- wardrobe
		{ -18, 42, 18, 64 }, -- pet pen
		{ -38, 26, -22, 40 }, { 22, 26, 38, 40 }, -- leaderboards
		{ -24, 4, 24, 30 }, -- spawn plaza, benches, gift
		{ -92, 78, 92, 82 }, { -92, -52, -88, 82 }, { 88, -52, 92, 82 }, -- fences
		{ -90, 46, -18, 64 }, -- monster gallery
	}, 13, 2024)

	-- bats + low fog particles
	local bats = B.marker(decor, "Bats", CFrame.new(0, 40, -40), Vector3.new(120, 4, 60))
	B.particles(bats, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(Color3.fromRGB(60, 40, 90)),
		Size = NumberSequence.new(0.8),
		Rate = 2,
		Lifetime = NumberRange.new(6, 9),
		Speed = NumberRange.new(4, 7),
		SpreadAngle = Vector2.new(180, 30),
	})
	B.tag(bats, "AmbientParticles")
	local fog = B.marker(decor, "GroundFog", CFrame.new(0, 1, 0), Vector3.new(160, 1, 140))
	B.particles(fog, {
		Color = ColorSequence.new(Color3.fromRGB(200, 190, 230)),
		Size = NumberSequence.new(8),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.85), NumberSequenceKeypoint.new(1, 1) }),
		Rate = 6,
		Lifetime = NumberRange.new(8, 12),
		Speed = NumberRange.new(0.3, 0.8),
		SpreadAngle = Vector2.new(180, 0),
	})
	B.tag(fog, "AmbientParticles")

	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d.Size.Magnitude < 1.2 then
			d.CastShadow = false
			d.CanCollide = false
		end
	end
	m.Parent = parent
	return m
end

return Lobby
