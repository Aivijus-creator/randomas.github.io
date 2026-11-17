--[[
	BonusService – nemokami bonusai:
	  - Grupės bonusas (+10 % pajamų, jei žaidėjas Roblox grupėje; GroupId – Config/Monetization)
	  - Kasdienis prizas kas 24 val.: 5 min. pajamų × serijos daugiklis (1–7 d.)
	  - ×3 boost'o laikmatis (mažėja tik žaidžiant, išsaugomas)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Monetization = require(Config:WaitForChild("Monetization"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RateLimit = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("RateLimit"))

local D = Settings.Daily

local BonusService = {}
local S
local inGroup = {}
local limiter = RateLimit.new(Settings.RemoteRateLimit)

function BonusService:IsInGroup(player)
	return inGroup[player] == true
end

function BonusService:ClaimDaily(player)
	local data = S.DataService:Get(player)
	if not data then
		return { Success = false }
	end
	local now = os.time()
	local since = now - data.lastDaily
	if data.lastDaily > 0 and since < D.Cooldown then
		return { Success = false, Wait = D.Cooldown - since }
	end
	if data.lastDaily > 0 and since <= D.StreakResetAfter then
		data.dailyStreak = math.min(data.dailyStreak + 1, #D.StreakMultipliers)
	else
		data.dailyStreak = 1
	end
	data.lastDaily = now
	local multiplier = D.StreakMultipliers[data.dailyStreak]
	local base = math.max(D.MinReward, S.TycoonService:GetIncomePerSecond(player) * D.IncomeSeconds)
	local amount = base * multiplier
	S.DataService:AddMoney(player, amount, true)
	player:SetAttribute("DailyStreak", data.dailyStreak)
	player:SetAttribute("LastDaily", data.lastDaily)
	S.DataService:Notify(player, "DailyGot", nil, nil, { amount = amount }, "success")
	return { Success = true, Amount = amount, Streak = data.dailyStreak }
end

function BonusService:Init(services)
	S = services
end

function BonusService:Start()
	Remotes.ClaimDaily.OnServerInvoke = function(player)
		if not limiter:Check(player) then
			return { Success = false }
		end
		return self:ClaimDaily(player)
	end

	S.DataService:OnPlayerLoaded(function(player, data)
		-- Praleista diena – serija nusinuliuoja (rodoma UI)
		if data.lastDaily > 0 and os.time() - data.lastDaily > D.StreakResetAfter then
			data.dailyStreak = 0
			player:SetAttribute("DailyStreak", 0)
		end
		if Monetization.GroupId ~= 0 then
			local ok, result = pcall(function()
				return player:IsInGroupAsync(Monetization.GroupId)
			end)
			if ok and result then
				inGroup[player] = true
				S.DataService:Notify(player, "GroupBonus", nil, nil, nil, "success")
				S.TycoonService:UpdateIncome(player)
			end
		end
	end)

	-- Boost'o laikmatis
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				local data = S.DataService:Get(player)
				if data and data.boostRemaining > 0 then
					data.boostRemaining = math.max(0, data.boostRemaining - 1)
					player:SetAttribute("BoostRemaining", data.boostRemaining)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			inGroup[player] = nil
		end)
	end)
end

return BonusService
