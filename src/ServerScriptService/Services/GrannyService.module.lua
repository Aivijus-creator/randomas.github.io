--[[
	GrannyService – močiutės darbuotojos (po vieną kiekvienai linijai, 3 lygiai).
	- R15 rig'as su skarele ir prijuoste (jei nepavyksta sukurti – paprasta močiutė iš Parts).
	- Klientas animuoja rankas ir rodo kalbos burbulą (atributas "Phrase").
	- Kainos ir efektai – Settings.Grannies, formulės – Calc.
	Savo modelį gali įdėti į ServerStorage/Templates/Machines pavadinimu "Granny"
	(jame turi būti HumanoidRootPart, Head, o skarelė/prijuostė – dalys "Scarf" ir "Apron").
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local ProductLines = require(Config:WaitForChild("ProductLines"))
local Texts = require(Config:WaitForChild("Texts"))
local Calc = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Calc"))
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local GrannyModels = require(Lib:WaitForChild("GrannyModels"))

local G = Settings.Grannies
local L = Settings.Layout
local CF = CFrame.new
local V = Vector3.new
local C = Color3.fromRGB

local GrannyService = {}
local S
local records = {}                 -- [player] = { [lineId] = { Model = ..., NextAt = ... } }
local random = Random.new()

----------------------------------------------------------------------
-- Modeliai (Lib/GrannyModels). Savo modelį gali įdėti į ServerStorage/Templates/Machines
-- pavadinimu "Granny_1", "Granny_2" arba "Granny_3".
----------------------------------------------------------------------
local function getTemplate(level)
	local machines = ServerStorage:WaitForChild("Templates"):WaitForChild("Machines")
	local name = "Granny_" .. level
	local template = machines:FindFirstChild(name)
	if not template then
		template = GrannyModels.Build(level)
		template.Name = name
		template.Parent = machines
	end
	return template
end

----------------------------------------------------------------------
-- Statymas sklype
----------------------------------------------------------------------
function GrannyService:GetLevel(player, lineId)
	local data = S.DataService:Get(player)
	if not data then
		return 0
	end
	return Calc.GetGrannyLevel(data, lineId, S.TycoonService:GetContext(player))
end

-- Kitas perkamas lygis ir kaina (nil – maksimalus lygis arba linija užrakinta)
function GrannyService:GetNextLevel(player, lineId)
	local data = S.DataService:Get(player)
	if not data or not Calc.IsLineUnlocked(data, lineId) then
		return nil
	end
	local nextLevel = self:GetLevel(player, lineId) + 1
	local price = Calc.GetGrannyPrice(lineId, nextLevel)
	if not price then
		return nil
	end
	return nextLevel, price
end

function GrannyService:BuildLine(player, lineId, animate)
	local plot = S.PlotService:GetPlot(player)
	if not plot then
		return
	end
	for _, name in ipairs({ "Granny_" .. lineId, "GrannyTable_" .. lineId }) do
		local old = plot.Machines:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	records[player] = records[player] or {}
	records[player][lineId] = nil

	local data = S.DataService:Get(player)
	if not data or not Calc.IsLineUnlocked(data, lineId) then
		return
	end
	local x = S.PlotService:GetLaneX(lineId) + L.GrannyX
	local tableModel = S.TemplateBuilder:CloneMachine("GrannyTable")
	if tableModel then
		tableModel.Name = "GrannyTable_" .. lineId
		tableModel:PivotTo(plot.CFrame * CF(x, L.ZoneTopY, L.GrannyZ))
		tableModel.Parent = plot.Machines
	end

	local level = self:GetLevel(player, lineId)
	if level <= 0 then
		return
	end
	local granny = getTemplate(level):Clone()
	granny.Name = "Granny_" .. lineId
	local root = granny:FindFirstChild("HumanoidRootPart")
	if root then
		root.Anchored = true
	end
	granny:SetAttribute("Level", level)
	granny:SetAttribute("Phrase", "")
	if animate then
		-- Klientas parodo nusileidimą iš dangaus
		granny:SetAttribute("ArriveAt", workspace:GetServerTimeNow())
	end
	-- Stovi už stalo, veidu į konvejerį (+X)
	local position = (plot.CFrame * CF(x - L.GrannyStandOffset, L.ZoneTopY, L.GrannyZ)).Position
	local facing = position + plot.CFrame.RightVector
	granny.Parent = plot.Machines
	Build.PlaceOnFloor(granny, CFrame.lookAt(position, Vector3.new(facing.X, position.Y, facing.Z)))
	local head = granny:FindFirstChild("Head")
	if head then
		local top = level == 3 and 4.2 or 2.6
		Build.Billboard(head, { Name = "GrannyStars", Text = string.rep("★", level) .. string.rep("☆", 3 - level), Size = UDim2.fromScale(3, 0.9), Offset = V(0, top + 2.0, 0), MaxDistance = 60, Color = C(255, 205, 60) })
		Build.Billboard(head, { Name = "GrannyName", TextKey = "Granny_" .. level, Size = UDim2.fromScale(6, 1.2), Offset = V(0, top + 1.1, 0), MaxDistance = 60, Font = Enum.Font.Fondamento })
		-- Ką močiutė duoda (greitis / vertė)
		Build.Billboard(head, { Name = "GrannyEffect", TextKey = "GrannyEffect_" .. level, Size = UDim2.fromScale(8, 1), Offset = V(0, top, 0), MaxDistance = 60, Font = Enum.Font.Merriweather, Color = C(170, 255, 140) })
	end
	CollectionService:AddTag(granny, "Granny")
	records[player][lineId] = { Model = granny, NextAt = os.clock() + random:NextNumber(G.PhraseMin, G.PhraseMax) }
end

function GrannyService:BuildForPlayer(player)
	for _, lineId in ipairs(ProductLines.Order) do
		task.spawn(function()
			self:BuildLine(player, lineId)
		end)
	end
end

function GrannyService:Purchase(player, lineId)
	local data = S.DataService:Get(player)
	if not data then
		return
	end
	local level, price = self:GetNextLevel(player, lineId)
	if not level then
		return
	end
	if not S.TycoonService:TrySpend(player, price) then
		return
	end
	data.grannies[lineId] = level
	self:BuildLine(player, lineId, true)
	S.DataService:Notify(player, "GrannyHired", nil, { granny = "Granny_" .. level, line = "Line_" .. lineId }, nil, "success")
	S.TycoonService:RefreshButtons(player)
	S.TycoonService:UpdateIncome(player)
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function GrannyService:Init(services)
	S = services
end

function GrannyService:Start()
	-- Šablonai sukuriami iš anksto (matosi ServerStorage žaidžiant)
	for level = 1, #G.Levels do
		getTemplate(level)
	end

	-- Kalbos burbulai: kas 20–40 s atsitiktinė frazė (tekstą klientas parenka pagal savo kalbą)
	local phraseCount = #Texts.en.GrannyPhrases
	task.spawn(function()
		local nonce = 0
		while true do
			task.wait(1)
			local now = os.clock()
			for _, lines in pairs(records) do
				for _, rec in pairs(lines) do
					if rec.Model.Parent and now >= rec.NextAt then
						nonce = nonce + 1
						rec.Model:SetAttribute("Phrase", math.random(1, phraseCount) .. ":" .. nonce)
						rec.NextAt = now + random:NextNumber(G.PhraseMin, G.PhraseMax)
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		records[player] = nil
	end)
end

return GrannyService
