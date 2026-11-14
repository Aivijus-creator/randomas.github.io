-- QuestService: 3 daily quests (auto-rewarded on completion) + the 7-day daily gift.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Quests = require(Shared.Config.Quests)
local P = require(Shared.Logic.ProgressionMath)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local QuestService = {}
local S

local function today(): string
	return os.date("!%Y-%m-%d") :: string
end

local function dayIndex(): number
	return math.floor(os.time() / 86400)
end

local function ensureQuests(player: Player)
	local d = S.DataService:Get(player)
	if not d or d.DailyQuests.Date == today() then
		return
	end
	local rng = Random.new(player.UserId + dayIndex() * 7919)
	local pool = table.clone(Quests.Pool)
	local list = {}
	for _ = 1, Quests.PerDay do
		if #pool == 0 then
			break
		end
		local q = table.remove(pool, rng:NextInteger(1, #pool))
		table.insert(list, { Id = q.Id, Progress = 0, Done = false })
	end
	S.DataService:Update(player, function(data)
		data.DailyQuests = { Date = today(), Quests = list }
	end)
end

local function defOf(id: string)
	for _, q in Quests.Pool do
		if q.Id == id then
			return q
		end
	end
	return nil
end

function QuestService:Track(player: Player, stat: string, amount: number, arg: string?)
	local d = S.DataService:Get(player)
	if not d then
		return
	end
	ensureQuests(player)
	local rewards = {}
	S.DataService:Update(player, function(data)
		for _, q in data.DailyQuests.Quests do
			local def = defOf(q.Id)
			if def and not q.Done and def.Stat == stat and (def.Arg == nil or def.Arg == arg) then
				q.Progress = math.min(def.Goal, q.Progress + amount)
				if q.Progress >= def.Goal then
					q.Done = true
					table.insert(rewards, def)
				end
			end
		end
	end)
	for _, def in rewards do
		S.ProgressionService:AddCoins(player, def.Reward)
		ServerUtil.notify(player, { "Toast_QuestDone", "Quest_" .. def.Id, def.Reward }, "coins")
	end
end

function QuestService:Init(services)
	S = services
end

function QuestService:Start()
	S.DataService.Loaded:Connect(function(player)
		ensureQuests(player)
	end)
	Remotes.event("ClaimDaily").OnServerEvent:Connect(function(player)
		if not ServerUtil.rateLimit(player, "Daily", 1) then
			return
		end
		local d = S.DataService:Get(player)
		if not d then
			return
		end
		local ok, streak, coins = P.dailyReward(d.DailyReward.LastClaim, d.DailyReward.Streak, dayIndex())
		if not ok then
			ServerUtil.notify(player, "Daily_Already", "error")
			return
		end
		S.DataService:Update(player, function(data)
			data.DailyReward.LastClaim = dayIndex()
			data.DailyReward.Streak = streak
		end)
		S.ProgressionService:AddCoins(player, coins)
		ServerUtil.notify(player, { "Toast_Daily", coins, streak }, "coins")
	end)
end

return QuestService
