--[[
	DataService – žaidėjų duomenų įkėlimas ir išsaugojimas (DataStore).

	- Savas DataStore wrapper'is su UpdateAsync, pakartojimais ir session lock'u
	  (kad tas pats žaidėjas dviejuose serveriuose neperrašytų duomenų).
	- Autosave kas Settings.AutosaveInterval s, išsaugojimas išeinant ir BindToClose.
	- Jei DataStore nepasiekiamas (pvz. nepublikuotas place Studio), žaidimas veikia
	  „offline“ režimu: viskas veikia, tik neišsaugoma (Output lange – įspėjimas).
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Texts = require(Config:WaitForChild("Texts"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))
local Calc = require(Shared:WaitForChild("Calc"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RateLimit = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("RateLimit"))

local DataService = {}
DataService.Profiles = {}         -- [player] = duomenų lentelė
DataService.SessionStart = {}     -- [player] = os.time()

local S
local dataStore = nil
local storeState = "pending"      -- "pending" | "online" | "offline"
local loadedCallbacks = {}
local removingCallbacks = {}
local settingsLimiter = RateLimit.new(Settings.RemoteRateLimit)

----------------------------------------------------------------------
-- Duomenų struktūra (bendro failo 9 skyrius + vėlesnių etapų laukai)
----------------------------------------------------------------------
local function defaultData()
	return {
		version = Settings.DataVersion,
		money = Settings.StartingMoney,
		totalEarned = 0,
		rebirths = 0,
		purchases = {},           -- { ["Cepelinai_3"] = true }
		grannies = {},            -- { Cepelinai = 2 }
		globalUpgrades = {},      -- { DropperSpeed = 1, Flag = true, StorkNest = true, ... }
		dailyStreak = 0,
		lastDaily = 0,
		lastOnline = 0,
		settings = { music = true, sfx = true, beeps = true, lang = "en", langChosen = false },
		tutorialDone = false,
		cosmetics = { skins = {} },
		badges = {},
		receipts = {},            -- { [PurchaseId] = os.time() }
		receiptOrder = {},        -- PurchaseId sąrašas (seniausi pirmi)
		boostRemaining = 0,       -- ×3 boost'o likęs laikas (s)
		weapons = {},             -- { Spoon = true } – nupirkti ginklai (lieka po rebirth)
		radio = { recent = {} },
		jailed = false,           -- /jail bausmė (tęsiasi ir grįžus)  -- radijo „Magė“ neseniai grotos dainos { {id=, name=} }
		stats = { itemsSold = 0, playTime = 0, joins = 0 },
	}
end

-- Užpildo trūkstamus laukus (pvz. senesnis išsaugojimas be naujų laukų)
local function reconcile(target, template)
	for key, value in pairs(template) do
		if target[key] == nil then
			if type(value) == "table" then
				local copy = {}
				for k, v in pairs(value) do
					copy[k] = v
				end
				target[key] = copy
			else
				target[key] = value
			end
		elseif type(value) == "table" and type(target[key]) == "table" and next(value) ~= nil then
			reconcile(target[key], value)
		end
	end
end

-- Migracijos: MIGRATIONS[n] paverčia n versijos duomenis n+1 versija
local MIGRATIONS = {
	-- 1 -> 2: konvejeris sujungtas su pirmu bulvių maišu, todėl Cepelinų pirkiniai pernumeruoti
	-- (senas Cepelinai_2 = konvejeris išmetamas, seni 3..10 tampa 2..9)
	[1] = function(data)
		-- Tik senoji schema turėjo Cepelinai_10 (naujoje jų 9)
		if not data.purchases["Cepelinai_10"] then
			return
		end
		local old = data.purchases
		local new = {}
		for id, value in pairs(old) do
			local n = tonumber(string.match(id, "^Cepelinai_(%d+)$"))
			if not n then
				new[id] = value
			elseif n == 1 then
				new[id] = value
			elseif n >= 3 then
				new["Cepelinai_" .. (n - 1)] = value
			end
		end
		data.purchases = new
	end,
}

local function migrate(data)
	data.version = data.version or 1
	while data.version < Settings.DataVersion do
		local step = MIGRATIONS[data.version]
		if not step then
			break
		end
		step(data)
		data.version = data.version + 1
	end
	reconcile(data, defaultData())
	return data
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function isLockedByOther(record)
	return record and record.sessionLock
		and record.sessionLock.jobId ~= game.JobId
		and os.time() - (record.sessionLock.time or 0) < Settings.SessionLockStale
end

local function waitForStore()
	while storeState == "pending" do
		task.wait(0.1)
	end
end

----------------------------------------------------------------------
-- Įkėlimas / išsaugojimas
----------------------------------------------------------------------
local function loadData(player)
	waitForStore()
	if storeState ~= "online" then
		return defaultData()
	end
	local key = keyFor(player)
	for attempt = 1, Settings.LoadRetries do
		local result = nil
		local isLastAttempt = attempt == Settings.LoadRetries
		local ok, err = pcall(function()
			dataStore:UpdateAsync(key, function(old)
				-- Kitas serveris dar laiko užraktą: laukiam (paskutinį kartą – perimam)
				if isLockedByOther(old) and not isLastAttempt then
					return nil
				end
				local data = old or defaultData()
				data.sessionLock = { jobId = game.JobId, time = os.time() }
				result = data
				return data
			end)
		end)
		if ok and result then
			return result
		end
		if not ok then
			warn("[DataService] Įkėlimo klaida (" .. attempt .. "): " .. tostring(err))
		end
		task.wait(Settings.RetryDelay * attempt)
	end
	return nil
end

function DataService:Save(player, release)
	local data = self.Profiles[player]
	if not data then
		return false
	end
	data.lastOnline = os.time()
	if storeState ~= "online" then
		return true -- offline režimas: nėra kur saugoti
	end
	local key = keyFor(player)
	for attempt = 1, Settings.SaveRetries do
		local blocked = false
		local ok, err = pcall(function()
			dataStore:UpdateAsync(key, function(old)
				if isLockedByOther(old) then
					blocked = true
					return nil
				end
				if release then
					data.sessionLock = nil
				else
					data.sessionLock = { jobId = game.JobId, time = os.time() }
				end
				return data
			end)
		end)
		if ok and not blocked then
			return true
		end
		if blocked then
			warn("[DataService] " .. player.Name .. " duomenis užrakino kitas serveris – neišsaugota.")
			return false
		end
		warn("[DataService] Išsaugojimo klaida (" .. attempt .. "): " .. tostring(err))
		task.wait(Settings.RetryDelay)
	end
	return false
end

function DataService:IsOnline()
	return storeState == "online"
end

----------------------------------------------------------------------
-- Prieiga kitiems servisams
----------------------------------------------------------------------
function DataService:Get(player)
	return self.Profiles[player]
end

function DataService:OnPlayerLoaded(callback)
	table.insert(loadedCallbacks, callback)
	for player, data in pairs(self.Profiles) do
		task.spawn(callback, player, data)
	end
end

function DataService:OnPlayerRemoving(callback)
	table.insert(removingCallbacks, callback)
end

function DataService:GetLang(player)
	local data = self.Profiles[player]
	return (data and data.settings.lang) or "en"
end

function DataService:Text(player, key, args)
	return Texts.Get(self:GetLang(player), key, args)
end

-- Pranešimas žaidėjui (klientas išverčia pagal raktą)
-- args – paprasti tekstai; keys – reikšmės, kurios pačios yra teksto raktai; nums – skaičiai
function DataService:Notify(player, key, args, keys, nums, kind)
	Remotes.Notify:FireClient(player, key, args or {}, keys or {}, nums or {}, kind or "info")
end

function DataService:UpdateStats(player)
	local data = self.Profiles[player]
	if not data then
		return
	end
	player:SetAttribute("Money", data.money)
	player:SetAttribute("TotalEarned", data.totalEarned)
	player:SetAttribute("Rebirths", data.rebirths)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Litai.Value = NumberFormat.Format(data.money)
		leaderstats.Rebirth.Value = data.rebirths
		leaderstats.Titulas.Value = Texts.Get(data.settings.lang, Calc.GetTitleKey(data.rebirths))
	end
end

-- Prideda litų. earned = true – skaičiuojama į totalEarned (pardavimai, prizai)
function DataService:AddMoney(player, amount, earned)
	local data = self.Profiles[player]
	if not data or type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false
	end
	data.money = data.money + amount
	if earned then
		data.totalEarned = data.totalEarned + amount
	end
	player:SetAttribute("Money", data.money)
	player:SetAttribute("TotalEarned", data.totalEarned)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Litai.Value = NumberFormat.Format(data.money)
	end
	return true
end

function DataService:SpendMoney(player, amount)
	local data = self.Profiles[player]
	if not data or type(amount) ~= "number" or amount < 0 then
		return false
	end
	if data.money < amount then
		return false
	end
	data.money = data.money - amount
	self:UpdateStats(player)
	return true
end

function DataService:SyncAttributes(player)
	local data = self.Profiles[player]
	if not data then
		return
	end
	player:SetAttribute("Lang", data.settings.lang)
	player:SetAttribute("Music", data.settings.music)
	player:SetAttribute("Sfx", data.settings.sfx)
	player:SetAttribute("Beeps", data.settings.beeps ~= false)
	player:SetAttribute("TutorialDone", data.tutorialDone)
	player:SetAttribute("DailyStreak", data.dailyStreak)
	player:SetAttribute("LastDaily", data.lastDaily)
	player:SetAttribute("BoostRemaining", data.boostRemaining)
	self:UpdateStats(player)
end

----------------------------------------------------------------------
-- Žaidėjai
----------------------------------------------------------------------
local function createLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local litai = Instance.new("StringValue")
	litai.Name = "Litai"
	litai.Parent = folder
	local rebirth = Instance.new("IntValue")
	rebirth.Name = "Rebirth"
	rebirth.Parent = folder
	local title = Instance.new("StringValue")
	title.Name = "Titulas"
	title.Parent = folder
	folder.Parent = player
end

function DataService:_onPlayerAdded(player)
	local data = loadData(player)
	if not data then
		player:Kick("Nepavyko įkelti duomenų. Prisijunk iš naujo. / Could not load your data, please rejoin.")
		return
	end
	migrate(data)

	if not player.Parent then
		-- Žaidėjas išėjo, kol krovėsi duomenys – atlaisvinam užraktą
		self.Profiles[player] = data
		self:Save(player, true)
		self.Profiles[player] = nil
		return
	end

	-- Pradinė kalba pagal LocalizationService (lietuvių -> LT, kitaip EN)
	if not data.settings.langChosen then
		local locale = string.lower(player.LocaleId or "")
		if string.sub(locale, 1, 2) == "lt" then
			data.settings.lang = "lt"
		else
			data.settings.lang = "en"
		end
	end
	data.stats.joins = data.stats.joins + 1

	self.Profiles[player] = data
	self.SessionStart[player] = os.time()
	createLeaderstats(player)
	self:SyncAttributes(player)
	player:SetAttribute("DataLoaded", true)

	for _, callback in ipairs(loadedCallbacks) do
		task.spawn(callback, player, data)
	end
end

function DataService:_onPlayerRemoving(player)
	local data = self.Profiles[player]
	if not data then
		return
	end
	for _, callback in ipairs(removingCallbacks) do
		local ok, err = pcall(callback, player, data)
		if not ok then
			warn("[DataService] OnPlayerRemoving klaida: " .. tostring(err))
		end
	end
	local started = self.SessionStart[player]
	if started then
		data.stats.playTime = data.stats.playTime + (os.time() - started)
		self.SessionStart[player] = nil
	end
	self:Save(player, true)
	self.Profiles[player] = nil
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function DataService:Init(services)
	S = services
end

function DataService:Start()
	-- Patikrinam, ar DataStore pasiekiamas
	task.spawn(function()
		local ok, store = pcall(function()
			return DataStoreService:GetDataStore(Settings.DataStoreName)
		end)
		if ok and store then
			local pingOk, err = pcall(function()
				return store:GetAsync("__ping")
			end)
			if pingOk then
				dataStore = store
				storeState = "online"
				return
			end
			warn("[DataService] DataStore nepasiekiamas – progresas NEBUS išsaugotas. "
				.. "Publikuok place ir įjunk Game Settings → Security → Enable Studio Access to API Services. ("
				.. tostring(err) .. ")")
		else
			warn("[DataService] DataStore nepasiekiamas: " .. tostring(store))
		end
		storeState = "offline"
	end)

	-- Autosave
	task.spawn(function()
		while true do
			task.wait(Settings.AutosaveInterval)
			for player in pairs(self.Profiles) do
				task.spawn(function()
					self:Save(player, false)
				end)
			end
		end
	end)

	-- Serverio išjungimas: išsaugom visus
	game:BindToClose(function()
		if RunService:IsStudio() and storeState ~= "online" then
			return
		end
		local pending = 0
		for player in pairs(self.Profiles) do
			pending = pending + 1
			task.spawn(function()
				self:Save(player, true)
				pending = pending - 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)

	-- Nustatymų keitimas iš kliento (muzika, garsai, kalba)
	Remotes.ChangeSetting.OnServerEvent:Connect(function(player, key, value)
		if not settingsLimiter:Check(player) then
			return
		end
		local data = self.Profiles[player]
		if not data then
			return
		end
		if (key == "music" or key == "sfx" or key == "beeps") and type(value) == "boolean" then
			data.settings[key] = value
		elseif key == "lang" and (value == "en" or value == "lt") then
			data.settings.lang = value
			data.settings.langChosen = true
		elseif key == "systemLocale" and type(value) == "string" then
			-- Įrenginio (Windows / telefono) kalba: jei lietuviška ir žaidėjas pats kalbos dar nesirinko – LT
			if not data.settings.langChosen and string.sub(string.lower(value), 1, 2) == "lt" then
				data.settings.lang = "lt"
			else
				return
			end
		else
			return
		end
		self:SyncAttributes(player)
	end)

	-- Tutorial baigtas
	Remotes.TutorialDone.OnServerEvent:Connect(function(player)
		if not settingsLimiter:Check(player) then
			return
		end
		local data = self.Profiles[player]
		if data and not data.tutorialDone then
			data.tutorialDone = true
			player:SetAttribute("TutorialDone", true)
		end
	end)
end

-- Kviečiama iš Main, kai visi servisai paleisti
function DataService:BeginPlayers()
	Players.PlayerAdded:Connect(function(player)
		self:_onPlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:_onPlayerRemoving(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_onPlayerAdded(player)
		end)
	end
end

return DataService
