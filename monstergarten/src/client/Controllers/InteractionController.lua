-- InteractionController: shows only the prompts that make sense for what you hold, renders them in the
-- custom bubble style (with a hold ring + touch support), and opens lobby windows from lobby prompts.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared.Strings)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local InteractionController = {}
local Controllers
local original: { [ProximityPrompt]: number } = {}
local shown: { [ProximityPrompt]: BillboardGui } = {}

local function matches(need: string?, held: any): boolean
	if not need or need == "" or need == "Any" then
		return true
	end
	for token in string.gmatch(need, "[^,]+") do
		if token == "Empty" and held == nil then
			return true
		elseif token == "Baby" and held and held.Kind == "Baby" then
			return true
		elseif held then
			local kind, id = token:match("^(%w+):(%w+)$")
			if kind == "Kind" and held.Kind == id then
				return true
			elseif kind and kind ~= "Kind" and held.Kind == kind and held.Id == id then
				return true
			end
		end
	end
	return false
end

local function visibleFor(prompt: ProximityPrompt): boolean
	if not matches(prompt:GetAttribute("NeedHeld"), State.Held) then
		return false
	end
	if prompt:GetAttribute("NeedsReveal") then
		local model = prompt:FindFirstAncestorWhichIsA("Model")
		if model and model:GetAttribute("LocallyVisible") == false then
			return false
		end
	end
	-- don't offer to pick up / feed the baby you are carrying
	local uid = player:GetAttribute("HeldUid")
	if uid then
		local model = prompt:FindFirstAncestorWhichIsA("Model")
		if model and model:GetAttribute("Uid") == uid then
			return false
		end
	end
	return true
end

local function refreshOne(prompt: ProximityPrompt)
	if not original[prompt] then
		original[prompt] = prompt.MaxActivationDistance
	end
	prompt.MaxActivationDistance = if visibleFor(prompt) then original[prompt] else 0
end

function InteractionController:Refresh()
	for prompt in original do
		if prompt.Parent then
			refreshOne(prompt)
		else
			original[prompt] = nil
		end
	end
end

local function promptText(prompt: ProximityPrompt): (string, string)
	local action = prompt:GetAttribute("Action") or ""
	local key = "Prompt_" .. action
	local text = if Strings.has(key) then Strings.t(key) else prompt.ActionText
	local obj = prompt.ObjectText
	if obj ~= "" then
		obj = Strings.msg({ "Name_Generic", obj })
	end
	return text, obj
end

local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string
	if inputType == Enum.ProximityPromptInputType.Gamepad then
		local k = prompt.GamepadKeyCode.Name
		return (k:gsub("^Button", ""))
	elseif inputType == Enum.ProximityPromptInputType.Touch then
		return "👆"
	end
	return prompt.KeyboardKeyCode.Name
end

local function show(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local pg = player:WaitForChild("PlayerGui")
	local bb = Instance.new("BillboardGui")
	bb.Name = "PromptUI"
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(230, 64)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.LightInfluence = 0
	bb.Adornee = prompt.Parent :: any
	bb.ResetOnSpawn = false
	bb.Active = true
	bb.Parent = pg
	local frame = UI.new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Cream, BackgroundTransparency = 0.05, Parent = bb })
	UI.corner(frame, UDim.new(1, 0))
	UI.stroke(frame, C.Plum, 3)
	local keyBtn = UI.new("TextButton", {
		Size = UDim2.fromOffset(50, 50),
		Position = UDim2.fromOffset(7, 7),
		BackgroundColor3 = C.Mint,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextColor3 = C.Plum,
		Text = keyLabel(prompt, inputType),
		AutoButtonColor = false,
		Parent = frame,
	})
	UI.corner(keyBtn, UDim.new(1, 0))
	UI.stroke(keyBtn, C.Plum, 2)
	local ring = UI.new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.Yellow, BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 0, Parent = frame })
	UI.corner(ring, UDim.new(1, 0))
	local text, obj = promptText(prompt)
	UI.new("TextLabel", {
		Position = UDim2.fromOffset(64, 6),
		Size = UDim2.new(1, -74, 0, 30),
		BackgroundTransparency = 1,
		Font = Enum.Font.FredokaOne,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Plum,
		Text = text,
		Parent = frame,
	})
	UI.new("TextLabel", {
		Position = UDim2.fromOffset(64, 36),
		Size = UDim2.new(1, -74, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = C.Plum,
		TextTransparency = 0.3,
		Text = obj,
		Parent = frame,
	})
	local holdTween: Tween? = nil
	local c1 = prompt.PromptButtonHoldBegan:Connect(function()
		if prompt.HoldDuration > 0 then
			ring.Size = UDim2.fromScale(0, 1)
			holdTween = TweenService:Create(ring, TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1, 1) })
			holdTween:Play()
		end
	end)
	local c2 = prompt.PromptButtonHoldEnded:Connect(function()
		if holdTween then
			holdTween:Cancel()
		end
		ring.Size = UDim2.fromScale(0, 1)
	end)
	local c3 = prompt.Triggered:Connect(function()
		frame.BackgroundColor3 = C.Mint
		task.delay(0.15, function()
			frame.BackgroundColor3 = C.Cream
		end)
	end)
	if inputType == Enum.ProximityPromptInputType.Touch or prompt.ClickablePrompt then
		keyBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				prompt:InputHoldBegin()
			end
		end)
		keyBtn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				prompt:InputHoldEnd()
			end
		end)
	end
	local scale = UI.new("UIScale", { Scale = 0.5, Parent = frame })
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	bb.Destroying:Connect(function()
		c1:Disconnect()
		c2:Disconnect()
		c3:Disconnect()
	end)
	shown[prompt] = bb
end

local function hide(prompt: ProximityPrompt)
	local bb = shown[prompt]
	if bb then
		bb:Destroy()
		shown[prompt] = nil
	end
end

function InteractionController:Init(c)
	Controllers = c
end

function InteractionController:Start()
	local function add(p)
		if p:IsA("ProximityPrompt") then
			refreshOne(p)
		end
	end
	for _, p in CollectionService:GetTagged("MGPrompt") do
		add(p)
	end
	CollectionService:GetInstanceAddedSignal("MGPrompt"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("MGPrompt"):Connect(function(p)
		original[p] = nil
		hide(p)
	end)
	State.HeldChanged:Connect(function()
		self:Refresh()
	end)
	-- ghost reveal changes continuously; refresh a few times a second
	task.spawn(function()
		while true do
			task.wait(0.25)
			self:Refresh()
		end
	end)
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style == Enum.ProximityPromptStyle.Custom then
			show(prompt, inputType)
		end
	end)
	ProximityPromptService.PromptHidden:Connect(hide)
	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local action = prompt:GetAttribute("Action")
		if action == "OpenShop" then
			Controllers.ShopController:Open()
		elseif action == "OpenWardrobe" then
			Controllers.WardrobeController:Open()
		elseif action == "OpenPets" then
			Controllers.PetController:Open()
		elseif action == "OpenDaily" then
			Controllers.HUDController:OpenDaily()
		end
	end)
	local _ = UserInputService
end

return InteractionController
