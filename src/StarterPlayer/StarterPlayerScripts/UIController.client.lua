--[[
	UIController – visas žaidėjo UI (viduramžių LDK stilius: pergamentas, tamsus medis, auksas).
	  - Litų juosta viršuje (litai + pajamos/s), eventų juosta, boost'o laikmatis
	  - Kairysis meniu: Rebirth, Parduotuvė, Nustatymai, Teleportas, Prizas
	  - Langai su atidarymo / uždarymo animacija
	  - Pranešimai dešinėje apačioje, dideli skelbimai viršuje
	  - Tutorial (rodomas tik pirmą kartą)
	Spalvos ir šriftai – lentelėje STYLE (lengva pritaikyti pagal nuotrauką).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Config = ReplicatedStorage:WaitForChild("Config")
local Texts = require(Config:WaitForChild("Texts"))
local Settings = require(Config:WaitForChild("Settings"))
local Monetization = require(Config:WaitForChild("Monetization"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local C = Color3.fromRGB

local STYLE = {
	Parchment = C(236, 216, 168),
	ParchmentDark = C(205, 172, 115),
	Wood = C(96, 60, 32),
	WoodDark = C(58, 36, 18),
	WoodLight = C(140, 92, 52),
	Gold = C(214, 172, 58),
	Ink = C(55, 32, 14),
	Cream = C(255, 240, 205),
	Red = C(150, 35, 30),
	Green = C(60, 130, 50),
	-- Šriftai su lietuviškomis raidėmis (ą č ę ė į š ų ū ž): seni Fantasy / Garamond jų neturi
	TitleFont = Enum.Font.Fondamento,
	BodyFont = Enum.Font.Merriweather,
}

local function lang()
	return player:GetAttribute("Lang") or "en"
end

local function T(key, args)
	return Texts.Get(lang(), key, args)
end

----------------------------------------------------------------------
-- Tekstų susiejimas (atnaujinama pakeitus kalbą)
----------------------------------------------------------------------
local bindings = {}

local function bindText(label, key, argsFn)
	local entry = { Label = label, Key = key, Args = argsFn }
	table.insert(bindings, entry)
	label.Text = T(key, argsFn and argsFn() or nil)
	return entry
end

local function refreshTexts()
	for _, entry in ipairs(bindings) do
		if entry.Label.Parent then
			entry.Label.Text = T(entry.Key, entry.Args and entry.Args() or nil)
		end
	end
end

----------------------------------------------------------------------
-- Stiliaus pagalbinės
----------------------------------------------------------------------
local function new(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end

local function decorate(frame, strokeColor, thickness, radius)
	new("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, frame)
	new("UIStroke", { Color = strokeColor or STYLE.WoodDark, Thickness = thickness or 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
end

local function panel(parent, props)
	local frame = new("Frame", props, parent)
	frame.BackgroundColor3 = STYLE.Parchment
	decorate(frame, STYLE.WoodDark, 4, 10)
	new("UIGradient", {
		Color = ColorSequence.new(C(255, 255, 255), C(225, 200, 160)),
		Rotation = 90,
	}, frame)
	return frame
end

local function textLabel(parent, props)
	local label = new("TextLabel", {
		BackgroundTransparency = 1,
		TextScaled = true,
		Font = STYLE.BodyFont,
		TextColor3 = STYLE.Ink,
		Text = "",
	}, parent)
	for key, value in pairs(props or {}) do
		label[key] = value
	end
	return label
end

local function woodButton(parent, props)
	local button = new("TextButton", {
		BackgroundColor3 = STYLE.Wood,
		AutoButtonColor = false,
		TextScaled = true,
		Font = STYLE.TitleFont,
		TextColor3 = STYLE.Cream,
		Text = "",
	}, parent)
	for key, value in pairs(props or {}) do
		button[key] = value
	end
	decorate(button, STYLE.Gold, 3, 8)
	new("UIGradient", { Color = ColorSequence.new(C(255, 255, 255), C(170, 150, 130)), Rotation = 90 }, button)
	new("UITextSizeConstraint", { MaxTextSize = 34 }, button)
	local base = button.Size
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { Size = UDim2.new(base.X.Scale * 1.04, base.X.Offset * 1.04, base.Y.Scale * 1.04, base.Y.Offset * 1.04) }):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), { Size = base }):Play()
	end)
	return button
end

----------------------------------------------------------------------
-- Pagrindinis ScreenGui
----------------------------------------------------------------------
local screen = new("ScreenGui", { Name = "CepelinuUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, playerGui)
local uiScale = new("UIScale", {}, screen)

local function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local size = camera.ViewportSize
	uiScale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), 0.75, 1.3)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

----------------------------------------------------------------------
-- Pranešimai (dešinėje apačioje)
----------------------------------------------------------------------
local notifyArea = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -12, 1, -12), Size = UDim2.fromOffset(380, 340) }, screen)
new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }, notifyArea)
local notifyCount = 0

local KIND_COLORS = { success = STYLE.Green, error = STYLE.Red, info = STYLE.WoodDark }

local function notify(text, kind)
	notifyCount = notifyCount + 1
	local item = panel(notifyArea, { Size = UDim2.fromOffset(380, 50), LayoutOrder = notifyCount })
	local stroke = item:FindFirstChildOfClass("UIStroke")
	stroke.Color = KIND_COLORS[kind] or STYLE.WoodDark
	local label = textLabel(item, { Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5), Text = text, TextXAlignment = Enum.TextXAlignment.Right })
	new("UITextSizeConstraint", { MaxTextSize = 24 }, label)
	local children = {}
	for _, child in ipairs(notifyArea:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(children, child)
		end
	end
	table.sort(children, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #children > Settings.UI.MaxNotifications do
		table.remove(children, 1):Destroy()
	end
	task.delay(Settings.UI.NotificationTime, function()
		if item.Parent then
			TweenService:Create(item, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
			Debris:AddItem(item, 0.45)
		end
	end)
end

Remotes.Notify.OnClientEvent:Connect(function(key, args, keys, nums, kind)
	local merged = {}
	for name, value in pairs(args or {}) do
		merged[name] = value
	end
	for name, value in pairs(keys or {}) do
		merged[name] = T(value)
	end
	for name, value in pairs(nums or {}) do
		merged[name] = NumberFormat.Format(value)
	end
	if key == "__raw" then
		notify(tostring(merged.text), kind)
	else
		notify(T(key, merged), kind)
	end
end)

----------------------------------------------------------------------
-- Didelis skelbimas viršuje
----------------------------------------------------------------------
local banner = panel(screen, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -140), Size = UDim2.fromOffset(620, 110), Visible = false })
banner.BackgroundColor3 = STYLE.Parchment
local bannerTitle = textLabel(banner, { Font = STYLE.TitleFont, TextColor3 = STYLE.Red, Size = UDim2.new(1, -24, 0.58, 0), Position = UDim2.fromOffset(12, 6) })
local bannerText = textLabel(banner, { Size = UDim2.new(1, -24, 0.32, 0), Position = UDim2.new(0, 12, 0.62, 0) })
local bannerToken = 0

local function announce(title, text)
	bannerToken = bannerToken + 1
	local token = bannerToken
	bannerTitle.Text = title
	bannerText.Text = text or ""
	banner.Visible = true
	banner.Position = UDim2.new(0.5, 0, 0, -140)
	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 175) }):Play()
	task.delay(Settings.UI.AnnouncementTime, function()
		if token == bannerToken then
			local tween = TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -140) })
			tween:Play()
			tween.Completed:Connect(function()
				if token == bannerToken then
					banner.Visible = false
				end
			end)
		end
	end)
