-- BubbleController: need bubbles over babies, mood rings under them, and screen-edge arrows pointing at
-- babies in a tantrum (or the one the player tapped in the baby list).
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needs = require(Shared.Config.Needs)
local Babies = require(Shared.Config.Babies)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local BubbleController = {}
local bubbles: { [Model]: any } = {}
local arrowGui: ScreenGui
local arrows: { [Model]: ImageLabel | TextLabel } = {}
local locateTarget: Model? = nil
local locateUntil = 0

local YELLOW = Color3.fromRGB(255, 220, 100)
local RED = Color3.fromRGB(240, 90, 90)

local function lowestNeed(model: Model): (string?, number)
	local list = model:GetAttribute("NeedList") or ""
	local best, bestV = nil, math.huge
	for n in string.gmatch(list, "[^,]+") do
		local v = model:GetAttribute("N_" .. n) or 100
		if v < bestV then
			best, bestV = n, v
		end
	end
	return best, bestV
end

local function inMySession(model: Model): boolean
	return State.Shift ~= nil and model:GetAttribute("Session") == State.Shift.Slot
end

local function setup(model: Model)
	if bubbles[model] or model:GetAttribute("Pet") then
		return
	end
	local root = model.PrimaryPart
	if not root then
		return
	end
	local adornee = root:FindFirstChild("HeadTop") or root
	local bb = Instance.new("BillboardGui")
	bb.Name = "NeedBubble"
	bb.Size = UDim2.fromOffset(54, 54)
	bb.StudsOffset = Vector3.new(0, if adornee == root then 3 else 1.4, 0)
	bb.MaxDistance = 120
	bb.LightInfluence = 0
	bb.Adornee = adornee
	bb.Enabled = false
	bb.Parent = root
	local bubble = Instance.new("Frame")
	bubble.Size = UDim2.fromScale(1, 1)
	bubble.BackgroundColor3 = YELLOW
	bubble.Parent = bb
	UI.corner(bubble, UDim.new(1, 0))
	UI.stroke(bubble, UI.Theme.Colors.Plum, 3)
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(0.8, 0.8)
	icon.Position = UDim2.fromScale(0.1, 0.1)
	icon.BackgroundTransparency = 1
	icon.TextScaled = true
	icon.Text = ""
	icon.Parent = bubble
	local scale = Instance.new("UIScale")
	scale.Parent = bubble
	-- mood ring (local only)
	local ring = Instance.new("Part")
	ring.Name = "MoodRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.08, 3.2, 3.2)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.55
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Anchored = true
	ring.CastShadow = false
	ring.Parent = workspace
	bubbles[model] = { BB = bb, Bubble = bubble, Icon = icon, Scale = scale, Ring = ring, Root = root }
	model.AncestryChanged:Connect(function(_, parent)
		if not parent then
			ring:Destroy()
			bubbles[model] = nil
			local a = arrows[model]
			if a then
				a:Destroy()
				arrows[model] = nil
			end
		end
	end)
end

function BubbleController:Locate(uid: string)
	for _, m in CollectionService:GetTagged("Baby") do
		if m:GetAttribute("Uid") == uid then
			locateTarget = m
			locateUntil = os.clock() + 5
		end
	end
end

local function arrowFor(model: Model)
	local a = arrows[model]
	if not a then
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromOffset(56, 56)
		l.AnchorPoint = Vector2.new(0.5, 0.5)
		l.BackgroundColor3 = RED
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.new(1, 1, 1)
		l.Parent = arrowGui
		UI.corner(l, UDim.new(1, 0))
		UI.stroke(l, Color3.new(1, 1, 1), 3)
		local def = Babies.Defs[model:GetAttribute("BabyId") or ""]
		l.Text = (def and def.Emoji or "!")
		arrows[model] = l
		a = l
	end
	return a
end

function BubbleController:Start()
	arrowGui = UI.screen("ArrowsGui", 3)
	local sc = arrowGui:FindFirstChildOfClass("UIScale")
	if sc then
		sc:Destroy() -- arrows use raw viewport pixels
	end
	for _, m in CollectionService:GetTagged("Baby") do
		if m:IsA("Model") then
			setup(m)
		end
	end
	CollectionService:GetInstanceAddedSignal("Baby"):Connect(function(m)
		if m:IsA("Model") then
			task.defer(setup, m)
		end
	end)
	local t0 = os.clock()
	RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local cam = workspace.CurrentCamera
		local vp = cam.ViewportSize
		local used = {}
		for model, b in bubbles do
			local mine = inMySession(model)
			local need, v = lowestNeed(model)
			local tantrum = (model:GetAttribute("Tantrum") or "") ~= ""
			local visible = model:GetAttribute("LocallyVisible") ~= false
			local anim = model:GetAttribute("Anim")
			local show = mine and visible and anim ~= "Frozen" and model:GetAttribute("State") ~= "Leaving" and (tantrum or v < Needs.Thresholds.Bubble)
			b.BB.Enabled = show
			if show then
				local needId = if tantrum then model:GetAttribute("Tantrum") else need
				local def = needId and Needs.Defs[needId]
				b.Icon.Text = if tantrum then "💢" .. (def and def.Emoji or "") else (def and def.Emoji or "?")
				local red = tantrum or v < Needs.Thresholds.Crying
				b.Bubble.BackgroundColor3 = if red then RED else YELLOW
				b.BB.AlwaysOnTop = red
				b.Scale.Scale = 1 + math.sin(t * (if red then 9 else 5)) * 0.08
			end
			-- mood ring
			local mood = model:GetAttribute("Mood") or 70
			b.Ring.Transparency = if mine and visible and model:GetAttribute("State") ~= "Leaving" then 0.55 else 1
			if mine then
				b.Ring.Color = if mood > 70 then Color3.fromRGB(120, 230, 140) elseif mood > 35 then YELLOW else RED
				local root = b.Root
				local offset = model:GetAttribute("FloorOffset") or 1.45
				b.Ring.CFrame = CFrame.new(root.Position - Vector3.new(0, offset * (model:GetAttribute("Scale") or 1) - 0.12, 0)) * CFrame.Angles(0, 0, math.rad(90))
			end
			-- edge arrows
			local wantArrow = mine and visible and (tantrum or (model == locateTarget and os.clock() < locateUntil))
			if wantArrow then
				local sp, onScreen = cam:WorldToViewportPoint(b.Root.Position)
				local isLocate = model == locateTarget and os.clock() < locateUntil
				if not onScreen or isLocate then
					local a = arrowFor(model)
					local x, y = sp.X, sp.Y
					if sp.Z < 0 then
						x, y = vp.X - x, vp.Y - y
					end
					x = math.clamp(x, 40, vp.X - 40)
					y = math.clamp(y, 60, vp.Y - 60)
					if onScreen and isLocate then
						y = math.max(60, y - 70)
					end
					a.Position = UDim2.fromOffset(x, y)
					a.BackgroundColor3 = if tantrum then RED else UI.Theme.Colors.Lavender
					a.Visible = true
					used[model] = true
				end
			end
		end
		for model, a in arrows do
			if not used[model] then
				a.Visible = false
			end
		end
	end)
	local _ = TweenService
end

return BubbleController
