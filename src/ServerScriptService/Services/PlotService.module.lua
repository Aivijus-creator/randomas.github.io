--[[
	PlotService – sklypų sukūrimas, priskyrimas (Claim), valymas ir zonų išvaizda.
	Vienas žaidėjas – vienas sklypas. Išėjus sklypas išvalomas ir atlaisvinamas.
	Grįžusiam žaidėjui (jau turinčiam progreso) sklypas priskiriamas automatiškai.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local ProductLines = require(Config:WaitForChild("ProductLines"))
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local GateModels = require(Lib:WaitForChild("GateModels"))
local ZoneThemes = require(Lib:WaitForChild("ZoneThemes"))
local RateLimit = require(Lib:WaitForChild("RateLimit"))

local L = Settings.Layout
local CF = CFrame.new

local PlotService = {}
PlotService.Plots = {}          -- [index] = plot įrašas
PlotService.ByPlayer = {}       -- [player] = plot įrašas

local S
local claimDebounce = RateLimit.debounce(1)
local pendingClaims = {}        -- [player] = plot (paspausta, kol dar kraunasi duomenys)

----------------------------------------------------------------------
-- Pagalbinės
----------------------------------------------------------------------
function PlotService:GetLaneX(lineId)
	return L.FirstLaneX - (ProductLines.Lines[lineId].Index - 1) * L.LaneSpacing
end

-- Linijos centro CFrame zonos paviršiuje (Z – sklypo lokali ašis)
function PlotService:GetLaneCFrame(plot, lineId)
	return plot.CFrame * CF(self:GetLaneX(lineId), L.ZoneTopY, 0)
end

function PlotService:GetPlot(player)
	return self.ByPlayer[player]
end

function PlotService:GetPlayerFromHit(hit)
	local character = hit and hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

function PlotService:GetSpawnCFrame(plot)
	return plot.CFrame * CF(0, 3, L.SpawnZ) * CFrame.Angles(0, math.rad(180), 0)
end

function PlotService:TeleportToPlot(player)
	local plot = self.ByPlayer[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if plot and root then
		character:PivotTo(self:GetSpawnCFrame(plot))
	end
end

----------------------------------------------------------------------
-- Išvaizda
----------------------------------------------------------------------
function PlotService:SetOwnerSign(plot)
	local beam = plot.Model:FindFirstChild("GateBeam")
	local sign = beam and beam:FindFirstChild("OwnerSign")
	local label = sign and sign:FindFirstChild("Text", true)
	if not label then
		return
	end
	if plot.Owner then
		label:SetAttribute("TextKey", "PlotOf")
		label:SetAttribute("Arg_name", plot.Owner.DisplayName)
	else
		label:SetAttribute("TextKey", "FreePlot")
		label:SetAttribute("Arg_name", nil)
	end
	local claimPad = plot.Model:FindFirstChild("ClaimPad")
	if claimPad then
		claimPad.Transparency = plot.Owner and 1 or 0
		claimPad.CanCollide = plot.Owner == nil
		local claimLabel = claimPad:FindFirstChild("ClaimLabel")
		if claimLabel then
			claimLabel.Enabled = plot.Owner == nil
		end
		local prompt = claimPad:FindFirstChild("ClaimPrompt")
		if prompt then
			prompt.Enabled = plot.Owner == nil
		end
	end
end

function PlotService:ApplySkin(plot, skinName)
	local skin = Settings.Skins[skinName] or Settings.Skins.Default
	local floor = plot.Model:FindFirstChild("Floor")
	if floor then
		floor.Color = skin.Floor
		floor.Material = skin.FloorMaterial
	end
	local fence = plot.Model:FindFirstChild("Fence")
	if fence then
		for _, part in ipairs(fence:GetChildren()) do
			if part:IsA("BasePart") then
				part.Color = skin.Fence
				part.Material = skin.FenceMaterial
			end
		end
	end
end

-- Zona: užrakinta (pusiau permatoma su užrašu) arba atrakinta (temos spalvos + dekoracijos)
function PlotService:SetZoneUnlocked(plot, lineId, unlocked)
	local line = ProductLines.Lines[lineId]
	local zones = plot.Model:FindFirstChild("Zones")
	local zone = zones and zones:FindFirstChild("Zone_" .. lineId)
	local decorFolder = plot.Decor:FindFirstChild(lineId)
	if decorFolder then
		decorFolder:Destroy()
	end
	if zone then
		local oldSign = zone:FindFirstChild("LockedSign")
		if oldSign then
			oldSign:Destroy()
		end
		if unlocked then
			zone.Transparency = 0
			zone.Color = line.Theme.Floor
			zone.Material = line.Theme.FloorMaterial
		else
			zone.Transparency = 0.6
			zone.Color = Color3.fromRGB(200, 200, 200)
			zone.Material = Enum.Material.SmoothPlastic
			if line.UnlockedBy then
				Build.Sign(zone, { Name = "LockedSign", TextKey = "ZoneLocked", Keys = { item = line.UnlockedBy }, Size = UDim2.fromScale(14, 3), Offset = Vector3.new(0, 5, 0), MaxDistance = 150 })
			end
		end
	end
	if unlocked then
		local folder = Build.Folder(lineId, plot.Decor)
		ZoneThemes.Build(lineId, folder, self:GetLaneCFrame(plot, lineId))
	end
end

-- Vartų išvaizda pagal lygį (0 – rąstai, 1 – dailidės, 2 – plytos)
function PlotService:ApplyGate(plot, level)
	level = level or 0
	if plot.GateLevel == level and plot.Model:FindFirstChild("Gate") then
		return
	end
	plot.GateLevel = level
	local old = plot.Model:FindFirstChild("Gate")
	if old then
		old:Destroy()
	end
	local folder = Build.Folder("Gate", plot.Model)
	GateModels.Build(folder, plot.CFrame, level, L.GateWidth / 2 + 2, L.GateZ, L.GateWidth)
end

-- Išvalo viską, kas pastatyta (mašinos, mygtukai, dekoracijos, žaliavos)
function PlotService:ClearPlot(plot)
	for _, folder in ipairs({ plot.Machines, plot.Buttons, plot.Decor, plot.Items }) do
		folder:ClearAllChildren()
	end
	for _, lineId in ipairs(ProductLines.Order) do
		self:SetZoneUnlocked(plot, lineId, false)
	end
	self:ApplySkin(plot, "Default")
	self:ApplyGate(plot, 0)
end

----------------------------------------------------------------------
-- Claim / Release
----------------------------------------------------------------------
function PlotService:Claim(player, plot)
	local data = S.DataService:Get(player)
	if not data then
		S.DataService:Notify(player, "DataNotLoaded")
		return false
	end
	if self.ByPlayer[player] then
		if self.ByPlayer[player] ~= plot then
			S.DataService:Notify(player, "AlreadyHavePlot", nil, nil, nil, "error")
		end
		return false
	end
	if plot.Owner then
		S.DataService:Notify(player, "PlotTaken", nil, nil, nil, "error")
		return false
	end
	plot.Owner = player
	plot.Model:SetAttribute("OwnerId", player.UserId)
	self.ByPlayer[player] = plot
	player:SetAttribute("PlotIndex", plot.Index)
	self:SetOwnerSign(plot)
	local ok, err = xpcall(function()
		S.TycoonService:BuildPlot(player, false)
	end, debug.traceback)
	if not ok then
		warn("[PlotService] Klaida statant gamyklą: " .. tostring(err))
	end
	S.DataService:Notify(player, "PlotClaimed", nil, nil, nil, "success")
	return true
end

-- Žaidėjas užlipo ant Claim mygtuko / paspaudė „E“
function PlotService:TryClaim(player, plot)
	if not claimDebounce:Check(player) then
		return
	end
	-- Jau turi sklypą: kitų sklypų Claim mygtukai jam paslėpti ir neveikia
	if self.ByPlayer[player] then
		return
	end
	if plot.Owner then
		S.DataService:Notify(player, "PlotTaken", nil, nil, nil, "error")
		return
	end
	if not S.DataService:Get(player) then
		-- Duomenys dar kraunasi: sklypas bus priskirtas, kai tik įsikels
		pendingClaims[player] = plot
		return
	end
	self:Claim(player, plot)
end

function PlotService:ClaimFirstFree(player)
	for _, plot in ipairs(self.Plots) do
		if not plot.Owner then
			return self:Claim(player, plot)
		end
	end
	return false
end

function PlotService:Release(player)
	local plot = self.ByPlayer[player]
	if not plot then
		return
	end
	S.TycoonService:StopPlayer(player)
	self.ByPlayer[player] = nil
	plot.Owner = nil
	plot.Model:SetAttribute("OwnerId", 0)
	self:ClearPlot(plot)
	self:SetOwnerSign(plot)
	if player.Parent then
		player:SetAttribute("PlotIndex", 0)
	end
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function PlotService:Init(services)
	S = services
end

function PlotService:Start()
	local container = workspace:FindFirstChild("Plots") or Build.Folder("Plots", workspace)
	for index = 1, Settings.PlotCount do
		local model = S.TemplateBuilder:ClonePlot()
		model.Name = "Plot_" .. index
		local cframe = S.MapBuilder:GetPlotCFrame(index)
		model:PivotTo(cframe)
		model:SetAttribute("Index", index)
		model:SetAttribute("OwnerId", 0)
		local plot = {
			Index = index,
			Model = model,
			CFrame = cframe,
			Owner = nil,
			Machines = Build.Folder("Machines", model),
			Buttons = Build.Folder("Buttons", model),
			Decor = Build.Folder("Decor", model),
			Items = Build.Folder("Items", model),
		}
		model.Parent = container
		self.Plots[index] = plot
		self:ClearPlot(plot)
		self:SetOwnerSign(plot)

		local function onTouched(hit)
			local player = self:GetPlayerFromHit(hit)
			if player then
				self:TryClaim(player, plot)
			end
		end
		for _, name in ipairs({ "ClaimPad", "ClaimZone" }) do
			local part = model:FindFirstChild(name)
			if part then
				part.Touched:Connect(onTouched)
			end
		end
		local pad = model:FindFirstChild("ClaimPad")
		local prompt = pad and pad:FindFirstChild("ClaimPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				self:TryClaim(player, plot)
			end)
		end
	end

	-- Grįžęs žaidėjas su progresu gauna sklypą automatiškai
	S.DataService:OnPlayerLoaded(function(player, data)
		local pending = pendingClaims[player]
		pendingClaims[player] = nil
		if pending and not pending.Owner and not self.ByPlayer[player] then
			self:Claim(player, pending)
			return
		end
		if data.tutorialDone or next(data.purchases) ~= nil or data.rebirths > 0 then
			if self:ClaimFirstFree(player) then
				local function teleport()
					task.wait(0.5)
					self:TeleportToPlot(player)
				end
				if player.Character then
					task.spawn(teleport)
				else
					local connection
					connection = player.CharacterAdded:Connect(function()
						connection:Disconnect()
						teleport()
					end)
				end
			end
		end
	end)

	-- Claim pagal žaidėjo poziciją (nepriklauso nuo fizikos Touched įvykių)
	task.spawn(function()
		while true do
			task.wait(Settings.ButtonCheckRate)
			for _, player in ipairs(Players:GetPlayers()) do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if root and not self.ByPlayer[player] then
					for _, plot in ipairs(self.Plots) do
						local pad = plot.Model:FindFirstChild("ClaimPad")
						if pad and not plot.Owner then
							local offset = root.Position - pad.Position
							if Vector3.new(offset.X, 0, offset.Z).Magnitude <= 4.5 and offset.Y > -2 and offset.Y < 8 then
								self:TryClaim(player, plot)
							end
						end
					end
				end
			end
		end
	end)

	S.DataService:OnPlayerRemoving(function(player)
		self:Release(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		pendingClaims[player] = nil
	end)
end

return PlotService
