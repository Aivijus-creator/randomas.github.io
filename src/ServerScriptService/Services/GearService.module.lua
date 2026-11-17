--[[
	GearService – daiktai kuprinėje (Tool be Handle):
	  „Magė“      – radijas tiems, kas jį turi (savininkas arba nusipirkęs už 20B).
	                Išsitraukus – radijas atsiduria ant dešinio peties, o ranka jį prilaiko
	                (IKControl nukreipia plaštaką į radiją). Paspaudus – atsidaro valdymo langas.
	  Ženklas     – tik savininkui: lentelė ant kotelio iškelta virš galvos su užrašu
	                Settings.Sign.Text (dideliu šriftu, matosi visiems).

	Daiktai prisegami prie liemens (Weld), o IKControl serveryje sukuriamas Humanoide –
	jis replikuojasi ir kiekvienas klientas ranką „pastato“ pats, todėl pozą mato visi.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))

local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local GearService = {}
local S

----------------------------------------------------------------------
-- Pagalbinės
----------------------------------------------------------------------
local function torsoOf(character)
	return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
end

local function newTool(name, tip)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool.ToolTip = tip or name
	return tool
end

-- Dalis prisegama prie liemens per Weld su tikslia vieta (offset – liemens koordinatėmis)
local function welded(model, torso, props, offset)
	props.Parent = model
	props.Anchored = false
	props.CanCollide = false
	props.CanQuery = false
	props.CanTouch = false
	props.Massless = true
	props.CFrame = torso.CFrame * offset
	local part = Build.Part(props)
	local weld = Instance.new("Weld")
	weld.Part0 = torso
	weld.Part1 = part
	weld.C0 = offset
	weld.Parent = part
	return part
end

-- Ranka laiko daiktą: IKControl veda dešinę plaštaką į taikinį
local function holdWithRightHand(character, target, name)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local upperArm = character:FindFirstChild("RightUpperArm")
	local hand = character:FindFirstChild("RightHand")
	if not humanoid or not upperArm or not hand then
		return nil -- R6 – daiktas tiesiog prisegtas
	end
	local ik = Instance.new("IKControl")
	ik.Name = name
	ik.Type = Enum.IKControlType.Position
	ik.ChainRoot = upperArm
	ik.EndEffector = hand
	ik.Target = target
	ik.Weight = 1
	ik.Priority = 1
	ik.Parent = humanoid
	return ik
end

local function clearGear(character, name)
	local old = character:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local ik = humanoid and humanoid:FindFirstChild(name .. "IK")
	if ik then
		ik:Destroy()
	end
end

----------------------------------------------------------------------
-- Magė ant peties
----------------------------------------------------------------------
local function equipMage(character)
	clearGear(character, "MageOnShoulder")
	local torso = torsoOf(character)
	if not torso then
		return
	end
	local model = Instance.new("Model")
	model.Name = "MageOnShoulder"
	local top = torso.Size.Y / 2
	local side = torso.Size.X / 2
	-- Radijas guli ant peties: ilgoji ašis – į priekį/atgal, garsiakalbiai į šoną (+X)
	local base = CF(side, top + 0.62, 0.05)
	local wood = C(105, 62, 32)
	local body = welded(model, torso, { Name = "MageBody", Size = V(0.7, 1.15, 2.1), Color = wood, Material = M.Wood }, base)
	welded(model, torso, { Name = "MageGrille", Size = V(0.08, 0.85, 1.25), Color = C(225, 200, 150), Material = M.Fabric }, base * CF(0.36, -0.02, 0.28))
	for i, color in ipairs({ C(253, 185, 19), C(0, 106, 68), C(193, 39, 45) }) do
		welded(model, torso, { Name = "MageStripe", Size = V(0.09, 0.08, 1.25), Color = color, Material = M.SmoothPlastic }, base * CF(0.37, -0.38 + (i - 1) * 0.08, 0.28))
	end
	welded(model, torso, { Name = "MageDial", Size = V(0.08, 0.3, 0.5), Color = C(255, 190, 90), Material = M.Neon }, base * CF(0.36, 0.25, -0.62))
	welded(model, torso, { Name = "MageKnob", Shape = Enum.PartType.Cylinder, Size = V(0.12, 0.25, 0.25), Color = C(230, 190, 90), Material = M.Metal }, base * CF(0.4, -0.2, -0.62))
	welded(model, torso, { Name = "MageHandle", Size = V(0.15, 0.15, 1.3), Color = C(60, 40, 25), Material = M.Wood }, base * CF(0, 0.72, 0))
	welded(model, torso, { Name = "MageAntenna", Size = V(0.06, 1.4, 0.06), Color = C(190, 190, 195), Material = M.Metal }, base * CF(-0.15, 1.2, -0.85) * CFrame.Angles(math.rad(-20), 0, 0))
	-- Natos, kai Magė groja
	local notes = Instance.new("ParticleEmitter")
	notes.Name = "Notes"
	notes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	notes.Color = ColorSequence.new(C(255, 220, 120), C(255, 150, 200))
	notes.Size = NumberSequence.new(0.2)
	notes.Lifetime = NumberRange.new(0.8, 1.4)
	notes.Speed = NumberRange.new(1, 2)
	notes.Rate = 4
	notes.Enabled = (ReplicatedStorage:GetAttribute("RadioId") or "") ~= ""
	notes.Parent = body
	-- Taikinys plaštakai: išorinis apatinis radijo kampas (ranka prilaiko iš šono)
	local grip = Instance.new("Attachment")
	grip.Name = "HandGrip"
	grip.Position = V(0.55, -0.45, 0.3)
	grip.Parent = body
	model.Parent = character
	local ik = holdWithRightHand(character, grip, "MageOnShoulderIK")
	if ik then
		ik.Name = "MageOnShoulderIK"
	end
