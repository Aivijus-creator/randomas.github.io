-- HUDController: lobby HUD (coins, levels, menu buttons), shift HUD (clock, baby cards, held item,
-- building health, event banners), toasts, quests + daily gift windows, player name tags.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local Babies = require(Shared.Config.Babies)
local Needs = require(Shared.Config.Needs)
local Tools = require(Shared.Config.Tools)
local Recipes = require(Shared.Config.Recipes)
local Events = require(Shared.Config.Events)
local Quests = require(Shared.Config.Quests)
local Progression = require(Shared.Config.Progression)
local P = require(Shared.Logic.ProgressionMath)
local MathUtil = require(Shared.Util.Math)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local HUDController = {}
local Controllers

local gui: ScreenGui
local lobby: Frame
local shift: Frame
local coinsLabel: TextLabel
local levelLabel: TextLabel
local levelBar: (number, Color3?) -> ()
local nannyLabel: TextLabel
local clockLabel: TextLabel
local timeBar: (number, Color3?) -> ()
local buildingBar: (number, Color3?) -> ()
local babyList: Frame
local heldIcon: TextLabel
local heldName: TextLabel
local toastHolder: Frame
local bannerFrame: Frame
local bannerText: TextLabel
local cards: { [string]: any } = {}
local questWindow, dailyWindow
local shownCoins = 0

local function emojiFor(held): string
	if not held then
		return "✋"
	end
	if held.Kind == "Tool" then
		return Tools.Defs[held.Id] and Tools.Defs[held.Id].Emoji or "🔧"
	elseif held.Kind == "Ingredient" then
		return Recipes.Ingredients[held.Id] and Recipes.Ingredients[held.Id].Emoji or "?"
	elseif held.Kind == "Dish" then
		return Recipes.Dishes[held.Id] and Recipes.Dishes[held.Id].Emoji or "?"
	elseif held.Kind == "Baby" then
		return Babies.Defs[held.Id] and Babies.Defs[held.Id].Emoji or "👶"
	elseif held.Kind == "Trash" then
		return "🗑️"
	elseif held.Kind == "Egg" then
		return "🥚"
	end
	return "?"
end

-- Toasts ------------------------------------------------------------------------------------------

local TOAST_COLORS = { info = C.Cream, good = C.Mint, bad = C.Pink, error = C.Pink, coins = C.Yellow, level = C.Lavender, unlock = C.Peach }

function HUDController:Toast(msg: any, kind: string?)
	local text = Strings.msg(msg)
	local f = UI.panel({ Size = UDim2.fromOffset(380, 48), BackgroundTransparency = 0.05, Parent = toastHolder }, TOAST_COLORS[kind or "info"] or C.Cream)
	UI.label(text, { Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), TextWrapped = true, Parent = f })
	local scale = UI.new("UIScale", { Scale = 0.3, Parent = f })
	TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if kind == "error" and Controllers.SoundController then
		Controllers.SoundController:Play("UI_Error")
	elseif Controllers.SoundController then
		Controllers.SoundController:Play("UI_Notify")
	end
	task.delay(3.5, function()
		TweenService:Create(scale, TweenInfo.new(0.25), { Scale = 0 }):Play()
		task.wait(0.3)
		f:Destroy()
	end)
end

-- Banner ------------------------------------------------------------------------------------------

function HUDController:Banner(id: string, phase: string, extra: any)
	local text
	if id == "ParentsComing" then
		text = Strings.t("Banner_ParentsComing")
	else
		local def = Events.Defs[id]
		local emoji = def and def.Emoji or "⭐"
		if phase == "start" then
			text = emoji .. " " .. Strings.t("Event_" .. id) .. " — " .. Strings.msg({ "EventDesc_" .. id, extra and extra.Baby or "" })
		elseif phase == "success" then
			text = emoji .. " " .. Strings.t("Event_Success", (extra and extra.Coins) or 0)
		else
			text = emoji .. " " .. Strings.t("Event_Fail")
		end
	end
	bannerText.Text = text
	bannerFrame.Visible = true
	bannerFrame.Position = UDim2.new(0.5, 0, 0, -120)
	TweenService:Create(bannerFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Position = UDim2.new(0.5, 0, 0, 90) }):Play()
	local token = os.clock()
	bannerFrame:SetAttribute("Token", token)
	task.delay(if phase == "start" then 5 else 3, function()
		if bannerFrame:GetAttribute("Token") == token then
			TweenService:Create(bannerFrame, TweenInfo.new(0.3), { Position = UDim2.new(0.5, 0, 0, -120) }):Play()
		end
	end)
