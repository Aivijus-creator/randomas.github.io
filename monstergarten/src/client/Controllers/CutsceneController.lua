-- CutsceneController: parents drop-off / pick-up scenes at the hall window, screen fades, skip button.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local ModelRegistry = require(Shared.World.ModelRegistry)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local CutsceneController = { Active = false }
local Controllers
local gui: ScreenGui
local fade: Frame
local skipBtn: TextButton
local caption: TextLabel
local props: { Instance } = {}
local renderConn: RBXScriptConnection? = nil

local function clearProps()
	for _, p in props do
		p:Destroy()
	end
	props = {}
	if renderConn then
		renderConn:Disconnect()
		renderConn = nil
	end
end

local function daycare(slot: number): Model?
	local dc = workspace:FindFirstChild("Daycares")
	return dc and dc:FindFirstChild("Daycare_" .. tostring(slot)) :: Model?
end

local function windowOf(m: Model): Model?
	for _, w in CollectionService:GetTagged("ParentDropoff") do
		if w:IsDescendantOf(m) then
			return w :: Model
		end
	end
	return nil
end

local function spawnParents(window: Model, babies: { any }, faces: boolean, facesOnly: boolean?)
	local spot = window:FindFirstChild("ParentSpot") :: BasePart?
	if not spot and not facesOnly then
		return
	end
	local n = math.min(#babies, 4)
	local seen = {}
	local i = 0
	for _, b in babies do
		if not facesOnly and not seen[b.Id] and i < n then
			seen[b.Id] = true
			i += 1
			local ok, parent = pcall(ModelRegistry.getParent, b.Id)
			if ok and parent then
				local x = (i - (n + 1) / 2) * 16
				local base = spot.CFrame * CFrame.new(x, 0, 6 + math.random() * 4)
				local offset = parent:GetAttribute("FloorOffset") or 8
				parent:PivotTo(CFrame.lookAt(base.Position + Vector3.new(0, offset - 3, 0), spot.Position + Vector3.new(0, offset - 3, -30)))
				parent.Parent = workspace
				table.insert(props, parent)
				local start = parent:GetPivot()
				local phase = math.random() * 3
				local conn = RunService.RenderStepped:Connect(function()
					local t = os.clock() + phase
					parent:PivotTo(start * CFrame.new(0, math.sin(t * 1.5) * 0.8, 0) * CFrame.Angles(0, 0, math.sin(t) * 0.04))
				end)
				parent.Destroying:Connect(function()
					conn:Disconnect()
				end)
			end
		end
	end
	if faces then
		-- face rating above each baby
		for _, b in babies do
			for _, m in CollectionService:GetTagged("Baby") do
				if m:GetAttribute("Uid") == b.Uid and m.PrimaryPart then
					local bb = Instance.new("BillboardGui")
					bb.Size = UDim2.fromOffset(70, 70)
					bb.StudsOffset = Vector3.new(0, 3.5, 0)
					bb.AlwaysOnTop = true
					bb.Adornee = m.PrimaryPart
					bb.Parent = player:WaitForChild("PlayerGui")
					local t = Instance.new("TextLabel")
					t.Size = UDim2.fromScale(1, 1)
					t.BackgroundTransparency = 1
					t.TextScaled = true
					t.Text = if b.Score >= 85 then "😃" elseif b.Score >= 50 then "😐" else "😢"
					t.Parent = bb
					table.insert(props, bb)
				end
			end
		end
	end
end

local function celebrate()
	for i = 1, 3 do
		local star = UI.label("⭐", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.3 + i * 0.1, 1.1), Size = UDim2.fromOffset(90, 90), Parent = gui })
		TweenService:Create(star, TweenInfo.new(1.2 + i * 0.2, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.3 + i * 0.1, 0.35), Rotation = 360 }):Play()
		table.insert(props, star)
	end
	local yay = UI.label("", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromOffset(600, 80), TextColor3 = C.Yellow, TextStrokeTransparency = 0.2, Parent = gui })
	UI.bind(yay, "Cutscene_Happy")
	local scale = UI.new("UIScale", { Scale = 0.2, Parent = yay })
	TweenService:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	table.insert(props, yay)