end

----------------------------------------------------------------------
-- Litų juosta, eventų juosta, boost'as
----------------------------------------------------------------------
local moneyBar = panel(screen, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(380, 78) })
local coin = new("Frame", { BackgroundColor3 = STYLE.Gold, Size = UDim2.fromOffset(54, 54), Position = UDim2.fromOffset(12, 12) }, moneyBar)
decorate(coin, STYLE.WoodDark, 3, 27)
textLabel(coin, { Size = UDim2.fromScale(1, 1), Text = "Lt", Font = STYLE.TitleFont, TextColor3 = STYLE.WoodDark })
local moneyLabel = textLabel(moneyBar, { Font = STYLE.TitleFont, Size = UDim2.new(1, -86, 0, 44), Position = UDim2.fromOffset(76, 4), TextXAlignment = Enum.TextXAlignment.Left, Text = "0 Lt" })
local incomeLabel = textLabel(moneyBar, { Size = UDim2.new(1, -86, 0, 26), Position = UDim2.fromOffset(76, 48), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = STYLE.Green, Text = "+0 Lt/s" })

local eventBar = panel(screen, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 94), Size = UDim2.fromOffset(380, 40), Visible = false })
eventBar.BackgroundColor3 = C(250, 210, 140)
local eventLabel = textLabel(eventBar, { Font = STYLE.TitleFont, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), TextColor3 = STYLE.Red })

local boostBar = panel(screen, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 140), Size = UDim2.fromOffset(260, 32), Visible = false })
local boostLabel = textLabel(boostBar, { Font = STYLE.TitleFont, Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3), TextColor3 = C(150, 60, 160) })
local buffBar = panel(screen, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 178), Size = UDim2.fromOffset(320, 32), Visible = false })
buffBar.BackgroundColor3 = C(210, 255, 225)
local buffLabel = textLabel(buffBar, { Font = STYLE.TitleFont, Size = UDim2.new(1, -16, 1, -6), Position = UDim2.fromOffset(8, 3), TextColor3 = C(30, 120, 70) })

task.spawn(function()
	while true do
		moneyLabel.Text = NumberFormat.Format(player:GetAttribute("Money") or 0) .. " Lt"
		incomeLabel.Text = T("PerSecond", { amount = NumberFormat.Format(player:GetAttribute("IncomePerSec") or 0) })
		local eventId = ReplicatedStorage:GetAttribute("CurrentEvent") or ""
		if eventId ~= "" then
			local remaining = (ReplicatedStorage:GetAttribute("EventEndsAt") or 0) - workspace:GetServerTimeNow()
			eventBar.Visible = true
			eventLabel.Text = T("EventTimeLeft", { event = T("Event_" .. eventId), time = NumberFormat.Time(remaining) })
		else
			eventBar.Visible = false
		end
		local boost = player:GetAttribute("BoostRemaining") or 0
		boostBar.Visible = boost > 0
		local buffId = ReplicatedStorage:GetAttribute("BuffId") or ""
		local buffLeft = (ReplicatedStorage:GetAttribute("BuffEndsAt") or 0) - workspace:GetServerTimeNow()
		buffBar.Visible = buffId ~= "" and buffLeft > 0
		if buffBar.Visible then
			buffLabel.Text = T("Buff_" .. buffId, { time = NumberFormat.Time(buffLeft) })
		end
		if boost > 0 then
			boostLabel.Text = T("BoostLeft", { time = NumberFormat.Time(boost) })
		end
		task.wait(0.2)
	end
end)

Remotes.EventStarted.OnClientEvent:Connect(function(eventId)
	announce(T("Event_" .. eventId), T("Event_" .. eventId .. "_Desc"))
end)

----------------------------------------------------------------------
-- Kalbos mygtukas LT / EN (viršuje, šalia litų juostos)
----------------------------------------------------------------------
local langButton = woodButton(screen, { Name = "LanguageButton", AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.5, 200, 0, 8), Size = UDim2.fromOffset(150, 78) })
langButton.Text = ""
local langLT = textLabel(langButton, { Font = STYLE.TitleFont, Text = "LT", Size = UDim2.new(0.42, 0, 0.62, 0), Position = UDim2.new(0.05, 0, 0.06, 0) })
textLabel(langButton, { Font = STYLE.TitleFont, Text = "|", TextColor3 = STYLE.Cream, Size = UDim2.new(0.1, 0, 0.62, 0), Position = UDim2.new(0.45, 0, 0.06, 0) })
local langEN = textLabel(langButton, { Font = STYLE.TitleFont, Text = "EN", Size = UDim2.new(0.42, 0, 0.62, 0), Position = UDim2.new(0.53, 0, 0.06, 0) })
local langCaption = textLabel(langButton, { Size = UDim2.new(0.9, 0, 0.28, 0), Position = UDim2.new(0.05, 0, 0.68, 0), TextColor3 = STYLE.Cream })
bindText(langCaption, "Language")
local function updateLangButton()
	local isLT = lang() == "lt"
	langLT.TextColor3 = isLT and STYLE.Gold or C(160, 140, 120)
	langEN.TextColor3 = isLT and C(160, 140, 120) or STYLE.Gold
