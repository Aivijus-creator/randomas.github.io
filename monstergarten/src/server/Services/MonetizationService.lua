-- MonetizationService: game passes, developer products and a safe ProcessReceipt.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Monetization = require(Shared.Config.Monetization)
local Shop = require(Shared.Config.Shop)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local MonetizationService = {}
local S
local passCache: { [Player]: { [string]: boolean } } = {}

local function passName(id: number): string?
	for name, pid in Monetization.GamePasses do
		if pid == id and pid ~= 0 then
			return name
		end
	end
	return nil
end

local function applyPassPerks(player: Player)
	local vip = MonetizationService:OwnsPass(player, "VIP")
	player:SetAttribute("VIP", vip)
	if vip then
		S.DataService:Update(player, function(d)
			d.Cosmetics.Owned.Apron_VIP = true
		end)
	end
	player:SetAttribute("PetSlots", if vip then 2 else 1)
	player:SetAttribute("HeadNanny", MonetizationService:OwnsPass(player, "HeadNanny"))
	player:SetAttribute("MusicBox", MonetizationService:OwnsPass(player, "MusicBox"))
end

function MonetizationService:OwnsPass(player: Player, name: string): boolean
	local id = Monetization.GamePasses[name]
	if not id or id == 0 then
		return false
	end
	local cache = passCache[player]
	if not cache then
		cache = {}
		passCache[player] = cache
	end
	if cache[name] == nil then
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
		cache[name] = ok and owns == true
	end
	return cache[name] == true
end

-- product id -> grant function
local function grantFor(productId: number): ((Player, any) -> ())?
	for _, pack in Shop.CoinPacks do
		if Monetization.Products[pack.Id] == productId and productId ~= 0 then
			return function(player)
				S.DataService:Update(player, function(d)
					d.Coins += pack.Coins
				end)
				ServerUtil.notify(player, { "Toast_CoinsReward", pack.Coins }, "coins")
			end
		end
	end
	for cosmeticId, pid in Monetization.PremiumCosmetics do
		if pid == productId and pid ~= 0 then
			return function(player)
				S.DataService:Update(player, function(d)
					d.Cosmetics.Owned[cosmeticId] = true
				end)
				ServerUtil.notify(player, { "Toast_CosmeticReward", cosmeticId }, "unlock")
			end
		end
	end
	return nil
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = S.DataService:WaitFor(player, 10)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local key = tostring(info.PurchaseId)
	if data.ProcessedReceipts[key] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local grant = grantFor(info.ProductId)
	if not grant then
		warn("[Monetization] unknown product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local ok, err = pcall(grant, player, info)
	if not ok then
		warn("[Monetization] grant failed", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	S.DataService:Update(player, function(d)
		d.ProcessedReceipts[key] = os.time()
		-- keep the receipt log bounded
		local n = 0
		for _ in d.ProcessedReceipts do
			n += 1
		end
		if n > 200 then
			local oldestK, oldestT = nil, math.huge
			for k, t in d.ProcessedReceipts do
				if t < oldestT then
					oldestK, oldestT = k, t
				end
			end
			if oldestK then
				d.ProcessedReceipts[oldestK] = nil
			end
		end
	end)
	-- Persist before telling Roblox the purchase is granted.
	if not S.DataService:Save(player) and not S.DataService.UseMock then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:Init(services)
	S = services
end

function MonetizationService:Start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, id, purchased)
		local name = passName(id)
		if purchased and name then
			passCache[player] = passCache[player] or {}
			passCache[player][name] = true
			applyPassPerks(player)
			ServerUtil.notify(player, { "Toast_PassBought", "Pass_" .. name }, "unlock")
		end
	end)
	S.DataService.Loaded:Connect(function(player)
		applyPassPerks(player)
	end)
	Players.PlayerRemoving:Connect(function(p)
		passCache[p] = nil
	end)
	Remotes.event("PromptPurchase").OnServerEvent:Connect(function(player, kind, id)
		if not ServerUtil.rateLimit(player, "Purchase", 2) or type(id) ~= "string" then
			return
		end
		if kind == "Pass" then
			local pid = Monetization.GamePasses[id]
			if pid and pid ~= 0 then
				MarketplaceService:PromptGamePassPurchase(player, pid)
			end
		elseif kind == "Product" then
			local pid = Monetization.Products[id]
			if pid and pid ~= 0 then
				MarketplaceService:PromptProductPurchase(player, pid)
			end
		elseif kind == "Cosmetic" then
			local pid = Monetization.PremiumCosmetics[id]
			if pid and pid ~= 0 then
				MarketplaceService:PromptProductPurchase(player, pid)
			end
		end
	end)
end

return MonetizationService
