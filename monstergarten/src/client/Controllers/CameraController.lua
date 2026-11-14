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

local HIDE_TAGS = { "Ceiling", "CeilingDecor", "Roof" }
local hiddenNow: boolean? = nil
local function setCeilings(hidden: boolean)
	if hiddenNow == hidden then
		return
	end
	hiddenNow = hidden
	for _, tag in HIDE_TAGS do
		for _, inst in CollectionService:GetTagged(tag) do
			local parts = if inst:IsA("BasePart") then { inst } else inst:GetDescendants()
			for _, p in parts do
				if p:IsA("BasePart") then
					p.LocalTransparencyModifier = if hidden then 1 else 0
				end
			end
		end
	end
end

-- Is the local player inside a room of their daycare (not the yard / front yard)?
local function indoors(): boolean
	local shift = State.Shift
	local dc = workspace:FindFirstChild("Daycares")
	local m = shift and dc and dc:FindFirstChild("Daycare_" .. tostring(shift.Slot))
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not m or not r then
		return false
	end
	local vols = m:FindFirstChild("RoomVolumes")
	for _, v in (vols and vols:GetChildren() or {}) do
		if v:IsA("BasePart") then
			local rel = v.CFrame:PointToObjectSpace(r.Position)
			local h = v.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z then
				local name = v:GetAttribute("RoomName")
				return name ~= "Yard" and name ~= "Outside" and name ~= "Front"
			end
		end
	end
	return false
end

function CameraController:Init(c)
	Controllers = c
end

function CameraController:Start()
	Remotes.event("CameraShake").OnClientEvent:Connect(function(i, pos, radius)
		self:Shake(i, pos, radius)
	end)
	for _, tag in HIDE_TAGS do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function()
			hiddenNow = nil -- re-apply on the next check (streamed-in parts)
		end)
	end
	State.ShiftChanged:Connect(function(shift)
		player.CameraMaxZoomDistance = if shift then 32 else 40
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			local cut = Controllers.CutsceneController
			setCeilings(State.inShift() and indoors() and not (cut and cut.Active))
		end
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