end
updateLangButton()
player:GetAttributeChangedSignal("Lang"):Connect(updateLangButton)
langButton.Activated:Connect(function()
	Remotes.ChangeSetting:FireServer("lang", lang() == "lt" and "en" or "lt")
end)

----------------------------------------------------------------------
-- Langai
----------------------------------------------------------------------
local windows = {}
local openWindow = nil

local function createWindow(name, titleKey, width, height)
	local frame = panel(screen, { Name = name, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(width, height), Visible = false, ZIndex = 5 })
	local scale = new("UIScale", { Scale = 0 }, frame)
	-- Medinė antraštės juosta
	local header = new("Frame", { BackgroundColor3 = STYLE.Wood, Size = UDim2.new(1, 0, 0, 58) }, frame)
	decorate(header, STYLE.Gold, 3, 10)
	local title = textLabel(header, { Font = STYLE.TitleFont, TextColor3 = STYLE.Cream, Size = UDim2.new(1, -150, 1, -12), Position = UDim2.fromOffset(75, 6) })
	bindText(title, titleKey)
	local close = woodButton(header, { Text = "✕", Size = UDim2.fromOffset(60, 60), Position = UDim2.new(1, -64, 0, -1), BackgroundColor3 = STYLE.Red })
	local content = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 70), Size = UDim2.new(1, -36, 1, -84) }, frame)

	local window = { Frame = frame, Content = content, Scale = scale }
	function window.Open()
		if openWindow and openWindow ~= window then
			openWindow.Close()
		end
		openWindow = window
		frame.Visible = true
		scale.Scale = 0.6
		TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		if window.OnOpen then
			window.OnOpen()
		end
	end
	function window.Close()
		if openWindow == window then
			openWindow = nil
		end
		local tween = TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 })
		tween:Play()
		tween.Completed:Connect(function()
			if openWindow ~= window then
				frame.Visible = false
			end
		end)
	end
	function window.Toggle()
		if openWindow == window then
			window.Close()
		else
			window.Open()
		end
	end
	close.Activated:Connect(window.Close)
	windows[name] = window
	return window
end

local function row(parent, y, height)
	return new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, y), Size = UDim2.new(1, 0, 0, height) }, parent)
end

----------------------------------------------------------------------
-- Rebirth langas
----------------------------------------------------------------------
local rebirthWindow = createWindow("Rebirth", "RebirthTitle", 560, 470)
do
	local content = rebirthWindow.Content
	local countLabel = textLabel(content, { Font = STYLE.TitleFont, Size = UDim2.new(1, 0, 0, 36), TextColor3 = STYLE.Red })
	local costLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 42) })
	local multLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 78), TextColor3 = STYLE.Green })
	local loseLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 118), TextColor3 = STYLE.Red })
	local keepLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 166) })
	local rewardLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 32), Position = UDim2.fromOffset(0, 216), TextColor3 = C(120, 70, 20) })
	local reqLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 252), TextColor3 = STYLE.Red })
	local confirm = woodButton(content, { Size = UDim2.fromOffset(240, 66), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = STYLE.Green })
	bindText(confirm, "RebirthConfirm")
	bindText(loseLabel, "RebirthLose")
	bindText(keepLabel, "RebirthKeep")

	local info = nil
	local function fill()
		if not info then
			return
		end
		countLabel.Text = T(info.TitleKey) .. " · " .. T("RebirthCount", { count = info.Rebirths })
		costLabel.Text = T("RebirthCost", { cost = NumberFormat.Format(info.Cost) })
		local function mult(v)
			return (string.gsub(string.format("%.1f", v), "%.", ","))
		end
		multLabel.Text = T("RebirthMultiplier", { old = mult(info.CurrentMultiplier), new = mult(info.NewMultiplier) })
		if info.NextRewardAt then
			rewardLabel.Text = T("RebirthNextReward", { at = info.NextRewardAt, reward = T(info.NextRewardKey) })
		else
			rewardLabel.Text = ""
		end
		if not info.RequirementMet then
			reqLabel.Text = T("RebirthRequirement")
		elseif not info.CanRebirth then
			reqLabel.Text = T("RebirthNotEnough")
		else
			reqLabel.Text = ""
		end
		confirm.BackgroundColor3 = info.CanRebirth and STYLE.Green or C(110, 100, 90)
	end

	rebirthWindow.OnOpen = function()
		local ok, result = pcall(function()
			return Remotes.RequestRebirth:InvokeServer("info")
		end)
		if ok and result then
			info = result
			fill()
		end
	end
	confirm.Activated:Connect(function()
		if not info or not info.CanRebirth then
			return
		end
		local ok, result = pcall(function()
			return Remotes.RequestRebirth:InvokeServer("confirm")
		end)
		if ok and result then
			if result.Success then
				rebirthWindow.Close()
			else
				notify(T(result.Key or "RebirthNotEnough"), "error")
			end
			info = result.Info
			fill()
		end
	end)
	player:GetAttributeChangedSignal("Lang"):Connect(fill)
end

Remotes.RebirthDone.OnClientEvent:Connect(function(rebirths, multiplier, titleKey)
	local multText = string.gsub(string.format("%.1f", multiplier), "%.", ",")
	announce(T("RebirthDone", { mult = multText }), T("TitleChanged", { title = T(titleKey) }))
end)

