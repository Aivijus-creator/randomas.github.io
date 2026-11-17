--[[
	LeaderboardService – dvi lyderių lentos lobby (OrderedDataStore, top 10):
	  daugiausia uždirbta per visą laiką (totalEarned) ir daugiausia rebirth.
	Atnaujinama kas Settings.Leaderboard.RefreshInterval s.
	Pirmosios vietos savininkas (jei yra serveryje) gauna titulą virš vardo ir pokalbyje:
	  „👑 #1 Turtingiausias“ (daugiausia uždirbta) ir „🔁 #1 Rebirth karalius“.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Build = require(script.Parent.Parent:WaitForChild("Lib"):WaitForChild("Build"))

local LB = Settings.Leaderboard
local C = Color3.fromRGB

local LeaderboardService = {}
local S
local boards = {}
local nameCache = {}
local warned = false

local function getName(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		nameCache[userId] = player.DisplayName
		return player.DisplayName
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if ok and name then
		nameCache[userId] = name
		return name
	end
	return "#" .. tostring(userId)
end

local function createBoard(part, titleKey)
	if not part then
		return nil
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BoardGui"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = C(232, 211, 162)
	frame.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = C(92, 58, 30)
	stroke.Thickness = 10
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(0.9, 0.14)
	title.Position = UDim2.fromScale(0.05, 0.02)
	title.Font = Enum.Font.Fondamento
	title.TextScaled = true
	title.TextColor3 = C(110, 30, 25)
	title.Parent = frame
	Build.Localize(title, titleKey)

	local rows = {}
	for i = 1, LB.Top do
		local row = Instance.new("TextLabel")
		row.Name = "Row" .. i
		row.BackgroundTransparency = 1
		row.Size = UDim2.fromScale(0.9, 0.075)
		row.Position = UDim2.fromScale(0.05, 0.17 + (i - 1) * 0.08)
		row.Font = Enum.Font.Merriweather
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = C(60, 35, 15)
		row.Text = ""
		row.Parent = frame
		rows[i] = row
	end
	local empty = rows[1]
	Build.Localize(empty, "LB_Empty")
	return { Rows = rows }
end

local function render(board, entries, formatter)
	if not board then
		return
	end
	for i, row in ipairs(board.Rows) do
		local entry = entries[i]
		if entry then
			row:SetAttribute("TextKey", nil)
			row.Text = string.format("%d. %s – %s", i, getName(tonumber(entry.key)), formatter(entry.value))
		elseif i == 1 then
			row:SetAttribute("TextKey", "LB_Empty")
		else
			row.Text = ""
		end
	end
end

local function refresh(store, field, board, formatter)
	for _, player in ipairs(Players:GetPlayers()) do
		local data = S.DataService:Get(player)
		if data then
			pcall(function()
				store:SetAsync(tostring(player.UserId), math.floor(data[field]))
			end)
		end
	end
	local ok, result = pcall(function()
		return store:GetSortedAsync(false, LB.Top):GetCurrentPage()
	end)
	if ok then
		render(board, result, formatter)
		local first = result[1]
		if first and (tonumber(first.value) or 0) > 0 then
			return tonumber(first.key)
		end
		return 0
	elseif not warned then
		warned = true
		warn("[Leaderboard] OrderedDataStore nepasiekiamas: " .. tostring(result))
	end
	return nil
end

----------------------------------------------------------------------
-- #1 titulai virš vardo
----------------------------------------------------------------------
local topMoneyId, topRebirthId = 0, 0

local function applyTopTag(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("TopTitleGui")
	if old then
		old:Destroy()
	end
	local money = player.UserId == topMoneyId
	local rebirth = player.UserId == topRebirthId
	player:SetAttribute("TopMoney", money)
	player:SetAttribute("TopRebirth", rebirth)
	if not money and not rebirth then
		return
	end
	local key = (money and rebirth) and "TopTitle_Both" or (money and "TopTitle_Money" or "TopTitle_Rebirth")
	Build.Billboard(head, { Name = "TopTitleGui", TextKey = key, Size = UDim2.fromScale(10, 1.3), Offset = Vector3.new(0, 3.6, 0), MaxDistance = 150, Color = C(255, 200, 40) })
end

function LeaderboardService:SetTop(moneyId, rebirthId)
	if moneyId then
		topMoneyId = moneyId
	end
	if rebirthId then
		topRebirthId = rebirthId
	end
	ReplicatedStorage:SetAttribute("TopMoneyUserId", topMoneyId)
	ReplicatedStorage:SetAttribute("TopRebirthUserId", topRebirthId)
	for _, player in ipairs(Players:GetPlayers()) do
		applyTopTag(player)
	end
end

function LeaderboardService:Init(services)
	S = services
end

function LeaderboardService:Start()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.delay(1.2, function()
				applyTopTag(player)
			end)
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		player.CharacterAdded:Connect(function()
			task.delay(1.2, function()
				applyTopTag(player)
			end)
		end)
	end
	boards.Total = createBoard(S.MapBuilder.Anchors.LeaderboardTotal, "LB_Total")
	boards.Rebirths = createBoard(S.MapBuilder.Anchors.LeaderboardRebirths, "LB_Rebirths")

	task.spawn(function()
		local ok, totalStore, rebirthStore = pcall(function()
			return DataStoreService:GetOrderedDataStore(LB.TotalStore), DataStoreService:GetOrderedDataStore(LB.RebirthStore)
		end)
		if not ok then
			warn("[Leaderboard] Nepavyko gauti OrderedDataStore: " .. tostring(totalStore))
			return
		end
		task.wait(LB.FirstRefresh)
		while true do
			if S.DataService:IsOnline() then
				local moneyId = refresh(totalStore, "totalEarned", boards.Total, function(v)
					return NumberFormat.Money(v)
				end)
				local rebirthId = refresh(rebirthStore, "rebirths", boards.Rebirths, function(v)
					return tostring(v)
				end)
				self:SetTop(moneyId, rebirthId)
			end
			task.wait(LB.RefreshInterval)
		end
	end)
end

return LeaderboardService
