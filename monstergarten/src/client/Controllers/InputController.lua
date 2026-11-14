-- InputController: drop (Q / ButtonB), use tool (LMB / R2, hold to repeat), run (Shift / L3),
-- movement speed modifiers (carrying, bandage trails) and slipping on puddles.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local GameSettings = require(Shared.Config.GameSettings)
local Tools = require(Shared.Config.Tools)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local InputController = { Running = false, UsingHeld = false }
local lastUse = 0
local slipVel = Vector3.zero

local function root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function InputController:Drop()
	if State.inShift() and State.Held then
		Remotes.event("DropHeld"):FireServer()
	end
end

function InputController:UseOnce()
	local held = State.Held
	if not State.inShift() or not held or held.Kind ~= "Tool" then
		return
	end
	local def = Tools.Defs[held.Id]
	if not def or def.Use == "Prompt" or def.Use == "Place" then
		return
	end
	if self.Running and def.Use == "Cone" then
		return -- no tools while running
	end
	local now = os.clock()
	if now - lastUse < 0.2 then
		return
	end
	lastUse = now
	local r = root()
	Remotes.event("UseTool"):FireServer(r and r.CFrame.LookVector or Vector3.new(0, 0, -1), true)
	local fx = State.Controllers.EffectsController
	if fx and fx.LocalToolUse then
		fx:LocalToolUse(held.Id)
	end
end

function InputController:SetUsing(on: boolean)
	self.UsingHeld = on
	if on then
		self:UseOnce()
	end
end

function InputController:SetRunning(on: boolean)
	self.Running = on
end

local function isTyping(): boolean
	return UserInputService:GetFocusedTextBox() ~= nil
end

function InputController:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if isTyping() then
			return
		end
		local kc = input.KeyCode
		if kc == Enum.KeyCode.Q or kc == Enum.KeyCode.ButtonB then
			self:Drop()
		elseif kc == Enum.KeyCode.LeftShift or kc == Enum.KeyCode.ButtonL3 then
			self:SetRunning(if kc == Enum.KeyCode.ButtonL3 then not self.Running else true)
		elseif kc == Enum.KeyCode.ButtonR2 then
			self:SetUsing(true)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not processed then
			self:SetUsing(true)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local kc = input.KeyCode
		if kc == Enum.KeyCode.LeftShift then
			self:SetRunning(false)
		elseif kc == Enum.KeyCode.ButtonR2 or input.UserInputType == Enum.UserInputType.MouseButton1 then
			self:SetUsing(false)
		end
	end)

	local trailParams = OverlapParams.new()
	trailParams.FilterType = Enum.RaycastFilterType.Include
	RunService.Heartbeat:Connect(function(dt)
		if self.UsingHeld then
			local held = State.Held
			local def = held and held.Kind == "Tool" and Tools.Defs[held.Id]
			if def and def.Use == "Cone" then
				self:UseOnce()
			end
		end
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local r = root()
		if not hum or not r then
			return
		end
		local speed = if self.Running then GameSettings.RunSpeed else GameSettings.WalkSpeed
		local slow = player:GetAttribute("HeldSlow") or 0
		speed *= (1 - slow)
		-- bandage trails and slippery puddles (only in a shift)
		local slippery = false
		if State.inShift() then
			local pos = r.Position
			for _, t in CollectionService:GetTagged("BandageTrail") do
				if t:IsA("BasePart") and (t.Position - pos).Magnitude < 3.2 and math.abs(t.Position.Y - (pos.Y - 3)) < 2 then
					speed *= 0.5
					break
				end
			end
			for _, p in CollectionService:GetTagged("Puddle") do
				if p:IsA("BasePart") and p:GetAttribute("Slippery") then
					local flat = Vector3.new(p.Position.X - pos.X, 0, p.Position.Z - pos.Z).Magnitude
					if flat < p.Size.Y / 2 and math.abs(p.Position.Y - (pos.Y - 3)) < 2.5 then
						slippery = true
						break
					end
				end
			end
		end
		hum.WalkSpeed = speed
		-- slip: keep sliding in the previous direction
		local vel = r.AssemblyLinearVelocity
		local flatVel = Vector3.new(vel.X, 0, vel.Z)
		if slippery then
			slipVel = slipVel:Lerp(flatVel, math.min(1, dt * 1.5))
			if slipVel.Magnitude > 2 then
				r.AssemblyLinearVelocity = Vector3.new(slipVel.X, vel.Y, slipVel.Z)
			end
		else
			slipVel = flatVel
		end
	end)
end

return InputController