----------------------------------------------------------------------
-- Parduotuvė
----------------------------------------------------------------------
local shopWindow = createWindow("Shop", "ShopTitle", 640, 520)
do
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8, ScrollBarImageColor3 = STYLE.Wood, BorderSizePixel = 0,
	}, shopWindow.Content)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	local order = 0
	local passButtons = {}

	local function header(key)
		order = order + 1
		local label = textLabel(scroll, { Font = STYLE.TitleFont, Size = UDim2.new(1, -12, 0, 34), TextColor3 = STYLE.Red, LayoutOrder = order, TextXAlignment = Enum.TextXAlignment.Left })
		bindText(label, key)
	end

	local function card(kind, name, info)
		order = order + 1
		local frame = panel(scroll, { Size = UDim2.new(1, -12, 0, 92), LayoutOrder = order })
		frame.BackgroundColor3 = STYLE.ParchmentDark
		textLabel(frame, { Text = info.Icon or "", Size = UDim2.fromOffset(70, 70), Position = UDim2.fromOffset(10, 11), Font = Enum.Font.GothamBold })
		local prefix = kind == "Pass" and "Pass_" or "Product_"
		local title = textLabel(frame, { Font = STYLE.TitleFont, Size = UDim2.new(1, -250, 0, 36), Position = UDim2.fromOffset(90, 8), TextXAlignment = Enum.TextXAlignment.Left })
		bindText(title, prefix .. name)
		local desc = textLabel(frame, { Size = UDim2.new(1, -250, 0, 38), Position = UDim2.fromOffset(90, 46), TextXAlignment = Enum.TextXAlignment.Left })
		bindText(desc, prefix .. name .. "_Desc")
		local buy = woodButton(frame, { Size = UDim2.fromOffset(140, 64), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), BackgroundColor3 = STYLE.Green })
		local function updateButton()
			if kind == "Pass" and player:GetAttribute("Pass_" .. name) == true then
				buy.Text = T("Owned")
				buy.BackgroundColor3 = C(110, 100, 90)
			else
				buy.Text = "R$ " .. info.Price
				buy.BackgroundColor3 = STYLE.Green
			end
		end
		updateButton()
		if kind == "Pass" then
			player:GetAttributeChangedSignal("Pass_" .. name):Connect(updateButton)
			passButtons[name] = updateButton
		end
		player:GetAttributeChangedSignal("Lang"):Connect(updateButton)
		buy.Activated:Connect(function()
			if kind == "Pass" and player:GetAttribute("Pass_" .. name) == true then
				return
			end
			if info.Id == 0 then
				notify(T("NotConfigured"), "error")
				return
			end
			if kind == "Pass" then
				MarketplaceService:PromptGamePassPurchase(player, info.Id)
			else
				MarketplaceService:PromptProductPurchase(player, info.Id)
			end
		end)
	end

	header("ShopPasses")
	for _, name in ipairs(Monetization.PassOrder) do
		card("Pass", name, Monetization.GamePasses[name])
	end
	header("ShopProducts")
	for _, name in ipairs(Monetization.ProductOrder) do
		card("Product", name, Monetization.Products[name])
	end
end

----------------------------------------------------------------------
-- Nustatymai
----------------------------------------------------------------------
local settingsWindow = createWindow("Settings", "SettingsTitle", 560, 440)
do
	local content = settingsWindow.Content
	local function toggleRow(y, key, attribute)
		local r = row(content, y, 70)
		local label = textLabel(r, { Font = STYLE.TitleFont, Size = UDim2.new(0.5, 0, 1, -10), Position = UDim2.fromOffset(0, 5), TextXAlignment = Enum.TextXAlignment.Left })
		bindText(label, key)
		local button = woodButton(r, { Size = UDim2.fromOffset(150, 64), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3) })
		local function update()
			local on = player:GetAttribute(attribute) ~= false
			button.Text = on and T("On") or T("Off")
			button.BackgroundColor3 = on and STYLE.Green or STYLE.Red
		end
		update()
		player:GetAttributeChangedSignal(attribute):Connect(update)
		player:GetAttributeChangedSignal("Lang"):Connect(update)
		button.Activated:Connect(function()
			Remotes.ChangeSetting:FireServer(string.lower(attribute), not (player:GetAttribute(attribute) ~= false))
		end)
	end
	toggleRow(0, "Music", "Music")
	toggleRow(84, "Sfx", "Sfx")
	toggleRow(168, "Beeps", "Beeps")

	local r = row(content, 252, 70)
	local label = textLabel(r, { Font = STYLE.TitleFont, Size = UDim2.new(0.4, 0, 1, -10), Position = UDim2.fromOffset(0, 5), TextXAlignment = Enum.TextXAlignment.Left })
	bindText(label, "Language")
	local en = woodButton(r, { Text = "EN", Size = UDim2.fromOffset(100, 64), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -110, 0, 3) })
	local lt = woodButton(r, { Text = "LT", Size = UDim2.fromOffset(100, 64), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 3) })
	local function updateLang()
		en.BackgroundColor3 = lang() == "en" and STYLE.Gold or STYLE.Wood
		lt.BackgroundColor3 = lang() == "lt" and STYLE.Gold or STYLE.Wood
	end
	updateLang()
	player:GetAttributeChangedSignal("Lang"):Connect(updateLang)
	en.Activated:Connect(function()
		Remotes.ChangeSetting:FireServer("lang", "en")
	end)
	lt.Activated:Connect(function()
		Remotes.ChangeSetting:FireServer("lang", "lt")
	end)
end

----------------------------------------------------------------------
-- Teleportas
----------------------------------------------------------------------
local function teleportTo(cframe)
	if player:GetAttribute("Jailed") then
		notify(T("JailNoTeleport"), "error")
		return
	end
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		character:PivotTo(cframe)
	end
end

local teleportWindow = createWindow("Teleport", "TeleportTitle", 460, 260)
do
	local content = teleportWindow.Content
	local toPlot = woodButton(content, { Size = UDim2.new(1, 0, 0, 70) })
	bindText(toPlot, "ToPlot")
	local toLobby = woodButton(content, { Size = UDim2.new(1, 0, 0, 70), Position = UDim2.fromOffset(0, 86) })
	bindText(toLobby, "ToLobby")
	toPlot.Activated:Connect(function()
		local index = player:GetAttribute("PlotIndex") or 0
		local plots = workspace:FindFirstChild("Plots")
		local plot = plots and plots:FindFirstChild("Plot_" .. index)
		local spawn = plot and plot:FindFirstChild("PlotSpawn")
		if index == 0 or not spawn then
			notify(T("NoPlot"), "error")
			return
		end
		teleportTo(spawn.CFrame * CFrame.Angles(0, math.rad(180), 0))
		teleportWindow.Close()
	end)
	toLobby.Activated:Connect(function()
		local lobby = workspace:FindFirstChild("Lobby")
		local spawn = lobby and lobby:FindFirstChild("LobbySpawn", true)
		if spawn then
			teleportTo(spawn.CFrame + Vector3.new(0, 4, 0))
		end
		teleportWindow.Close()
	end)
end

----------------------------------------------------------------------
-- Kasdienis prizas
----------------------------------------------------------------------
local function dailyRemaining()
	local last = player:GetAttribute("LastDaily") or 0
	if last == 0 then
		return 0
	end
	return math.max(0, Settings.Daily.Cooldown - (workspace:GetServerTimeNow() - last))
