--[[
	AdminService – administratoriaus komandos.
	Kas gali naudoti:
	  - Roblox Studio: visi (testavimui);
	  - tikrame žaidime: TIK žaidimo savininkas (game.CreatorId) ir Settings.AdminUserIds žaidėjai.
	Kitiems žaidėjams komandos nieko nedaro.

	Komandos (rašyk į pokalbį):
	  /givemoney Jonas 5000      – duoti litų kitam žaidėjui (vardo pradžia, "all" – visiems)
	  /addmoney 1000000          – pridėti litų sau
	  /takemoney Jonas 5000      – atimti litų iš žaidėjo ("all" – iš visų; daugiau nei turi – lieka 0)
	  /setrebirths 5             – nustatyti rebirth skaičių (gamykla perstatoma)
	  /event lietus|cepelinas|jonines|stop
	  /givepass DoubleMoney|FastDroppers|GrannyHelp|VIP|OfflineIncome
	  /product SmallBag|BigBag|PotatoRain|Boost3
	  /resetdata                 – ištrinti savo progresą
	  /jail Jonas / /unjail Jonas – pasodinti nusikaltėlį ant kėdės miške / paleisti
	  /mage 1234567890           – radijas „Magė“ groja muziką pagal kodą (/mage stop, /mage volume 0.5)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Monetization = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Monetization"))
local Settings = require(ReplicatedStorage:WaitForChild("Config"):WaitForChild("Settings"))

local AdminService = {}
local S

local EVENT_NAMES = {
	lietus = "PotatoRain", cepelinas = "BigCepelinas", jonines = "Jonines",
	laume = "Fairy", ziema = "Winter", varzybos = "Contest", mociute = "SkyGranny",
}

local function reply(player, text)
	ReplicatedStorage.Remotes.Notify:FireClient(player, "__raw", { text = "[Admin] " .. text }, {}, {}, "info")
end

-- Ar žaidėjas gali naudoti admin komandas
function AdminService:IsAdmin(player)
	if RunService:IsStudio() then
		return true
	end
	for _, id in ipairs(Settings.AdminUserIds or {}) do
		if player.UserId == id then
			return true
		end
	end
	if game.CreatorType == Enum.CreatorType.User then
		return player.UserId == game.CreatorId
	end
	-- Grupės žaidimas: grupės savininkas (rangas 255)
	local ok, rank = pcall(function()
		return player:GetRankInGroup(game.CreatorId)
	end)
	return ok and rank >= 255
end

-- Randa žaidėjus pagal vardo pradžią (Name arba DisplayName); "all" – visi
local function findTargets(query)
	local list = {}
	query = string.lower(query or "")
	if query == "" then
		return list
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if query == "all" or string.sub(string.lower(other.Name), 1, #query) == query or string.sub(string.lower(other.DisplayName), 1, #query) == query then
			table.insert(list, other)
		end
	end
	return list
end

function AdminService:Run(player, message)
	if not self:IsAdmin(player) then
		return
	end
	local args = string.split(message, " ")
	local command = string.lower(args[1] or "")
	local data = S.DataService:Get(player)
	if not data then
		return
	end
	print("[Admin] " .. player.Name .. ": " .. message)

	if command == "/givemoney" then
		local targets = findTargets(args[2])
		local amount = tonumber(args[3])
		if #targets == 0 or not amount or amount <= 0 then
			reply(player, "/givemoney <vardas|all> <suma>, pvz. /givemoney Jonas 5000")
			return
		end
		for _, target in ipairs(targets) do
			if S.DataService:AddMoney(target, amount, false) then
				ReplicatedStorage.Remotes.Notify:FireClient(target, "__raw", { text = "🎁 +" .. amount .. " Lt" }, {}, {}, "success")
				reply(player, target.Name .. " +" .. amount .. " Lt")
			end
		end
	elseif command == "/takemoney" then
		local targets = findTargets(args[2])
		local amount = tonumber(args[3])
		if #targets == 0 or not amount or amount <= 0 or amount ~= amount then
			reply(player, "/takemoney <vardas|all> <suma>, pvz. /takemoney Jonas 5000")
			return
		end
		for _, target in ipairs(targets) do
			local targetData = S.DataService:Get(target)
			if targetData then
				local taken = math.min(amount, targetData.money)
				targetData.money = targetData.money - taken
				S.DataService:UpdateStats(target)
				ReplicatedStorage.Remotes.Notify:FireClient(target, "__raw", { text = "💸 -" .. math.floor(taken) .. " Lt" }, {}, {}, "error")
				reply(player, target.Name .. " -" .. math.floor(taken) .. " Lt (liko " .. math.floor(targetData.money) .. ")")
			end
		end
	elseif command == "/addmoney" then
		local amount = tonumber(args[2])
		if amount and amount > 0 then
			S.DataService:AddMoney(player, amount, false)
			reply(player, "+" .. amount .. " Lt")
		end
	elseif command == "/setrebirths" then
		local count = tonumber(args[2])
		if count and count >= 0 then
			data.rebirths = math.floor(count)
			S.DataService:UpdateStats(player)
			S.TycoonService:BuildPlot(player)
			S.RebirthService:ApplyTitle(player)
			reply(player, "rebirths = " .. data.rebirths)
		end
	elseif command == "/event" then
		local which = string.lower(args[2] or "")
		if which == "stop" then
			S.EventService:StopEvent()
			reply(player, "event stopped")
		elseif EVENT_NAMES[which] then
			S.EventService:StopEvent()
			S.EventService:StartEvent(EVENT_NAMES[which], nil, true)
			reply(player, "event " .. EVENT_NAMES[which])
		else
			reply(player, "/event lietus|cepelinas|jonines|laume|ziema|varzybos|mociute|stop")
		end
	elseif command == "/jail" or command == "/unjail" then
		local targets = findTargets(args[2])
		if #targets == 0 or string.lower(args[2] or "") == "all" then
			reply(player, command .. " <vardas>")
			return
		end
		for _, target in ipairs(targets) do
			if command == "/jail" then
				S.JailService:Jail(target)
				reply(player, "jailed: " .. target.Name)
			else
				S.JailService:Release(target)
				reply(player, "released: " .. target.Name)
			end
		end
	elseif command == "/mage" then
		local arg = string.lower(args[2] or "")
		if arg == "stop" then
			S.RadioService:Stop()
			reply(player, "Magė: stop")
		elseif arg == "volume" then
			reply(player, "Magė volume = " .. S.RadioService:SetVolume(args[3]))
		else
			local ok, result = S.RadioService:Play(player, args[2])
			reply(player, ok and ("Magė ♪ " .. result) or "/mage <kodas> | /mage stop | /mage volume 0.5")
		end
	elseif command == "/quiz" then
		if S.QuizService:StartQuiz() then
			reply(player, "quiz started")
		else
			reply(player, "quiz already running")
		end
	elseif command == "/givepass" then
		local name = args[2]
		if name and Monetization.GamePasses[name] then
			S.MonetizationService:GrantPass(player, name)
			reply(player, "pass " .. name)
		else
			reply(player, "/givepass DoubleMoney|FastDroppers|GrannyHelp|VIP|OfflineIncome")
		end
	elseif command == "/product" then
		local name = args[2]
		if name and Monetization.Products[name] then
			S.MonetizationService:GrantProduct(player, name)
		else
			reply(player, "/product SmallBag|BigBag|PotatoRain|Boost3")
		end
	elseif command == "/resetdata" then
		data.money = 0
		data.totalEarned = 0
		data.rebirths = 0
		data.purchases = {}
		data.grannies = {}
		data.globalUpgrades = {}
		data.tutorialDone = false
		data.boostRemaining = 0
		data.radio = { recent = {} }
		player:SetAttribute("CanUseRadio", self:IsAdmin(player))
		data.dailyStreak = 0
		data.lastDaily = 0
		S.DataService:SyncAttributes(player)
		S.TycoonService:BuildPlot(player)
		S.RebirthService:ApplyTitle(player)
		reply(player, "data reset")
	end
end

function AdminService:Init(services)
	S = services
end

function AdminService:Start()
	if RunService:IsStudio() then
		print("[AdminService] Studio admin komandos įjungtos: /givemoney, /addmoney, /setrebirths, /event, /givepass, /product, /resetdata")
	end

	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local folder = Instance.new("Folder")
		folder.Name = "AdminCommands"
		folder.Parent = TextChatService
		for _, name in ipairs({ "givemoney", "takemoney", "addmoney", "setrebirths", "event", "quiz", "mage", "jail", "unjail", "givepass", "product", "resetdata" }) do
			local command = Instance.new("TextChatCommand")
			command.Name = "Admin_" .. name
			command.PrimaryAlias = "/" .. name
			pcall(function()
				command.AutocompleteVisible = false -- kiti žaidėjai komandų pasiūlymų nemato
			end)
			command.Parent = folder
			command.Triggered:Connect(function(source, text)
				local player = Players:GetPlayerByUserId(source.UserId)
				if player then
					self:Run(player, text)
				end
			end)
		end
	else
		local function hook(player)
			player.Chatted:Connect(function(message)
				if string.sub(message, 1, 1) == "/" then
					self:Run(player, message)
				end
			end)
		end
		for _, player in ipairs(Players:GetPlayers()) do
			hook(player)
		end
		Players.PlayerAdded:Connect(hook)
	end
end

return AdminService
