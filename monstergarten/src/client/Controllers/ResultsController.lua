-- ResultsController: animated end-of-shift screen (stars drop in, numbers count up, baby cards, MVP).
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local Babies = require(Shared.Config.Babies)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local C = UI.Theme.Colors
local ResultsController = { Showing = false }
local Controllers
local gui: ScreenGui
local panel: Frame

local function countUp(label: TextLabel, prefix: string, target: number, time: number)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < time do
			label.Text = prefix .. tostring(math.floor(target * (os.clock() - t0) / time))
			task.wait()
		end
		label.Text = prefix .. tostring(target)
	end)
end

local function confetti(parent: Instance)
	for i = 1, 40 do
		local f = UI.new("Frame", {
			Size = UDim2.fromOffset(10, 16),
			Position = UDim2.new(math.random(), 0, -0.05, 0),
			BackgroundColor3 = Color3.fromHSV(math.random(), 0.5, 1),
			Rotation = math.random(0, 360),
			BorderSizePixel = 0,
			ZIndex = 20,
			Parent = parent,
		})
		TweenService:Create(f, TweenInfo.new(1.6 + math.random() * 1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(f.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.1, 0),
			Rotation = f.Rotation + math.random(-360, 360),
		}):Play()
		task.delay(3.2, function()
			f:Destroy()
		end)
		if i % 10 == 0 then
			task.wait(0.05)
		end
	end
end

