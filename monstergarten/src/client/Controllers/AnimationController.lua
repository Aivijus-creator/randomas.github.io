-- AnimationController: plays real animations when a model has an Animator + ids, otherwise procedural
-- animations on the body joint (Idle, Walk, Cry, Tantrum, Eat, Sleep, Happy, Carried, Frozen, Chaos).
-- Also handles ghost visibility (hidden / blackout, revealed by any flashlight cone).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local MathUtil = require(Shared.Util.Math)

local AnimationController = {}
local entries: { [Model]: any } = {}

local function findJoint(model: Model): (JointInstance?, CFrame?)
	local root = model:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil, nil
	end
	local j = root:FindFirstChild("BodyJoint")
	if j and j:IsA("JointInstance") then
		return j, j.C0
	end
	for _, d in model:GetDescendants() do
		if d:IsA("Motor6D") and d.Part0 == root then
			return d, d.C0
		end
	end
	return nil, nil
end

local function animationId(model: Model, name: string): number?
	local folder = model:FindFirstChild("Animations")
	local a = folder and folder:FindFirstChild(name)
	if a and a:IsA("Animation") and a.AnimationId ~= "" then
		return -1 -- use the Animation object itself
	end
	local id = model:GetAttribute("BabyId")
	local per = id and Assets.Animations.Babies[id]
	local v = (per and per[name]) or Assets.Animations.BabyDefault[name]
	if v and v ~= 0 then
		return v
	end
	return nil
end

local function setup(model: Model)
	if entries[model] then
		return
	end
	local joint, baseC0 = findJoint(model)
	local animator = model:FindFirstChildWhichIsA("Animator", true)
	local entry = {
		Model = model,
		Joint = joint,
		BaseC0 = baseC0,
		Animator = animator,
		Tracks = {} :: { [string]: AnimationTrack },
		Current = nil :: string?,
		Phase = math.random() * 10,
		Body = nil :: BasePart?,
		BodySize = nil :: Vector3?,
		Highlight = nil :: Highlight?,
		Parts = {} :: { BasePart },
	}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			if d:GetAttribute("SquashPart") then
				entry.Body = d
				entry.BodySize = d.Size
			end
			if d.Name ~= "HumanoidRootPart" then
				table.insert(entry.Parts, d)
			end
		end
	end
	entries[model] = entry
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			entries[model] = nil
		end
	end)
end

local function playReal(entry, name: string): boolean
	local animator = entry.Animator :: Animator?
	if not animator then
		return false
	end
	local track = entry.Tracks[name]
	if not track then
		local id = animationId(entry.Model, name)
		if not id then
			return false
		end
		local anim: Animation
		if id == -1 then
			anim = entry.Model.Animations[name]
		else
			anim = Instance.new("Animation")
			anim.AnimationId = "rbxassetid://" .. tostring(id)
		end
		local ok, t = pcall(animator.LoadAnimation, animator, anim)
		if not ok then
			return false
		end
		track = t
		track.Looped = name ~= "Chaos" and name ~= "Eat" and name ~= "Happy"
		entry.Tracks[name] = track
	end
	if entry.Current ~= name then
		for n, t in entry.Tracks do
			if n ~= name and t.IsPlaying then
				t:Stop(0.2)
			end
		end
		track:Play(0.2)
		entry.Current = name
	end
	return true
end