end

local dailyWindow = createWindow("Daily", "DailyTitle", 480, 320)
do
	local content = dailyWindow.Content
	local streakLabel = textLabel(content, { Font = STYLE.TitleFont, Size = UDim2.new(1, 0, 0, 40) })
	local statusLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 36), Position = UDim2.fromOffset(0, 50) })
	local claim = woodButton(content, { Size = UDim2.fromOffset(220, 66), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = STYLE.Green })
	bindText(claim, "DailyClaim")
	task.spawn(function()
		while true do
			if dailyWindow.Frame.Visible then
				local streak = player:GetAttribute("DailyStreak") or 0
				local nextDay = math.min(streak + 1, #Settings.Daily.StreakMultipliers)
				local mult = string.gsub(tostring(Settings.Daily.StreakMultipliers[nextDay]), "%.", ",")
				streakLabel.Text = T("DailyStreak", { days = streak, mult = mult })
				local remaining = dailyRemaining()
				if remaining <= 0 then
					statusLabel.Text = T("DailyReady")
					claim.BackgroundColor3 = STYLE.Green
				else
					statusLabel.Text = T("DailyWait", { time = NumberFormat.Time(remaining) })
					claim.BackgroundColor3 = C(110, 100, 90)
				end
			end
			task.wait(0.5)
		end
	end)
	claim.Activated:Connect(function()
		if dailyRemaining() > 0 then
			return
		end
		pcall(function()
			Remotes.ClaimDaily:InvokeServer()
		end)
	end)
end

----------------------------------------------------------------------
-- Offline pajamų langas
----------------------------------------------------------------------
local offlineWindow = createWindow("Offline", "OfflineTitle", 480, 280)
local offlineText
do
	local content = offlineWindow.Content
	offlineText = textLabel(content, { Size = UDim2.new(1, 0, 0, 90) })
	local ok = woodButton(content, { Size = UDim2.fromOffset(200, 64), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), BackgroundColor3 = STYLE.Green })
	bindText(ok, "Ok")
	ok.Activated:Connect(offlineWindow.Close)
end

----------------------------------------------------------------------
-- Radijas „Magė“: muzika pagal kodą (savininkas arba nusipirkęs už Settings.Radio.Price)
----------------------------------------------------------------------
local radioWindow = createWindow("Radio", "RadioTitle", 580, 560)
do
	local content = radioWindow.Content
	local nowLabel = textLabel(content, { Font = STYLE.TitleFont, Size = UDim2.new(1, 0, 0, 34), TextColor3 = STYLE.Green })
	local input = new("TextBox", {
		Name = "CodeInput", Size = UDim2.new(1, 0, 0, 52), Position = UDim2.fromOffset(0, 44),
		BackgroundColor3 = STYLE.Cream, TextColor3 = STYLE.Ink, PlaceholderColor3 = C(150, 120, 90),
		Font = STYLE.BodyFont, TextScaled = true, ClearTextOnFocus = false, Text = "",
	}, content)
	decorate(input, STYLE.WoodDark, 3, 8)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, input)
	local play = woodButton(content, { Name = "Play", Size = UDim2.new(0.5, -6, 0, 58), Position = UDim2.fromOffset(0, 106), BackgroundColor3 = STYLE.Green })
	local stop = woodButton(content, { Name = "Stop", Size = UDim2.new(0.5, -6, 0, 58), Position = UDim2.new(0.5, 6, 0, 106), BackgroundColor3 = STYLE.Red })
	bindText(play, "RadioPlay")
	bindText(stop, "RadioStop")
	local minus = woodButton(content, { Name = "VolDown", Text = "−", Size = UDim2.fromOffset(56, 44), Position = UDim2.fromOffset(0, 174) })
	local volumeLabel = textLabel(content, { Size = UDim2.new(1, -132, 0, 36), Position = UDim2.fromOffset(66, 178) })
	local plus = woodButton(content, { Name = "VolUp", Text = "+", Size = UDim2.fromOffset(56, 44), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 174) })
	local errorLabel = textLabel(content, { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.fromOffset(0, 226), TextColor3 = STYLE.Red })
	local recentTitle = textLabel(content, { Font = STYLE.TitleFont, Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 256), TextXAlignment = Enum.TextXAlignment.Left })
	bindText(recentTitle, "RadioRecent")
	local list = new("Frame", { Name = "Recent", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 132), Position = UDim2.fromOffset(0, 288) }, content)
	new("UIGridLayout", { CellSize = UDim2.new(0.5, -5, 0, 38), CellPadding = UDim2.fromOffset(10, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local hint = textLabel(content, { Size = UDim2.new(1, 0, 0, 22), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), TextColor3 = C(110, 80, 50) })
	bindText(hint, "RadioHint")

	local busy = false

	local function refreshNow()
		local id = ReplicatedStorage:GetAttribute("RadioId") or ""
		if id ~= "" then
			nowLabel.Text = T("RadioNow", { name = ReplicatedStorage:GetAttribute("RadioName") or "" })
			nowLabel.TextColor3 = STYLE.Green
		else
			nowLabel.Text = T("RadioSilent")
			nowLabel.TextColor3 = C(120, 90, 60)
		end
		local volume = ReplicatedStorage:GetAttribute("RadioVolume") or Settings.Radio.Volume
		volumeLabel.Text = T("RadioVolume", { v = math.floor(volume * 100 + 0.5) })
		input.PlaceholderText = T("RadioPlaceholder")
	end

	local function showError(key)
		errorLabel.Text = key and T(key) or ""
	end

	-- Jei daina neužsikrauna (privati / neleidžiama šiam žaidimui) – parašom savininkui
	local function watchLoad(expectedId)
		task.spawn(function()
			for _ = 1, 40 do
				task.wait(0.25)
				if (ReplicatedStorage:GetAttribute("RadioId") or "") ~= expectedId then
					return
				end
				local sound = SoundService:FindFirstChild("MageRadio")
				if sound and sound.TimeLength > 0 then
					return
				end
			end
			if (ReplicatedStorage:GetAttribute("RadioId") or "") == expectedId then
				showError("RadioLoadFailed")
				notify(T("RadioLoadFailed"), "error")
			end
		end)
	end

	local fillRecent

	local function call(action, value)
		if busy then
			return nil
		end
		busy = true
		local ok, result = pcall(function()
			return Remotes.RadioControl:InvokeServer(action, value)
		end)
		busy = false
		if not ok or type(result) ~= "table" then
			return nil
		end
		if result.recent then
			fillRecent(result.recent)
		end
		if result.ok == false and result.err then
			showError(result.err)
		end
		return result
	end

	local function playCode(code)
		showError(nil)
		local result = call("play", code)
		if result and result.ok then
			input.Text = ""
			watchLoad(ReplicatedStorage:GetAttribute("RadioId") or "")
		end
	end

	fillRecent = function(recent)
		for _, child in ipairs(list:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for i, entry in ipairs(recent) do
			local button = woodButton(list, { Name = "Song" .. i, LayoutOrder = i, Text = "♪ " .. tostring(entry.name), Font = STYLE.BodyFont, BackgroundColor3 = STYLE.WoodLight })
			button.Activated:Connect(function()
				playCode(entry.id)
			end)
		end
	end

	play.Activated:Connect(function()
		playCode(input.Text)
	end)
	input.FocusLost:Connect(function(enterPressed)
		if enterPressed and input.Text ~= "" then
			playCode(input.Text)
		end
	end)
	stop.Activated:Connect(function()
		showError(nil)
		call("stop")
	end)
	minus.Activated:Connect(function()
		call("volume", -0.1)
	end)
	plus.Activated:Connect(function()
		call("volume", 0.1)
	end)

	radioWindow.OnOpen = function()
		showError(nil)
		refreshNow()
		task.spawn(call, "open")
	end

	ReplicatedStorage:GetAttributeChangedSignal("RadioId"):Connect(refreshNow)
	ReplicatedStorage:GetAttributeChangedSignal("RadioName"):Connect(refreshNow)
	ReplicatedStorage:GetAttributeChangedSignal("RadioVolume"):Connect(refreshNow)
	player:GetAttributeChangedSignal("Lang"):Connect(refreshNow)
	refreshNow()

	-- Visiems: trumpas pranešimas, kai Magė pradeda groti naują dainą
	local lastAnnounced = ""
	ReplicatedStorage:GetAttributeChangedSignal("RadioId"):Connect(function()
		local id = ReplicatedStorage:GetAttribute("RadioId") or ""
		if id ~= "" and id ~= lastAnnounced then
			lastAnnounced = id
			task.defer(function()
				notify(T("RadioStarted", { name = ReplicatedStorage:GetAttribute("RadioName") or "" }), "info")
			end)
		elseif id == "" then
			lastAnnounced = ""
		end
	end)

	-- Radijo E mygtukas: savininkui „Magė“, kitiems – „Pirkti: 20B Lt“
	local function updatePrompt(prompt)
		if player:GetAttribute("CanUseRadio") then
			prompt.ActionText = Settings.Radio.Name
			prompt.ObjectText = "📻"
		else
			prompt.ActionText = T("RadioBuy", { price = NumberFormat.Format(Settings.Radio.Price) })
			prompt.ObjectText = "📻 " .. Settings.Radio.Name
		end
	end
	task.spawn(function()
		local lobby = workspace:WaitForChild("Lobby", 60)
		local radio = lobby and lobby:WaitForChild("MageRadio", 60)
		local body = radio and radio:WaitForChild("Body", 30)
		local prompt = body and body:WaitForChild("RadioPrompt", 30)
		if prompt then
			updatePrompt(prompt)
			player:GetAttributeChangedSignal("CanUseRadio"):Connect(function()
				updatePrompt(prompt)
			end)
			player:GetAttributeChangedSignal("Lang"):Connect(function()
				updatePrompt(prompt)
			end)
		end
	end)
end

Remotes.OpenWindow.OnClientEvent:Connect(function(name, value)
	if name == "Offline" then
		offlineText.Text = T("OfflineText", { amount = NumberFormat.Format(value or 0) })
		offlineWindow.Open()
	elseif windows[name] then
		windows[name].Open()
	end
end)

----------------------------------------------------------------------
-- Kairysis meniu
----------------------------------------------------------------------
local menu = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(84, 5 * 94) }, screen)
new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, menu)