end

-- Lobby HUD ----------------------------------------------------------------------------------------

local function buildLobby()
	lobby = UI.new("Frame", { Name = "Lobby", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })
	local top = UI.panel({ Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(330, 116), Parent = lobby })
	coinsLabel = UI.label("🪙 0", { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 34), TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
	levelLabel = UI.label("🏠 1", { Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
	local bar
	bar, levelBar = UI.bar({ Position = UDim2.fromOffset(12, 70), Size = UDim2.new(1, -24, 0, 12), Parent = top }, C.Yellow)
	local _ = bar
	nannyLabel = UI.label("🍼 1", { Position = UDim2.fromOffset(12, 86), Size = UDim2.new(1, -24, 0, 24), TextXAlignment = Enum.TextXAlignment.Left, Parent = top })
	local menu = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.55, 0), Size = UDim2.fromOffset(150, 330), Parent = lobby })
	UI.list(menu, 8)
	local function menuBtn(order: number, key: string, color: Color3, fn: () -> ())
		local b = UI.button("", color, fn, { Size = UDim2.fromOffset(150, 48), LayoutOrder = order, Parent = menu })
		UI.bind(b, key)
	end
	menuBtn(1, "Menu_Shop", C.Mint, function()
		Controllers.ShopController:Open()
	end)
	menuBtn(2, "Menu_Wardrobe", C.Lavender, function()
		Controllers.WardrobeController:Open()
	end)
	menuBtn(3, "Menu_Pets", C.Peach, function()
		Controllers.PetController:Open()
	end)
	menuBtn(4, "Menu_Quests", C.Yellow, function()
		questWindow.Open()
	end)
	menuBtn(5, "Menu_Daily", C.Pink, function()
		dailyWindow.Open()
	end)
	menuBtn(6, "Menu_Settings", C.Cream, function()
		Controllers.SettingsController:Open()
	end)
	-- tutorial offer for new players
	local offer = UI.panel({ Name = "TutorialOffer", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(460, 110), Visible = false, Parent = lobby }, C.Yellow)
	local ot = UI.label("", { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 40), TextWrapped = true, Parent = offer })
	UI.bind(ot, "Tutorial_Offer")
	local yes = UI.button("", C.Mint, function()
		offer.Visible = false
		Remotes.event("TutorialAction"):FireServer("Replay")
	end, { Position = UDim2.fromOffset(40, 56), Size = UDim2.fromOffset(170, 44), Parent = offer })
	UI.bind(yes, "Tutorial_Start")
	local no = UI.button("", C.Pink, function()
		offer.Visible = false
		Remotes.event("TutorialAction"):FireServer("Skip")
	end, { Position = UDim2.new(1, -210, 0, 56), Size = UDim2.fromOffset(170, 44), Parent = offer })
	UI.bind(no, "Tutorial_Skip")
end

-- Shift HUD -----------------------------------------------------------------------------------------

local function buildShift()
	shift = UI.new("Frame", { Name = "Shift", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = gui })
	local top = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(300, 74), Parent = shift })
	clockLabel = UI.label("07:00", { Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 40), Parent = top })
	local tb
	tb, timeBar = UI.bar({ Position = UDim2.fromOffset(14, 50), Size = UDim2.new(1, -28, 0, 12), Parent = top }, C.Mint)
	local _ = tb
	local bpanel = UI.panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16), Size = UDim2.fromOffset(230, 56), Parent = shift })
	local bl = UI.label("", { Position = UDim2.fromOffset(10, 2), Size = UDim2.new(1, -20, 0, 24), Parent = bpanel })
	UI.bind(bl, "HUD_Building")
	local bb
	bb, buildingBar = UI.bar({ Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 12), Parent = bpanel }, C.Green)
	local _2 = bb
	babyList = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 100), Size = UDim2.fromOffset(250, 600), Parent = shift })
	UI.list(babyList, 6)
	local held = UI.panel({ AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(200, 92), Parent = shift })
	heldIcon = UI.label("✋", { Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(60, 60), Parent = held })
	heldName = UI.label("", { Position = UDim2.fromOffset(72, 10), Size = UDim2.new(1, -80, 0, 50), TextWrapped = true, Parent = held })
	local hint = UI.label("", { Position = UDim2.fromOffset(8, 66), Size = UDim2.new(1, -16, 0, 20), Font = Enum.Font.GothamBold, TextTransparency = 0.3, Parent = held })
	UI.bind(hint, "HUD_HeldHint")