local function procedural(entry, anim: string, t: number)
	local joint = entry.Joint
	if not joint or not entry.BaseC0 then
		return
	end
	local p = t + entry.Phase
	local offset = CFrame.new()
	local squash = 1
	local floatY = if entry.Model:GetAttribute("BabyId") == "Ghostie" then math.sin(p * 2) * 0.25 else 0
	if anim == "Idle" then
		offset = CFrame.new(0, math.sin(p * 2) * 0.06, 0)
		squash = 1 + math.sin(p * 2) * 0.03
	elseif anim == "Walk" then
		local hop = math.abs(math.sin(p * 9))
		offset = CFrame.new(0, hop * 0.55, 0) * CFrame.Angles(0, 0, math.sin(p * 9) * 0.12)
		squash = 1 + (0.5 - hop) * 0.18
	elseif anim == "Cry" then
		offset = CFrame.new(math.sin(p * 40) * 0.06, 0, 0) * CFrame.Angles(math.rad(-8), 0, 0)
	elseif anim == "Tantrum" then
		local hop = math.abs(math.sin(p * 16))
		offset = CFrame.new(math.sin(p * 30) * 0.1, hop * 0.7, 0) * CFrame.Angles(0, 0, math.sin(p * 16) * 0.25)
		squash = 1 + (0.5 - hop) * 0.25
	elseif anim == "Eat" then
		offset = CFrame.Angles(math.sin(p * 14) * 0.25, 0, 0)
	elseif anim == "Sleep" then
		offset = CFrame.new(0, math.sin(p * 1.2) * 0.04, 0) * CFrame.Angles(0, 0, math.rad(25))
		squash = 1 + math.sin(p * 1.2) * 0.04
	elseif anim == "Happy" then
		local cycle = p % 2.5
		if cycle < 0.6 then
			local k = cycle / 0.6
			offset = CFrame.new(0, math.sin(k * math.pi) * 1.1, 0) * CFrame.Angles(0, k * math.pi * 2, 0)
		else
			offset = CFrame.new(0, math.sin(p * 3) * 0.08, 0)
		end
	elseif anim == "Carried" then
		offset = CFrame.Angles(math.sin(p * 5) * 0.12, 0, math.sin(p * 3.5) * 0.15)
	elseif anim == "Frozen" then
		offset = CFrame.new()
	elseif anim == "Chaos" then
		local k = (p * 2) % 1
		offset = if k < 0.6 then CFrame.Angles(math.rad(-25) * (k / 0.6), 0, 0) else CFrame.Angles(math.rad(30), 0, 0)
	end
	joint.C0 = entry.BaseC0 * CFrame.new(0, floatY, 0) * offset
	if entry.Body and entry.BodySize then
		entry.Body.Size = Vector3.new(entry.BodySize.X / math.sqrt(squash), entry.BodySize.Y * squash, entry.BodySize.Z / math.sqrt(squash))
	end
	-- red tint during tantrums
	if anim == "Tantrum" and not entry.Highlight then
		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(255, 60, 60)
		hl.FillTransparency = 0.6
		hl.OutlineTransparency = 0.6
		hl.OutlineColor = Color3.fromRGB(255, 80, 80)
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = entry.Model
		entry.Highlight = hl
	elseif anim ~= "Tantrum" and entry.Highlight then
		entry.Highlight:Destroy()
		entry.Highlight = nil
	end
end

-- Ghost visibility --------------------------------------------------------------------------

local function revealedByFlashlight(pos: Vector3): boolean
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("FlashlightOn") then
			local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if r then
				local range = (p:GetAttribute("FlashlightRange") or 30) + 2
				local angle = (p:GetAttribute("FlashlightAngle") or 22) + 6
				if MathUtil.inCone(r.Position, r.CFrame.LookVector, pos, range, angle) then
					return true
				end
			end
		end
	end
	return false
end

function AnimationController:IsGhostVisible(model: Model): boolean
	local root = model.PrimaryPart
	if not root then
		return true
	end
	local hidden = model:GetAttribute("Hidden") == true
	local dc = model:FindFirstAncestorWhichIsA("Model")
	while dc and not dc.Name:match("^Daycare_") do
		dc = dc:FindFirstAncestorWhichIsA("Model")
	end
	local dark = dc ~= nil and dc:GetAttribute("PowerOn") == false
	if not hidden and not dark then
		return true
	end
	return revealedByFlashlight(root.Position)
end

local function updateGhost(entry)
	local model = entry.Model
	local visible = AnimationController:IsGhostVisible(model)
	local target = if visible then 0 else 0.95
	if entry.GhostT ~= target then
		entry.GhostT = target
		for _, p in entry.Parts do
			p.LocalTransparencyModifier = target
		end
		local tag = model:FindFirstChild("NameTag", true)
		if tag and tag:IsA("BillboardGui") then
			tag.Enabled = visible
		end
		local trail = model:FindFirstChild("GhostTrail", true)
		if trail and trail:IsA("Trail") then
			trail.Enabled = visible or model:GetAttribute("Hidden") == true
		end
	end
	model:SetAttribute("LocallyVisible", visible)
end

function AnimationController:Start()
	for _, tag in { "Baby", "PetModel" } do
		for _, m in CollectionService:GetTagged(tag) do
			if m:IsA("Model") then
				setup(m)
			end
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(m)
			if m:IsA("Model") then
				task.defer(setup, m)
			end
		end)
	end
	local t0 = os.clock()
	RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local cam = workspace.CurrentCamera
		local camPos = cam and cam.CFrame.Position or Vector3.zero
		for model, entry in entries do
			local root = model.PrimaryPart
			if root and (root.Position - camPos).Magnitude < 160 then
				local anim = model:GetAttribute("Anim") or "Idle"
				if not playReal(entry, anim) then
					procedural(entry, anim, t)
				end
				if model:GetAttribute("BabyId") == "Ghostie" and not model:GetAttribute("Pet") then
					updateGhost(entry)
				end
			end
		end
	end)
end

return AnimationController