local function menuButton(order, icon, key, window)
	local button = woodButton(menu, { Size = UDim2.fromOffset(84, 84), LayoutOrder = order })
	textLabel(button, { Text = icon, Size = UDim2.new(1, 0, 0.6, 0), Position = UDim2.fromOffset(0, 4), Font = Enum.Font.GothamBold, TextColor3 = STYLE.Cream })
	local caption = textLabel(button, { Size = UDim2.new(1, -6, 0.3, 0), Position = UDim2.new(0, 3, 0.66, 0), Font = STYLE.TitleFont, TextColor3 = STYLE.Cream })
	bindText(caption, key)
	button.Activated:Connect(window.Toggle)
	return button
end

menuButton(1, "👵", "Btn_Rebirth", rebirthWindow)
menuButton(2, "🛒", "Btn_Shop", shopWindow)
menuButton(3, "⚙️", "Btn_Settings", settingsWindow)
menuButton(4, "🏠", "Btn_Teleport", teleportWindow)
local dailyButton = menuButton(5, "🎁", "Btn_Daily", dailyWindow)
local dailyDot = new("Frame", { BackgroundColor3 = STYLE.Red, Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -16, 0, -6), Visible = false, ZIndex = 3 }, dailyButton)
decorate(dailyDot, STYLE.Cream, 2, 11)
task.spawn(function()
	while true do
		dailyDot.Visible = player:GetAttribute("DataLoaded") == true and dailyRemaining() <= 0
		task.wait(1)
	end
end)

----------------------------------------------------------------------
-- Tutorial (tik pirmą kartą)
----------------------------------------------------------------------
local tutorialPanel = panel(screen, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(560, 64), Visible = false })
local tutorialLabel = textLabel(tutorialPanel, { Font = STYLE.TitleFont, Size = UDim2.new(1, -24, 1, -12), Position = UDim2.fromOffset(12, 6) })
local arrow = nil
local arrowTarget = nil
local tutorialFinishing = false

