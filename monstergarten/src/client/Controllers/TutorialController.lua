-- TutorialController: step bubble with text, progress, Next / Skip buttons and a 3D arrow over the target.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local TutorialController = {}
local panel: Frame
local text: TextLabel
local stepLabel: TextLabel
local nextBtn: TextButton
local arrow: BillboardGui
local step: any = nil

local function myDaycare(): Instance?
	local s = State.Shift
	local dc = workspace:FindFirstChild("Daycares")
	return s and dc and dc:FindFirstChild("Daycare_" .. tostring(s.Slot))
end

local function nearestTagged(tag: string): Instance?
	local dc = myDaycare()
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not dc or not r then
		return nil
	end
	local best, bestD = nil, math.huge
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsDescendantOf(dc) then
			local pos = if inst:IsA("Model") then inst:GetPivot().Position elseif inst:IsA("BasePart") then inst.Position else nil
			if pos then
				-- the cook step points at the oven
				if tag == "Appliance" and inst:GetAttribute("Kind") ~= "Oven" then
					continue
				end
				if tag == "ToolRack" and inst:GetAttribute("ToolId") ~= "Extinguisher" then
					continue
				end
				local d = (pos - r.Position).Magnitude
				if d < bestD then
					best, bestD = inst, d
				end
			end
		end
	end
	return best
end

function TutorialController:Init()
	local gui = UI.screen("TutorialGui", 12)
	panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 96), Size = UDim2.fromOffset(560, 150), Visible = false, Parent = gui }, C.Yellow)
	stepLabel = UI.label("", { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -28, 0, 22), Font = Enum.Font.GothamBold, Parent = panel })
	text = UI.label("", { Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 64), TextWrapped = true, Parent = panel })
	nextBtn = UI.button("", C.Mint, function()
		Remotes.event("TutorialAction"):FireServer("Next")
	end, { Position = UDim2.new(1, -330, 1, -52), Size = UDim2.fromOffset(150, 42), Parent = panel })
	UI.bind(nextBtn, "Tutorial_Next")
	local skip = UI.button("", C.Pink, function()
		Remotes.event("TutorialAction"):FireServer("Skip")
	end, { Position = UDim2.new(1, -168, 1, -52), Size = UDim2.fromOffset(150, 42), Parent = panel })
	UI.bind(skip, "Tutorial_Skip")
	arrow = Instance.new("BillboardGui")
	arrow.Name = "TutorialArrow"
	arrow.Size = UDim2.fromOffset(70, 70)
	arrow.StudsOffset = Vector3.new(0, 7, 0)
	arrow.AlwaysOnTop = true
	arrow.Enabled = false
	arrow.Parent = player:WaitForChild("PlayerGui")
	local a = Instance.new("TextLabel")
	a.Size = UDim2.fromScale(1, 1)
	a.BackgroundTransparency = 1
	a.TextScaled = true
	a.Text = "⬇️"
	a.Parent = arrow
end

local function render()
	panel.Visible = step ~= nil and State.inShift()
	if not step then
		arrow.Enabled = false
		return
	end
	stepLabel.Text = Strings.t("Tutorial_Step", step.Index, step.Total)
	text.Text = Strings.t(step.Key)
	nextBtn.Visible = step.Wait == "Next"
end

function TutorialController:Start()
	Remotes.event("TutorialStep").OnClientEvent:Connect(function(index, data)
		if data then
			step = { Index = index, Key = data.Key, Target = data.Target, Total = data.Total, Wait = data.Wait }
			local snd = State.Controllers.SoundController
			if snd then
				snd:Play("UI_Notify")
			end
		else
			step = nil
		end
		render()
	end)
	State.ShiftChanged:Connect(function(s)
		if not s then
			step = nil
		end
		render()
	end)
	State.LanguageChanged:Connect(render)
	local t0 = os.clock()
	RunService.Heartbeat:Connect(function()
		if step and State.inShift() then
			local target = nearestTagged(step.Target)
			local adornee = if target and target:IsA("Model") then target.PrimaryPart elseif target and target:IsA("BasePart") then target else nil
			arrow.Adornee = adornee
			arrow.Enabled = adornee ~= nil
			arrow.StudsOffset = Vector3.new(0, 6 + math.sin((os.clock() - t0) * 4) * 0.8, 0)
		else
			arrow.Enabled = false
		end
	end)
end

return TutorialController
