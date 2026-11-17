--[[
	TycoonService – universali gamybos sistema visoms linijoms:
	dropper'iai, konvejeris, upgrader'iai, pardavimo langelis, pirkimo mygtukai ant grindų.
	Linijos skiriasi tik konfigūracija (Config/ProductLines).

	Žaliavų judėjimas tikrinamas serveryje pagal poziciją (patikimiau nei Touched):
	kai objektas pravažiuoja upgrader'io vietą – pritaikomas efektas (vieną kartą),
	kai pasiekia pardavimo langelį – parduodamas savininkui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local ProductLines = require(Config:WaitForChild("ProductLines"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Calc = require(Shared:WaitForChild("Calc"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local FoodLooks = require(Lib:WaitForChild("FoodLooks"))
local Build = require(Lib:WaitForChild("Build"))
local RateLimit = require(Lib:WaitForChild("RateLimit"))

local L = Settings.Layout
local CF = CFrame.new
local V = Vector3.new

local UPGRADER_WINDOW = 3          -- studai: upgrader'is suveikia tik ką tik pravažiavus jo vietą
local RISE_DEPTH = 8               -- iš kokio gylio „iškyla“ nauja mašina
local RISE_TIME = 0.7

local TycoonService = {}
local S
local states = {}                  -- [player] = būsena
local purchaseDebounce = RateLimit.debounce(Settings.PurchaseDebounce)
local buttonInfo = setmetatable({}, { __mode = "k" })   -- [mygtuko Part] = info
local insideButton = {}            -- [player] = { Pad = mygtukas, At = laikas }, kol stovi ant mygtuko
local BUTTON_RETRY = 1             -- s; stovint ant to paties mygtuko bandoma pirkti iš naujo
local notifyDebounce = RateLimit.debounce(2)

----------------------------------------------------------------------
-- Kontekstas (gamepass'ai, eventai, boost'ai)
----------------------------------------------------------------------
function TycoonService:GetContext(player)
	local data = S.DataService:Get(player)
	local passes = S.MonetizationService:GetPasses(player)
	return {
		eventDropMult = S.EventService:GetDropMultiplier(),
		eventMoneyMult = S.EventService:GetMoneyMultiplier(),
		doublePass = passes.DoubleMoney == true,
		fastPass = passes.FastDroppers == true,
		grannyPass = passes.GrannyHelp == true,
		vip = passes.VIP == true,
		group = S.BonusService:IsInGroup(player),
		boost = data ~= nil and data.boostRemaining > 0,
	}
end

function TycoonService:GetIncomePerSecond(player)
	local data = S.DataService:Get(player)
	if not data then
		return 0
	end
	return Calc.GetIncomePerSecond(data, self:GetContext(player))
end

function TycoonService:UpdateIncome(player)
	player:SetAttribute("IncomePerSec", self:GetIncomePerSecond(player))
end

function TycoonService:GetState(player)
	return states[player]
end

----------------------------------------------------------------------
-- Mašinų statymas
----------------------------------------------------------------------
local conveyorFactor = 1            -- Žiemos pūgos metu konvejeriai lėtesni

local function setBelt(model, plotCFrame)
	local belt = model:FindFirstChild("Belt", true)
	if belt then
		belt.AssemblyLinearVelocity = plotCFrame.LookVector * Settings.ConveyorSpeed * conveyorFactor
	end
end

-- Pakeičia visų konvejerių greitį (1 = įprastas)
function TycoonService:SetConveyorFactor(factor)
	conveyorFactor = factor
	for _, state in pairs(states) do
		for _, model in ipairs(state.Plot.Machines:GetChildren()) do
			if string.sub(model.Name, 1, 9) == "Conveyor_" then
				setBelt(model, state.Plot.CFrame)
			end
		end
	end
end

-- Pastato mašiną. localCF – sklypo lokaliose koordinatėse. animate – iškyla iš žemės.
function TycoonService:PlaceMachine(state, templateName, localCF, name, animate)
	local model = S.TemplateBuilder:CloneMachine(templateName)
	if not model then
		return nil
	end
	model.Name = name
	local plotCF = state.Plot.CFrame
	local target = plotCF * localCF
	model.Parent = state.Plot.Machines

	if animate then
		model:PivotTo(target * CF(0, -RISE_DEPTH, 0))
		local value = Instance.new("NumberValue")
		value.Value = 0
		value.Changed:Connect(function(alpha)
			if model.Parent then
				model:PivotTo(target * CF(0, -RISE_DEPTH * (1 - alpha), 0))
			end
		end)
		local tween = TweenService:Create(value, TweenInfo.new(RISE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
		tween.Completed:Connect(function()
			value:Destroy()
			if model.Parent then
				model:PivotTo(target)
				setBelt(model, plotCF)
			end
		end)
		tween:Play()
		Remotes.MachineBuilt:FireClient(state.Player, target.Position)
	else
		model:PivotTo(target)
	end
	setBelt(model, plotCF)
	return model
end

function TycoonService:PlaceBase(state, lineId, animate)
	local x = S.PlotService:GetLaneX(lineId)
	local midZ = (L.ConveyorStartZ + L.ConveyorEndZ) / 2
	self:PlaceMachine(state, "Conveyor_" .. lineId, CF(x, L.ZoneTopY, midZ), "Conveyor_" .. lineId, animate)
	self:PlaceMachine(state, "Sell_" .. lineId, CF(x, L.ZoneTopY, L.SellZ), "Sell_" .. lineId, animate)
	state.Lines[lineId].HasBase = true
end

function TycoonService:PlaceDropper(state, lineId, slot, animate)
	local x = S.PlotService:GetLaneX(lineId)
	local localCF = CF(x, L.ZoneTopY, L.DropperZ[slot])
	local model = self:PlaceMachine(state, "Dropper_" .. lineId, localCF, "Dropper_" .. lineId .. "_" .. slot, animate)
	-- Kritimo taškas (pagal modelio DropPoint dalį, jei yra)
	local dropCF = state.Plot.CFrame * localCF * CF(0, L.DropSpawnHeight, 0)
	local point = model and model:FindFirstChild("DropPoint", true)
	if model and point then
		local target = state.Plot.CFrame * localCF
		-- Santykinis poslinkis nuo modelio pivot (nepriklauso nuo „iškilimo“ animacijos)
		local offset = model:GetPivot():ToObjectSpace(point.CFrame)
		dropCF = target * offset
	end
	local rec = state.Lines[lineId]
	rec.DropPoints[slot] = dropCF
	rec.Timers[slot] = 0
end

function TycoonService:PlaceUpgrader(state, purchase, animate)
	local x = S.PlotService:GetLaneX(purchase.Line)
	self:PlaceMachine(state, purchase.Id, CF(x, L.ZoneTopY, L.UpgraderZ[purchase.Slot]), purchase.Id, animate)
	state.Lines[purchase.Line].Upgraders[purchase.Slot] = purchase
end

function TycoonService:PlaceDecoration(state, purchase, animate)
	local x = S.PlotService:GetLaneX(purchase.Line)
	-- Pasukta 90°, kad ilgas auksinis cepelinas eitų išilgai linijos ir nekabotų virš kitų mygtukų
	self:PlaceMachine(state, purchase.Id, CF(x, L.ZoneTopY, L.StatueZ) * CFrame.Angles(0, math.rad(90), 0), purchase.Id, animate)
end

function TycoonService:PlaceShelf(state, animate)
	if state.Plot.Machines:FindFirstChild("Shelf") then
		return
	end
	self:PlaceMachine(state, "Shelf", CF(L.ShelfX, 0, L.ShelfZ), "Shelf", animate)
end

function TycoonService:PlaceFlag(state, animate)
	if state.Plot.Machines:FindFirstChild("Flag") then
		return
	end
	local x = -(L.GateWidth / 2 + 2)
	self:PlaceMachine(state, "Flag", CF(x, 12, L.GateZ), "Flag", animate)
end

-- Sklypo puošmena iš lentynos (Settings.GlobalUpgrades.Decor)
function TycoonService:PlaceDecor(state, decorId, animate)
	if decorId == "Flag" then
		self:PlaceFlag(state, animate)
		return
	end
	if state.Plot.Machines:FindFirstChild(decorId) then
		return
	end
	for _, decor in ipairs(Settings.GlobalUpgrades.Decor) do
		if decor.Id == decorId and decor.Pos then
			self:PlaceMachine(state, decorId, CF(decor.Pos[1], 0, decor.Pos[2]), decorId, animate)
		end
	end
end

-- Pastato visą liniją pagal būseną (Calc.GetLineState)
function TycoonService:BuildLine(state, lineId, lineState, animate)
	state.Lines[lineId] = { DropPoints = {}, Timers = {}, Backlog = {}, Upgraders = {}, HasBase = false, ValueBonus = 1, ItemCount = 0 }
	if lineState.HasBase then
		self:PlaceBase(state, lineId, animate)
	end
	for slot = 1, lineState.Droppers do
		self:PlaceDropper(state, lineId, slot, animate)
	end
	for _, purchase in ipairs(lineState.Upgraders) do
		self:PlaceUpgrader(state, purchase, animate)
	end
end

----------------------------------------------------------------------
-- Visos gamyklos atkūrimas (prisijungus, po rebirth)
----------------------------------------------------------------------
function TycoonService:BuildPlot(player)
	local plot = S.PlotService:GetPlot(player)
	local data = S.DataService:Get(player)
	if not plot or not data then
		return
	end
	self:StopPlayer(player)
	S.PlotService:ClearPlot(plot)

	local state = { Player = player, Plot = plot, Lines = {}, Items = {}, ItemCount = 0, IncomeMult = 1 }
	states[player] = state

	S.PlotService:ApplySkin(plot, Calc.GetSkin(data.rebirths))
	S.PlotService:ApplyGate(plot, data.globalUpgrades.Gate or 0)
	for _, lineId in ipairs(ProductLines.Order) do
		local lineState = Calc.GetLineState(data, lineId)
		S.PlotService:SetZoneUnlocked(plot, lineId, lineState.Unlocked)
		if lineState.Unlocked then
			self:BuildLine(state, lineId, lineState, false)
			for _, purchase in ipairs(ProductLines.Lines[lineId].Purchases) do
				if purchase.Type == "Decoration" and data.purchases[purchase.Id] then
					self:PlaceDecoration(state, purchase, false)
				end
			end
		end
	end
	if Calc.IsShelfUnlocked(data) then
		self:PlaceShelf(state, false)
	end
	for _, decor in ipairs(Settings.GlobalUpgrades.Decor) do
		if data.globalUpgrades[decor.Id] then
			self:PlaceDecor(state, decor.Id, false)
		end
	end
	S.GrannyService:BuildForPlayer(player)
	self:RefreshButtons(player)
	self:UpdateIncome(player)
end

function TycoonService:StopPlayer(player)
	local state = states[player]
	if not state then
		return
	end
	for _, rec in ipairs(state.Items) do
		if rec.Part.Parent then
			rec.Part:Destroy()
		end
	end
	states[player] = nil
end

----------------------------------------------------------------------
-- Pirkimo mygtukai
----------------------------------------------------------------------
function TycoonService:GetButtonPosition(purchase)
	local x = S.PlotService:GetLaneX(purchase.Line)
	local y = L.ZoneTopY + 0.25
	local side = x + L.ButtonSideOffset
	if purchase.Type == "Dropper" then
		return V(side, y, L.DropperZ[purchase.Slot])
	elseif purchase.Type == "Base" then
		return V(side, y, L.BaseButtonZ)
	elseif purchase.Type == "Upgrader" then
		return V(side, y, L.UpgraderZ[purchase.Slot])
	end
	return V(x, y, L.UnlockButtonZ)
end

function TycoonService:CreateButton(state, localPosition, info)
	local radius = L.ButtonRadius
	local pad = Build.Part({
		Name = "Button_" .. info.Id,
		Parent = state.Plot.Buttons,
		Shape = Enum.PartType.Cylinder,
		Size = V(0.8, radius * 2, radius * 2),
		CFrame = state.Plot.CFrame * CF(localPosition + V(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(200, 60, 50),
		Material = Enum.Material.SmoothPlastic,
		Tags = { "BuyButton" },
		Attributes = { Price = info.Price, OwnerId = state.Player.UserId, ButtonKind = info.Kind, ButtonId = info.Id },
	})
	-- Medinis apvadas
	Build.Part({
		Name = "Rim",
		Parent = pad,
		Shape = Enum.PartType.Cylinder,
		Size = V(0.5, radius * 2 + 0.8, radius * 2 + 0.8),
		CFrame = pad.CFrame * CF(-0.2, 0, 0),
		Color = Color3.fromRGB(92, 58, 30),
		Material = Enum.Material.Wood,
		CanCollide = false,
		CanTouch = false,
	})
	-- Didelis šviečiantis apskritimas ant žemės (klientas nuspalvina: žalias – gali pirkti, raudonas – trūksta)
	Build.Part({
		Name = "Glow",
		Parent = pad,
		Shape = Enum.PartType.Cylinder,
		Size = V(0.12, radius * 2 + 1.2, radius * 2 + 1.2),
		CFrame = pad.CFrame * CF(-0.36, 0, 0),
		Color = Color3.fromRGB(200, 60, 50),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
	})
	Build.Sign(pad, { Name = "NameSign", TextKey = info.TextKey, Size = UDim2.fromScale(7.5, 2), Offset = V(0, 4.4, 0), MaxDistance = 70 })
	if info.Price > 0 then
		Build.Billboard(pad, { Name = "PriceLabel", TextKey = "MoneyAmount", Nums = { amount = info.Price }, Size = UDim2.fromScale(6, 1.4), Offset = V(0, 2.6, 0), MaxDistance = 70, Color = Color3.fromRGB(255, 225, 120) })
	else
		Build.Billboard(pad, { Name = "PriceLabel", TextKey = "Free", Size = UDim2.fromScale(6, 1.4), Offset = V(0, 2.6, 0), MaxDistance = 70, Color = Color3.fromRGB(170, 255, 150) })
	end
	-- Pirkimas užlipus tikrinamas serveryje pagal poziciją (CheckButtons), o čia – atsarginis „E“ mygtukas
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy / Pirkti"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 7
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
	prompt.Triggered:Connect(function(player)
		self:OnButtonTouched(player, state, info)
	end)
	buttonInfo[pad] = info
	return pad
end

-- Ar žaidėjas stovi ant savo sklypo mygtuko? Perkama tik UŽLIPUS (ne stovint vietoje),
-- kad naujas mygtukas toje pačioje vietoje nenupirktų savaime.
function TycoonService:CheckButtons()
	for player, state in pairs(states) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local onButton = nil
		if root and humanoid and humanoid.Health > 0 then
			for _, pad in ipairs(state.Plot.Buttons:GetChildren()) do
				if buttonInfo[pad] then
					local offset = root.Position - pad.Position
					local flat = Vector3.new(offset.X, 0, offset.Z).Magnitude
					if flat <= L.ButtonRadius + 0.8 and offset.Y > -1.5 and offset.Y < Settings.ButtonHeight then
						onButton = pad
						break
					end
				end
			end
		end
		local now = os.clock()
		local inside = insideButton[player]
		if onButton then
			if not inside then
				-- Ką tik užlipo
				insideButton[player] = { Pad = onButton, At = now }
				self:OnButtonTouched(player, state, buttonInfo[onButton])
			elseif inside.Pad == onButton and now - inside.At >= BUTTON_RETRY then
				-- Vis dar stovi ant to paties (pvz. laukė, kol užteks litų)
				inside.At = now
				self:OnButtonTouched(player, state, buttonInfo[onButton])
			end
			-- Naujas mygtukas toje pačioje vietoje (po pirkimo) neperkamas, kol nenulips
		else
			insideButton[player] = nil
		end
	end
end

function TycoonService:RefreshButtons(player)
	local state = states[player]
	local data = S.DataService:Get(player)
	if not state or not data then
		return
	end
	state.Plot.Buttons:ClearAllChildren()
	for _, lineId in ipairs(ProductLines.Order) do
		if Calc.IsLineUnlocked(data, lineId) then
			local purchase = Calc.GetNextPurchase(data, lineId)
			if purchase then
				self:CreateButton(state, self:GetButtonPosition(purchase), { Kind = "Line", Id = purchase.Id, Price = purchase.Price, TextKey = purchase.Id })
			end
			local level, price = S.GrannyService:GetNextLevel(player, lineId)
			if level then
				local x = S.PlotService:GetLaneX(lineId) + L.GrannyButtonX
				self:CreateButton(state, V(x, L.ZoneTopY + 0.25, L.GrannyButtonZ), { Kind = "Granny", Id = "Granny_" .. lineId, LineId = lineId, Price = price, TextKey = "Granny_" .. level })
			end
		end
	end
	for _, upgrade in ipairs(Calc.GetAvailableGlobalUpgrades(data)) do
		local x = L.ShelfButtonsX[upgrade.Slot]
		self:CreateButton(state, V(x, 0.25, L.ShelfButtonsZ), { Kind = "Global", Id = upgrade.Id, Price = upgrade.Price, TextKey = "Global_" .. upgrade.Id })
	end
end

function TycoonService:OnButtonTouched(player, state, info)
	if state.Player ~= player then
		if notifyDebounce:Check(player) then
			S.DataService:Notify(player, "NotYourPlot", nil, nil, nil, "error")
		end
		return
	end
	if states[player] ~= state then
		return
	end
	if not purchaseDebounce:Check(player) then
		return
	end
	if info.Kind == "Line" then
		self:PurchaseLine(player, info.Id)
	elseif info.Kind == "Granny" then
		S.GrannyService:Purchase(player, info.LineId)
	elseif info.Kind == "Global" then
		self:PurchaseGlobal(player, info.Id)
	end
end

-- Bando nurašyti litus; jei trūksta – praneša kiek
function TycoonService:TrySpend(player, price)
	local data = S.DataService:Get(player)
	if not data then
		return false
	end
	if data.money < price then
		if notifyDebounce:Check(player) then
			S.DataService:Notify(player, "NotEnough", nil, nil, { amount = math.ceil(price - data.money) }, "error")
		end
		return false
	end
	return S.DataService:SpendMoney(player, price)
end

----------------------------------------------------------------------
-- Pirkimai
----------------------------------------------------------------------
function TycoonService:PurchaseLine(player, purchaseId)
	local state = states[player]
	local data = S.DataService:Get(player)
	local purchase = ProductLines.ById[purchaseId]
	if not state or not data or not purchase then
		return
	end
	-- Griežta eilė: galima pirkti tik kitą linijos pirkinį
	if Calc.GetNextPurchase(data, purchase.Line) ~= purchase then
		return
	end
	if not self:TrySpend(player, purchase.Price) then
		return
	end
	data.purchases[purchase.Id] = true

	if purchase.Type == "Dropper" then
		if purchase.IncludesBase and not state.Lines[purchase.Line].HasBase then
			self:PlaceBase(state, purchase.Line, true)
		end
		self:PlaceDropper(state, purchase.Line, purchase.Slot, true)
	elseif purchase.Type == "Base" then
		self:PlaceBase(state, purchase.Line, true)
	elseif purchase.Type == "Upgrader" then
		self:PlaceUpgrader(state, purchase, true)
	elseif purchase.Type == "Unlock" then
		local target = purchase.Unlocks
		S.PlotService:SetZoneUnlocked(state.Plot, target, true)
		self:BuildLine(state, target, Calc.GetLineState(data, target), true)
		S.GrannyService:BuildLine(player, target)
		if Calc.IsShelfUnlocked(data) then
			self:PlaceShelf(state, true)
		end
		S.DataService:Notify(player, "LineUnlocked", nil, { line = "Line_" .. target }, nil, "success")
	elseif purchase.Type == "Decoration" then
		self:PlaceDecoration(state, purchase, true)
		if purchase.Badge then
			S.MonetizationService:AwardBadge(player, purchase.Badge)
		end
		S.DataService:Notify(player, "GoldenStatueDone", nil, nil, nil, "success")
	end

	S.DataService:Notify(player, "Bought", nil, { item = purchase.Id }, nil, "success")
	self:RefreshButtons(player)
	self:UpdateIncome(player)
end

function TycoonService:PurchaseGlobal(player, upgradeId)
	local state = states[player]
	local data = S.DataService:Get(player)
	if not state or not data then
		return
	end
	local entry = nil
	for _, upgrade in ipairs(Calc.GetAvailableGlobalUpgrades(data)) do
		if upgrade.Id == upgradeId then
			entry = upgrade
		end
	end
	if not entry then
		return
	end
	if not self:TrySpend(player, entry.Price) then
		return
	end
	if entry.Kind == "DropperSpeed" then
		data.globalUpgrades.DropperSpeed = entry.Level
		Remotes.MachineBuilt:FireClient(player, (state.Plot.CFrame * CF(L.ShelfX, 4, L.ShelfZ)).Position)
	elseif entry.Kind == "Gate" then
		data.globalUpgrades.Gate = entry.Level
		S.PlotService:ApplyGate(state.Plot, entry.Level)
		Remotes.MachineBuilt:FireClient(player, (state.Plot.CFrame * CF(0, 6, L.GateZ)).Position)
	elseif entry.Kind == "Decor" then
		data.globalUpgrades[entry.Id] = true
		self:PlaceDecor(state, entry.Id, true)
	end
	S.DataService:Notify(player, "Bought", nil, { item = "Global_" .. entry.Id }, nil, "success")
	self:RefreshButtons(player)
	self:UpdateIncome(player)
end

----------------------------------------------------------------------
-- Žaliavos: atsiradimas, upgrader'iai, pardavimas
----------------------------------------------------------------------
function TycoonService:SpawnItem(state, lineId, dropCF, valueFactor)
	local line = ProductLines.Lines[lineId]
	local item = S.TemplateBuilder:CloneItem(lineId)
	item.Anchored = false
	item.CanQuery = false
	item.CanTouch = false
	item.CastShadow = false
	item:SetAttribute("Value", line.Item.Value)
	item:SetAttribute("Owner", state.Player.UserId)
	item:SetAttribute("Line", lineId)
	-- Pirma į Workspace (kad suvirintos detalės judėtų kartu), tada į vietą
	item.Parent = state.Plot.Items
	item.CFrame = dropCF * CF((math.random() - 0.5) * 0.6, 0, 0) * CFrame.Angles(0, math.random() * 6.28, 0)
	pcall(function()
		item:SetNetworkOwner(nil)
	end)
	table.insert(state.Items, {
		Part = item,
		Line = lineId,
		Born = os.clock(),
		Value = line.Item.Value,
		Factor = valueFactor,
		Applied = {},
	})
	state.ItemCount = state.ItemCount + 1
	local lineRec = state.Lines[lineId]
	if lineRec then
		lineRec.ItemCount = (lineRec.ItemCount or 0) + 1
	end
end

local function applyLook(part, purchase)
	-- Tikroviškas vaizdas po apdorojimo (Lib/FoodLooks)
	if purchase.ItemLook and FoodLooks.Apply(part, purchase.ItemLook) then
		return
	end
	-- Pirmas apdorojimas: žalios žaliavos detalės (gumbai, lapai) dingsta
	for _, child in ipairs(part:GetChildren()) do
		if child.Name == "Detail" then
			child:Destroy()
		end
	end
	if purchase.ItemColor then
		part.Color = purchase.ItemColor
	end
	if purchase.ItemMaterial then
		part.Material = purchase.ItemMaterial
	end
	if purchase.ItemSize then
		part.Size = purchase.ItemSize
	end
	if purchase.ItemMesh then
		S.TemplateBuilder:ApplyItemMesh(part, purchase.ItemMesh)
	end
	-- Priedas viršuje (grietinė, glajus, antspaudas, kaspinas...)
	if purchase.ItemTopping then
		local old = part:FindFirstChild("Topping")
		if old then
			old:Destroy()
		end
		local size = part.Size
		S.TemplateBuilder.AddDetail(part, "Topping", Vector3.new(size.X * 0.65, math.max(0.25, size.Y * 0.3), size.Z * 0.65),
			CF(0, size.Y / 2, 0), purchase.ItemTopping, Enum.Material.SmoothPlastic, Enum.MeshType.Sphere)
	end
end

function TycoonService:SellItem(state, data, rec)
	local player = state.Player
	if rec.Part:GetAttribute("Owner") ~= player.UserId then
		return
	end
	local lineRec = state.Lines[rec.Line]
	local amount = rec.Value * rec.Factor * (lineRec and lineRec.ValueBonus or 1) * state.IncomeMult
	S.DataService:AddMoney(player, amount, true)
	S.EventService:RecordSale(player, amount)
	data.stats.itemsSold = data.stats.itemsSold + 1
	local x = S.PlotService:GetLaneX(rec.Line)
	local position = (state.Plot.CFrame * CF(x, L.ZoneTopY + 5.5, L.SellZ)).Position
	Remotes.ItemSold:FireClient(player, amount, position)
end

function TycoonService:ProcessItems(state, data)
	local plotCF = state.Plot.CFrame
	local now = os.clock()
	local items = state.Items
	local i = 1
	while i <= #items do
		local rec = items[i]
		local part = rec.Part
		local remove = false
		if not part.Parent or now - rec.Born > Settings.ItemLifetime then
			remove = true
		else
			local lp = plotCF:PointToObjectSpace(part.Position)
			local lineRec = state.Lines[rec.Line]
			if lp.Y < Settings.FallKillDepth then
				remove = true
			elseif lineRec and math.abs(lp.X - S.PlotService:GetLaneX(rec.Line)) <= Settings.ItemLaneTolerance then
				-- Upgrader'is suveikia, kai produktas kerta jo liniją (patikima net serveriui strigus)
				local lastZ = rec.LastZ or (lp.Z + UPGRADER_WINDOW)
				for slot = 1, #L.UpgraderZ do
					local purchase = lineRec.Upgraders[slot]
					if purchase and not rec.Applied[slot] then
						local z = L.UpgraderZ[slot]
						if lp.Z <= z and lastZ >= z - 0.01 then
							rec.Applied[slot] = true
							rec.Value = Calc.ApplyUpgrade(rec.Value, purchase)
							part:SetAttribute("Value", rec.Value)
							part:SetAttribute("Upg_" .. purchase.Id, true)
							applyLook(part, purchase)
						end
					end
				end
				rec.LastZ = lp.Z
				if lineRec.HasBase and lp.Z <= L.SellTriggerZ and lp.Y < L.ConveyorHeight + 4 then
					self:SellItem(state, data, rec)
					remove = true
				end
			end
		end
		if remove then
			if part.Parent then
				part:Destroy()
			end
			items[i] = items[#items]
			items[#items] = nil
			state.ItemCount = state.ItemCount - 1
			local removedLine = state.Lines[rec.Line]
			if removedLine and removedLine.ItemCount then
				removedLine.ItemCount = math.max(0, removedLine.ItemCount - 1)
			end
		else
			i = i + 1
		end
	end
end

function TycoonService:TickState(state, dt)
	local player = state.Player
	local data = S.DataService:Get(player)
	if not data then
		return
	end
	local ctx = self:GetContext(player)
	state.IncomeMult = Calc.GetIncomeMultiplier(data, ctx)

	-- Kiekviena linija gauna savo dalį vietų, kad viena linija neužimtų visų (ir kitos nesustotų)
	local activeLines = 0
	for _, rec in pairs(state.Lines) do
		if next(rec.DropPoints) ~= nil then
			activeLines = activeLines + 1
		end
	end
	local perLine = math.max(Settings.MinItemsPerLine, math.floor(Settings.MaxItemsPerPlot / math.max(1, activeLines)))

	for lineId, rec in pairs(state.Lines) do
		if next(rec.DropPoints) ~= nil then
			local interval, valueFactor = Calc.GetDropInterval(data, lineId, ctx)
			rec.ValueBonus = Calc.GetLineValueBonus(data, lineId, ctx)
			for slot, dropCF in pairs(rec.DropPoints) do
				local timer = (rec.Timers[slot] or 0) + dt
				if timer >= interval then
					timer = timer - interval
					if timer > interval then
						timer = 0
					end
					if (rec.ItemCount or 0) < perLine and state.ItemCount < Settings.MaxItemsPerPlot + Settings.MinItemsPerLine then
						-- Jei anksčiau vietų nebuvo, praleisti produktai pridedami prie šio vertės (pajamos nedingsta)
						local backlog = rec.Backlog[slot] or 0
						rec.Backlog[slot] = 0
						self:SpawnItem(state, lineId, dropCF, valueFactor * (1 + backlog))
					else
						rec.Backlog[slot] = math.min((rec.Backlog[slot] or 0) + 1, 20)
					end
				end
				rec.Timers[slot] = timer
			end
		end
	end
	self:ProcessItems(state, data)
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function TycoonService:Init(services)
	S = services
end

function TycoonService:Start()
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator = accumulator + dt
		if accumulator < Settings.ItemTickRate then
			return
		end
		local step = accumulator
		accumulator = 0
		for _, state in pairs(states) do
			local ok, err = pcall(self.TickState, self, state, step)
			if not ok then
				warn("[TycoonService] " .. tostring(err))
			end
		end
	end)

	-- Mygtukų tikrinimas pagal žaidėjo poziciją
	task.spawn(function()
		while true do
			task.wait(Settings.ButtonCheckRate)
			local ok, err = pcall(self.CheckButtons, self)
			if not ok then
				warn("[TycoonService] CheckButtons: " .. tostring(err))
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		insideButton[player] = nil
	end)

	-- Pajamų per sekundę atnaujinimas UI
	task.spawn(function()
		while true do
			task.wait(Settings.IncomeUpdateRate)
			for _, player in ipairs(Players:GetPlayers()) do
				if S.DataService:Get(player) then
					self:UpdateIncome(player)
				end
			end
		end
	end)
end

return TycoonService
