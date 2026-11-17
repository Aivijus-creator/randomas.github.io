--[[
	EventService – serverio eventai (vienu metu daugiausia vienas):
	  PotatoRain   – dropper'iai meta dvigubai dažniau, kliente krenta dekoratyvios bulvės
	  BigCepelinas – lobby nusileidžia milžiniškas cepelinas; pirmas paspaudęs gauna 300 s pajamų, kiti – 30 s
	  Jonines      – ×2 pinigai, vakarinis dangus, laužai, paparčio žiedas (pagal Lietuvos laiką)
	  Fairy        – Laumės dovana: laumė pasirodo miške, pirmas radęs gauna atsitiktinį norą
	  Winter       – Žiemos pūga: lėtesni konvejeriai, ×3 pinigai, Kūčiukų dovana turguje
	  Contest      – Močiučių varžybos: kas per 3 min. parduos daugiausiai
	  SkyGranny    – Dangaus močiutė: milžiniška močiutė toli danguje kočėlu kviečia auksinius cepelinus
	Dabartinis eventas matomas ReplicatedStorage atributuose CurrentEvent / EventEndsAt,
	laumės norų „buff'ai“ – BuffId / BuffEndsAt.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local Scenery = require(Lib:WaitForChild("Scenery"))
local GrannyModels = require(Lib:WaitForChild("GrannyModels"))

local E = Settings.Events
local V = Vector3.new
local C = Color3.fromRGB
local CF = CFrame.new

local EventService = {}
local S
local current = nil              -- { Id, EndsAt, Manual, Objects, ... }
local nextAt = {}                -- [eventId] = os.clock() laikas, kada kitas atsitiktinis
local buff = nil                 -- { Id, EndsAt, Money, Drop } – laumės noras
local pendingRain = 0
local eventToken = 0
local RANDOM_EVENTS = { "PotatoRain", "BigCepelinas", "Fairy", "Winter", "Contest", "SkyGranny" }            -- nupirkti Bulvių lietūs, laukiantys eilėje
local savedLighting = nil
local random = Random.new()

----------------------------------------------------------------------
-- Lietuvos laikas (UTC+2, vasarą UTC+3: nuo paskutinio kovo sekmadienio iki paskutinio spalio sekmadienio 01:00 UTC)
----------------------------------------------------------------------
local function weekday(timestamp)
	-- 0 = sekmadienis (1970-01-01 buvo ketvirtadienis)
	return (math.floor(timestamp / 86400) + 4) % 7
end

local function lastSunday(year, month)
	local day31 = DateTime.fromUniversalTime(year, month, 31, 1, 0, 0).UnixTimestamp
	return day31 - weekday(day31) * 86400
end

function EventService:GetLithuanianTime(now)
	now = now or os.time()
	local year = DateTime.fromUnixTimestamp(now):ToUniversalTime().Year
	local dst = now >= lastSunday(year, 3) and now < lastSunday(year, 10)
	local offset = (dst and 3 or 2) * 3600
	local localTs = now + offset
	local t = DateTime.fromUnixTimestamp(localTs):ToUniversalTime()
	return { Year = t.Year, Month = t.Month, Day = t.Day, Hour = t.Hour, Minute = t.Minute, Second = t.Second, Weekday = weekday(localTs) }
end

-- Diena (LT laiku), kurią Joninės jau įvyko – kad sustabdytos neprasidėtų iš naujo
local joninesDoneDay = nil

local function markJoninesDone(self)
	local lt = self:GetLithuanianTime()
	joninesDoneDay = string.format("%d-%d-%d", lt.Year, lt.Month, lt.Day)
end

-- Ar dabar Joninių laikas? Grąžina likusias sekundes arba nil
function EventService:GetJoninesRemaining()
	local lt = self:GetLithuanianTime()
	local isDay = false
	for _, d in ipairs(E.Jonines.Days) do
		if lt.Month == d.Month and lt.Day == d.Day then
			isDay = true
		end
	end
	if E.Jonines.Weekends and (lt.Weekday == 0 or lt.Weekday == 6) then
		isDay = true
	end
	if not isDay then
		return nil
	end
	-- Šiandien jau buvo (arba admin sustabdė) – antrą kartą nebepaleidžiam
	if joninesDoneDay == string.format("%d-%d-%d", lt.Year, lt.Month, lt.Day) then
		return nil
	end
	local secondsSinceStart = (lt.Hour - E.Jonines.StartHourLT) * 3600 + lt.Minute * 60 + lt.Second
	if secondsSinceStart >= 0 and secondsSinceStart < E.Jonines.Duration then
		return E.Jonines.Duration - secondsSinceStart
	end
	return nil
end

----------------------------------------------------------------------
-- Daugikliai (naudoja Calc per TycoonService:GetContext)
----------------------------------------------------------------------
local function buffActive()
	return buff and workspace:GetServerTimeNow() < buff.EndsAt
end

function EventService:GetDropMultiplier()
	local m = 1
	if current and current.Id == "PotatoRain" then
		m = E.PotatoRain.DropSpeedMultiplier
	end
	if buffActive() then
		m = m * (buff.Drop or 1)
	end
	return m
end

function EventService:GetMoneyMultiplier()
	local m = 1
	if current and current.Id == "Jonines" then
		m = E.Jonines.MoneyMultiplier
	elseif current and current.Id == "Winter" then
		m = E.Winter.MoneyMultiplier
	end
	if buffActive() then
		m = m * (buff.Money or 1)
	end
	return m
end

local function refreshIncome()
	for _, player in ipairs(Players:GetPlayers()) do
		if S.DataService:Get(player) then
			S.TycoonService:UpdateIncome(player)
		end
	end
end

function EventService:SetBuff(id, duration, money, drop)
	buff = { Id = id, EndsAt = workspace:GetServerTimeNow() + duration, Money = money, Drop = drop }
	ReplicatedStorage:SetAttribute("BuffId", id)
	ReplicatedStorage:SetAttribute("BuffEndsAt", buff.EndsAt)
	refreshIncome()
end

function EventService:GetCurrent()
	return current and current.Id or nil
end

----------------------------------------------------------------------
-- Eventų pradžia / pabaiga
----------------------------------------------------------------------
local function setReplicated(id, endsAt)
	ReplicatedStorage:SetAttribute("CurrentEvent", id or "")
	ReplicatedStorage:SetAttribute("EventEndsAt", endsAt or 0)
end

local function isDecember()
	return EventService:GetLithuanianTime().Month == 12
end

local function scheduleNext(id)
	local cfg = E[id]
	if not cfg or not cfg.MinGap then
		return
	end
	local minGap, maxGap = cfg.MinGap, cfg.MaxGap
	if id == "Winter" and isDecember() then
		minGap, maxGap = cfg.DecemberMinGap, cfg.DecemberMaxGap
	end
	nextAt[id] = os.clock() + random:NextNumber(minGap, maxGap)
end

local function tweenLighting(target)
	if not savedLighting then
		savedLighting = {
			ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
		}
	end
	TweenService:Create(Lighting, TweenInfo.new(4), {
		ClockTime = target.ClockTime, Brightness = target.Brightness, Ambient = target.Ambient,
		OutdoorAmbient = target.OutdoorAmbient, FogColor = target.FogColor, FogEnd = target.FogEnd,
	}):Play()
end

local function startJoninesVisuals(objects)
	savedLighting = {
		ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd,
	}
	local target = E.Jonines.Lighting
	TweenService:Create(Lighting, TweenInfo.new(4), {
		ClockTime = target.ClockTime, Brightness = target.Brightness, Ambient = target.Ambient,
		OutdoorAmbient = target.OutdoorAmbient, FogColor = target.FogColor, FogEnd = target.FogEnd,
	}):Play()
	local folder = Build.Folder("JoninesDecor", workspace)
	table.insert(objects, folder)
	for _, position in ipairs(S.MapBuilder.Anchors.Bonfires or {}) do
		for i = 0, 5 do
			local angle = i * 60
			Build.Part({ Name = "Log", Parent = folder, Size = V(0.6, 0.6, 4), CFrame = CF(position + V(0, 0.4, 0)) * CFrame.Angles(0, math.rad(angle), math.rad(25)), Color = C(90, 60, 35), Material = Enum.Material.Wood })
		end
		local core = Build.Part({ Name = "Bonfire", Parent = folder, Size = V(1, 1, 1), CFrame = CF(position + V(0, 1.2, 0)), Transparency = 1, CanCollide = false })
		local fire = Instance.new("Fire")
		fire.Size = 8
		fire.Heat = 12
		fire.Parent = core
		local light = Instance.new("PointLight")
		light.Color = C(255, 150, 60)
		light.Range = 30
		light.Brightness = 3
		light.Parent = core
	end
	local fern = S.MapBuilder.Anchors.FernSpot
	if fern then
		for i = 0, 4 do
			local angle = math.rad(i * 72)
			Build.Part({ Name = "FernLeaf", Parent = folder, Size = V(0.3, 0.2, 3), CFrame = CF(fern + V(math.cos(angle) * 1.4, 0.6, math.sin(angle) * 1.4)) * CFrame.Angles(0, -angle + math.rad(90), math.rad(15)), Color = C(50, 140, 50), Material = Enum.Material.Grass })
		end
		local flower = Build.Part({ Name = "FernFlower", Parent = folder, Shape = Enum.PartType.Ball, Size = V(1.2, 1.2, 1.2), CFrame = CF(fern + V(0, 2, 0)), Color = C(255, 120, 230), Material = Enum.Material.Neon, CanCollide = false })
		local glow = Instance.new("PointLight")
		glow.Color = C(255, 140, 230)
		glow.Range = 16
		glow.Brightness = 3
		glow.Parent = flower
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = C(255, 180, 240)
		sparkles.Parent = flower
	end
end

local function stopJoninesVisuals()
	if savedLighting then
		TweenService:Create(Lighting, TweenInfo.new(4), savedLighting):Play()
		savedLighting = nil
	end
end

function EventService:GrantIncome(player, seconds, minimum)
	local amount = math.max(minimum or 0, S.TycoonService:GetIncomePerSecond(player) * seconds)
	S.DataService:AddMoney(player, amount, true)
	return amount
end

local function spawnBigCepelinas(objects)
	local spot = S.MapBuilder.Anchors.BigCepelinasSpot or V(0, 1, 24)
	local cfg = E.BigCepelinas
	local body = Build.Part({ Name = "BigCepelinas", Parent = workspace, Size = V(16, 9, 9), CFrame = CF(spot + V(0, cfg.DropHeight, 0)), Color = C(225, 220, 205), Material = Enum.Material.SmoothPlastic, CanCollide = true })
	Build.Mesh(body, Enum.MeshType.Sphere)
	table.insert(objects, body)
	local cream = Build.Part({ Name = "SourCream", Parent = body, Size = V(6, 1.5, 5), CFrame = body.CFrame * CF(0, 4.3, 0), Color = C(250, 250, 245), Material = Enum.Material.SmoothPlastic, Anchored = false, CanCollide = false, Massless = true })
	Build.Mesh(cream, Enum.MeshType.Sphere)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = body
	weld.Part1 = cream
	weld.Parent = cream
	for i = 1, 6 do
		local crackling = Build.Part({ Name = "Crackling", Parent = body, Size = V(0.8, 0.5, 0.8), CFrame = body.CFrame * CF(-2.5 + i * 0.8, 5, (i % 2) - 0.5), Color = C(160, 100, 50), Material = Enum.Material.Sand, Anchored = false, CanCollide = false, Massless = true })
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = crackling
		w.Parent = crackling
	end
	Build.Billboard(body, { Name = "Name", TextKey = "BigCepelinasName", Size = UDim2.fromScale(14, 2.5), Offset = V(0, 9, 0), MaxDistance = 400, AlwaysOnTop = true, Color = C(255, 230, 140) })
	TweenService:Create(body, TweenInfo.new(cfg.FallTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { CFrame = CF(spot + V(0, 4.5, 0)) }):Play()

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Grab / Pagauti"
	prompt.ObjectText = "Big Cepelinas"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	local claimed = false
	prompt.Triggered:Connect(function(winner)
		if claimed or not S.DataService:Get(winner) then
			return
		end
		claimed = true
		local won = EventService:GrantIncome(winner, cfg.WinnerSeconds, cfg.MinReward)
		S.DataService:Notify(winner, "BigCepelinasWin", nil, nil, { amount = won }, "success")
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= winner and S.DataService:Get(other) then
				local amount = EventService:GrantIncome(other, cfg.OthersSeconds, cfg.MinReward * cfg.OthersSeconds / cfg.WinnerSeconds)
				S.DataService:Notify(other, "BigCepelinasOther", { name = winner.DisplayName }, nil, { amount = amount }, "info")
			end
		end
		Remotes.BigCepelinasBurst:FireAllClients(body.Position)
		EventService:StopEvent()
	end)
end

----------------------------------------------------------------------
-- Laumės dovana
----------------------------------------------------------------------
local WISHES = { { "Money2x", 3 }, { "Gold", 3 }, { "Speed2x", 3 }, { "BigHeads", 1 } }

local function pickWish()
	local total = 0
	for _, w in ipairs(WISHES) do
		total = total + w[2]
	end
	local roll = random:NextNumber(0, total)
	for _, w in ipairs(WISHES) do
		roll = roll - w[2]
		if roll <= 0 then
			return w[1]
		end
	end
	return WISHES[1][1]
end

local function bigHeads()
	local cfg = E.Fairy
	local changed = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local scale = humanoid and humanoid:FindFirstChild("HeadScale")
		if scale and scale:IsA("NumberValue") then
			table.insert(changed, { scale, scale.Value })
			scale.Value = cfg.BigHeadsScale
		end
	end
	task.delay(cfg.BigHeadsDuration, function()
		for _, entry in ipairs(changed) do
			if entry[1].Parent then
				entry[1].Value = entry[2]
			end
		end
	end)
end

local function spawnFairy(objects)
	local cfg = E.Fairy
	local spot = S.MapBuilder:RandomFreeSpot(random) or V(random:NextNumber(-200, 200), 0, random:NextNumber(-200, 200))
	local folder = Build.Folder("Fairy", workspace)
	table.insert(objects, folder)
	local base = CF(spot + V(0, 3.5, 0))
	local body = Build.Part({ Name = "FairyBody", Parent = folder, Size = V(1, 1.6, 1), CFrame = base, Color = C(220, 255, 230), Material = Enum.Material.Neon })
	Build.Mesh(body, Enum.MeshType.Sphere)
	local head = Build.Part({ Name = "FairyHead", Parent = folder, Shape = Enum.PartType.Ball, Size = V(0.8, 0.8, 0.8), CFrame = base * CF(0, 1.15, 0), Color = C(255, 225, 200), Material = Enum.Material.SmoothPlastic, Anchored = false, CanCollide = false, Massless = true })
	local crown = Build.Part({ Name = "FlowerCrown", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(0.15, 0.9, 0.9), CFrame = base * CF(0, 1.5, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(255, 150, 210), Material = Enum.Material.Neon, Anchored = false, CanCollide = false, Massless = true })
	local attached = { head, crown }
	for _, side in ipairs({ -1, 1 }) do
		local wing = Build.Part({ Name = "Wing", Parent = folder, Size = V(1.6, 1.4, 0.05), CFrame = base * CF(side * 0.8, 0.5, 0.45) * CFrame.Angles(0, side * math.rad(25), side * math.rad(20)), Color = C(170, 240, 255), Material = Enum.Material.Neon, Transparency = 0.45, Anchored = false, CanCollide = false, Massless = true })
		Build.Mesh(wing, Enum.MeshType.Sphere)
		table.insert(attached, wing)
	end
	for _, p in ipairs(attached) do
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = p
		w.Parent = p
	end
	local light = Instance.new("PointLight")
	light.Color = C(190, 255, 220)
	light.Range = 22
	light.Brightness = 3
	light.Parent = body
	local sparkles = Instance.new("Sparkles")
	sparkles.SparkleColor = C(200, 255, 230)
	sparkles.Parent = body
	-- Aukštas šviesos stulpas, kad laumę būtų galima rasti iš toli
	Build.Part({ Name = "FairyBeam", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(160, 2.5, 2.5), CFrame = CF(spot + V(0, 80, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(180, 255, 220), Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
	TweenService:Create(body, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = base * CF(0, 1.2, 0) }):Play()

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Wish / Norėti"
	prompt.ObjectText = "🧚 Laumė"
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	local used = false
	prompt.Triggered:Connect(function(winner)
		if used or not S.DataService:Get(winner) then
			return
		end
		used = true
		local wish = pickWish()
		if wish == "Money2x" then
			EventService:SetBuff("Money2x", cfg.WishMoney.Duration, cfg.WishMoney.Multiplier, 1)
		elseif wish == "Speed2x" then
			EventService:SetBuff("Speed2x", cfg.WishSpeed.Duration, 1, cfg.WishSpeed.Multiplier)
		elseif wish == "Gold" then
			local amount = EventService:GrantIncome(winner, cfg.WishGoldSeconds, cfg.MinReward)
			S.DataService:Notify(winner, "BigCepelinasWin", nil, nil, { amount = amount }, "success")
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= winner and S.DataService:Get(other) then
					EventService:GrantIncome(other, cfg.OthersSeconds, cfg.MinReward / 4)
				end
			end
		elseif wish == "BigHeads" then
			bigHeads()
		end
		for _, player in ipairs(Players:GetPlayers()) do
			S.DataService:Notify(player, "FairyWish_" .. wish, { name = winner.DisplayName }, nil, nil, "success")
		end
		Remotes.MachineBuilt:FireAllClients(body.Position)
		EventService:StopEvent()
	end)
end

----------------------------------------------------------------------
-- Žiemos pūga / Kūčios
----------------------------------------------------------------------
local savedTerrainColors = nil

local function startWinter(objects)
	local cfg = E.Winter
	tweenLighting(cfg.Lighting)
	pcall(function()
		local terrain = workspace.Terrain
		savedTerrainColors = {
			Grass = terrain:GetMaterialColor(Enum.Material.Grass),
			LeafyGrass = terrain:GetMaterialColor(Enum.Material.LeafyGrass),
		}
		terrain:SetMaterialColor(Enum.Material.Grass, cfg.SnowColor)
		terrain:SetMaterialColor(Enum.Material.LeafyGrass, cfg.SnowColor)
	end)
	S.TycoonService:SetConveyorFactor(cfg.ConveyorFactor)
	-- Kūčiukų stalas turguje
	local spot = S.MapBuilder.Anchors.FernSpot or V(-12, 1, 21)
	local folder = Build.Folder("KuciukaiStand", workspace)
	table.insert(objects, folder)
	local top = Build.Part({ Name = "Table", Parent = folder, Size = V(4, 0.4, 2.6), CFrame = CF(spot + V(0, 2.6, 0)), Color = C(140, 95, 55), Material = Enum.Material.WoodPlanks })
	Build.Part({ Name = "Cloth", Parent = folder, Size = V(4.1, 0.08, 2.7), CFrame = CF(spot + V(0, 2.84, 0)), Color = C(245, 245, 240), Material = Enum.Material.Fabric })
	for _, x in ipairs({ -1.7, 1.7 }) do
		Build.Part({ Name = "Leg", Parent = folder, Size = V(0.3, 2.4, 2.2), CFrame = CF(spot + V(x, 1.2, 0)), Color = C(100, 65, 35), Material = Enum.Material.Wood })
	end
	local bowl = Build.Part({ Name = "Bowl", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(0.6, 2, 2), CFrame = CF(spot + V(-0.6, 3.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(190, 60, 50), Material = Enum.Material.SmoothPlastic })
	for i = 1, 8 do
		local a = i * math.pi / 4
		Build.Part({ Name = "Kuciukas", Parent = folder, Shape = Enum.PartType.Ball, Size = V(0.35, 0.35, 0.35), CFrame = CF(spot + V(-0.6 + math.cos(a) * 0.55, 3.55, math.sin(a) * 0.55)), Color = C(220, 180, 120), Material = Enum.Material.Sand })
	end
	Scenery.ChristmasTree(folder, spot + V(1.3, 2.88, 0), 0.35)
	Build.Sign(top, { Name = "Sign", Text = "🎄 Kūčiukai", Size = UDim2.fromScale(6, 1.6), Offset = V(0, 3.4, 0), MaxDistance = 120 })
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Gift / Dovana"
	prompt.ObjectText = "Kūčiukai"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = bowl
	local taken = {}
	prompt.Triggered:Connect(function(player)
		if not S.DataService:Get(player) then
			return
		end
		if taken[player.UserId] then
			S.DataService:Notify(player, "KuciukaiTaken", nil, nil, nil, "info")
			return
		end
		taken[player.UserId] = true
		local amount = EventService:GrantIncome(player, cfg.GiftSeconds, cfg.GiftMin)
		S.DataService:Notify(player, "KuciukaiGift", nil, nil, { amount = amount }, "success")
	end)
end

local function stopWinter()
	stopJoninesVisuals()
	pcall(function()
		if savedTerrainColors then
			workspace.Terrain:SetMaterialColor(Enum.Material.Grass, savedTerrainColors.Grass)
			workspace.Terrain:SetMaterialColor(Enum.Material.LeafyGrass, savedTerrainColors.LeafyGrass)
			savedTerrainColors = nil
		end
	end)
	S.TycoonService:SetConveyorFactor(1)
end

----------------------------------------------------------------------
-- Dangaus močiutė: milžiniška močiutė toli danguje kočėlu kviečia auksinius cepelinus
----------------------------------------------------------------------
local savedAtmosphere = nil

local function groundY(x, z)
	local y = 1
	pcall(function()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local exclude = {}
		local map = workspace:FindFirstChild("Map")
		local nature = map and map:FindFirstChild("Nature")
		if nature then
			table.insert(exclude, nature)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				table.insert(exclude, player.Character)
			end
		end
		params.FilterDescendantsInstances = exclude
		local hit = workspace:Raycast(V(x, 300, z), V(0, -400, 0), params)
		if hit then
			y = hit.Position.Y
		end
	end)
	return y
end

-- Kur nukris auksinis cepelinas: dažniau šalia žaidėjų, kitaip – bet kur žaidimo zonoje
local function pickDropSpot(cfg)
	local players = Players:GetPlayers()
	if #players > 0 and random:NextNumber() < cfg.NearPlayerChance then
		local player = players[random:NextInteger(1, #players)]
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local a = random:NextNumber() * math.pi * 2
			local r = random:NextNumber(cfg.NearMin, cfg.NearMax)
			local x, z = root.Position.X + math.cos(a) * r, root.Position.Z + math.sin(a) * r
			return V(x, groundY(x, z), z)
		end
	end
	local a = random:NextNumber() * math.pi * 2
	local r = random:NextNumber(20, cfg.MaxRadius)
	local x, z = math.cos(a) * r, math.sin(a) * r
	return V(x, groundY(x, z), z)
end

local function dropGoldenCepelinas(cfg, token)
	local spot = pickDropSpot(cfg)
	local folder = Build.Folder("GoldenCepelinas", workspace)
	folder:SetAttribute("SkyGrannyToken", token)
	local body = Build.Part({ Name = "GoldenCepelinas", Parent = folder, Size = V(3.4, 1.8, 2), CFrame = CF(spot + V(0, cfg.DropHeight, 0)) * CFrame.Angles(0, random:NextNumber() * 6.28, 0), Color = C(255, 205, 50), Material = Enum.Material.Metal, CanCollide = false })
	Build.Mesh(body, Enum.MeshType.Sphere)
	local glow = Instance.new("PointLight")
	glow.Color = C(255, 210, 90)
	glow.Range = 14
	glow.Brightness = 2
	glow.Parent = body
	local trail = Instance.new("Sparkles")
	trail.SparkleColor = C(255, 230, 120)
	trail.Parent = body
	local landCF = CF(spot + V(0, 1.1, 0)) * CFrame.Angles(0, random:NextNumber() * 6.28, 0)
	local tween = TweenService:Create(body, TweenInfo.new(cfg.FallTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = landCF })
	tween:Play()
	tween.Completed:Connect(function()
		if not folder.Parent then
			return
		end
		-- Šviečianti auksinė vieta, kur nukrito
		local disk = Build.Part({ Name = "GoldenGlow", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(0.2, 7, 7), CFrame = CF(spot + V(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(255, 200, 60), Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, CanQuery = false, CanTouch = false })
		local beam = Build.Part({ Name = "GoldenBeam", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(40, 1.6, 1.6), CFrame = CF(spot + V(0, 20, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(255, 220, 110), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		local light = Instance.new("PointLight")
		light.Color = C(255, 200, 80)
		light.Range = 20
		light.Brightness = 3
		light.Parent = disk
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Pick up / Paimti"
		prompt.ObjectText = "Golden Cepelinas"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Parent = body
		local taken = false
		prompt.Triggered:Connect(function(player)
			if taken or not S.DataService:Get(player) then
				return
			end
			taken = true
			local amount = EventService:GrantIncome(player, cfg.RewardSeconds, cfg.MinReward)
			S.DataService:Notify(player, "GoldenCepelinasFound", nil, nil, { amount = amount }, "success")
			Remotes.BigCepelinasBurst:FireAllClients(body.Position)
			folder:Destroy()
		end)
		beam.Name = "GoldenBeam"
		disk.Name = "GoldenGlow"
	end)
end

local function startSkyGranny(objects, state)
	local cfg = E.SkyGranny
	tweenLighting(cfg.Lighting)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		savedAtmosphere = { Density = atmosphere.Density, Color = atmosphere.Color, Decay = atmosphere.Decay }
		TweenService:Create(atmosphere, TweenInfo.new(4), cfg.Atmosphere):Play()
	end
	-- Milžiniška pirmo lygio močiutė toli už žemėlapio krašto, stovi ant debesų
	local model = GrannyModels.Build(1)
	model.Name = "SkyGranny"
	local rightArm = model:FindFirstChild("RightArm")
	if rightArm then
		-- Kočėlas dešinėje rankoje – laikomas kaip lazda
		local pinCF = rightArm.CFrame * CF(0, -1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
		local pin = Build.Part({ Name = "RollingPin", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(3.2, 0.42, 0.42), CFrame = pinCF, Color = C(215, 175, 115), Material = Enum.Material.Wood, Anchored = false })
		for _, side in ipairs({ -1, 1 }) do
			local handle = Build.Part({ Name = "PinHandle", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.7, 0.22, 0.22), CFrame = pinCF * CF(side * 1.95, 0, 0), Color = C(150, 105, 60), Material = Enum.Material.Wood, Anchored = false })
			local w = Instance.new("WeldConstraint")
			w.Part0 = pin
			w.Part1 = handle
			w.Parent = handle
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = rightArm
		weld.Part1 = pin
		weld.Parent = pin
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	pcall(function()
		model:ScaleTo(cfg.Scale)
	end)
	local angle = math.rad(cfg.Angle)
	local position = V(math.cos(angle) * cfg.Distance, cfg.BaseY, math.sin(angle) * cfg.Distance)
	-- Kojos ant debesų (BaseY aukštyje), ne liemuo
	Build.PlaceOnFloor(model, CFrame.lookAt(position, V(0, cfg.BaseY, 0)))
	model.Parent = workspace
	table.insert(objects, model)
	-- Debesys po kojomis
	local clouds = Build.Folder("SkyGrannyClouds", workspace)
	table.insert(objects, clouds)
	for i = 1, 9 do
		local a = i * 0.7
		local size = random:NextNumber(40, 70)
		local cloud = Build.Part({ Name = "Cloud", Parent = clouds, Size = V(size * 1.6, size * 0.55, size), CFrame = CF(position + V(math.cos(a) * 45, random:NextNumber(-8, 6), math.sin(a) * 45)), Color = C(255, 245, 250), Material = Enum.Material.SmoothPlastic, Transparency = 0.15, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		Build.Mesh(cloud, Enum.MeshType.Sphere)
	end
	-- Kočėlo smūgiai į dangų ir auksinių cepelinų lietus
	local token = (state.Token or 0)
	task.spawn(function()
		task.wait(cfg.FirstStrike)
		while current == state do
			model:SetAttribute("StrikeAt", workspace:GetServerTimeNow())
			task.wait(1.1)
			if current ~= state then
				break
			end
			for _ = 1, random:NextInteger(cfg.PerStrike[1], cfg.PerStrike[2]) do
				dropGoldenCepelinas(cfg, token)
				task.wait(0.35)
			end
			task.wait(random:NextNumber(cfg.StrikeEvery[1], cfg.StrikeEvery[2]))
		end
	end)
end

local function stopSkyGranny(state)
	stopJoninesVisuals()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere and savedAtmosphere then
		TweenService:Create(atmosphere, TweenInfo.new(4), savedAtmosphere):Play()
		savedAtmosphere = nil
	end
	-- Nukritę, bet nepaimti cepelinai dar kurį laiką lieka, paskui dingsta
	local token = state.Token or 0
	task.delay(E.SkyGranny.Grace, function()
		for _, child in ipairs(workspace:GetChildren()) do
			if child.Name == "GoldenCepelinas" and child:GetAttribute("SkyGrannyToken") == token then
				child:Destroy()
			end
		end
	end)
end

----------------------------------------------------------------------
-- Močiučių varžybos
----------------------------------------------------------------------
-- Varžybose dalyvauja tik paspaudę „Dalyvauti“ (kiti nerodomi lentelėje ir negauna prizų)
function EventService:RecordSale(player, amount)
	if current and current.Id == "Contest" and current.Joined[player] then
		current.Scores[player] = (current.Scores[player] or 0) + amount
	end
end

local function contestRanking(state)
	local list = {}
	for player, score in pairs(state.Scores) do
		if player.Parent then
			table.insert(list, { Player = player, Score = score })
		end
	end
	table.sort(list, function(a, b)
		return a.Score > b.Score
	end)
	return list
end

local function sendContestUpdate(state)
	local ranking = contestRanking(state)
	local top = {}
	for i = 1, math.min(3, #ranking) do
		top[i] = { Name = ranking[i].Player.DisplayName, Score = ranking[i].Score }
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local rank, score = 0, state.Scores[player] or 0
		for i, entry in ipairs(ranking) do
			if entry.Player == player then
				rank = i
			end
		end
		Remotes.ContestUpdate:FireClient(player, top, score, rank, state.EndsAt, state.Joined[player] == true)
	end
end

local function giveChefHat(player, duration)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = character:FindFirstChild("ChefHat")
	if old then
		old:Destroy()
	end
	local hat = Instance.new("Model")
	hat.Name = "ChefHat"
	local band = Build.Part({ Name = "Band", Parent = hat, Shape = Enum.PartType.Cylinder, Size = V(0.5, 1.35, 1.35), CFrame = head.CFrame * CF(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(250, 250, 250), Material = Enum.Material.Fabric, Anchored = false, CanCollide = false, Massless = true })
	local puff = Build.Part({ Name = "Puff", Parent = hat, Shape = Enum.PartType.Ball, Size = V(1.7, 1.7, 1.7), CFrame = head.CFrame * CF(0, 1.45, 0), Color = C(255, 255, 255), Material = Enum.Material.Fabric, Anchored = false, CanCollide = false, Massless = true })
	for _, p in ipairs({ band, puff }) do
		local w = Instance.new("WeldConstraint")
		w.Part0 = head
		w.Part1 = p
		w.Parent = p
	end
	hat.Parent = character
	game:GetService("Debris"):AddItem(hat, duration)
end

local function finishContest(state)
	local cfg = E.Contest
	local ranking = contestRanking(state)
	for i = 1, math.min(3, #ranking) do
		local player = ranking[i].Player
		local amount = EventService:GrantIncome(player, cfg.PrizeSeconds[i], cfg.PrizeMin[i])
		S.DataService:Notify(player, "ContestPrize", nil, nil, { amount = amount, rank = i }, "success")
	end
	if ranking[1] then
		giveChefHat(ranking[1].Player, cfg.HatDuration)
		for _, player in ipairs(Players:GetPlayers()) do
			S.DataService:Notify(player, "ContestWinner", { name = ranking[1].Player.DisplayName }, nil, nil, "success")
		end
	end
	Remotes.ContestUpdate:FireAllClients(nil)
end

-- Paleidžia eventą. duration – nebūtina (Joninėms – likęs laikas)
function EventService:StartEvent(id, duration, manual)
	if current then
		return false
	end
	local objects = {}
	if id == "PotatoRain" then
		duration = duration or E.PotatoRain.Duration
	elseif id == "BigCepelinas" then
		duration = duration or E.BigCepelinas.Duration
		spawnBigCepelinas(objects)
	elseif id == "Jonines" then
		duration = duration or E.Jonines.Duration
		startJoninesVisuals(objects)
	elseif id == "Fairy" then
		duration = duration or E.Fairy.Duration
		spawnFairy(objects)
	elseif id == "Winter" then
		duration = duration or E.Winter.Duration
		startWinter(objects)
	elseif id == "Contest" then
		duration = duration or E.Contest.Duration
	elseif id == "SkyGranny" then
		duration = duration or E.SkyGranny.Duration
	else
		return false
	end
	local endsAt = workspace:GetServerTimeNow() + duration
	eventToken = eventToken + 1
	current = { Id = id, EndsAt = endsAt, Manual = manual == true, Objects = objects, Scores = {}, Joined = {}, Token = eventToken }
	if id == "SkyGranny" then
		startSkyGranny(objects, current)
	end
	setReplicated(id, endsAt)
	Remotes.EventStarted:FireAllClients(id, endsAt)
	for _, player in ipairs(Players:GetPlayers()) do
		if S.DataService:Get(player) then
			S.TycoonService:UpdateIncome(player)
		end
	end
	return true
end

function EventService:StopEvent()
	if not current then
		return
	end
	local id = current.Id
	for _, object in ipairs(current.Objects) do
		if object.Parent then
			object:Destroy()
		end
	end
	local state = current
	if id == "Jonines" then
		stopJoninesVisuals()
		markJoninesDone(self)
	elseif id == "Winter" then
		stopWinter()
	elseif id == "Contest" then
		finishContest(state)
	elseif id == "SkyGranny" then
		stopSkyGranny(state)
	end
	current = nil
	setReplicated(nil, nil)
	Remotes.EventEnded:FireAllClients(id)
	scheduleNext(id)
	for _, player in ipairs(Players:GetPlayers()) do
		if S.DataService:Get(player) then
			S.TycoonService:UpdateIncome(player)
		end
	end
end

-- Developer product „Šventinis Bulvių lietus“: jei dabar vyksta kitas eventas – eilėje
function EventService:QueuePotatoRain()
	if not current then
		self:StartEvent("PotatoRain")
	else
		pendingRain = pendingRain + 1
	end
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function EventService:Init(services)
	S = services
	Remotes.ContestJoin.OnServerEvent:Connect(function(player)
		if not current or current.Id ~= "Contest" or current.Joined[player] or not S.DataService:Get(player) then
			return
		end
		current.Joined[player] = true
		current.Scores[player] = 0
		S.DataService:Notify(player, "ContestJoined", nil, nil, nil, "success")
		sendContestUpdate(current)
	end)
end

function EventService:RunLoop()
	local first = random:NextNumber(E.FirstEventDelay[1], E.FirstEventDelay[2])
	for i, id in ipairs(RANDOM_EVENTS) do
		-- Pirmieji eventai išdėstomi, kad neprasidėtų visi iš karto
		nextAt[id] = os.clock() + first + (i - 1) * random:NextNumber(90, 180) + random:NextNumber(0, E[id].MinGap / 3)
	end
	local lastJoninesCheck = 0
	local lastContestUpdate = 0
	while true do
		task.wait(1)
		local now = os.clock()
		-- Laumės noro pabaiga
		if buff and workspace:GetServerTimeNow() >= buff.EndsAt then
			buff = nil
			ReplicatedStorage:SetAttribute("BuffId", "")
			ReplicatedStorage:SetAttribute("BuffEndsAt", 0)
			refreshIncome()
		end
		if current then
			if current.Id == "Contest" and now - lastContestUpdate >= E.Contest.UpdateInterval then
				lastContestUpdate = now
				sendContestUpdate(current)
			end
			if workspace:GetServerTimeNow() >= current.EndsAt then
				self:StopEvent()
			end
		else
			-- Joninės turi pirmenybę
			if now - lastJoninesCheck >= E.Jonines.CheckInterval then
				lastJoninesCheck = now
				local remaining = self:GetJoninesRemaining()
				if remaining then
					self:StartEvent("Jonines", remaining)
				end
			end
			if not current then
				if pendingRain > 0 then
					pendingRain = pendingRain - 1
					self:StartEvent("PotatoRain")
				else
					-- Paleidžiam tą atsitiktinį eventą, kurio laikas atėjo anksčiausiai
					local dueId, dueAt = nil, math.huge
					for _, id in ipairs(RANDOM_EVENTS) do
						if nextAt[id] and nextAt[id] <= now and nextAt[id] < dueAt then
							dueId, dueAt = id, nextAt[id]
						end
					end
					if dueId then
						self:StartEvent(dueId)
						scheduleNext(dueId)
					end
				end
			end
		end
	end
end

function EventService:Start()
	setReplicated(nil, nil)
	ReplicatedStorage:SetAttribute("BuffId", "")
	ReplicatedStorage:SetAttribute("BuffEndsAt", 0)
	-- Gruodį turguje stovi Kalėdų eglė
	if isDecember() then
		local spot = S.MapBuilder.Anchors.ChristmasSpot
		if spot then
			local folder = Build.Folder("ChristmasDecor", workspace)
			Scenery.ChristmasTree(folder, spot, 1)
		end
	end
	task.spawn(function()
		self:RunLoop()
	end)
end

return EventService