end

local function complaint()
	local paper = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, -0.2, 0), Size = UDim2.fromOffset(260, 180), Rotation = -12, Parent = gui }, C.White)
	local l = UI.label("", { Position = UDim2.fromOffset(10, 10), Size = UDim2.new(1, -20, 1, -20), TextColor3 = C.Red, Parent = paper })
	UI.bind(l, "Cutscene_Complaint")
	TweenService:Create(paper, TweenInfo.new(2.2, Enum.EasingStyle.Bounce), { Position = UDim2.fromScale(0.5, 0.55), Rotation = 8 }):Play()
	if Controllers.SoundController then
		Controllers.SoundController:Play("Shift_Complaint")
	end
	table.insert(props, paper)
end

function CutsceneController:Play(kind: string, data: any)
	clearProps()
	local m = daycare(data.Slot)
	if not m then
		return
	end
	self.Active = true
	Controllers.CameraController.Locked = true
	local cam = workspace.CurrentCamera
	-- The parents and babies are moved by the server; the camera watches the front porch.
	local camMarker = nil
	for _, c in CollectionService:GetTagged("FrontCamera") do
		if c:IsDescendantOf(m) then
			camMarker = c
		end
	end
	local window = windowOf(m)
	local camCF = if camMarker then (camMarker :: BasePart).CFrame else (window and window:GetPivot() * CFrame.new(0, 8, 30) or m:GetPivot())
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = camCF * CFrame.new(-18, 6, 10)
	TweenService:Create(cam, TweenInfo.new(4, Enum.EasingStyle.Sine), { CFrame = camCF }):Play()
	if kind == "Return" then
		-- face ratings above every baby
		spawnParents(window or m, data.Babies or {}, true, true)
		local stars = data.Stars or 0
		task.delay(3, function()
			if self.Active then
				if stars >= 2 then
					celebrate()
				else
					complaint()
				end
			end
		end)
	end
	caption.Text = Strings.t(if kind == "Arrival" then "Cutscene_Arrival" else "Cutscene_Return")
	caption.Visible = true
	skipBtn.Visible = true
	if Controllers.SoundController then
		Controllers.SoundController:Play("Env_Bell")
	end
end

function CutsceneController:Stop()
	if not self.Active then
		return
	end
	self.Active = false
	clearProps()
	caption.Visible = false
	skipBtn.Visible = false
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		cam.CameraSubject = hum
	end
	Controllers.CameraController.Locked = false
end

function CutsceneController:Fade(fadeIn: boolean, time: number)
	TweenService:Create(fade, TweenInfo.new(time or 0.5), { BackgroundTransparency = if fadeIn then 0 else 1 }):Play()
end

function CutsceneController:Init(c)
	Controllers = c
	gui = UI.screen("CutsceneGui", 30)
	fade = UI.new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = gui })
	caption = UI.label("", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(700, 50), TextColor3 = C.White, TextStrokeTransparency = 0.3, Visible = false, Parent = gui })
	skipBtn = UI.button("", C.Peach, function()
		Remotes.event("CutsceneSkip"):FireServer()
		skipBtn.Text = "✔"
	end, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(150, 48), Visible = false, Parent = gui })
	UI.bind(skipBtn, "Cutscene_Skip")
end

function CutsceneController:Start()
	Remotes.event("Cutscene").OnClientEvent:Connect(function(kind, data)
		if kind == "End" then
			self:Stop()
			UI.bind(skipBtn, "Cutscene_Skip")
		else
			self:Play(kind, data or {})
		end
	end)
	Remotes.event("Fade").OnClientEvent:Connect(function(fadeIn, time)
		self:Fade(fadeIn, time)
	end)
	State.ShiftChanged:Connect(function(s)
		if not s then
			self:Stop()
		end
	end)
end

return CutsceneController
