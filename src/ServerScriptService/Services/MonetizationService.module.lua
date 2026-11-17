--[[
	MonetizationService – gamepass'ai, developer products, badge'ai, offline pajamos, VIP zona.
	ID – Config/Monetization (kol 0, pirkti negalima; Studio testams – /givepass).

	ProcessReceipt: kiekvienas PurchaseId išsaugomas žaidėjo duomenyse, todėl produktas
	nepasikartoja ir nedingsta; PurchaseGranted grąžinamas tik po sėkmingo išsaugojimo.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Monetization = require(Config:WaitForChild("Monetization"))
local Calc = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Calc"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local MonetizationService = {}
local S
local passCache = {}             -- [player] = { DoubleMoney = true, ... }
local passReady = {}             -- [player] = true, kai patikrinta
local EMPTY = {}

----------------------------------------------------------------------
-- Gamepass'ai
----------------------------------------------------------------------
function MonetizationService:GetPasses(player)
	return passCache[player] or EMPTY
end

function MonetizationService:HasPass(player, name)
	return (passCache[player] or EMPTY)[name] == true
end

local function passNameById(id)
	for name, pass in pairs(Monetization.GamePasses) do
		if pass.Id ~= 0 and pass.Id == id then
			return name
		end
	end
	return nil
end

local function productNameById(id)
	for name, product in pairs(Monetization.Products) do
		if product.Id ~= 0 and product.Id == id then
			return name
		end
	end
	return nil
end

-- Pritaiko gamepass'ą iš karto (po pirkimo arba /givepass)
function MonetizationService:GrantPass(player, name)
	passCache[player] = passCache[player] or {}
	if passCache[player][name] then
		return
	end
	passCache[player][name] = true
	player:SetAttribute("Pass_" .. name, true)
	if name == "GrannyHelp" then
		S.GrannyService:BuildForPlayer(player)
		S.TycoonService:RefreshButtons(player)
	end
	S.TycoonService:UpdateIncome(player)
end

local function loadPasses(player)
	local cache = {}
	for name, pass in pairs(Monetization.GamePasses) do
		if pass.Id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.Id)
			end)
			if ok and owns then
				cache[name] = true
			elseif not ok then
				warn("[Monetization] Nepavyko patikrinti gamepass " .. name .. ": " .. tostring(owns))
			end
		end
	end
	-- Jei jau buvo suteikta (pvz. /givepass), neprarandam
	for name, value in pairs(passCache[player] or EMPTY) do
		cache[name] = value
	end
	passCache[player] = cache
	for name in pairs(Monetization.GamePasses) do
		player:SetAttribute("Pass_" .. name, cache[name] == true)
	end
	passReady[player] = true
end

----------------------------------------------------------------------
-- Badge'ai
----------------------------------------------------------------------
function MonetizationService:AwardBadge(player, key)
	local data = S.DataService:Get(player)
	if data then
		data.badges[key] = true
	end
	local id = Settings.Badges[key]
	if not id or id == 0 then
		return
	end
	task.spawn(function()
		local ok, err = pcall(function()
			BadgeService:AwardBadgeAsync(player.UserId, id)
		end)
		if not ok then
			warn("[Monetization] Badge klaida: " .. tostring(err))
		end
	end)
end

----------------------------------------------------------------------
-- Developer products
----------------------------------------------------------------------
function MonetizationService:GrantProduct(player, name)
	local product = Monetization.Products[name]
	if not product then
		return false
	end
	local data = S.DataService:Get(player)
	if name == "SmallBag" or name == "BigBag" then
		local amount = math.max(product.MinReward, S.TycoonService:GetIncomePerSecond(player) * product.IncomeSeconds)
		S.DataService:AddMoney(player, amount, true)
	elseif name == "PotatoRain" then
		S.EventService:QueuePotatoRain()
	elseif name == "Boost3" then
		data.boostRemaining = data.boostRemaining + product.Duration
		player:SetAttribute("BoostRemaining", data.boostRemaining)
		S.TycoonService:UpdateIncome(player)
	end
	S.DataService:Notify(player, "PurchaseThanks", nil, { item = "Product_" .. name }, nil, "success")
	return true
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = S.DataService:Get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)

	-- Jau apdorotas: tik užtikrinam, kad išsaugota
	if data.receipts[purchaseId] then
		if S.DataService:Save(player, false) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local name = productNameById(receipt.ProductId)
	if not name then
		warn("[Monetization] Nežinomas produktas: " .. tostring(receipt.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not MonetizationService:GrantProduct(player, name) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.receipts[purchaseId] = os.time()
	table.insert(data.receiptOrder, purchaseId)
	while #data.receiptOrder > Monetization.ReceiptHistory do
		local oldest = table.remove(data.receiptOrder, 1)
		data.receipts[oldest] = nil
	end

	if S.DataService:Save(player, false) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- Išsaugoti nepavyko: Roblox pakartos, o PurchaseId jau pažymėtas – prizas nebus duotas antrą kartą
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

----------------------------------------------------------------------
-- Offline pajamos
----------------------------------------------------------------------
local function grantOffline(player, data, lastOnline)
	if not MonetizationService:HasPass(player, "OfflineIncome") or lastOnline <= 0 then
		return
	end
	local elapsed = math.min(os.time() - lastOnline, Settings.Offline.MaxSeconds)
	if elapsed < Settings.Offline.MinSeconds then
		return
	end
	local ctx = S.TycoonService:GetContext(player)
	ctx.eventDropMult = 1
	ctx.eventMoneyMult = 1
	ctx.boost = false
	local amount = Calc.GetIncomePerSecond(data, ctx) * elapsed * Settings.Offline.Share
	if amount > 0 then
		S.DataService:AddMoney(player, amount, true)
		Remotes.OpenWindow:FireClient(player, "Offline", amount)
	end
end

----------------------------------------------------------------------
-- VIP zona
----------------------------------------------------------------------
local function setupVipZone()
	local zone = S.MapBuilder.Anchors.VIPZone
	if not zone then
		return
	end
	zone.CanTouch = true
	zone.Touched:Connect(function(hit)
		local player = S.PlotService:GetPlayerFromHit(hit)
		if player and not MonetizationService:HasPass(player, "VIP") then
			local character = player.Character
			if character then
				character:PivotTo(S.MapBuilder:GetLobbySpawnCFrame())
				S.DataService:Notify(player, "VIPOnly", nil, nil, nil, "error")
			end
		end
	end)
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function MonetizationService:Init(services)
	S = services
end

function MonetizationService:Start()
	MarketplaceService.ProcessReceipt = processReceipt

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local name = passNameById(passId)
		if name then
			self:GrantPass(player, name)
			S.DataService:Notify(player, "PurchaseThanks", nil, { item = "Pass_" .. name }, nil, "success")
		end
	end)

	S.DataService:OnPlayerLoaded(function(player, data)
		local lastOnline = data.lastOnline
		loadPasses(player)
		if player.Parent then
			S.TycoonService:UpdateIncome(player)
			if self:HasPass(player, "GrannyHelp") and S.PlotService:GetPlot(player) then
				S.GrannyService:BuildForPlayer(player)
				S.TycoonService:RefreshButtons(player)
			end
			grantOffline(player, data, lastOnline)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			passCache[player] = nil
			passReady[player] = nil
		end)
	end)

	setupVipZone()
end

return MonetizationService
