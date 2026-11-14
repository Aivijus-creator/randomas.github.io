-- CameraController: camera shake (setting-aware), hides daycare ceilings while inside, zoom limits.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local CameraController = { Locked = false }
local Controllers
local shake = 0

function CameraController:Shake(intensity: number, pos: Vector3?, radius: number?)
	local settings = Controllers.SettingsController.Settings
	if settings.CameraShake == false then
		return
	end
	if pos and radius then
		local c = player.Character
		local r = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not r or (r.Position - pos).Magnitude > radius then
			return
		end
	end
	shake = math.max(shake, intensity)
end

local function setCeilings(hidden: boolean)
	for _, c in CollectionService:GetTagged("Ceiling") do
		if c:IsA("BasePart") then
			c.LocalTransparencyModifier = if hidden then 1 else 0
		end
	end
end

function CameraController:Init(c)
	Controllers = c
end

function CameraController:Start()
	Remotes.event("CameraShake").OnClientEvent:Connect(function(i, pos, radius)
		self:Shake(i, pos, radius)
	end)
	CollectionService:GetInstanceAddedSignal("Ceiling"):Connect(function(c)
		if State.inShift() and c:IsA("BasePart") then
			c.LocalTransparencyModifier = 1
		end
	end)
	State.ShiftChanged:Connect(function(shift)
		setCeilings(shift ~= nil)
		player.CameraMaxZoomDistance = if shift then 32 else 40
	end)
	RunService:BindToRenderStep("MonstergartenShake", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if shake > 0.01 and not self.Locked then
			local cam = workspace.CurrentCamera
			local t = os.clock() * 40
			cam.CFrame = cam.CFrame * CFrame.Angles(math.noise(t, 0) * shake * 0.05, math.noise(0, t) * shake * 0.05, 0)
			shake = math.max(0, shake - dt * 2)
		end
	end)
end

return CameraController
