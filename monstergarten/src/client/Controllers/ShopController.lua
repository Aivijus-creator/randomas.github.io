-- ShopController: tabs Tools / Daycare / Cosmetics / Robux. Buying is validated on the server.
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local Tools = require(Shared.Config.Tools)
local Shop = require(Shared.Config.Shop)
local Cosmetics = require(Shared.Config.Cosmetics)
local Monetization = require(Shared.Config.Monetization)
local P = require(Shared.Logic.ProgressionMath)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local C = UI.Theme.Colors
local ShopController = {}
local window
local tabBar: Frame
local grid: ScrollingFrame
local tab = "Tools"
local productPrices: { [number]: string } = {}

local function card(order: number, emoji: string, name: string, sub: string, price: string, color: Color3, enabled: boolean, onBuy: () -> ())
	local f = UI.panel({ Size = UDim2.fromOffset(196, 200), LayoutOrder = order, Parent = grid }, color)
	UI.label(emoji, { Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 56), Parent = f })
	UI.label(name, { Position = UDim2.fromOffset(8, 66), Size = UDim2.new(1, -16, 0, 28), TextWrapped = true, Parent = f })
	UI.label(sub, { Position = UDim2.fromOffset(8, 96), Size = UDim2.new(1, -16, 0, 40), Font = Enum.Font.GothamBold, TextWrapped = true, TextTransparency = 0.2, Parent = f })
	local b = UI.button(price, if enabled then C.Mint else Color3.fromRGB(190, 190, 190), function()
		if enabled then
			onBuy()
		end
	end, { Position = UDim2.new(0, 12, 1, -54), Size = UDim2.new(1, -24, 0, 44), Parent = f })
	b.AutoButtonColor = false
end

local function clear()
	for _, c in grid:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
end

