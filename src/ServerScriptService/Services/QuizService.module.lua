--[[
	QuizService – „Viktorina apie Lietuvą“: kas kelias minutes visiems iššoka klausimas.
	Teisingai atsakęs gauna litų. Atsakymai tikrinami TIK serveryje (klientas teisingo
	atsakymo nežino), kiekvienas gali atsakyti tik vieną kartą.
	Klausimai – ServerScriptService/Lib/QuizQuestions, nustatymai – Settings.Quiz.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Questions = require(Lib:WaitForChild("QuizQuestions"))
local RateLimit = require(Lib:WaitForChild("RateLimit"))

local Q = Settings.Quiz

local QuizService = {}
local S
local current = nil               -- { Id, Index, Order, EndsAt, Answered }
local quizCounter = 0
local lastIndex = nil
local random = Random.new()
local limiter = RateLimit.new(Settings.RemoteRateLimit)

local function shuffledOrder()
	local order = { 1, 2, 3, 4 }
	for i = #order, 2, -1 do
		local j = random:NextInteger(1, i)
		order[i], order[j] = order[j], order[i]
	end
	return order
end

local function payloadFor(player)
	local lang = S.DataService:GetLang(player)
	local q = Questions[current.Index][lang] or Questions[current.Index].en
	local answers = {}
	for i, original in ipairs(current.Order) do
		answers[i] = q[original + 1]
	end
	return { Id = current.Id, Question = q[1], Answers = answers, EndsAt = current.EndsAt }
end

local function correctText(player)
	local lang = S.DataService:GetLang(player)
	local q = Questions[current.Index][lang] or Questions[current.Index].en
	return q[2]
end

function QuizService:IsActive()
	return current ~= nil
end

function QuizService:StartQuiz(index)
	if current or #Questions == 0 then
		return false
	end
	if not index then
		repeat
			index = random:NextInteger(1, #Questions)
		until index ~= lastIndex or #Questions == 1
	end
	lastIndex = index
	quizCounter = quizCounter + 1
	current = {
		Id = quizCounter,
		Index = index,
		Order = shuffledOrder(),
		EndsAt = workspace:GetServerTimeNow() + Q.Duration,
		Answered = {},
	}
	for _, player in ipairs(Players:GetPlayers()) do
		if S.DataService:Get(player) then
			Remotes.QuizStart:FireClient(player, payloadFor(player))
		end
	end
	local quiz = current
	task.delay(Q.Duration + 0.5, function()
		if current ~= quiz then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			if S.DataService:Get(player) and not quiz.Answered[player] then
				Remotes.QuizResult:FireClient(player, quiz.Id, nil, 0, correctText(player))
			end
		end
		current = nil
	end)
	return true
end

function QuizService:Answer(player, quizId, choice)
	if not current or quizId ~= current.Id or current.Answered[player] then
		return
	end
	if type(choice) ~= "number" or choice < 1 or choice > 4 or choice ~= math.floor(choice) then
		return
	end
	if workspace:GetServerTimeNow() > current.EndsAt + 1 then
		return
	end
	current.Answered[player] = true
	local correct = current.Order[choice] == 1
	local reward = 0
	if correct then
		reward = math.max(Q.MinReward, S.TycoonService:GetIncomePerSecond(player) * Q.RewardSeconds)
		S.DataService:AddMoney(player, reward, true)
	end
	Remotes.QuizResult:FireClient(player, current.Id, correct, reward, correctText(player))
end

function QuizService:Init(services)
	S = services
end

function QuizService:Start()
	Remotes.QuizAnswer.OnServerEvent:Connect(function(player, quizId, choice)
		if limiter:Check(player) then
			self:Answer(player, quizId, choice)
		end
	end)
	task.spawn(function()
		task.wait(random:NextNumber(Q.FirstDelay[1], Q.FirstDelay[2]))
		while true do
			self:StartQuiz()
			task.wait(random:NextNumber(Q.MinGap, Q.MaxGap))
		end
	end)
end

return QuizService
