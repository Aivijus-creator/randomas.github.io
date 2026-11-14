-- ShopService: buying tool upgrades, daycare upgrades and cosmetics with coins.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tools = require(Shared.Config.Tools)
local Shop = require(Shared.Config.Shop)
local Cosmetics = require(Shared.Config.Cosmetics)
local P = require(Shared.Logic.ProgressionMath)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local ShopService = {}
local S

local function buy(player: Player, kind: string, id: string)
	local d = S.DataService:Get(player)
	if not d then
		return
	end
	if kind == "Tool" then
		local def = Tools.Defs[id]
		if not def or #def.UpgradeCost == 0 then
			return
		end
		if not S.ProgressionService:IsUnlocked(player, "Tool:" .. id) then
			ServerUtil.notify(player, { "Tool_Locked", id }, "error")
			return
		end
		local lvl = d.ToolUpgrades[id] or 0
		local cost = def.UpgradeCost[lvl + 1]
		if not cost then
			ServerUtil.notify(player, "Shop_MaxLevel", "error")
			return
		end
		if not S.ProgressionService:SpendCoins(player, cost) then
			ServerUtil.notify(player, "Shop_NoCoins", "error")
			return
		end
		S.DataService:Update(player, function(data)
			data.ToolUpgrades[id] = lvl + 1
		end)
		ServerUtil.notify(player, { "Toast_Upgraded", id, lvl + 2 }, "good")
	elseif kind == "Daycare" then
		local def = Shop.DaycareUpgrades[id]
		if not def then
			return
		end
		if d.DaycareUpgrades[id] then
			ServerUtil.notify(player, "Shop_Owned", "error")
			return
		end
		if P.daycareLevel(d.TotalStars) < def.UnlockLevel and not d.DebugUnlockAll then
			ServerUtil.notify(player, { "Shop_NeedLevel", def.UnlockLevel }, "error")
			return
		end
		if not S.ProgressionService:SpendCoins(player, def.Cost) then
			ServerUtil.notify(player, "Shop_NoCoins", "error")
			return
		end
		S.DataService:Update(player, function(data)
			data.DaycareUpgrades[id] = true
		end)
		ServerUtil.notify(player, { "Toast_Bought", "Upgrade_" .. id }, "good")
	elseif kind == "Cosmetic" then
		local def = Cosmetics.Defs[id]
		if not def or def.Premium or def.Cost <= 0 then
			return
		end
		if d.Cosmetics.Owned[id] then
			ServerUtil.notify(player, "Shop_Owned", "error")
			return
		end
		if not S.ProgressionService:SpendCoins(player, def.Cost) then
			ServerUtil.notify(player, "Shop_NoCoins", "error")
			return
		end
		S.DataService:Update(player, function(data)
			data.Cosmetics.Owned[id] = true
		end)
		ServerUtil.notify(player, { "Toast_Bought", id }, "good")
	else
		return
	end
	ServerUtil.sound({ player }, "UI_Purchase")
end

function ShopService:Init(services)
	S = services
end

function ShopService:Start()
	Remotes.event("ShopBuy").OnServerEvent:Connect(function(player, kind, id)
		if not ServerUtil.rateLimit(player, "Shop", 4) then
			return
		end
		if type(kind) ~= "string" or type(id) ~= "string" then
			return
		end
		if S.ShiftService:SessionOf(player) then
			return -- shopping only in the lobby
		end
		buy(player, kind, id)
	end)
end

return ShopService
