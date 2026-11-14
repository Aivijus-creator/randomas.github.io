-- ProgressionService: coins, stars (daycare level), nanny XP/levels, unlock checks and notifications.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local P = require(Shared.Logic.ProgressionMath)
local Progression = require(Shared.Config.Progression)
local Babies = require(Shared.Config.Babies)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local ProgressionService = {}
local S

local function setAttributes(player: Player, data)
	player:SetAttribute("NannyLevel", data.NannyLevel)
	player:SetAttribute("DaycareLevel", P.daycareLevel(data.TotalStars))
	player:SetAttribute("TitleKey", P.titleKey(data.NannyLevel))
end

function ProgressionService:Init(services)
	S = services
end

function ProgressionService:Start()
	S.DataService.Loaded:Connect(function(player, data)
		setAttributes(player, data)
	end)
	for _, p in Players:GetPlayers() do
		local d = S.DataService:Get(p)
		if d then
			setAttributes(p, d)
		end
	end
end

function ProgressionService:GetLevel(player: Player): number
	local d = S.DataService:Get(player)
	return d and P.daycareLevel(d.TotalStars) or 1
end

function ProgressionService:IsUnlocked(player: Player, unlockId: string): boolean
	local d = S.DataService:Get(player)
	if not d then
		return false
	end
	if d.DebugUnlockAll then
		return true
	end
	return P.isUnlocked(d.TotalStars, unlockId)
end

function ProgressionService:UnlockedBabies(player: Player): { string }
	local out = {}
	for _, id in Babies.Order do
		if self:IsUnlocked(player, "Baby:" .. id) then
			table.insert(out, id)
		end
	end
	return out
end

function ProgressionService:AddCoins(player: Player, amount: number, silent: boolean?)
	amount = math.floor(amount)
	if amount == 0 then
		return
	end
	S.DataService:Update(player, function(d)
		d.Coins = math.max(0, d.Coins + amount)
	end)
	if not silent and amount > 0 then
		ServerUtil.sound({ player }, "UI_Coins")
	end
end

function ProgressionService:SpendCoins(player: Player, amount: number): boolean
	local d = S.DataService:Get(player)
	if not d or d.Coins < amount or amount < 0 then
		return false
	end
	S.DataService:Update(player, function(data)
		data.Coins -= amount
	end)
	return true
end

function ProgressionService:AddStars(player: Player, stars: number)
	if stars <= 0 then
		return
	end
	local d = S.DataService:Get(player)
	if not d then
		return
	end
	local before = P.daycareLevel(d.TotalStars)
	S.DataService:Update(player, function(data)
		data.TotalStars += stars
	end)
	local after = P.daycareLevel(d.TotalStars)
	for lvl = before + 1, after do
		ServerUtil.notify(player, { "Toast_DaycareLevel", lvl }, "level")
		for _, unlock in P.unlocksAt(lvl) do
			local kind, id = unlock:match("^(%w+):(%w+)$")
			ServerUtil.notify(player, { "Toast_Unlocked_" .. tostring(kind), id }, "unlock")
		end
	end
	if after > before then
		ServerUtil.sound({ player }, "UI_LevelUp")
	end
	setAttributes(player, d)
end

function ProgressionService:AddXP(player: Player, xp: number)
	local d = S.DataService:Get(player)
	if not d or xp <= 0 then
		return
	end
	local newLevel, rest, gained = P.applyXP(d.NannyLevel, d.NannyXP, xp)
	S.DataService:Update(player, function(data)
		data.NannyLevel = newLevel
		data.NannyXP = rest
	end)
	for _, lvl in gained do
		ServerUtil.notify(player, { "Toast_NannyLevel", lvl }, "level")
		local reward = Progression.NannyLevelRewards[lvl]
		if reward then
			if reward.Coins then
				self:AddCoins(player, reward.Coins, true)
				ServerUtil.notify(player, { "Toast_CoinsReward", reward.Coins }, "coins")
			end
			if reward.Cosmetic then
				S.DataService:Update(player, function(data)
					data.Cosmetics.Owned[reward.Cosmetic] = true
				end)
				ServerUtil.notify(player, { "Toast_CosmeticReward", reward.Cosmetic }, "unlock")
			end
		end
		if lvl % 5 == 0 then
			ServerUtil.notify(player, { "Toast_NewTitle", P.titleKey(lvl) }, "level")
		end
	end
	if #gained > 0 then
		ServerUtil.sound({ player }, "UI_LevelUp")
	end
	setAttributes(player, d)
end

function ProgressionService:Refresh(player: Player)
	local d = S.DataService:Get(player)
	if d then
		setAttributes(player, d)
	end
end

return ProgressionService
