-- DebugController: F2 opens the debug menu (Studio / creator / whitelisted users only; the server re-checks).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Babies = require(Shared.Config.Babies)
local Events = require(Shared.Config.Events)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local DebugController = {}
local window
local showAI = false
local labels: { [Model]: BillboardGui } = {}

local function cmd(name: string, ...)
	Remotes.event("DebugCommand"):FireServer(name, ...)
end

local function section(parent: Instance, order: number, title: string)
	local f = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = parent })
	UI.label(title, { Size = UDim2.new(1, 0, 0, 26), TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
	local row = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = f })
	UI.grid(row, UDim2.fromOffset(120, 36), 6)
	return row
end

local function small(parent: Instance, text: string, fn: () -> ())
	UI.button(text, C.Lavender, fn, { Size = UDim2.fromOffset(120, 36), Parent = parent })
end

function DebugController:Init()
	local gui = UI.screen("DebugGui", 40)
	window = UI.window(gui, "Debug_Title", UDim2.fromOffset(820, 560), C.Mint)
	local scroll = UI.scroll(window.Content)
	UI.list(scroll, 10)
	local babies = section(scroll, 1, "Spawn baby")
	for _, id in Babies.Order do
		small(babies, Babies.Defs[id].Emoji .. " " .. id, function()
			cmd("SpawnBaby", id)
		end)
	end
	local needs = section(scroll, 2, "Set all needs")
	for _, v in { 0, 10, 30, 50, 100 } do
		small(needs, tostring(v), function()
			cmd("SetNeeds", v)
		end)
	end
	local events = section(scroll, 3, "Trigger event")
	for _, id in Events.Order do
		small(events, Events.Defs[id].Emoji .. " " .. id, function()
			cmd("TriggerEvent", id)
		end)
	end
	local misc = section(scroll, 4, "Misc")
	small(misc, "Time x1", function()
		cmd("TimeScale", 1)
	end)
	small(misc, "Time x5", function()
		cmd("TimeScale", 5)
	end)
	small(misc, "+1000 🪙", function()
		cmd("AddCoins", 1000)
	end)
	small(misc, "+10 ⭐", function()
		cmd("AddStars", 10)
	end)
	small(misc, "Unlock all", function()
		cmd("UnlockAll")
	end)
	small(misc, "AI labels", function()
		showAI = not showAI
		cmd("ShowAI", showAI)
	end)
	small(misc, "End shift", function()
		cmd("EndShift")
	end)
	small(misc, "Power off", function()
		cmd("PowerOff")
	end)
	small(misc, "Reset data", function()
		cmd("ResetData")
	end)
	local friends = section(scroll, 5, "Friendship = 5")
	for _, id in Babies.Order do
		small(friends, Babies.Defs[id].Emoji, function()
			cmd("Friendship", id)
		end)
	end
end

function DebugController:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.F2 and not processed and player:GetAttribute("DebugAllowed") then
			window.Toggle()
		end
	end)
	-- AI state labels
	task.spawn(function()
		while true do
			task.wait(0.5)
			local on = workspace:GetAttribute("DebugAI") == true
			for _, m in CollectionService:GetTagged("Baby") do
				local root = m.PrimaryPart
				if on and root and not labels[m] then
					local bb = Instance.new("BillboardGui")
					bb.Size = UDim2.fromOffset(160, 24)
					bb.StudsOffset = Vector3.new(0, 4.5, 0)
					bb.AlwaysOnTop = true
					bb.Adornee = root
					bb.Parent = player:WaitForChild("PlayerGui")
					local t = Instance.new("TextLabel")
					t.Size = UDim2.fromScale(1, 1)
					t.BackgroundTransparency = 0.4
					t.TextScaled = true
					t.Font = Enum.Font.Code
					t.Parent = bb
					labels[m] = bb
				end
				local bb = labels[m]
				if bb then
					bb.Enabled = on and m.Parent ~= nil
					local t = bb:FindFirstChildOfClass("TextLabel")
					if t then
						t.Text = tostring(m:GetAttribute("DebugState") or "")
					end
				end
			end
			for m, bb in labels do
				if not m.Parent then
					bb:Destroy()
					labels[m] = nil
				end
			end
		end
	end)
end

return DebugController