function ShopController:Render()
	if not window or not window.IsOpen() then
		return
	end
	clear()
	local d = State.Data
	if not d then
		return
	end
	local level = P.daycareLevel(d.TotalStars)
	for _, b in tabBar:GetChildren() do
		if b:IsA("TextButton") then
			b.BackgroundColor3 = if b.Name == tab then C.Yellow else C.Lavender
		end
	end
	if tab == "Tools" then
		for i, id in Tools.Order do
			local def = Tools.Defs[id]
			if #def.UpgradeCost > 0 then
				local lvl = d.ToolUpgrades[id] or 0
				local cost = def.UpgradeCost[lvl + 1]
				local unlocked = P.isUnlocked(d.TotalStars, "Tool:" .. id) or d.DebugUnlockAll
				local sub = Strings.t("Shop_Level", lvl + 1, #def.UpgradeCost + 1) .. "\n" .. Strings.t("ToolDesc_" .. id)
				local price = if not unlocked then Strings.t("Shop_Locked") elseif cost then ("🪙 " .. cost) else Strings.t("Shop_Max")
				card(i, def.Emoji, Strings.t("Item_" .. id), sub, price, C.Cream, unlocked and cost ~= nil and d.Coins >= cost, function()
					Remotes.event("ShopBuy"):FireServer("Tool", id)
				end)
			end
		end
	elseif tab == "Daycare" then
		for i, id in Shop.DaycareOrder do
			local def = Shop.DaycareUpgrades[id]
			local owned = d.DaycareUpgrades[id]
			local unlocked = level >= def.UnlockLevel or d.DebugUnlockAll
			local price = if owned then Strings.t("Shop_Owned") elseif not unlocked then Strings.t("Shop_NeedLevel", def.UnlockLevel) else ("🪙 " .. def.Cost)
			card(i, def.Emoji, Strings.t("Upgrade_" .. id), Strings.t("UpgradeDesc_" .. id), price, C.Cream, not owned and unlocked and d.Coins >= def.Cost, function()
				Remotes.event("ShopBuy"):FireServer("Daycare", id)
			end)
		end
	elseif tab == "Cosmetics" then
		for i, id in Cosmetics.Order do
			local def = Cosmetics.Defs[id]
			if def.Cost > 0 then
				local owned = d.Cosmetics.Owned[id]
				card(i, "👗", Strings.name(def.Name), Strings.t("Slot_" .. def.Slot), if owned then Strings.t("Shop_Owned") else ("🪙 " .. def.Cost), C.Cream, not owned and d.Coins >= def.Cost, function()
					Remotes.event("ShopBuy"):FireServer("Cosmetic", id)
				end)
			end
		end
	elseif tab == "Robux" then
		local order = 0
		local function robuxCard(emoji, nameKey, descKey, kind, id, pid)
			if pid == 0 then
				return
			end
			order += 1
			local price = productPrices[pid] or "R$"
			card(order, emoji, Strings.t(nameKey), Strings.t(descKey), price, C.Peach, true, function()
				Remotes.event("PromptPurchase"):FireServer(kind, id)
			end)
		end
		robuxCard("👑", "Pass_VIP", "PassDesc_VIP", "Pass", "VIP", Monetization.GamePasses.VIP)
		robuxCard("🍼", "Pass_HeadNanny", "PassDesc_HeadNanny", "Pass", "HeadNanny", Monetization.GamePasses.HeadNanny)
		robuxCard("🎶", "Pass_MusicBox", "PassDesc_MusicBox", "Pass", "MusicBox", Monetization.GamePasses.MusicBox)
		robuxCard("💰", "Pass_CoinPouch", "PassDesc_CoinPouch", "Pass", "CoinPouch", Monetization.GamePasses.CoinPouch)
		for _, pack in Shop.CoinPacks do
			robuxCard("🪙", "Product_" .. pack.Id, "ProductDesc_Coins", "Product", pack.Id, Monetization.Products[pack.Id])
		end
		for cid, pid in Monetization.PremiumCosmetics do
			local def = Cosmetics.Defs[cid]
			if def and pid ~= 0 then
				order += 1
				local owned = d.Cosmetics.Owned[cid]
				card(order, "✨", Strings.name(def.Name), Strings.t("Slot_" .. def.Slot), if owned then Strings.t("Shop_Owned") else (productPrices[pid] or "R$"), C.Peach, not owned, function()
					Remotes.event("PromptPurchase"):FireServer("Cosmetic", cid)
				end)
			end
		end
		if order == 0 then
			local l = UI.label("", { Size = UDim2.new(1, 0, 0, 60), TextWrapped = true, Parent = grid })
			UI.bind(l, "Shop_NoRobux")
			l.Parent = grid
		end
	end
end

function ShopController:Open()
	if State.inShift() then
		return
	end
	window.Open()
	self:Render()
end

function ShopController:Init()
	local gui = UI.screen("ShopGui", 16)
	window = UI.window(gui, "Shop_Title", UDim2.fromOffset(880, 560))
	tabBar = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 46), Parent = window.Content })
	UI.list(tabBar, 8, true)
	for i, id in { "Tools", "Daycare", "Cosmetics", "Robux" } do
		local b = UI.button("", C.Lavender, function()
			tab = id
			self:Render()
		end, { Size = UDim2.fromOffset(170, 44), LayoutOrder = i, Parent = tabBar })
		b.Name = id
		UI.bind(b, "ShopTab_" .. id)
	end
	grid = UI.scroll(window.Content, { Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 1, -56) })
	UI.grid(grid, UDim2.fromOffset(196, 200), 10)
	window.OnOpen = function()
		self:Render()
	end
end

function ShopController:Start()
	State.DataChanged:Connect(function()
		self:Render()
	end)
	State.LanguageChanged:Connect(function()
		self:Render()
	end)
	-- fetch Robux prices once (only for configured ids)
	task.spawn(function()
		local function price(id: number, infoType: Enum.InfoType)
			if id == 0 then
				return
			end
			local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, id, infoType)
			if ok and info and info.PriceInRobux then
				productPrices[id] = "R$ " .. tostring(info.PriceInRobux)
			end
		end
		for _, id in Monetization.GamePasses do
			price(id, Enum.InfoType.GamePass)
		end
		for _, id in Monetization.Products do
			price(id, Enum.InfoType.Product)
		end
		for _, id in Monetization.PremiumCosmetics do
			price(id, Enum.InfoType.Product)
		end
	end)
end

return ShopController
