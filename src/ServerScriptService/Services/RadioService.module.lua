--[[
	RadioService – radijas „Magė“ turgaus aikštėje.
	Savininkas (ir Settings.AdminUserIds) valdo nemokamai; kiti žaidėjai gali radiją nusipirkti
	už Settings.Radio.Price litų (pirkinys lieka visam laikui, ir po rebirth).
	Prie radijo paspaudi E ir įvedi muzikos kodą (ID) iš Creator Store → Audio. Muzika groja VISIEMS serveryje vietoj fono muzikos, kol
	ją sustabdai. Žaidėjai, kurie nustatymuose išjungė muziką, radijo negirdi.

	Būsena replikuojama ReplicatedStorage atributais:
	  RadioId        – "rbxassetid://123..." arba "" (radijas tyli)
	  RadioName      – dainos pavadinimas
	  RadioStartedAt – serverio laikas, kada pradėta (vėliau prisijungę girdi tą pačią vietą)
	  RadioVolume    – garsumas 0.1–1

	Komandos pokalbyje (tik savininkui): /mage 1234567890, /mage stop, /mage volume 0.5
	Neseniai grotos dainos išsaugomos žaidėjo duomenyse (data.radio.recent), pirkinys – data.radio.owned.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local RateLimit = require(Lib:WaitForChild("RateLimit"))

local R = Settings.Radio
local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local RadioService = {}
local S
local limiter = RateLimit.new(4)
local radioModel = nil

----------------------------------------------------------------------
-- Kas gali valdyti radiją
----------------------------------------------------------------------
function RadioService:CanUse(player)
	if S.AdminService ~= nil and S.AdminService:IsAdmin(player) then
		return true
	end
	local data = S.DataService:Get(player)
	return data ~= nil and data.radio ~= nil and data.radio.owned == true
end

-- Nusipirkti radiją už litus. Grąžina true, jei dabar gali naudoti.
function RadioService:Purchase(player)
	if self:CanUse(player) then
		return true
	end
	local data = S.DataService:Get(player)
	if not data then
		return false
	end
	if not S.DataService:SpendMoney(player, R.Price) then
		Remotes.Notify:FireClient(player, "RadioTooExpensive", {}, {}, { price = R.Price }, "error")
		return false
	end
	data.radio = data.radio or { recent = {} }
	data.radio.owned = true
	player:SetAttribute("CanUseRadio", true)
	Remotes.Notify:FireClient(player, "RadioBought", {}, {}, {}, "success")
	return true
end

----------------------------------------------------------------------
-- Radijo modelis
----------------------------------------------------------------------
local function buildRadio(parent, position)
	local model = Build.Model("MageRadio", parent)
	local cf = CFrame.lookAt(position, V(0, position.Y, 0))
	local wood = C(105, 62, 32)
	local darkWood = C(70, 40, 20)
	-- Staliukas
	Build.Part({ Name = "Table", Parent = model, Size = V(5, 0.4, 3), CFrame = cf * CF(0, 2.6, 0), Color = darkWood, Material = M.WoodPlanks })
	for _, x in ipairs({ -2.1, 2.1 }) do
		for _, z in ipairs({ -1.1, 1.1 }) do
			Build.Part({ Name = "Leg", Parent = model, Size = V(0.35, 2.4, 0.35), CFrame = cf * CF(x, 1.2, z), Color = darkWood, Material = M.Wood })
		end
	end
	-- Korpusas (senovinis medinis radijas)
	local body = Build.Part({ Name = "Body", Parent = model, Size = V(4, 2.8, 2), CFrame = cf * CF(0, 4.2, 0), Color = wood, Material = M.Wood })
	Build.Part({ Name = "Top", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(2, 2.4, 4), CFrame = cf * CF(0, 5.6, 0) * CFrame.Angles(0, math.rad(90), 0), Color = wood, Material = M.Wood })
	-- Garsiakalbio audinys ir lietuviška trispalvė juostelė
	Build.Part({ Name = "Grille", Parent = model, Size = V(2.2, 1.9, 0.16), CFrame = cf * CF(-0.65, 4.4, -1.06), Color = C(225, 200, 150), Material = M.Fabric })
	for i, color in ipairs({ C(253, 185, 19), C(0, 106, 68), C(193, 39, 45) }) do
		Build.Part({ Name = "Stripe", Parent = model, Size = V(3.6, 0.2, 0.12), CFrame = cf * CF(0, 3.25 - (i - 1) * 0.2, -1.06), Color = color, Material = M.SmoothPlastic })
	end
	-- Skalė (šviečia, kai groja) ir rankenėlės
	local dial = Build.Part({ Name = "Dial", Parent = model, Size = V(1.2, 0.6, 0.16), CFrame = cf * CF(1.2, 4.9, -1.06), Color = C(255, 190, 90), Material = M.SmoothPlastic })
	for _, y in ipairs({ 4.25, 3.7 }) do
		Build.Part({ Name = "Knob", Parent = model, Shape = Enum.PartType.Cylinder, Size = V(0.3, 0.5, 0.5), CFrame = cf * CF(1.2, y, -1.15) * CFrame.Angles(0, math.rad(90), 0), Color = C(230, 190, 90), Material = M.Metal })
	end
	-- Antena
	Build.Part({ Name = "Antenna", Parent = model, Size = V(0.1, 2.6, 0.1), CFrame = cf * CF(1.3, 6.9, 0.4) * CFrame.Angles(0, 0, math.rad(-20)), Color = C(190, 190, 195), Material = M.Metal })
	Build.Part({ Name = "AntennaTip", Parent = model, Shape = Enum.PartType.Ball, Size = V(0.25, 0.25, 0.25), CFrame = cf * CF(1.75, 8.1, 0.4), Color = C(190, 190, 195), Material = M.Metal })
	model.PrimaryPart = body

	-- Užrašas virš radijo: pavadinimas ir kas dabar groja
	local _, title = Build.Billboard(body, { Name = "Title", Size = UDim2.fromScale(7, 1.5), Offset = V(0, 4.2, 0), Text = "📻 " .. R.Name, MaxDistance = 80 })
	title.TextColor3 = C(255, 225, 120)
	local _, now = Build.Billboard(body, { Name = "NowPlaying", Size = UDim2.fromScale(9, 1), Offset = V(0, 2.9, 0), Text = "", MaxDistance = 60, Font = Enum.Font.Merriweather })

	-- Natos, kai groja
	local notes = Instance.new("ParticleEmitter")
	notes.Name = "Notes"
	notes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	notes.Color = ColorSequence.new(C(255, 220, 120), C(255, 150, 200))
	notes.Size = NumberSequence.new(0.35)
	notes.Lifetime = NumberRange.new(1.2, 2)
	notes.Speed = NumberRange.new(1.5, 2.5)
	notes.SpreadAngle = Vector2.new(35, 35)
	notes.EmissionDirection = Enum.NormalId.Top
	notes.Rate = 6
	notes.Enabled = false
	notes.Parent = body

	-- E: savininkui – atidaro valdymą, kitiems – nupirkti (tekstą klientas pakeičia pagal CanUseRadio)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RadioPrompt"
	prompt.ActionText = R.Name
	prompt.ObjectText = "📻"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	return model, dial, now, notes, prompt
end

local dialPart, nowLabel, notesEmitter

local function refreshModel()
	local playing = (ReplicatedStorage:GetAttribute("RadioId") or "") ~= ""
	if dialPart then
		dialPart.Material = playing and M.Neon or M.SmoothPlastic
	end
	if notesEmitter then
		notesEmitter.Enabled = playing
	end
	if nowLabel then
		nowLabel.Text = playing and ("♪ " .. (ReplicatedStorage:GetAttribute("RadioName") or "")) or ""
	end
end

----------------------------------------------------------------------
-- Valdymas
----------------------------------------------------------------------
local function recentList(player)
	local data = S.DataService:Get(player)
	if not data then
		return {}
	end
	data.radio = data.radio or {}
	data.radio.recent = data.radio.recent or {}
	return data.radio.recent
end

local function remember(player, id, name)
	local list = recentList(player)
	for i = #list, 1, -1 do
		if list[i].id == id then
			table.remove(list, i)
		end
	end
	table.insert(list, 1, { id = id, name = name })
	while #list > R.MaxRecent do
		table.remove(list)
	end
end

-- Iš teksto ištraukia ID: tinka "123", "rbxassetid://123" ar nuoroda su skaičiumi
function RadioService.ParseId(text)
	local digits = string.match(tostring(text or ""), "(%d+)")
	if not digits or #digits < 4 or #digits > 20 then
		return nil
	end
	return digits
end

function RadioService:Play(player, text)
	local digits = RadioService.ParseId(text)
	if not digits then
		return false, "RadioBadId"
	end
	local name = "#" .. digits
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfoAsync(tonumber(digits), Enum.InfoType.Asset)
	end)
	if ok and type(info) == "table" then
		if info.AssetTypeId and info.AssetTypeId ~= 3 then
			return false, "RadioNotAudio"
		end
		if type(info.Name) == "string" and info.Name ~= "" then
			name = string.sub(info.Name, 1, 60)
		end
	end
	ReplicatedStorage:SetAttribute("RadioName", name)
	ReplicatedStorage:SetAttribute("RadioStartedAt", workspace:GetServerTimeNow())
	ReplicatedStorage:SetAttribute("RadioId", "rbxassetid://" .. digits)
	refreshModel()
	if player then
		remember(player, digits, name)
	end
	return true, name
end

function RadioService:Stop()
	ReplicatedStorage:SetAttribute("RadioId", "")
	ReplicatedStorage:SetAttribute("RadioName", "")
	refreshModel()
end

function RadioService:SetVolume(volume)
	volume = math.clamp(tonumber(volume) or R.Volume, 0.1, 1)
	volume = math.floor(volume * 10 + 0.5) / 10
	ReplicatedStorage:SetAttribute("RadioVolume", volume)
	return volume
end

-- Klientas → serveris (RemoteFunction RadioControl)
local function onControl(player, action, value)
	if not limiter:Check(player) then
		return { ok = false, err = "RadioSlow" }
	end
	if not RadioService:CanUse(player) then
		return { ok = false, err = "RadioNotAllowed" }
	end
	local result = { ok = true }
	if action == "play" then
		local ok, nameOrErr = RadioService:Play(player, value)
		result.ok = ok
		if ok then
			result.name = nameOrErr
		else
			result.err = nameOrErr
		end
	elseif action == "stop" then
		RadioService:Stop()
	elseif action == "volume" then
		local current = ReplicatedStorage:GetAttribute("RadioVolume") or R.Volume
		local delta = tonumber(value) or 0
		result.volume = RadioService:SetVolume(current + math.clamp(delta, -0.5, 0.5))
	elseif action ~= "open" then
		return { ok = false }
	end
	local recent = {}
	for i, entry in ipairs(recentList(player)) do
		recent[i] = { id = entry.id, name = entry.name }
	end
	result.recent = recent
	return result
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function RadioService:Init(services)
	S = services
end

function RadioService:Start()
	ReplicatedStorage:SetAttribute("RadioId", "")
	ReplicatedStorage:SetAttribute("RadioName", "")
	ReplicatedStorage:SetAttribute("RadioStartedAt", 0)
	ReplicatedStorage:SetAttribute("RadioVolume", R.Volume)

	local lobby = workspace:FindFirstChild("Lobby")
	if lobby then
		local existing = lobby:FindFirstChild("MageRadio")
		if existing then
			existing:Destroy()
		end
		local a = math.rad(R.Angle)
		local model, dial, now, notes, prompt = buildRadio(lobby, V(math.cos(a) * R.Radius, 1, math.sin(a) * R.Radius))
		radioModel = model
		dialPart, nowLabel, notesEmitter = dial, now, notes
		prompt.Triggered:Connect(function(player)
			if RadioService:Purchase(player) then
				Remotes.OpenWindow:FireClient(player, "Radio")
			end
		end)
	end

	Remotes.RadioControl.OnServerInvoke = onControl

	-- Klientui: ar žaidėjas jau turi radiją (E mygtuko tekstas „Magė“ arba „Pirkti“)
	local function mark(player)
		task.spawn(function()
			for _ = 1, 30 do
				if S.DataService:Get(player) or not player.Parent then
					break
				end
				task.wait(1)
			end
			if player.Parent then
				player:SetAttribute("CanUseRadio", RadioService:CanUse(player))
			end
		end)
	end
	Players.PlayerAdded:Connect(mark)
	for _, player in ipairs(Players:GetPlayers()) do
		mark(player)
	end
end

function RadioService:GetModel()
	return radioModel
end

return RadioService