local function setArrow(target)
	if target == arrowTarget then
		return
	end
	arrowTarget = target
	if arrow then
		arrow:Destroy()
		arrow = nil
	end
	if not target then
		return
	end
	arrow = new("BillboardGui", { Name = "TutorialArrow", Adornee = target, Size = UDim2.fromScale(4, 4), StudsOffset = Vector3.new(0, 7, 0), AlwaysOnTop = true, LightInfluence = 0 }, playerGui)
	textLabel(arrow, { Text = "⬇", Size = UDim2.fromScale(1, 1), TextColor3 = STYLE.Gold, TextStrokeTransparency = 0, TextStrokeColor3 = STYLE.WoodDark, Font = Enum.Font.GothamBlack })
	TweenService:Create(arrow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { StudsOffset = Vector3.new(0, 9, 0) }):Play()
end

local function findOwnButton(buttonId)
	local index = player:GetAttribute("PlotIndex") or 0
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot_" .. index)
	local buttons = plot and plot:FindFirstChild("Buttons")
	if not buttons then
		return nil
	end
	for _, button in ipairs(buttons:GetChildren()) do
		if button:GetAttribute("ButtonId") == buttonId then
			return button
		end
	end
	return nil
end

local function nearestFreeClaimPad()
	local plots = workspace:FindFirstChild("Plots")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plots or not root then
		return nil
	end
	local best, bestDistance = nil, math.huge
	for _, plot in ipairs(plots:GetChildren()) do
		local pad = plot:FindFirstChild("ClaimPad")
		if pad and plot:GetAttribute("OwnerId") == 0 then
			local distance = (pad.Position - root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = pad, distance
			end
		end
	end
	return best
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if player:GetAttribute("DataLoaded") ~= true or player:GetAttribute("TutorialDone") == true or tutorialFinishing then
			tutorialPanel.Visible = false
			setArrow(nil)
		else
			local key, target = nil, nil
			if (player:GetAttribute("PlotIndex") or 0) == 0 then
				key, target = "Tutorial_1", nearestFreeClaimPad()
			elseif findOwnButton("Cepelinai_1") then
				key, target = "Tutorial_2", findOwnButton("Cepelinai_1")
			elseif findOwnButton("Cepelinai_2") then
				key = "Tutorial_3"
				local grater = findOwnButton("Cepelinai_2")
				if grater and (player:GetAttribute("Money") or 0) >= (grater:GetAttribute("Price") or 0) then
					target = grater
				end
			else
				key = "Tutorial_4"
				tutorialFinishing = true
				tutorialPanel.Visible = true
				tutorialLabel.Text = T(key)
				setArrow(nil)
				task.delay(6, function()
					Remotes.TutorialDone:FireServer()
					tutorialPanel.Visible = false
				end)
			end
			if not tutorialFinishing then
				tutorialPanel.Visible = true
				tutorialLabel.Text = T(key)
				setArrow(target)
			end
		end
	end
end)

----------------------------------------------------------------------
-- Įrenginio kalba: lietuviams žaidimas įsijungia lietuviškai, net jei Roblox nustatytas angliškai
----------------------------------------------------------------------
task.spawn(function()
	while player:GetAttribute("DataLoaded") ~= true do
		task.wait(0.5)
	end
	local ok, systemLocale = pcall(function()
		return game:GetService("LocalizationService").SystemLocaleId
	end)
	if ok and type(systemLocale) == "string" and systemLocale ~= "" then
		Remotes.ChangeSetting:FireServer("systemLocale", systemLocale)
	end
end)

----------------------------------------------------------------------
-- Viktorina apie Lietuvą: langas įskrenda iš atsitiktinės ekrano pusės
----------------------------------------------------------------------
local quizPanel = panel(screen, { Name = "Quiz", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(640, 400), Visible = false, ZIndex = 20 })
local quizTitle = textLabel(quizPanel, { Font = STYLE.TitleFont, TextColor3 = STYLE.Red, Size = UDim2.new(1, -40, 0, 50), Position = UDim2.fromOffset(20, 10) })
local quizQuestion = textLabel(quizPanel, { Size = UDim2.new(1, -40, 0, 80), Position = UDim2.fromOffset(20, 64) })
new("UITextSizeConstraint", { MaxTextSize = 32 }, quizQuestion)
local timerBack = new("Frame", { BackgroundColor3 = C(160, 130, 90), Size = UDim2.new(1, -40, 0, 10), Position = UDim2.fromOffset(20, 152), BorderSizePixel = 0 }, quizPanel)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, timerBack)
local timerFill = new("Frame", { BackgroundColor3 = STYLE.Gold, Size = UDim2.fromScale(1, 1), BorderSizePixel = 0 }, timerBack)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, timerFill)
local quizButtons = {}
for i = 1, 4 do
	local col, rowIndex = (i - 1) % 2, math.floor((i - 1) / 2)
	local b = woodButton(quizPanel, { Size = UDim2.new(0.5, -30, 0, 78), Position = UDim2.new(col * 0.5, 20 + col * -5, 0, 176 + rowIndex * 90) })
	b.Font = STYLE.BodyFont
	quizButtons[i] = b
end
local quizResult = textLabel(quizPanel, { Font = STYLE.TitleFont, Size = UDim2.new(1, -40, 0, 34), Position = UDim2.new(0, 20, 1, -40), Text = "" })
local quizState = nil

local function closeQuiz()
	if not quizPanel.Visible then
		return
	end
	local tween = TweenService:Create(quizPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Position = UDim2.fromScale(0.5, 1.6) })
	tween:Play()
	tween.Completed:Connect(function()
		if not quizState or quizState.Closed then
			quizPanel.Visible = false
		end
	end)
	if quizState then
		quizState.Closed = true
	end
end

Remotes.QuizStart.OnClientEvent:Connect(function(payload)
	quizState = { Id = payload.Id, EndsAt = payload.EndsAt, Answered = false, Choice = nil, Closed = false }
	quizTitle.Text = "🇱🇹 " .. T("QuizTitle")
	quizQuestion.Text = payload.Question
	quizResult.Text = ""
	for i, b in ipairs(quizButtons) do
		b.Text = payload.Answers[i] or ""
		b.BackgroundColor3 = STYLE.Wood
		b.AutoButtonColor = false
	end
	-- Įskrenda iš atsitiktinės pusės, pasisukęs
	local starts = { UDim2.fromScale(-0.6, 0.5), UDim2.fromScale(1.6, 0.5), UDim2.fromScale(0.5, -0.6), UDim2.fromScale(0.5, 1.6), UDim2.fromScale(-0.6, -0.4), UDim2.fromScale(1.6, 1.4) }
	quizPanel.Position = starts[math.random(1, #starts)]
	quizPanel.Rotation = math.random(-25, 25)
	quizPanel.Visible = true
	TweenService:Create(quizPanel, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.5), Rotation = 0 }):Play()
	local state = quizState
	task.spawn(function()
		local total = math.max(1, payload.EndsAt - workspace:GetServerTimeNow())
		while quizState == state and not state.Closed do
			local left = state.EndsAt - workspace:GetServerTimeNow()
			timerFill.Size = UDim2.fromScale(math.clamp(left / total, 0, 1), 1)
			if left < -3 then
				closeQuiz()
			end
			task.wait(0.1)
		end
	end)
end)