end

local function cardFor(uid: string, babyId: string)
	local def = Babies.Defs[babyId]
	local f = UI.panel({ Size = UDim2.fromOffset(240, 60), Parent = babyList }, C.Cream)
	local btn = UI.new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = f })
	btn.Activated:Connect(function()
		Controllers.BubbleController:Locate(uid)
	end)
	UI.label(def and def.Emoji or "?", { Position = UDim2.fromOffset(6, 6), Size = UDim2.fromOffset(46, 46), Parent = f })
	local name = UI.label(Strings.name(def and def.Name), { Position = UDim2.fromOffset(56, 2), Size = UDim2.new(1, -62, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
	local bars = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(56, 26), Size = UDim2.new(1, -62, 0, 30), Parent = f })
	UI.list(bars, 2, true)
	local setters = {}
	local needIds = {}
	for _, n in Needs.Order do
		if def and def.Needs[n] then
			table.insert(needIds, n)
		end
	end
	for _, n in needIds do
		local col = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1 / #needIds, -2, 1, 0), Parent = bars })
		UI.new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), TextScaled = true, Text = Needs.Defs[n].Emoji, Parent = col })
		local _, set = UI.bar({ Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 8), Parent = col }, Needs.Defs[n].Color)
		setters[n] = set
	end
	return { Frame = f, Setters = setters, Name = name, Def = def }
end

local function findBaby(uid: string): Model?
	for _, m in CollectionService:GetTagged("Baby") do
		if m:GetAttribute("Uid") == uid then
			return m
		end
	end
	return nil
end

local function updateCards(t: number)
	for uid, card in cards do
		local m = findBaby(uid)
		if m then
			for n, set in card.Setters do
				local v = (m:GetAttribute("N_" .. n) or 100) / 100
				set(v, if v < 0.15 then C.Red elseif v < 0.35 then C.Yellow else Needs.Defs[n].Color)
			end
			local tantrum = (m:GetAttribute("Tantrum") or "") ~= ""
			if tantrum then
				card.Frame.BackgroundColor3 = if math.sin(t * 10) > 0 then C.Pink else C.Red
			elseif m:GetAttribute("Escaped") then
				card.Frame.BackgroundColor3 = C.Peach
			else
				card.Frame.BackgroundColor3 = C.Cream
			end
		end
	end
end

local function syncCards(shiftState)
	local want = {}
	for i, b in shiftState.Babies or {} do
		want[b.Uid] = true
		if not cards[b.Uid] then
			cards[b.Uid] = cardFor(b.Uid, b.Id)
		end
		cards[b.Uid].Frame.LayoutOrder = i
	end
	for uid, card in cards do
		if not want[uid] then
			card.Frame:Destroy()
			cards[uid] = nil
		end
	end
end

-- Lobby data ------------------------------------------------------------------------------------------

local function onData(d)
	if not d then
		return
	end
	local target = d.Coins
	local from = shownCoins
	shownCoins = target
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 0.6 do
			local k = (os.clock() - t0) / 0.6
			coinsLabel.Text = "🪙 " .. MathUtil.formatNumber(from + (target - from) * k)
			task.wait()
		end
		coinsLabel.Text = "🪙 " .. MathUtil.formatNumber(target)
	end)
	local lvl = P.daycareLevel(d.TotalStars)
	local cur, span = P.daycareProgress(d.TotalStars)
	levelLabel.Text = Strings.t("HUD_DaycareLevel", lvl, d.TotalStars)
	levelBar(if span then cur / span else 1)
	nannyLabel.Text = Strings.t("HUD_NannyLevel", d.NannyLevel, Strings.t(P.titleKey(d.NannyLevel)))
	-- "Golden daycare" (daycare level 15): the lobby sign shines gold for you
	for _, sign in CollectionService:GetTagged("LobbySign") do
		local label = sign:FindFirstChild("SignText", true)
		if label and label:IsA("TextLabel") then
			label.TextColor3 = if lvl >= 15 then C.Gold else Color3.fromRGB(255, 220, 140)
			label.Text = if lvl >= 15 then "✨ MONSTERGARTEN ✨" else "MONSTERGARTEN"
		end
	end
	local offer = lobby:FindFirstChild("TutorialOffer")
	if offer then
		offer.Visible = not d.TutorialDone and not State.inShift()
	end
	if questWindow and questWindow.IsOpen() then
		HUDController:RefreshQuests()
	end
	if dailyWindow and dailyWindow.IsOpen() then
		HUDController:RefreshDaily()
	end
