--[[
	WeaponService – ginklai, perkami už litus lobby kalvėje (šaukštas, kočėlas, keptuvė).
	- Ginklu galima nustumti kitus žaidėjus (nežeidžia). Lobby (turgus) – saugi zona.
	- Nupirkti ginklai išsaugomi (data.weapons) ir lieka po rebirth.
	- Pirkimas: užlipti ant mygtuko kalvėje arba paspausti E.
	Kainos, jėga, atstumas ir pertrauka – Settings.Weapons.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Texts = require(Config:WaitForChild("Texts"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Build = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("Build"))

local W = Settings.Weapons
local V = Vector3.new
local CF = CFrame.new
local C = Color3.fromRGB

local WeaponService = {}
local S
local defsById = {}
local pads = {}                  -- { Part = pad, Def = def }
local inside = {}                -- [player] = pad
local cooldowns = {}             -- [player] = { [id] = os.clock() }

for _, def in ipairs(W.Items) do
	defsById[def.Id] = def
end

----------------------------------------------------------------------
-- Įrankių (Tool) modeliai iš Parts
----------------------------------------------------------------------
local GRIP_ROTATION = CFrame.Angles(math.rad(90), math.rad(90), 0)

local function part(parent, handle, name, size, offset, color, material, meshType)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Wood
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = handle.CFrame * offset
	if meshType then
		Build.Mesh(p, meshType)
	end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = parent
	return p
end

local function makeTool(def, lang)
	local tool = Instance.new("Tool")
	tool.Name = Texts.Get(lang, "Weapon_" .. def.Id)
	tool.ToolTip = Texts.Get(lang, "WeaponHint")
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("WeaponId", def.Id)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.CanCollide = false
	handle.CanQuery = false
	handle.CanTouch = false
	handle.Massless = true
	handle.TopSurface = Enum.SurfaceType.Smooth
	handle.BottomSurface = Enum.SurfaceType.Smooth
	handle.CFrame = CF()

	local gripZ
	if def.Id == "Spoon" then
		handle.Size = V(0.3, 0.3, 3.2)
		handle.Color = C(205, 165, 105)
		handle.Material = Enum.Material.Wood
		handle.Parent = tool
		part(tool, handle, "Bowl", V(0.95, 0.3, 1.25), CF(0, 0, 2.05), C(205, 165, 105), Enum.Material.Wood, Enum.MeshType.Sphere)
		gripZ = -1.25
	elseif def.Id == "RollingPin" then
		handle.Size = V(0.8, 0.8, 3)
		handle.Color = C(220, 185, 130)
		handle.Material = Enum.Material.Wood
		handle.Parent = tool
		for _, z in ipairs({ -1.85, 1.85 }) do
			part(tool, handle, "End", V(0.35, 0.35, 0.7), CF(0, 0, z), C(160, 110, 60), Enum.Material.Wood)
		end
		gripZ = -1.85
	elseif def.Id == "Broom" then
		handle.Size = V(0.25, 0.25, 4.4)
		handle.Color = C(140, 95, 55)
		handle.Material = Enum.Material.Wood
		handle.Parent = tool
		part(tool, handle, "Binding", V(0.45, 0.45, 0.3), CF(0, 0, 2.2), C(170, 40, 40), Enum.Material.Fabric)
		local bristles = part(tool, handle, "Bristles", V(1.5, 0.35, 1.3), CF(0, 0, 3.0), C(225, 190, 100), Enum.Material.Grass)
		Build.Mesh(bristles, Enum.MeshType.Sphere)
		gripZ = -1.6
	elseif def.Id == "CepelinasCannon" then
		handle.Size = V(0.35, 0.6, 1.2)
		handle.Color = C(90, 60, 35)
		handle.Material = Enum.Material.Wood
		handle.Parent = tool
		local barrel = part(tool, handle, "Barrel", V(2.4, 0.75, 0.75), CF(0, 0.45, 1.0) * CFrame.Angles(0, math.rad(90), 0), C(60, 60, 65), Enum.Material.Metal)
		barrel.Shape = Enum.PartType.Cylinder
		part(tool, handle, "Ring", V(0.9, 0.9, 0.15), CF(0, 0.45, 2.1), C(220, 180, 60), Enum.Material.Metal)
		local ammo = part(tool, handle, "Ammo", V(0.55, 0.55, 0.85), CF(0, 0.45, 2.35), C(225, 220, 200), Enum.Material.SmoothPlastic, Enum.MeshType.Sphere)
		ammo.Name = "Ammo"
		gripZ = -0.3
	elseif def.Id == "SakotisClub" then
		handle.Size = V(0.32, 0.32, 1.8)
		handle.Color = C(120, 80, 45)
		handle.Material = Enum.Material.Wood
		handle.Parent = tool
		for i = 0, 4 do
			local radius = 1.3 - i * 0.2
			local layer = part(tool, handle, "Layer", V(0.45, radius, radius), CF(0, 0, 1.2 + i * 0.45) * CFrame.Angles(0, math.rad(90), 0), C(215, 160, 70), Enum.Material.SmoothPlastic)
			layer.Shape = Enum.PartType.Cylinder
			for k = 0, 3 do
				local a = k * math.pi / 2 + i * 0.4
				part(tool, handle, "Spike", V(0.18, 0.18, 0.3), CF(math.cos(a) * radius / 2, math.sin(a) * radius / 2, 1.2 + i * 0.45), C(150, 95, 40), Enum.Material.SmoothPlastic)
			end
		end
		gripZ = -0.6
	elseif def.Id == "AmberStaff" then
		handle.Size = V(0.22, 0.22, 4.6)
		handle.Color = C(240, 190, 55)
		handle.Material = Enum.Material.Metal
		handle.Parent = tool
		part(tool, handle, "Gem", V(0.6, 0.6, 0.7), CF(0, 0, 2.7), C(255, 150, 30), Enum.Material.Neon)
		for _, o in ipairs({ V(0.32, 0.32, 0), V(-0.32, 0.32, 0), V(0.32, -0.32, 0), V(-0.32, -0.32, 0) }) do
			part(tool, handle, "Cage", V(0.08, 0.08, 0.9), CF(o.X, o.Y, 2.7), C(240, 190, 55), Enum.Material.Metal)
		end
		gripZ = -1.6
	else -- Pan
		handle.Size = V(0.3, 0.3, 2.4)
		handle.Color = C(40, 40, 42)
		handle.Material = Enum.Material.Metal
		handle.Parent = tool
		local pan = part(tool, handle, "Pan", V(0.25, 2.6, 2.6), CF(0, 0, 2.4) * CFrame.Angles(0, 0, math.rad(90)), C(45, 45, 48), Enum.Material.Metal)
		pan.Shape = Enum.PartType.Cylinder
		gripZ = -0.85
	end
	tool.Grip = CF(0, 0, gripZ) * GRIP_ROTATION
	tool:SetAttribute("BaseGripZ", gripZ)
	return tool
end

----------------------------------------------------------------------
-- Davimas, pirkimas
----------------------------------------------------------------------
local function hasTool(player, id)
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") and child:GetAttribute("WeaponId") == id then
					return true
				end
			end
		end
	end
	return false
end

function WeaponService:GiveTools(player)
	local data = S.DataService:Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, def in ipairs(W.Items) do
		if data.weapons[def.Id] and not hasTool(player, def.Id) then
			local tool = makeTool(def, data.settings.lang)
			tool.Activated:Connect(function()
				self:Swing(player, tool, def)
			end)
			tool.Parent = backpack
		end
	end
end

function WeaponService:Purchase(player, id)
	local data = S.DataService:Get(player)
	local def = defsById[id]
	if not data or not def then
		return
	end
	if data.weapons[id] then
		S.DataService:Notify(player, "WeaponOwned", nil, { item = "Weapon_" .. id }, nil, "info")
		self:GiveTools(player)
		return
	end
	if not S.TycoonService:TrySpend(player, def.Price) then
		return
	end
	data.weapons[id] = true
	player:SetAttribute("Weapon_" .. id, true)
	self:GiveTools(player)
	S.DataService:Notify(player, "Bought", nil, { item = "Weapon_" .. id }, nil, "success")
end

----------------------------------------------------------------------
-- Mostas ir nustūmimas
----------------------------------------------------------------------
local function inSafeZone(position)
	return Vector3.new(position.X, 0, position.Z).Magnitude < W.SafeZoneRadius
end

function WeaponService:Swing(player, tool, def)
	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock()
	if now - (cooldowns[player][def.Id] or 0) < def.Cooldown then
		return
	end
	cooldowns[player][def.Id] = now

	-- Mosto animacija (pasukama rankena)
	local baseZ = tool:GetAttribute("BaseGripZ") or 0
	tool.Grip = CF(0, 0, baseZ) * GRIP_ROTATION * CFrame.Angles(0, 0, math.rad(-80))
	task.delay(0.2, function()
		if tool.Parent then
			tool.Grip = CF(0, 0, baseZ) * GRIP_ROTATION
		end
	end)

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or inSafeZone(root.Position) then
		return
	end
	if def.Kind == "Projectile" then
		self:FireProjectile(player, root, def)
	elseif def.Kind == "Area" then
		self:AreaBlast(player, root, def)
	else
		local look = root.CFrame.LookVector
		for _, other, otherRoot in self:Targets(player) do
			local offset = otherRoot.Position - root.Position
			local flat = Vector3.new(offset.X, 0, offset.Z)
			if flat.Magnitude <= def.Range and flat.Magnitude > 0.01 and flat.Unit:Dot(look) > (def.Arc or 0.2) then
				self:Push(player, other, flat.Unit, def.Force)
			end
		end
	end
end

-- Kiti gyvi žaidėjai už saugios zonos: iteratorius (indeksas, žaidėjas, HumanoidRootPart)
function WeaponService:Targets(player)
	local list = {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local otherChar = other.Character
			local otherRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
			local humanoid = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
			if otherRoot and humanoid and humanoid.Health > 0 and not inSafeZone(otherRoot.Position) then
				table.insert(list, { other, otherRoot })
			end
		end
	end
	local i = 0
	return function()
		i = i + 1
		local entry = list[i]
		if entry then
			return i, entry[1], entry[2]
		end
	end
end

function WeaponService:Push(player, other, direction, force)
	local velocity = direction * force + Vector3.new(0, force * 0.45, 0)
	Remotes.Knockback:FireClient(other, velocity)
	S.DataService:Notify(other, "WeaponHit", { name = player.DisplayName }, nil, nil, "error")
end

-- Cepelinų patranka: skrendantis cepelinas, nustumia pirmą pataikytą žaidėją
function WeaponService:FireProjectile(player, root, def)
	local look = root.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		return
	end
	flatLook = flatLook.Unit
	local start = root.Position + flatLook * 2.5 + Vector3.new(0, 1, 0)
	local ball = Instance.new("Part")
	ball.Name = "FlyingCepelinas"
	ball.Size = V(1.1, 1.1, 1.7)
	ball.Color = C(225, 220, 200)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.CFrame = CFrame.lookAt(start, start + flatLook)
	Build.Mesh(ball, Enum.MeshType.Sphere)
	local cream = Instance.new("Part")
	cream.Name = "Cream"
	cream.Size = V(0.7, 0.3, 0.9)
	cream.Color = C(252, 250, 245)
	cream.Anchored = true
	cream.CanCollide = false
	cream.CanQuery = false
	cream.CanTouch = false
	cream.CFrame = ball.CFrame * CF(0, 0.55, 0)
	Build.Mesh(cream, Enum.MeshType.Sphere)
	ball.Parent = workspace
	cream.Parent = ball
	local travelled = 0
	task.spawn(function()
		while travelled < def.Range and ball.Parent do
			local dt = task.wait() or (1 / 30)
			local step = def.Speed * dt
			travelled = travelled + step
			local position = ball.Position + flatLook * step
			ball.CFrame = CFrame.lookAt(position, position + flatLook) * CFrame.Angles(0, 0, travelled * 0.3)
			cream.CFrame = ball.CFrame * CF(0, 0.55, 0)
			for _, other, otherRoot in self:Targets(player) do
				if (otherRoot.Position - position).Magnitude <= def.HitRadius then
					self:Push(player, other, flatLook, def.Force)
					Remotes.BigCepelinasBurst:FireClient(other, position)
					Remotes.BigCepelinasBurst:FireClient(player, position)
					ball:Destroy()
					return
				end
			end
		end
		if ball.Parent then
			ball:Destroy()
		end
	end)
end

-- Gintarinė lazda: auksinė banga aplink žaidėją nustumia visus šalia
function WeaponService:AreaBlast(player, root, def)
	local center = root.Position
	local ring = Instance.new("Part")
	ring.Name = "AmberWave"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = V(0.3, 2, 2)
	ring.Color = C(255, 180, 40)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.3
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CFrame = CF(center - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	local diameter = def.Range * 2
	TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = V(0.3, diameter, diameter), Transparency = 1 }):Play()
	game:GetService("Debris"):AddItem(ring, 0.6)
	for _, other, otherRoot in self:Targets(player) do
		local offset = otherRoot.Position - center
		local flat = Vector3.new(offset.X, 0, offset.Z)
		if flat.Magnitude <= def.Range then
			local direction = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(1, 0, 0)
			self:Push(player, other, direction, def.Force)
		end
	end
end

----------------------------------------------------------------------
-- Kalvės mygtukai lobby
----------------------------------------------------------------------
local function createPad(def, cframe)
	local radius = 2.4
	local pad = Build.Part({
		Name = "WeaponPad_" .. def.Id, Parent = workspace.Lobby, Shape = Enum.PartType.Cylinder,
		Size = V(0.8, radius * 2, radius * 2), CFrame = cframe * CFrame.Angles(0, 0, math.rad(90)),
		Color = C(200, 60, 50), Material = Enum.Material.SmoothPlastic,
		Tags = { "WeaponPad" }, Attributes = { WeaponId = def.Id, Price = def.Price },
	})
	Build.Part({ Name = "Glow", Parent = pad, Shape = Enum.PartType.Cylinder, Size = V(0.12, radius * 2 + 1.2, radius * 2 + 1.2), CFrame = pad.CFrame * CF(-0.36, 0, 0), Color = C(200, 60, 50), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false })
	Build.Sign(pad, { Name = "NameSign", TextKey = "Weapon_" .. def.Id, Size = UDim2.fromScale(7, 1.8), Offset = V(0, 4.2, 0), MaxDistance = 60 })
	Build.Billboard(pad, { Name = "PriceLabel", TextKey = "MoneyAmount", Nums = { amount = def.Price }, Size = UDim2.fromScale(6, 1.3), Offset = V(0, 2.5, 0), MaxDistance = 60, Color = C(255, 225, 120) })
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy / Pirkti"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		WeaponService:Purchase(player, def.Id)
	end)
	table.insert(pads, { Part = pad, Def = def })
end

function WeaponService:CheckPads()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local found = nil
		if root then
			for _, rec in ipairs(pads) do
				local offset = root.Position - rec.Part.Position
				if Vector3.new(offset.X, 0, offset.Z).Magnitude <= 3.2 and offset.Y > -1.5 and offset.Y < 7 then
					found = rec
					break
				end
			end
		end
		if found then
			if inside[player] ~= found.Part then
				inside[player] = found.Part
				self:Purchase(player, found.Def.Id)
			end
		else
			inside[player] = nil
		end
	end
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function WeaponService:Init(services)
	S = services
end

function WeaponService:Start()
	local shopCF = S.MapBuilder.Anchors.WeaponShopCFrame
	if shopCF then
		-- Dvi eilės: pirmoje 4 pigesni, antroje likę
		local perRow = 4
		for i, def in ipairs(W.Items) do
			local rowIndex = math.floor((i - 1) / perRow)
			local inRow = (i - 1) % perRow
			local count = math.min(perRow, #W.Items - rowIndex * perRow)
			local x = (inRow - (count - 1) / 2) * 6.5
			createPad(def, shopCF * CF(x, 0.4, -6.5 - rowIndex * 6.5))
		end
	end

	task.spawn(function()
		while true do
			task.wait(W.CheckRate)
			local ok, err = pcall(self.CheckPads, self)
			if not ok then
				warn("[WeaponService] " .. tostring(err))
			end
		end
	end)

	local function onCharacter(player)
		task.wait(0.5)
		self:GiveTools(player)
	end
	local function setup(player)
		player.CharacterAdded:Connect(function()
			onCharacter(player)
		end)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		setup(player)
	end
	Players.PlayerAdded:Connect(setup)

	S.DataService:OnPlayerLoaded(function(player, data)
		for id in pairs(data.weapons) do
			player:SetAttribute("Weapon_" .. id, true)
		end
		self:GiveTools(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		inside[player] = nil
		cooldowns[player] = nil
	end)
end

return WeaponService
