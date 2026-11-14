-- RewardService: turns shift results into coins, XP, stars, friendship, stats, quests and leaderboards.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Scoring = require(Shared.Logic.Scoring)
local Progression = require(Shared.Config.Progression)
local Monetization = require(Shared.Config.Monetization)

local RewardService = {}
local S

function RewardService:Init(services)
	S = services
end

local function weekKey(): string
	local t = os.time()
	return tostring(math.floor((t / 86400 + 3) / 7)) -- weeks since epoch, Monday-based
end

function RewardService:Grant(session, results)
	session.Personal = {}
	-- MVP = most actions (ties: first)
	local mvp, mvpN = nil, -1
	for _, p in session.Players do
		local n = session.Actions[p] or 0
		if n > mvpN then
			mvp, mvpN = p, n
		end
	end
	if #session.Players < 2 then
		mvp = nil
	end
	results.MVP = mvp and mvp.UserId or nil
	results.MVPName = mvp and mvp.DisplayName or nil

	for _, p in session.Players do
		local personal = { Coins = 0, XP = 0, Stars = results.Stars, MVP = p == mvp, Tutorial = results.Tutorial }
		if results.Tutorial then
			local d = S.DataService:Get(p)
			if d and not d.TutorialDone then
				personal.Coins = Progression.TutorialReward
				S.ProgressionService:AddCoins(p, personal.Coins, true)
				S.DataService:Update(p, function(data)
					data.TutorialDone = true
				end)
			end
			personal.XP = Progression.ShiftXPBase
			S.ProgressionService:AddXP(p, personal.XP)
		else
			local coins = Scoring.coins(results.FinalScore, results.Stars, results.EventCoins, session.Difficulty.Coins)
			if p == mvp then
				coins = math.floor(coins * (1 + Progression.MVPBonus))
			end
			if S.MonetizationService:OwnsPass(p, "CoinPouch") then
				coins = math.floor(coins * (1 + Monetization.CoinPouchBonus))
			end
			personal.Coins = coins
			personal.XP = Scoring.xp(session.Actions[p] or 0, Progression.ShiftXPBase, Progression.ShiftXPMax)
			S.ProgressionService:AddCoins(p, coins, true)
			S.ProgressionService:AddXP(p, personal.XP)
			S.ProgressionService:AddStars(p, results.Stars)
			local wk = weekKey()
			S.DataService:Update(p, function(d)
				d.Stats.ShiftsPlayed += 1
				d.Stats.BestScore = math.max(d.Stats.BestScore, results.FinalScore)
				if results.Stars == 3 then
					d.Stats.ThreeStarShifts += 1
				end
				if d.WeeklyBest.Week ~= wk then
					d.WeeklyBest.Week = wk
					d.WeeklyBest.Score = 0
				end
				d.WeeklyBest.Score = math.max(d.WeeklyBest.Score, results.FinalScore)
				-- friendship: every baby cared for with 3 stars
				if results.Stars == 3 then
					for _, b in results.Babies do
						d.BabyFriendship[b.BabyId] = (d.BabyFriendship[b.BabyId] or 0) + 1
					end
				end
			end)
			S.QuestService:Track(p, "ShiftPlayed", 1)
			S.QuestService:Track(p, "Stars", results.Stars)
			if results.Stars == 3 then
				local seen = {}
				for _, b in results.Babies do
					if not seen[b.BabyId] then
						seen[b.BabyId] = true
						S.QuestService:Track(p, "ThreeStarBaby", 1, b.BabyId)
					end
				end
			end
			S.LeaderboardService:Submit(p)
		end
		session.Personal[p] = personal
		task.spawn(function()
			S.DataService:Save(p)
		end)
	end
end

function RewardService:ResultsFor(session, player: Player)
	local r = table.clone(session.Results or {})
	r.Personal = session.Personal and session.Personal[player] or {}
	return r
end

return RewardService