for i, b in ipairs(quizButtons) do
	b.Activated:Connect(function()
		if not quizState or quizState.Answered then
			return
		end
		quizState.Answered = true
		quizState.Choice = i
		b.BackgroundColor3 = STYLE.Gold
		Remotes.QuizAnswer:FireServer(quizState.Id, i)
	end)
end

Remotes.QuizResult.OnClientEvent:Connect(function(quizId, correct, reward, answerText)
	if not quizState or quizState.Id ~= quizId then
		return
	end
	quizState.Answered = true
	if correct then
		quizResult.TextColor3 = STYLE.Green
		quizResult.Text = "✅ " .. T("QuizCorrect", { amount = NumberFormat.Format(reward) })
	elseif correct == false then
		quizResult.TextColor3 = STYLE.Red
		quizResult.Text = "❌ " .. T("QuizWrong", { answer = answerText })
	else
		quizResult.TextColor3 = STYLE.Ink
		quizResult.Text = "⏰ " .. T("QuizTimeUp") .. " " .. T("QuizWrong", { answer = answerText })
	end
	for i, b in ipairs(quizButtons) do
		if b.Text == answerText then
			b.BackgroundColor3 = STYLE.Green
		elseif i == quizState.Choice then
			b.BackgroundColor3 = STYLE.Red
		end
	end
	local state = quizState
	task.delay(3.5, function()
		if quizState == state then
			closeQuiz()
		end
	end)
end)

----------------------------------------------------------------------
-- Močiučių varžybų lentelė (dešinėje viršuje)
----------------------------------------------------------------------
local contestPanel = panel(screen, { Name = "Contest", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 100), Size = UDim2.fromOffset(300, 196), Visible = false })
local contestTitle = textLabel(contestPanel, { Font = STYLE.TitleFont, TextColor3 = STYLE.Red, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 6) })
local contestRows = {}
for i = 1, 3 do
	contestRows[i] = textLabel(contestPanel, { Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 6 + i * 34), TextXAlignment = Enum.TextXAlignment.Left })
end
local contestYou = textLabel(contestPanel, { Font = STYLE.TitleFont, TextColor3 = STYLE.Green, Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 150), TextXAlignment = Enum.TextXAlignment.Left })
-- Mygtukas „Dalyvauti“: kol nepaspaudei – tavęs nėra lentelėje
local contestJoin = woodButton(contestPanel, { Name = "JoinButton", Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 146), BackgroundColor3 = STYLE.Green })
bindText(contestJoin, "ContestJoin")
contestJoin.Activated:Connect(function()
	contestJoin.Visible = false
	Remotes.ContestJoin:FireServer()
end)
local contestEndsAt = 0
local medals = { "🥇", "🥈", "🥉" }

Remotes.ContestUpdate.OnClientEvent:Connect(function(top, score, rank, endsAt, joined)
	if not top then
		contestPanel.Visible = false
		return
	end
	contestJoin.Visible = not joined
	contestYou.Visible = joined == true
	contestEndsAt = endsAt or contestEndsAt
	contestPanel.Visible = true
	for i = 1, 3 do
		local entry = top[i]
		contestRows[i].Text = entry and (medals[i] .. " " .. entry.Name .. " – " .. NumberFormat.Format(entry.Score) .. " Lt") or ""
	end
	contestYou.Text = T("ContestYou", { amount = NumberFormat.Format(score or 0), rank = (rank and rank > 0) and rank or "-" })
end)

task.spawn(function()
	while true do
		if contestPanel.Visible then
			contestTitle.Text = "👵 " .. T("ContestTitle", { time = NumberFormat.Time(contestEndsAt - workspace:GetServerTimeNow()) })
			if ReplicatedStorage:GetAttribute("CurrentEvent") ~= "Contest" then
				contestPanel.Visible = false
			end
		end
		task.wait(0.5)
	end
end)

----------------------------------------------------------------------
-- Bėgimas su Shift (telefone – 🏃 mygtukas). Kairysis Shift paimamas bėgimui,
-- todėl „Shift Lock“ kamerą perjungia dešinysis Shift.
----------------------------------------------------------------------
do
	local ContextActionService = game:GetService("ContextActionService")
	local SPR = Settings.Sprint
	local sprinting = false

	local function applySprint()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or player:GetAttribute("Jailed") then
			return
		end
		local running = sprinting
		humanoid.WalkSpeed = running and SPR.SprintSpeed or SPR.WalkSpeed
		local camera = workspace.CurrentCamera
		if camera then
			TweenService:Create(camera, TweenInfo.new(0.25), { FieldOfView = running and SPR.SprintFieldOfView or SPR.FieldOfView }):Play()
		end
	end

	ContextActionService:BindActionAtPriority("CepelinuSprint", function(_, state)
		if state == Enum.UserInputState.Begin then
			sprinting = true
		elseif state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel then
			sprinting = false
		end
		applySprint()
		return Enum.ContextActionResult.Sink
	end, true, Enum.ContextActionPriority.High.Value, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	pcall(function()
		ContextActionService:SetTitle("CepelinuSprint", "🏃")
		ContextActionService:SetPosition("CepelinuSprint", UDim2.new(1, -170, 1, -150))
	end)

	player.CharacterAdded:Connect(function()
		sprinting = false
		task.defer(applySprint)
	end)
	-- Paleistas iš „kalėjimo“ – grąžinam įprastą greitį
	player:GetAttributeChangedSignal("Jailed"):Connect(function()
		if not player:GetAttribute("Jailed") then
			sprinting = false
			task.delay(0.5, applySprint)
		end
	end)
end

----------------------------------------------------------------------
-- Kalbos keitimas
----------------------------------------------------------------------
player:GetAttributeChangedSignal("Lang"):Connect(refreshTexts)