function ResultsController:Show(r)
	self.Showing = true
	if Controllers.SoundController then
		Controllers.SoundController:Music("Results")
	end
	for _, c in panel:GetChildren() do
		if not c:IsA("UICorner") and not c:IsA("UIStroke") and not c:IsA("UIScale") then
			c:Destroy()
		end
	end
	panel.Visible = true
	local title = UI.label("", { Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -32, 0, 44), Parent = panel })
	UI.bind(title, if r.Tutorial then "Results_TutorialDone" else "Results_Title")
	-- stars
	local starRow = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 60), Size = UDim2.new(1, 0, 0, 90), Parent = panel })
	UI.list(starRow, 14, true, Enum.HorizontalAlignment.Center)
	for i = 1, 3 do
		local s = UI.label("⭐", { Size = UDim2.fromOffset(84, 84), TextTransparency = 0.85, LayoutOrder = i, Parent = starRow })
		if i <= (r.Stars or 0) then
			task.delay(0.5 + i * 0.5, function()
				local scale = UI.new("UIScale", { Scale = 3, Parent = s })
				s.TextTransparency = 0
				TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Bounce), { Scale = 1 }):Play()
				if Controllers.SoundController then
					Controllers.SoundController:Play("UI_Star")
				end
			end)
		end
	end
	-- numbers
	local personal = r.Personal or {}
	local stats = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 156), Size = UDim2.new(1, -40, 0, 70), Parent = panel })
	UI.list(stats, 10, true, Enum.HorizontalAlignment.Center)
	local function stat(order, prefix, value)
		local box = UI.panel({ Size = UDim2.fromOffset(150, 64), LayoutOrder = order, Parent = stats }, C.Peach)
		local l = UI.label(prefix .. "0", { Position = UDim2.fromOffset(6, 10), Size = UDim2.new(1, -12, 0, 44), Parent = box })
		countUp(l, prefix, value, 1.4)
	end
	stat(1, "📊 ", r.FinalScore or 0)
	stat(2, "🪙 ", personal.Coins or 0)
	stat(3, "✨ ", personal.XP or 0)
	stat(4, "🏠 ", r.BuildingScore or 0)
	-- MVP
	if r.MVPName then
		local mvp = UI.label("", { Position = UDim2.fromOffset(16, 232), Size = UDim2.new(1, -32, 0, 30), TextColor3 = C.Pumpkin, Parent = panel })
		mvp.Text = "👑 " .. Strings.t("Results_MVP", r.MVPName) .. (if personal.MVP then " (+20%)" else "")
	end
	-- baby cards
	local scroll = UI.scroll(panel, { Position = UDim2.fromOffset(16, 268), Size = UDim2.new(1, -32, 0, 120), AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollingDirection = Enum.ScrollingDirection.X })
	UI.list(scroll, 8, true)
	for i, b in r.Babies or {} do
		local def = Babies.Defs[b.BabyId]
		local card = UI.panel({ Size = UDim2.fromOffset(96, 110), LayoutOrder = i, Parent = scroll }, if b.Score >= 85 then C.Mint elseif b.Score >= 50 then C.Yellow else C.Pink)
		UI.label((def and def.Emoji or "?") .. (b.Face or ""), { Position = UDim2.fromOffset(4, 6), Size = UDim2.new(1, -8, 0, 40), Parent = card })
		UI.label(Strings.name(def and def.Name), { Position = UDim2.fromOffset(4, 48), Size = UDim2.new(1, -8, 0, 22), Parent = card })
		UI.label(tostring(b.Score), { Position = UDim2.fromOffset(4, 72), Size = UDim2.new(1, -8, 0, 30), Parent = card })
	end
	-- buttons
	if not r.Tutorial then
		local again = UI.button("", C.Mint, function()
			Remotes.event("ResultsChoice"):FireServer("Again")
			self:Hide()
		end, { Position = UDim2.new(0.5, -220, 1, -66), Size = UDim2.fromOffset(200, 50), Parent = panel })
		UI.bind(again, "Results_Again")
	end
	local lobbyBtn = UI.button("", C.Lavender, function()
		Remotes.event("ResultsChoice"):FireServer("Lobby")
		self:Hide()
	end, { Position = UDim2.new(0.5, if r.Tutorial then -100 else 20, 1, -66), Size = UDim2.fromOffset(200, 50), Parent = panel })
	UI.bind(lobbyBtn, "Results_Lobby")
	-- Win / lose mood: big animated banner, confetti or rain
	local stars = r.Stars or 0
	local win = stars >= 2 or r.Tutorial
	local banner = UI.label("", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0, -10),
		Size = UDim2.fromOffset(520, 64),
		TextColor3 = if win then C.Yellow else Color3.fromRGB(180, 200, 255),
		TextStrokeTransparency = 0.1,
		Parent = panel,
	})
	UI.bind(banner, if win then (if stars == 3 then "Results_Perfect" else "Results_Win") else "Results_Lose")
	local bscale = UI.new("UIScale", { Scale = 0, Parent = banner })
	TweenService:Create(bscale, TweenInfo.new(0.7, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if win then
		task.spawn(function()
			while panel.Visible and banner.Parent do
				TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Rotation = 4 }):Play()
				task.wait(0.5)
				TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { Rotation = -4 }):Play()
				task.wait(0.5)
			end
		end)
		task.delay(1.6, function()
			confetti(gui)
		end)
		if stars == 3 then
			task.delay(2.6, function()
				confetti(gui)
			end)
		end
	else
		-- grey mood + rain drops
		local tint = UI.new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 50, 80), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = gui })
		TweenService:Create(tint, TweenInfo.new(1), { BackgroundTransparency = 0.6 }):Play()
		task.delay(6, function()
			tint:Destroy()
		end)
		for i = 1, 40 do
			local drop = UI.new("Frame", { Size = UDim2.fromOffset(3, 18), Position = UDim2.new(math.random(), 0, -0.1, 0), BackgroundColor3 = Color3.fromRGB(150, 180, 255), BorderSizePixel = 0, ZIndex = 20, Parent = gui })
			TweenService:Create(drop, TweenInfo.new(0.9 + math.random() * 0.6, Enum.EasingStyle.Linear), { Position = UDim2.new(drop.Position.X.Scale, 0, 1.1, 0) }):Play()
			task.delay(1.6, function()
				drop:Destroy()
			end)
			if i % 8 == 0 then
				task.wait(0.15)
			end
		end
	end
end

function ResultsController:Hide()
	self.Showing = false
	panel.Visible = false
end

function ResultsController:Init(c)
	Controllers = c
	gui = UI.screen("ResultsGui", 25)
	panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(700, 480), Visible = false, Parent = gui }, C.Cream)
end

function ResultsController:Start()
	Remotes.event("Results").OnClientEvent:Connect(function(r)
		self:Show(r or {})
	end)
	State.ShiftChanged:Connect(function(s)
		if not s and self.Showing then
			self:Hide()
		end
	end)
end

return ResultsController