end

-- Quests + daily --------------------------------------------------------------------------------------------

local questList: Frame
function HUDController:RefreshQuests()
	for _, c in questList:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local d = State.Data
	if not d then
		return
	end
	for i, q in d.DailyQuests.Quests do
		local def
		for _, qd in Quests.Pool do
			if qd.Id == q.Id then
				def = qd
			end
		end
		if def then
			local f = UI.panel({ Size = UDim2.new(1, -8, 0, 76), LayoutOrder = i, Parent = questList }, if q.Done then C.Mint else C.Cream)
			UI.label(Strings.t("Quest_" .. q.Id, def.Goal), { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -120, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
			UI.label("🪙 " .. def.Reward, { Position = UDim2.new(1, -110, 0, 6), Size = UDim2.fromOffset(100, 30), Parent = f })
			local _, set = UI.bar({ Position = UDim2.fromOffset(12, 44), Size = UDim2.new(1, -110, 0, 14), Parent = f }, C.Lavender)
			set(q.Progress / def.Goal)
			UI.label(if q.Done then "✅" else (q.Progress .. "/" .. def.Goal), { Position = UDim2.new(1, -96, 0, 38), Size = UDim2.fromOffset(86, 26), Parent = f })
		end
	end
end

local dailyRow: Frame
local claimBtn: TextButton
function HUDController:RefreshDaily()
	for _, c in dailyRow:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local d = State.Data
	if not d then
		return
	end
	local today = math.floor(os.time() / 86400)
	local claimable, nextStreak = P.dailyReward(d.DailyReward.LastClaim, d.DailyReward.Streak, today)
	local current = if claimable then nextStreak else d.DailyReward.Streak
	for i, coins in Progression.DailyRewards do
		local idx = ((current - 1) % 7) + 1
		local col = if i < idx or (i == idx and not claimable) then C.Mint elseif i == idx then C.Yellow else C.Cream
		local f = UI.panel({ Size = UDim2.fromOffset(78, 100), LayoutOrder = i, Parent = dailyRow }, col)
		UI.label(Strings.t("Daily_Day", i), { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 24), Parent = f })
		UI.label("🎁", { Position = UDim2.fromOffset(4, 28), Size = UDim2.new(1, -8, 0, 36), Parent = f })
		UI.label("🪙" .. coins, { Position = UDim2.fromOffset(4, 68), Size = UDim2.new(1, -8, 0, 26), Parent = f })
	end
	claimBtn.Visible = claimable
end

function HUDController:OpenDaily()
	dailyWindow.Open()
end

-- Name tags -------------------------------------------------------------------------------------------------

local function nameTag(p: Player)
	local function attach(char: Model)
		local head = char:WaitForChild("Head", 10)
		if not head then
			return
		end
		local bb = Instance.new("BillboardGui")
		bb.Name = "MGNameTag"
		bb.Size = UDim2.fromOffset(220, 50)
		bb.StudsOffset = Vector3.new(0, 2.4, 0)
		bb.MaxDistance = 60
		bb.LightInfluence = 0
		bb.Adornee = head
		bb.Parent = player:WaitForChild("PlayerGui")
		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, 0, 0.45, 0)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextScaled = true
		title.TextColor3 = C.Lavender
		title.TextStrokeTransparency = 0.5
		title.Parent = bb
		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromScale(0, 0.45)
		name.Size = UDim2.new(1, 0, 0.55, 0)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.FredokaOne
		name.TextScaled = true
		name.TextStrokeTransparency = 0.4
		name.Text = p.DisplayName
		name.Parent = bb
		local function refresh()
			local key = p:GetAttribute("TitleKey")
			title.Text = (if key then Strings.t(key) else "") .. "  🍼" .. tostring(p:GetAttribute("NannyLevel") or 1)
			name.TextColor3 = if p:GetAttribute("VIP") then C.Gold else C.White
			name.Text = (if p:GetAttribute("VIP") then "👑 " else "") .. p.DisplayName
		end
		p:GetAttributeChangedSignal("TitleKey"):Connect(refresh)
		p:GetAttributeChangedSignal("NannyLevel"):Connect(refresh)
		p:GetAttributeChangedSignal("VIP"):Connect(refresh)
		State.LanguageChanged:Connect(refresh)
		refresh()
		char.AncestryChanged:Connect(function(_, parent)
			if not parent then
				bb:Destroy()
			end
		end)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
	end
	p.CharacterAdded:Connect(attach)
	if p.Character then
		task.spawn(attach, p.Character)
	end