end

----------------------------------------------------------------------
-- Ženklas virš galvos
----------------------------------------------------------------------
local function signFace(board, face, faceName)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignText_" .. faceName
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Text = Settings.Sign.Text
	label.TextColor3 = C(200, 30, 35)
	label.TextStrokeTransparency = 0.6
	label.Parent = gui
end

local function equipSign(character)
	clearGear(character, "BigSign")
	local torso = torsoOf(character)
	if not torso then
		return
	end
	local model = Instance.new("Model")
	model.Name = "BigSign"
	local top = torso.Size.Y / 2
	local side = torso.Size.X / 2
	-- Kotelis šalia dešinio peties, lentelė aukštai virš galvos
	local pole = welded(model, torso, { Name = "SignPole", Size = V(0.22, 5.2, 0.22), Color = C(120, 80, 45), Material = M.Wood }, CF(side + 0.55, top + 1.6, -0.35))
	local board = welded(model, torso, { Name = "SignBoard", Size = V(5.4, 2.3, 0.18), Color = C(250, 246, 235), Material = M.WoodPlanks }, CF(side - 0.6, top + 4.6, -0.35))
	welded(model, torso, { Name = "SignFrame", Size = V(5.7, 2.6, 0.12), Color = C(90, 58, 30), Material = M.Wood }, CF(side - 0.6, top + 4.6, -0.27))
	signFace(board, Enum.NormalId.Front, "Front")
	signFace(board, Enum.NormalId.Back, "Back")
	local grip = Instance.new("Attachment")
	grip.Name = "HandGrip"
	grip.Position = V(0, -1.1, 0)
	grip.Parent = pole
	model.Parent = character
	local ik = holdWithRightHand(character, grip, "BigSignIK")
	if ik then
		ik.Name = "BigSignIK"
	end
end

----------------------------------------------------------------------
-- Daiktų išdalijimas
----------------------------------------------------------------------
local function giveTools(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	local function has(name)
		return backpack:FindFirstChild(name) or (player.Character and player.Character:FindFirstChild(name))
	end
	if S.RadioService:CanUse(player) and not has("Magė") then
		local tool = newTool("Magė", "📻 " .. Settings.Radio.Name)
		tool.Equipped:Connect(function()
			if player.Character then
				equipMage(player.Character)
			end
		end)
		tool.Unequipped:Connect(function()
			if player.Character then
				clearGear(player.Character, "MageOnShoulder")
			end
		end)
		tool.Activated:Connect(function()
			if S.RadioService:CanUse(player) then
				Remotes.OpenWindow:FireClient(player, "Radio")
			end
		end)
		tool.Parent = backpack
	end
	if S.AdminService:IsAdmin(player) and not has("Ženklas") then
		local tool = newTool("Ženklas", Settings.Sign.Text)
		tool.Equipped:Connect(function()
			if player.Character then
				equipSign(player.Character)
			end
		end)
		tool.Unequipped:Connect(function()
			if player.Character then
				clearGear(player.Character, "BigSign")
			end
		end)
		tool.Parent = backpack
	end
end

function GearService:Refresh(player)
	giveTools(player)
end

function GearService:Init(services)
	S = services
end

function GearService:Start()
	local function onPlayer(player)
		player.CharacterAdded:Connect(function()
			task.delay(1.5, function()
				if player.Parent and S.DataService:Get(player) then
					giveTools(player)
				end
			end)
		end)
		player:GetAttributeChangedSignal("CanUseRadio"):Connect(function()
			giveTools(player)
		end)
		task.spawn(function()
			for _ = 1, 30 do
				if S.DataService:Get(player) or not player.Parent then
					break
				end
				task.wait(1)
			end
			if player.Parent and S.DataService:Get(player) then
				giveTools(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end
	-- Natos ant peties, kai Magė groja
	ReplicatedStorage:GetAttributeChangedSignal("RadioId"):Connect(function()
		local playing = (ReplicatedStorage:GetAttribute("RadioId") or "") ~= ""
		for _, player in ipairs(Players:GetPlayers()) do
			local gear = player.Character and player.Character:FindFirstChild("MageOnShoulder")
			local body = gear and gear:FindFirstChild("MageBody")
			local notes = body and body:FindFirstChild("Notes")
			if notes then
				notes.Enabled = playing
			end
		end
	end)
end

return GearService
