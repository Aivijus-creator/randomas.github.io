-- MobileController: on-screen buttons for touch devices (Use, Drop, Run).
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tools = require(Shared.Config.Tools)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local C = UI.Theme.Colors
local MobileController = {}
local Controllers
local gui

local function roundButton(text: string, color: Color3, pos: UDim2, size: number)
	local b = UI.button(text, color, nil, {
		Size = UDim2.fromOffset(size, size),
		Position = pos,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = gui,
	})
	UI.corner(b, UDim.new(1, 0))
	return b
end

function MobileController:Init(c)
	Controllers = c
end

function MobileController:Start()
	if not UserInputService.TouchEnabled then
		return
	end
	gui = UI.screen("MobileGui", 5)
	local use = roundButton("👆", C.Mint, UDim2.new(1, -110, 1, -230), 86)
	local drop = roundButton("⬇️", C.Peach, UDim2.new(1, -205, 1, -160), 66)
	local run = roundButton("🏃", C.Lavender, UDim2.new(1, -60, 1, -320), 62)
	use.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			Controllers.InputController:SetUsing(true)
		end
	end)
	use.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			Controllers.InputController:SetUsing(false)
		end
	end)
	drop.Activated:Connect(function()
		Controllers.InputController:Drop()
	end)
	run.Activated:Connect(function()
		local ic = Controllers.InputController
		ic:SetRunning(not ic.Running)
		run.BackgroundColor3 = if ic.Running then C.Yellow else C.Lavender
	end)
	local function refresh()
		local inShift = State.inShift()
		local held = State.Held
		local def = held and held.Kind == "Tool" and Tools.Defs[held.Id]
		use.Visible = inShift and def ~= nil and def.Use ~= "Prompt" and def.Use ~= "Place"
		use.Text = if def then def.Emoji else "👆"
		drop.Visible = inShift and held ~= nil
		run.Visible = true
	end
	State.HeldChanged:Connect(refresh)
	State.ShiftChanged:Connect(refresh)
	refresh()
end

return MobileController