end

-- Lifecycle ----------------------------------------------------------------------------------------------------

function HUDController:Init(c)
	Controllers = c
	gui = UI.screen("HUD", 2)
	buildLobby()
	buildShift()
	toastHolder = UI.new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 170), Size = UDim2.fromOffset(380, 300), Parent = gui })
	UI.list(toastHolder, 6, false, Enum.HorizontalAlignment.Center)
	bannerFrame = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -120), Size = UDim2.fromOffset(620, 70), Visible = false, Parent = gui }, C.Lavender)
	bannerText = UI.label("", { Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 1, -16), TextWrapped = true, Parent = bannerFrame })
	-- windows
	local wgui = UI.screen("HUDWindows", 15)
	questWindow = UI.window(wgui, "Quests_Title", UDim2.fromOffset(560, 380))
	questList = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = questWindow.Content })
	UI.list(questList, 8)
	questWindow.OnOpen = function()
		HUDController:RefreshQuests()
	end
	dailyWindow = UI.window(wgui, "Daily_Title", UDim2.fromOffset(640, 300), C.Peach)
	dailyRow = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 110), Parent = dailyWindow.Content })
	UI.list(dailyRow, 6, true, Enum.HorizontalAlignment.Center)
	claimBtn = UI.button("", C.Mint, function()
		Remotes.event("ClaimDaily"):FireServer()
		task.delay(0.6, function()
			HUDController:RefreshDaily()
		end)
	end, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 124), Size = UDim2.fromOffset(200, 50), Parent = dailyWindow.Content })
	UI.bind(claimBtn, "Daily_Claim")
	dailyWindow.OnOpen = function()
		HUDController:RefreshDaily()
	end
end

function HUDController:Start()
	Remotes.event("Notify").OnClientEvent:Connect(function(msg, kind)
		self:Toast(msg, kind)
	end)
	Remotes.event("Banner").OnClientEvent:Connect(function(id, phase, extra)
		self:Banner(id, phase, extra)
	end)
	State.DataChanged:Connect(onData)
	State.LanguageChanged:Connect(function()
		if State.Data then
			onData(State.Data)
		end
		for _, card in cards do
			card.Name.Text = Strings.name(card.Def and card.Def.Name)
		end
	end)
	State.ShiftChanged:Connect(function(s)
		lobby.Visible = s == nil
		shift.Visible = s ~= nil
		if s then
			UI.closeAll()
			syncCards(s)
			clockLabel.Text = "🕖 " .. MathUtil.formatClock(s.Clock or 7)
			timeBar(1 - math.clamp((s.Time or 0) / (s.Duration or 480), 0, 1), if (s.Duration - s.Time) < 30 then C.Red else C.Mint)
			buildingBar((s.Building or 100) / 100, if (s.Building or 100) < 50 then C.Red else C.Green)
		else
			syncCards({ Babies = {} })
			if State.Data then
				onData(State.Data)
			end
		end
	end)
	State.HeldChanged:Connect(function(held)
		heldIcon.Text = emojiFor(held)
		if not held then
			heldName.Text = ""
		else
			heldName.Text = Strings.msg({ "Name_Generic", held.Id })
			if held.Kind == "Trash" or (held.Kind == "Tool" and held.Id == "TrashBag") then
				heldName.Text ..= " ×" .. tostring(player:GetAttribute("TrashCount") or 0)
			end
		end
	end)
	player:GetAttributeChangedSignal("TrashCount"):Connect(function()
		State.HeldChanged:Fire(State.Held)
	end)
	local t0 = os.clock()
	RunService.Heartbeat:Connect(function()
		if shift.Visible then
			updateCards(os.clock() - t0)
			local s = State.Shift
			if s then
				clockLabel.Text = "🕖 " .. MathUtil.formatClock(s.Clock or 7)
			end
		end
	end)
	for _, p in Players:GetPlayers() do
		nameTag(p)
	end
	Players.PlayerAdded:Connect(nameTag)
end

return HUDController
