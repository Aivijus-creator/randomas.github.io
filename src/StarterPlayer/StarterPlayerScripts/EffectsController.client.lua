--[[
	EffectsController – kliento efektai ir garsai:
	  - 3D užrašų vertimas pagal kalbą (žymė "Loc")
	  - pirkimo mygtukų spalva: žalia – gali nupirkti, raudona – trūksta litų
	  - iššokantys „+31 Lt“ tekstai, monetų / „pop“ garsai
	  - konvejerių juostų animacija, besisukančios dalys, močiučių animacija ir kalbos burbulai
	  - Bulvių lietus (dekoratyvios bulvės tik kliente), Didžiojo Cepelino sprogimas
	  - muzika, VIP barjerai ir VIP žymė pokalbyje
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local TextChatService = game:GetService("TextChatService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local Config = ReplicatedStorage:WaitForChild("Config")
local Texts = require(Config:WaitForChild("Texts"))
local Settings = require(Config:WaitForChild("Settings"))
local Sounds = require(Config:WaitForChild("Sounds"))
local NumberFormat = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NumberFormat"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local C = Color3.fromRGB
local V = Vector3.new

local GREEN = C(70, 190, 70)
local RED = C(200, 60, 50)
local NEUTRAL = C(150, 120, 80)

local function lang()
	return player:GetAttribute("Lang") or "en"
end

----------------------------------------------------------------------
-- Garsai
----------------------------------------------------------------------
local soundCache = {}

local function getSound(id, volume)
	if not id or id == "" then
		return nil
	end
	local sound = soundCache[id]
	if not sound then
		sound = Instance.new("Sound")
		sound.SoundId = id
		sound.Volume = volume or Sounds.SfxVolume
		sound.Parent = SoundService
		soundCache[id] = sound
	end
	return sound
end

local function playSfx(id)
	if player:GetAttribute("Sfx") == false then
		return
	end
	local sound = getSound(id, id == Sounds.Coin and Sounds.CoinVolume or nil)
	if sound then
		SoundService:PlayLocalSound(sound)
	end
end

-- Fonė muzika: grojaraštis ratu, atsitiktinė pradžia
local playlist = {}
for _, id in ipairs(type(Sounds.Music) == "table" and Sounds.Music or { Sounds.Music }) do
	if id and id ~= "" then
		table.insert(playlist, id)
	end
end
local music = nil
local musicIndex = 0

-- Radijas „Magė“: kai groja, fono muzika pristabdoma
local function radioActive()
	return (ReplicatedStorage:GetAttribute("RadioId") or "") ~= ""
end

local function playNextTrack()
	if #playlist == 0 or not music then
		return
	end
	musicIndex = musicIndex % #playlist + 1
	music.SoundId = playlist[musicIndex]
	if player:GetAttribute("Music") ~= false and not radioActive() then
		music:Play()
	end
end

local function updateMusic()
	if #playlist == 0 then
		return
	end
	if not music then
		music = Instance.new("Sound")
		music.Name = "Music"
		music.Volume = Sounds.MusicVolume
		music.Looped = #playlist == 1
		music.Parent = SoundService
		music.Ended:Connect(playNextTrack)
		musicIndex = math.random(1, #playlist) - 1
		playNextTrack()
	end
	if radioActive() then
		if music.IsPlaying then
			music:Pause()
		end
	elseif player:GetAttribute("Music") ~= false then
		if not music.IsPlaying then
			if music.TimePosition > 0 then
				music:Resume()
			else
				music:Play()
			end
		end
	else
		music:Stop()
	end
end

local radioSound = nil

-- Paleidžia radiją nuo tos vietos, kur jis groja serveryje (vėliau prisijungusiems)
local function startRadioSynced(sound)
	task.spawn(function()
		local waited = 0
		while sound.Parent and sound.TimeLength <= 0 and waited < 10 do
			task.wait(0.25)
			waited = waited + 0.25
		end
		if not sound.Parent or sound ~= radioSound then
			return
		end
		local startedAt = ReplicatedStorage:GetAttribute("RadioStartedAt") or 0
		local elapsed = workspace:GetServerTimeNow() - startedAt
		if sound.TimeLength > 0 and elapsed > 1 then
			sound.TimePosition = elapsed % sound.TimeLength
		end
		if player:GetAttribute("Music") ~= false and not sound.IsPlaying then
			sound:Play()
		end
	end)
end

local function updateRadio()
	local id = ReplicatedStorage:GetAttribute("RadioId") or ""
	if id == "" then
		if radioSound then
			radioSound:Destroy()
			radioSound = nil
		end
		updateMusic()
		return
	end
	if not radioSound or radioSound.SoundId ~= id then
		if radioSound then
			radioSound:Destroy()
		end
		radioSound = Instance.new("Sound")
		radioSound.Name = "MageRadio"
		radioSound.SoundId = id
		radioSound.Looped = true
		radioSound.Volume = ReplicatedStorage:GetAttribute("RadioVolume") or Settings.Radio.Volume
		radioSound.Parent = SoundService
		startRadioSynced(radioSound)
	end
	radioSound.Volume = ReplicatedStorage:GetAttribute("RadioVolume") or Settings.Radio.Volume
	updateMusic()
	if player:GetAttribute("Music") == false then
		radioSound:Pause()
	elseif not radioSound.IsPlaying and radioSound.TimeLength > 0 then
		radioSound:Resume()
	end
end

----------------------------------------------------------------------
-- Vertimai
----------------------------------------------------------------------
local function localize(label)
	local key = label:GetAttribute("TextKey")
	if not key then
		return
	end
	local args = {}
	for name, value in pairs(label:GetAttributes()) do
		if string.sub(name, 1, 4) == "Arg_" then
			args[string.sub(name, 5)] = value
		elseif string.sub(name, 1, 7) == "ArgNum_" then
			args[string.sub(name, 8)] = NumberFormat.Format(value)
		elseif string.sub(name, 1, 7) == "ArgKey_" then
			args[string.sub(name, 8)] = Texts.Get(lang(), value)
		end
	end
	label.Text = Texts.Get(lang(), key, args)
end

local function watchLabel(label)
	if not label:IsA("TextLabel") and not label:IsA("TextButton") then
		return
	end
	localize(label)
	label.AttributeChanged:Connect(function()
		localize(label)
	end)
end

for _, label in ipairs(CollectionService:GetTagged("Loc")) do
	watchLabel(label)
end
CollectionService:GetInstanceAddedSignal("Loc"):Connect(watchLabel)

player:GetAttributeChangedSignal("Lang"):Connect(function()
	for _, label in ipairs(CollectionService:GetTagged("Loc")) do
		localize(label)
	end
end)

----------------------------------------------------------------------
-- Pirkimo mygtukai: spalva pagal litus
----------------------------------------------------------------------
task.spawn(function()
	while true do
		task.wait(0.1)
		local money = player:GetAttribute("Money") or 0
		local pulse = (math.sin(os.clock() * 5) + 1) / 2
		local function paint(button, color, neon)
			button.Color = color
			button.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
			local glow = button:FindFirstChild("Glow")
			if glow then
				glow.Color = color
			end
		end
		for _, button in ipairs(CollectionService:GetTagged("BuyButton")) do
			if button:IsA("BasePart") then
				if button:GetAttribute("OwnerId") == player.UserId then
					local canBuy = money >= (button:GetAttribute("Price") or 0)
					paint(button, canBuy and GREEN:Lerp(C(170, 255, 140), pulse * 0.6) or RED, canBuy)
				else
					paint(button, NEUTRAL, false)
				end
			end
		end
		for _, pad in ipairs(CollectionService:GetTagged("WeaponPad")) do
			if pad:IsA("BasePart") then
				local id = pad:GetAttribute("WeaponId")
				local owned = player:GetAttribute("Weapon_" .. tostring(id)) == true
				local priceLabel = pad:FindFirstChild("PriceLabel")
				local label = priceLabel and priceLabel:FindFirstChild("Text")
				if owned then
					paint(pad, C(214, 172, 58), true)
					if label and label:GetAttribute("TextKey") ~= "Owned" then
						label:SetAttribute("TextKey", "Owned")
					end
				else
					local canBuy = money >= (pad:GetAttribute("Price") or 0)
					paint(pad, canBuy and GREEN:Lerp(C(170, 255, 140), pulse * 0.6) or RED, canBuy)
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- Pakartotinai naudojami dalelių emiteriai (pigu: vienas Part kiekvienam efektui)
----------------------------------------------------------------------
local fxAnchorFolder = Instance.new("Folder")
fxAnchorFolder.Name = "ParticleFX"
fxAnchorFolder.Parent = workspace

local function makeEmitter(name, props)
	local anchor = Instance.new("Part")
	anchor.Name = name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = V(0.2, 0.2, 0.2)
	anchor.Parent = fxAnchorFolder
	local emitter = Instance.new("ParticleEmitter")
	emitter.Rate = 0
	for key, value in pairs(props) do
		emitter[key] = value
	end
	emitter.Parent = anchor
	return function(position, count)
		anchor.CFrame = CFrame.new(position)
		emitter:Emit(count)
	end
end

local emitDust = makeEmitter("DropDust", {
	Color = ColorSequence.new(C(235, 220, 185)), Size = NumberSequence.new(0.7, 0), Lifetime = NumberRange.new(0.3, 0.6),
	Speed = NumberRange.new(2, 4), SpreadAngle = Vector2.new(180, 180), Transparency = NumberSequence.new(0.3, 1),
})
local emitSparkle = makeEmitter("UpgradeSparkle", {
	Color = ColorSequence.new(C(255, 235, 130), C(255, 160, 60)), Size = NumberSequence.new(0.45, 0), Lifetime = NumberRange.new(0.4, 0.7),
	Speed = NumberRange.new(4, 8), SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Texture = "rbxasset://textures/particles/sparkles_main.dds",
})
local emitCoins = makeEmitter("SellCoins", {
	Color = ColorSequence.new(C(255, 210, 60)), Size = NumberSequence.new(0.5, 0.3), Lifetime = NumberRange.new(0.6, 0.9),
	Speed = NumberRange.new(8, 12), SpreadAngle = Vector2.new(25, 25), Acceleration = V(0, -35, 0), EmissionDirection = Enum.NormalId.Top,
	LightEmission = 0.4,
})

-- Savo sklypo produktai: dulkės iškritus, kibirkštys pravažiavus upgrader'į
local watchedItemFolders = {}
local function watchOwnPlot()
	local index = player:GetAttribute("PlotIndex") or 0
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot_" .. index)
	local items = plot and plot:FindFirstChild("Items")
	if not items or watchedItemFolders[items] then
		return
	end
	watchedItemFolders[items] = true
	items.ChildAdded:Connect(function(item)
		if not item:IsA("BasePart") or player:GetAttribute("PlotIndex") ~= index then
			return
		end
		task.defer(function()
			if item.Parent then
				emitDust(item.Position, 6)
			end
		end)
		item.AttributeChanged:Connect(function(name)
			if string.sub(name, 1, 4) == "Upg_" and item.Parent then
				emitSparkle(item.Position, 12)
			end
		end)
	end)
end
player:GetAttributeChangedSignal("PlotIndex"):Connect(watchOwnPlot)
task.defer(watchOwnPlot)

----------------------------------------------------------------------
-- „+31 Lt“ tekstai ir garsai
----------------------------------------------------------------------
local coinTimes = {}
local floatFolder = Instance.new("Folder")
floatFolder.Name = "FloatingTexts"
floatFolder.Parent = workspace

local function floatingText(text, position, color)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = V(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = floatFolder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(6, 1.6)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.Fondamento
	label.TextScaled = true
	label.Text = text
	label.TextColor3 = color or C(255, 215, 80)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = C(60, 35, 10)
	label.Parent = gui
	local duration = Settings.UI.FloatingTextTime
	TweenService:Create(gui, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = V(0, 3.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, duration + 0.1)
end

Remotes.ItemSold.OnClientEvent:Connect(function(amount, position)
	emitCoins(position - V(0, 2.5, 0), 5)
	floatingText("+" .. NumberFormat.Format(amount) .. " Lt", position + V((math.random() - 0.5) * 1.5, 0, 0))
	local now = os.clock()
	local recent = 0
	for i = #coinTimes, 1, -1 do
		if now - coinTimes[i] < 1 then
			recent = recent + 1
		else
			table.remove(coinTimes, i)
		end
	end
	if recent < Settings.UI.MaxCoinSoundsPerSecond and player:GetAttribute("Beeps") ~= false then
		table.insert(coinTimes, now)
		playSfx(Sounds.Coin)
	end
end)

Remotes.MachineBuilt.OnClientEvent:Connect(function(position)
	playSfx(Sounds.Pop)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = floatFolder
	local puff = Instance.new("ParticleEmitter")
	puff.Color = ColorSequence.new(C(240, 225, 190))
	puff.Size = NumberSequence.new(1.5, 0)
	puff.Lifetime = NumberRange.new(0.5, 0.9)
	puff.Speed = NumberRange.new(6, 10)
	puff.SpreadAngle = Vector2.new(180, 180)
	puff.Rate = 0
	puff.Parent = anchor
	puff:Emit(25)
	Debris:AddItem(anchor, 1.5)
end)

Remotes.RebirthDone.OnClientEvent:Connect(function()
	playSfx(Sounds.Fanfare)
end)

Remotes.EventStarted.OnClientEvent:Connect(function()
	playSfx(Sounds.EventHorn)
end)

----------------------------------------------------------------------
-- Konvejerio juostos: judančios skersinės juostelės (tik kliente).
-- Juda Belt'o LookVector kryptimi – ta pačia, kuria serveris stumia produktus.
----------------------------------------------------------------------
local SLAT_SPACING = 5
local BELT_ANIMATION_DISTANCE = 160
local belts = {}
local fxFolder = Instance.new("Folder")
fxFolder.Name = "ConveyorFX"
fxFolder.Parent = workspace

local function setupBelt(belt)
	if not belt:IsA("BasePart") or belts[belt] then
		return
	end
	local length = belt.Size.Z
	local slats = {}
	local slatColor = belt.Color:Lerp(C(0, 0, 0), 0.45)
	for i = 1, math.floor(length / SLAT_SPACING) do
		local slat = Instance.new("Part")
		slat.Name = "Slat"
		slat.Anchored = true
		slat.CanCollide = false
		slat.CanQuery = false
		slat.CanTouch = false
		slat.CastShadow = false
		slat.Size = V(belt.Size.X - 0.3, 0.06, 0.55)
		slat.Color = slatColor
		slat.Material = Enum.Material.SmoothPlastic
		slat.Transparency = belt.Transparency
		slat.Parent = fxFolder
		slats[i] = slat
	end
	belts[belt] = { Slats = slats, Length = length }
end

for _, belt in ipairs(CollectionService:GetTagged("ConveyorBelt")) do
	setupBelt(belt)
end
CollectionService:GetInstanceAddedSignal("ConveyorBelt"):Connect(setupBelt)
CollectionService:GetInstanceRemovedSignal("ConveyorBelt"):Connect(function(belt)
	local rec = belts[belt]
	if rec then
		for _, slat in ipairs(rec.Slats) do
			slat:Destroy()
		end
	end
	belts[belt] = nil
end)

----------------------------------------------------------------------
-- Močiutės: rankų animacija ir kalbos burbulai
----------------------------------------------------------------------
local grannies = {}

local function showBubble(granny, phraseIndex)
	local head = granny:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("SpeechBubble")
	if old then
		old:Destroy()
	end
	local phrases = Texts[lang()] and Texts[lang()].GrannyPhrases or Texts.en.GrannyPhrases
	local text = phrases[phraseIndex] or phrases[1]
	local gui = Instance.new("BillboardGui")
	gui.Name = "SpeechBubble"
	gui.Size = UDim2.fromScale(8, 2.6)
	gui.StudsOffset = V(0, 4.6, 0)
	gui.MaxDistance = 70
	gui.LightInfluence = 0
	gui.Parent = head
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = C(245, 232, 200)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = C(92, 58, 30)
	stroke.Thickness = 2
	stroke.Parent = frame
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.9, 0.84)
	label.Position = UDim2.fromScale(0.05, 0.08)
	label.Font = Enum.Font.Merriweather
	label.TextScaled = true
	label.TextColor3 = C(60, 35, 15)
	label.Text = text
	label.Parent = frame
	Debris:AddItem(gui, Settings.Grannies.PhraseShowTime)
	local root = granny:FindFirstChild("HumanoidRootPart")
	local character = player.Character
	local myRoot = character and character:FindFirstChild("HumanoidRootPart")
	if root and myRoot and (root.Position - myRoot.Position).Magnitude < 40 and player:GetAttribute("Sfx") ~= false then
		local voiceId = Sounds.GrannyVoice and Sounds.GrannyVoice[phraseIndex]
		if voiceId and voiceId ~= "" then
			-- Lietuviškas močiutės balsas, girdisi šalia jos
			local voice = Instance.new("Sound")
			voice.Name = "GrannyVoice"
			voice.SoundId = voiceId
			voice.Volume = Sounds.GrannyVoiceVolume or 0.9
			voice.RollOffMinDistance = 8
			voice.RollOffMaxDistance = 45
			voice.Parent = head
			voice:Play()
			Debris:AddItem(voice, 8)
		else
			playSfx(Sounds.Giggle)
		end
	end
end

local function setupGranny(granny)
	if grannies[granny] then
		return
	end
	local motors = {}
	for _, d in ipairs(granny:GetDescendants()) do
		if d:IsA("Motor6D") and (d.Name == "RightShoulder" or d.Name == "LeftShoulder") then
			table.insert(motors, {
				Motor = d,
				Original = d.C0,
				Side = d.Name == "RightShoulder" and 1 or -1,
				Amp = d:GetAttribute("SwingAmp") or 0.45,
				Bias = d:GetAttribute("SwingBias") or 0.7,
			})
		end
	end
	local pivot = granny:GetPivot()
	local bits = {}
	for _, d in ipairs(granny:GetDescendants()) do
		if d.Name == "FloatBit" and d:IsA("BasePart") then
			table.insert(bits, { Part = d, Offset = pivot:ToObjectSpace(d.CFrame), Phase = math.random() * 6 })
		end
	end
	local rec = { Motors = motors, Offset = math.random() * 6, Bits = bits }
	grannies[granny] = rec

	-- Nusileidimas iš dangaus (tik ką nupirkta močiutė)
	local arrive = granny:GetAttribute("ArriveAt")
	if arrive and workspace:GetServerTimeNow() - arrive < 2.5 then
		local level = granny:GetAttribute("Level") or 1
		local beamColor = ({ C(150, 230, 120), C(255, 215, 80), C(255, 190, 60) })[level] or C(255, 255, 255)
		local beam = Instance.new("Part")
		beam.Name = "ArrivalBeam"
		beam.Anchored = true
		beam.CanCollide = false
		beam.CanQuery = false
		beam.CanTouch = false
		beam.CastShadow = false
		beam.Shape = Enum.PartType.Cylinder
		beam.Material = Enum.Material.Neon
		beam.Color = beamColor
		beam.Transparency = 0.55
		beam.Size = V(70, 3.4, 3.4)
		beam.CFrame = pivot * CFrame.new(0, 35, 0) * CFrame.Angles(0, 0, math.rad(90))
		beam.Parent = fxAnchorFolder
		local shadow = Instance.new("Part")
		shadow.Name = "ArrivalShadow"
		shadow.Anchored = true
		shadow.CanCollide = false
		shadow.CanQuery = false
		shadow.CanTouch = false
		shadow.CastShadow = false
		shadow.Shape = Enum.PartType.Cylinder
		shadow.Material = Enum.Material.SmoothPlastic
		shadow.Color = C(20, 20, 20)
		shadow.Transparency = 0.5
		shadow.Size = V(0.05, 0.6, 0.6)
		shadow.CFrame = pivot * CFrame.new(0, -0.38, 0) * CFrame.Angles(0, 0, math.rad(90))
		shadow.Parent = fxAnchorFolder
		rec.Descend = { Base = pivot, Start = os.clock(), Duration = 1.9, Height = 55, Beam = beam, Shadow = shadow, Level = level }
		-- Saugiklis: šviesos tunelis visada dingsta, net jei močiutė pakeičiama animacijos metu
		Debris:AddItem(beam, 4)
		Debris:AddItem(shadow, 4)
		granny:PivotTo(pivot * CFrame.new(0, 55, 0))
	end
	granny:GetAttributeChangedSignal("Phrase"):Connect(function()
		local value = granny:GetAttribute("Phrase") or ""
		local index = tonumber(string.match(value, "^(%d+):"))
		if index then
			showBubble(granny, index)
		end
	end)
end

for _, granny in ipairs(CollectionService:GetTagged("Granny")) do
	setupGranny(granny)
end
CollectionService:GetInstanceAddedSignal("Granny"):Connect(setupGranny)
local function clearDescend(rec)
	local d = rec and rec.Descend
	if d then
		rec.Descend = nil
		if d.Beam then
			d.Beam:Destroy()
		end
		if d.Shadow then
			d.Shadow:Destroy()
		end
	end
end

CollectionService:GetInstanceRemovedSignal("Granny"):Connect(function(granny)
	clearDescend(grannies[granny])
	grannies[granny] = nil
end)

----------------------------------------------------------------------
-- Burbuliuojantys puodai (garsas šalia)
----------------------------------------------------------------------
local function setupBubbling(part)
	if Sounds.Bubbling == "" or not part:IsA("BasePart") then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "Bubbling"
	sound.SoundId = Sounds.Bubbling
	sound.Looped = true
	sound.Volume = 0.25
	sound.RollOffMaxDistance = 40
	sound.RollOffMinDistance = 5
	sound.Parent = part
	sound.Playing = player:GetAttribute("Sfx") ~= false
end
for _, part in ipairs(CollectionService:GetTagged("Bubbling")) do
	setupBubbling(part)
end
CollectionService:GetInstanceAddedSignal("Bubbling"):Connect(setupBubbling)

player:GetAttributeChangedSignal("Sfx"):Connect(function()
	local on = player:GetAttribute("Sfx") ~= false
	for _, part in ipairs(CollectionService:GetTagged("Bubbling")) do
		local sound = part:FindFirstChild("Bubbling")
		if sound then
			sound.Playing = on
		end
	end
end)
player:GetAttributeChangedSignal("Music"):Connect(updateMusic)
task.defer(updateMusic)
player:GetAttributeChangedSignal("Music"):Connect(updateRadio)
ReplicatedStorage:GetAttributeChangedSignal("RadioId"):Connect(updateRadio)
ReplicatedStorage:GetAttributeChangedSignal("RadioVolume"):Connect(updateRadio)
task.defer(updateRadio)
-- Sargas: muzika groja be pertraukų, kol žaidėjas pats jos neišjungia nustatymuose
task.spawn(function()
	while true do
		task.wait(2)
		if radioActive() then
			if radioSound and player:GetAttribute("Music") ~= false and not radioSound.IsPlaying and radioSound.TimeLength > 0 then
				radioSound:Resume()
			end
		elseif #playlist > 0 and player:GetAttribute("Music") ~= false then
			if not music then
				updateMusic()
			elseif not music.IsPlaying then
				if music.TimePosition > 0 and music.TimeLength > 0 and music.TimePosition < music.TimeLength - 0.5 then
					music:Resume()
				else
					playNextTrack()
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- Kadro atnaujinimas: juostos, sukimai, močiutės
----------------------------------------------------------------------
local clock = 0
RunService.RenderStepped:Connect(function(dt)
	clock = clock + dt
	local cam = workspace.CurrentCamera
	local camPosition = cam and cam.CFrame.Position or V()
	local travel = (clock * Settings.ConveyorSpeed) % SLAT_SPACING
	for belt, rec in pairs(belts) do
		if belt.Parent then
			local near = (belt.Position - camPosition).Magnitude < BELT_ANIMATION_DISTANCE + rec.Length / 2
			local half = rec.Length / 2
			local top = belt.Size.Y / 2 + 0.03
			for i, slat in ipairs(rec.Slats) do
				if near then
					-- nuo galo (+Z) link pradžios (-Z), t. y. LookVector kryptimi
					local z = half - 0.4 - travel - (i - 1) * SLAT_SPACING
					if z < -half + 0.4 then
						z = z + rec.Length - 0.8
					end
					slat.CFrame = belt.CFrame * CFrame.new(0, top, z)
				elseif slat.Transparency < 1 then
					slat.Transparency = 1
				end
				if near and slat.Transparency == 1 and belt.Transparency < 1 then
					slat.Transparency = belt.Transparency
				end
			end
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Spinner")) do
		if part:IsA("BasePart") and part.Anchored then
			part.CFrame = part.CFrame * CFrame.Angles((part:GetAttribute("SpinSpeed") or 1) * dt, 0, 0)
		end
	end
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position or V()
	for granny, rec in pairs(grannies) do
		local root = granny:FindFirstChild("HumanoidRootPart")
		local d = rec.Descend
		if d and not granny.Parent then
			clearDescend(rec)
			d = nil
		end
		if d then
			local alpha = math.min(1, (os.clock() - d.Start) / d.Duration)
			local eased = 1 - (1 - alpha) ^ 3
			local height = d.Height * (1 - eased)
			local spin = (1 - eased) * math.pi * 6
			granny:PivotTo(d.Base * CFrame.new(0, height, 0) * CFrame.Angles(0, spin, 0))
			local shadowSize = 0.6 + eased * 3.2
			d.Shadow.Size = V(0.05, shadowSize, shadowSize)
			d.Beam.Transparency = 0.55 + eased * 0.45
			if alpha >= 1 then
				rec.Descend = nil
				granny:PivotTo(d.Base)
				d.Beam:Destroy()
				d.Shadow:Destroy()
				local landing = d.Base.Position + V(0, 0.5, 0)
				emitDust(landing, 30)
				emitSparkle(landing + V(0, 2, 0), d.Level >= 2 and 30 or 14)
				playSfx(Sounds.Pop)
			end
		end
		if root and (root.Position - camPos).Magnitude < 150 then
			local t = clock * 3 + rec.Offset
			for _, m in ipairs(rec.Motors) do
				m.Motor.C0 = m.Original * CFrame.Angles(math.sin(t + (m.Side == 1 and 0 or math.pi)) * m.Amp + m.Bias, 0, 0)
			end
			if #rec.Bits > 0 then
				local pivot = granny:GetPivot()
				for i, b in ipairs(rec.Bits) do
					local bob = math.sin(clock * 2 + b.Phase) * 0.35
					b.Part.CFrame = pivot * b.Offset * CFrame.new(0, bob, 0) * CFrame.Angles(clock * 1.5 + i, clock + i, 0)
				end
			end
		end
	end
end)

----------------------------------------------------------------------
-- Sniegas Žiemos pūgos metu (tik kliente, aplink kamerą)
----------------------------------------------------------------------
local snowPart = nil
local function updateSnow()
	local winter = ReplicatedStorage:GetAttribute("CurrentEvent") == "Winter"
	if winter and not snowPart then
		snowPart = Instance.new("Part")
		snowPart.Name = "SnowEmitter"
		snowPart.Anchored = true
		snowPart.CanCollide = false
		snowPart.CanQuery = false
		snowPart.CanTouch = false
		snowPart.Transparency = 1
		snowPart.Size = V(140, 1, 140)
		snowPart.Parent = workspace
		local snow = Instance.new("ParticleEmitter")
		snow.Color = ColorSequence.new(C(255, 255, 255))
		snow.Size = NumberSequence.new(0.35, 0.25)
		snow.Lifetime = NumberRange.new(5, 7)
		snow.Rate = 260
		snow.Speed = NumberRange.new(7, 11)
		snow.SpreadAngle = Vector2.new(15, 15)
		snow.EmissionDirection = Enum.NormalId.Bottom
		snow.Acceleration = V(2, 0, 1)
		snow.Parent = snowPart
	elseif not winter and snowPart then
		snowPart:Destroy()
		snowPart = nil
	end
end
ReplicatedStorage:GetAttributeChangedSignal("CurrentEvent"):Connect(updateSnow)
task.defer(updateSnow)
RunService.RenderStepped:Connect(function()
	if snowPart then
		local camera = workspace.CurrentCamera
		if camera then
			snowPart.CFrame = CFrame.new(camera.CFrame.Position + V(0, 45, 0))
		end
	end
end)

----------------------------------------------------------------------
-- Bulvių lietus (dekoratyvios bulvės tik kliente)
----------------------------------------------------------------------
local rainFolder = Instance.new("Folder")
rainFolder.Name = "PotatoRain"
rainFolder.Parent = workspace
local raining = false

local function rainLoop()
	if raining then
		return
	end
	raining = true
	while ReplicatedStorage:GetAttribute("CurrentEvent") == "PotatoRain" do
		local camera = workspace.CurrentCamera
		if camera and #rainFolder:GetChildren() < 60 then
			local center = camera.CFrame.Position
			local potato = Instance.new("Part")
			potato.Size = V(1.5, 1.15, 1.2)
			potato.Color = C(170, 122, 72)
			potato.Material = Enum.Material.Sand
			potato.CanQuery = false
			potato.CanTouch = false
			potato.CastShadow = false
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = potato
			potato.Parent = rainFolder
			-- Gumbai ir akutės (kaip tikra bulvė)
			for i, offset in ipairs({ CFrame.new(0.4, 0.1, 0.15), CFrame.new(-0.4, -0.05, -0.2), CFrame.new(0.5, 0.3, 0.4), CFrame.new(-0.3, 0.4, 0.3) }) do
				local bit = Instance.new("Part")
				bit.Size = i <= 2 and V(0.75, 0.65, 0.7) or V(0.15, 0.12, 0.15)
				bit.Color = i <= 2 and C(160, 113, 66) or C(105, 70, 38)
				bit.Material = i <= 2 and Enum.Material.Sand or Enum.Material.SmoothPlastic
				bit.CanCollide = false
				bit.CanQuery = false
				bit.CanTouch = false
				bit.CastShadow = false
				bit.Massless = true
				bit.CFrame = potato.CFrame * offset
				local bitMesh = Instance.new("SpecialMesh")
				bitMesh.MeshType = Enum.MeshType.Sphere
				bitMesh.Parent = bit
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = potato
				weld.Part1 = bit
				weld.Parent = bit
				bit.Parent = potato
			end
			potato.CFrame = CFrame.new(center + V(math.random(-45, 45), 40 + math.random() * 15, math.random(-45, 45))) * CFrame.Angles(math.random() * 6, math.random() * 6, 0)
			Debris:AddItem(potato, 5)
		end
		task.wait(0.12)
	end
	raining = false
end

ReplicatedStorage:GetAttributeChangedSignal("CurrentEvent"):Connect(function()
	if ReplicatedStorage:GetAttribute("CurrentEvent") == "PotatoRain" then
		task.spawn(rainLoop)
	end
end)
if ReplicatedStorage:GetAttribute("CurrentEvent") == "PotatoRain" then
	task.spawn(rainLoop)
end

----------------------------------------------------------------------
-- Nustūmimas ginklu (žaidėjo personažas valdomas kliente, todėl jėga taikoma čia)
----------------------------------------------------------------------
Remotes.Knockback.OnClientEvent:Connect(function(velocity)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end
	playSfx(Sounds.Splat)
	humanoid.PlatformStand = true
	root.AssemblyLinearVelocity = velocity
	task.delay(0.9, function()
		if humanoid.Parent then
			humanoid.PlatformStand = false
		end
	end)
end)

----------------------------------------------------------------------
-- Kitų sklypų užrašai paslėpti: rodomi tik savo sklypo užrašai ir mygtukai.
-- Kai jau turi sklypą – kitų sklypų Claim mygtukai irgi paslepiami.
----------------------------------------------------------------------
local function applyVisibility(plot, object)
	local myIndex = player:GetAttribute("PlotIndex") or 0
	local isOwn = myIndex ~= 0 and plot:GetAttribute("Index") == myIndex
	local free = plot:GetAttribute("OwnerId") == 0
	local name = object.Name
	if object:IsA("BillboardGui") then
		if name == "OwnerSign" then
			object.Enabled = true
		elseif name == "ClaimLabel" then
			object.Enabled = myIndex == 0 and free
		else
			object.Enabled = isOwn
		end
	elseif object:IsA("ProximityPrompt") then
		if name == "ClaimPrompt" then
			object.Enabled = myIndex == 0 and free
		else
			object.Enabled = isOwn
		end
	elseif name == "ClaimPad" and object:IsA("BasePart") then
		object.Transparency = (myIndex == 0 and free) and 0 or 1
	end
end

local function refreshPlot(plot)
	for _, object in ipairs(plot:GetDescendants()) do
		applyVisibility(plot, object)
	end
end

local function refreshAllPlots()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	for _, plot in ipairs(plots:GetChildren()) do
		refreshPlot(plot)
	end
end

local watchedPlots = {}
local function watchPlots()
	local plots = workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	for _, plot in ipairs(plots:GetChildren()) do
		if not watchedPlots[plot] then
			watchedPlots[plot] = true
			plot.DescendantAdded:Connect(function(object)
				if object:IsA("BillboardGui") or object:IsA("ProximityPrompt") then
					task.defer(applyVisibility, plot, object)
				end
			end)
			plot:GetAttributeChangedSignal("OwnerId"):Connect(function()
				task.delay(0.2, refreshPlot, plot)
			end)
		end
	end
	refreshAllPlots()
end
player:GetAttributeChangedSignal("PlotIndex"):Connect(function()
	task.delay(0.2, refreshAllPlots)
end)
task.delay(1, watchPlots)
task.spawn(function()
	-- Atsarginis atnaujinimas (jei sklypai atsirado vėliau)
	while true do
		task.wait(5)
		watchPlots()
	end
end)

----------------------------------------------------------------------
-- Didžiojo Cepelino sprogimas į grietinės purslus
----------------------------------------------------------------------
Remotes.BigCepelinasBurst.OnClientEvent:Connect(function(position)
	playSfx(Sounds.Splat)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = floatFolder
	local cream = Instance.new("ParticleEmitter")
	cream.Color = ColorSequence.new(C(252, 250, 240))
	cream.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0.5) })
	cream.Lifetime = NumberRange.new(1.2, 2)
	cream.Speed = NumberRange.new(25, 45)
	cream.SpreadAngle = Vector2.new(180, 180)
	cream.Acceleration = V(0, -40, 0)
	cream.Rate = 0
	cream.Parent = anchor
	cream:Emit(120)
	local crumbs = cream:Clone()
	crumbs.Color = ColorSequence.new(C(220, 210, 180))
	crumbs.Size = NumberSequence.new(1, 0.3)
	crumbs.Parent = anchor
	crumbs:Emit(60)
	Debris:AddItem(anchor, 3)
end)

----------------------------------------------------------------------
-- VIP: barjerai praleidžia VIP žaidėją, VIP žymė pokalbyje
----------------------------------------------------------------------
local function updateVipBarriers()
	local lobby = workspace:FindFirstChild("Lobby")
	local barriers = lobby and lobby:FindFirstChild("VIPBarriers", true)
	if not barriers then
		return
	end
	local isVip = player:GetAttribute("Pass_VIP") == true
	for _, part in ipairs(barriers:GetChildren()) do
		if part:IsA("BasePart") then
			part.CanCollide = not isVip
		end
	end
end
player:GetAttributeChangedSignal("Pass_VIP"):Connect(updateVipBarriers)
task.delay(3, updateVipBarriers)

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	TextChatService.OnIncomingMessage = function(message)
		local properties = Instance.new("TextChatMessageProperties")
		if message.TextSource then
			local sender = Players:GetPlayerByUserId(message.TextSource.UserId)
			local prefix = message.PrefixText
			if sender and sender:GetAttribute("Pass_VIP") == true then
				prefix = "<font color=\"#FFD24A\">[VIP]</font> " .. prefix
			end
			-- #1 lyderių lentose
			if sender and sender:GetAttribute("TopRebirth") == true then
				prefix = "<font color=\"#7FD7FF\">[#1 🔁]</font> " .. prefix
			end
			if sender and sender:GetAttribute("TopMoney") == true then
				prefix = "<font color=\"#FFC83D\">[#1 👑]</font> " .. prefix
			end
			if prefix ~= message.PrefixText then
				properties.PrefixText = prefix
			end
		end
		return properties
	end
end

----------------------------------------------------------------------
-- Dangaus močiutė: milžinė kelia kočėlą kaip lazdą ir trenkia į dangų (žaibas)
----------------------------------------------------------------------
local Lighting = game:GetService("Lighting")

local function strikeFlash(granny)
	local pin = granny:FindFirstChild("RollingPin")
	if not pin then
		return
	end
	-- Žaibas nuo kočėlo galo į dangų
	local tip = (pin.CFrame * CFrame.new(-pin.Size.X / 2, 0, 0)).Position -- tolimasis kočėlo galas
	local top = tip + V(math.random(-40, 40), 420, math.random(-40, 40))
	local segments = 6
	local previous = tip
	local bolt = {}
	for i = 1, segments do
		local alpha = i / segments
		local point = tip:Lerp(top, alpha) + (i < segments and V(math.random(-25, 25), 0, math.random(-25, 25)) or V())
		local length = (point - previous).Magnitude
		local segment = Instance.new("Part")
		segment.Name = "SkyBolt"
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanQuery = false
		segment.CanTouch = false
		segment.CastShadow = false
		segment.Material = Enum.Material.Neon
		segment.Color = C(255, 235, 150)
		segment.Size = V(3, 3, length)
		segment.CFrame = CFrame.lookAt((previous + point) / 2, point)
		segment.Parent = fxAnchorFolder
		table.insert(bolt, segment)
		previous = point
	end
	for _, segment in ipairs(bolt) do
		Debris:AddItem(segment, 0.35)
	end
	-- Trumpas ekrano blyksnis
	local flash = Instance.new("ColorCorrectionEffect")
	flash.Name = "SkyGrannyFlash"
	flash.Brightness = 0.35
	flash.TintColor = C(255, 240, 200)
	flash.Parent = Lighting
	TweenService:Create(flash, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	Debris:AddItem(flash, 0.6)
	playSfx(Sounds.EventHorn)
end

local skyGranny = nil
local skyArm = nil

local function watchSkyGranny(model)
	if model.Name ~= "SkyGranny" or not model:IsA("Model") then
		return
	end
	skyGranny = model
	skyArm = nil
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == "RightShoulder" then
			skyArm = { Motor = d, Position = d.C0.Position, StrikeStart = 0 }
		end
	end
	model:GetAttributeChangedSignal("StrikeAt"):Connect(function()
		if skyArm then
			skyArm.StrikeStart = os.clock()
		end
		strikeFlash(model)
	end)
end

workspace.ChildAdded:Connect(watchSkyGranny)
for _, child in ipairs(workspace:GetChildren()) do
	watchSkyGranny(child)
end

RunService.RenderStepped:Connect(function()
	if not skyGranny or not skyGranny.Parent or not skyArm or not skyArm.Motor.Parent then
		return
	end
	local t = os.clock()
	-- Ranka iškelta virš galvos ir lėtai „kviečia“ (siūbuoja), smūgio metu staigiai kyla aukštyn
	local angle = math.rad(150) + math.sin(t * 1.6) * math.rad(14)
	local sinceStrike = t - skyArm.StrikeStart
	if sinceStrike < 0.9 then
		local k = sinceStrike < 0.25 and sinceStrike / 0.25 or 1 - (sinceStrike - 0.25) / 0.65
		angle = angle + math.rad(35) * math.max(0, k)
	end
	skyArm.Motor.C0 = CFrame.new(skyArm.Position) * CFrame.Angles(angle, 0, math.rad(-12))
end)

----------------------------------------------------------------------
-- Kalėjimas: močiutės sukasi aplink kėdę ir paeiliui „auklėja“ kočėlu
----------------------------------------------------------------------
local jailGrannies = {}

local function setupJailGranny(granny)
	if jailGrannies[granny] then
		return
	end
	local arm = nil
	for _, d in ipairs(granny:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == "RightShoulder" then
			arm = { Motor = d, Position = d.C0.Position }
		end
	end
	jailGrannies[granny] = { Arm = arm, LastBonk = -1 }
end

for _, granny in ipairs(CollectionService:GetTagged("JailGranny")) do
	setupJailGranny(granny)
end
CollectionService:GetInstanceAddedSignal("JailGranny"):Connect(setupJailGranny)
CollectionService:GetInstanceRemovedSignal("JailGranny"):Connect(function(granny)
	jailGrannies[granny] = nil
end)

local function bonkEffect(position)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = V(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = fxAnchorFolder
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromScale(5, 1.6)
	gui.StudsOffset = V(0, 1.5, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 100
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = ({ "BONK!", "PLIAukšt!", "Bum!", "Elkis gražiai!" })[math.random(1, 4)]
	label.TextColor3 = C(255, 220, 80)
	label.TextStrokeTransparency = 0
	label.Parent = gui
	TweenService:Create(gui, TweenInfo.new(0.7), { StudsOffset = V(0, 3.5, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.7), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	emitSparkle(position, 8)
	Debris:AddItem(anchor, 0.8)
end

RunService.RenderStepped:Connect(function()
	if next(jailGrannies) == nil then
		return
	end
	local t = os.clock()
	local camera = workspace.CurrentCamera
	local camPos = camera and camera.CFrame.Position or V()
	local J = Settings.Jail
	local slot = math.floor(t / J.BonkEvery)
	local phaseInBonk = (t % J.BonkEvery) / J.BonkEvery
	for granny, rec in pairs(jailGrannies) do
		if granny.Parent then
			local cx, cz = granny:GetAttribute("CenterX") or 0, granny:GetAttribute("CenterZ") or 0
			local center = V(cx, 0, cz)
			if (center - camPos).Magnitude < 250 then
				local phase = granny:GetAttribute("Phase") or 0
				local index = math.floor(phase / (2 * math.pi) * J.Grannies + 0.5)
				local myTurn = (slot % J.Grannies) == index
				local radius = J.CircleRadius
				if myTurn then
					radius = radius - 2.2 * math.sin(phaseInBonk * math.pi)  -- prieina arčiau
				end
				local a = phase + t * J.CircleSpeed
				local pivot = granny:GetPivot()
				local pos = V(cx + math.cos(a) * radius, pivot.Position.Y, cz + math.sin(a) * radius)
				granny:PivotTo(CFrame.lookAt(pos, V(cx, pos.Y, cz)))
				if rec.Arm then
					local angle = math.rad(40) + math.sin(t * 3 + phase) * math.rad(10)
					if myTurn then
						-- Užsimoja aukštyn ir trenkia žemyn
						angle = phaseInBonk < 0.55 and math.rad(40 + 130 * (phaseInBonk / 0.55)) or math.rad(170 - 150 * math.min(1, (phaseInBonk - 0.55) / 0.15))
					end
					rec.Arm.Motor.C0 = CFrame.new(rec.Arm.Position) * CFrame.Angles(angle, 0, 0)
				end
				if myTurn and phaseInBonk >= 0.68 and rec.LastBonk ~= slot then
					rec.LastBonk = slot
					local seatY = granny:GetAttribute("SeatY") or 2
					bonkEffect(V(cx, seatY + 3.2, cz))
					playSfx(Sounds.Splat)
				end
			end
		end
	end
end)
