-- EffectsController: all particle / beam / tween effects, built on the client from server signals and tags.
-- The server never creates particle spam itself; it sends Effect(name, payload) or sets tags/attributes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Recipes = require(Shared.Config.Recipes)
local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local EffectsController = {}
local Controllers

local TEX = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
}

local function quality(): number
	return if Controllers.SettingsController:Quality() == "Low" then 0.4 else 1
end

local function holder(pos: Vector3, size: Vector3?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = size or Vector3.one
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	return p
end

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Texture = TEX.Sparkle
	e.Rate = 0
	e.LightEmission = 0.3
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- One-shot burst at a position.
local function burst(pos: Vector3, count: number, props: { [string]: any }, life: number?)
	local h = holder(pos)
	local e = emitter(h, props)
	e:Emit(math.max(1, math.floor(count * quality())))
	Debris:AddItem(h, life or 3)
	return h
end

local function seq(a: number, b: number)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function textPop(pos: Vector3, text: string, color: Color3?, rise: number?)
	local h = holder(pos)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(60, 60)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = h
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.5
	t.Parent = bb
	TweenService:Create(h, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = h.CFrame + Vector3.new(0, rise or 3, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.2), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(h, 1.3)
end

local function ring(pos: Vector3, radius: number, color: Color3, time: number?)
	local p = holder(pos + Vector3.new(0, 0.3, 0))
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(0.2, 1, 1)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.3
	TweenService:Create(p, TweenInfo.new(time or 0.8, Enum.EasingStyle.Quad), { Size = Vector3.new(0.2, radius * 2, radius * 2), Transparency = 1 }):Play()
	Debris:AddItem(p, (time or 0.8) + 0.1)
end

-- Named effects -------------------------------------------------------------------------------

local handlers: { [string]: (any) -> () } = {}

handlers.Hearts = function(d)
	burst(d.Position, 6, { Texture = TEX.Sparkle, Color = ColorSequence.new(Color3.fromRGB(255, 120, 160)), Size = seq(0.6, 0.2), Speed = NumberRange.new(2, 4), Lifetime = NumberRange.new(0.8, 1.2), SpreadAngle = Vector2.new(40, 40), Acceleration = Vector3.new(0, 3, 0) })
	textPop(d.Position, "❤️", nil, 2.5)
end
handlers.Angry = function(d)
	burst(d.Position, 10, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(240, 240, 240)), Size = seq(1, 2), Transparency = seq(0.3, 1), Speed = NumberRange.new(1, 2), Lifetime = NumberRange.new(1, 1.5), SpreadAngle = Vector2.new(60, 60) })
	textPop(d.Position, "😡", nil, 1.5)
end
handlers.Scared = function(d)
	textPop(d.Position, "❗", Color3.fromRGB(255, 220, 90), 2)
end
handlers.Eat = function(d)
	burst(d.Position, 8, { Color = ColorSequence.new(Color3.fromRGB(255, 220, 160)), Size = seq(0.3, 0.1), Speed = NumberRange.new(3, 5), Lifetime = NumberRange.new(0.5, 0.8), SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, -20, 0) })
	local dish = Recipes.Dishes[d.Dish]
	textPop(d.Position + Vector3.new(0, 1, 0), dish and dish.Emoji or "😋", nil, 2)
end
handlers.Bubbles = function(d)
	burst(d.Position, 25, { Color = ColorSequence.new(Color3.fromRGB(220, 240, 255)), Size = seq(0.4, 0.7), Transparency = seq(0.2, 0.8), Speed = NumberRange.new(1, 3), Lifetime = NumberRange.new(1.5, 2.5), SpreadAngle = Vector2.new(80, 80), Acceleration = Vector3.new(0, 2, 0) }, 4)
end
handlers.Splash = function(d)
	burst(d.Position, 20, { Color = ColorSequence.new(Color3.fromRGB(110, 180, 255)), Size = seq(0.3, 0.1), Speed = NumberRange.new(4, 7), Lifetime = NumberRange.new(0.5, 0.9), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, -30, 0) })
end
handlers.Wail = function(d)
	ring(d.Position, d.Radius or 20, Color3.fromRGB(190, 150, 255), 1)
	task.delay(0.25, function()
		ring(d.Position, (d.Radius or 20) * 0.8, Color3.fromRGB(230, 200, 255), 0.9)
	end)
	textPop(d.Position + Vector3.new(0, 3, 0), "😭", nil, 2)
end
handlers.InkSpray = function(d)
	burst(d.Position, 30, { Color = ColorSequence.new(Color3.fromRGB(20, 15, 30)), Size = seq(0.6, 0.3), LightEmission = 0, Speed = NumberRange.new(6, 12), Lifetime = NumberRange.new(0.5, 0.9), SpreadAngle = Vector2.new(180, 40), Acceleration = Vector3.new(0, -30, 0) })
end
handlers.Stomp = function(d)
	ring(d.Position, 10, Color3.fromRGB(200, 180, 150), 0.6)
	burst(d.Position, 25, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(200, 185, 160)), Size = seq(1.5, 3), Transparency = seq(0.3, 1), Speed = NumberRange.new(5, 9), Lifetime = NumberRange.new(0.8, 1.2), SpreadAngle = Vector2.new(180, 10), LightEmission = 0 })
end
handlers.Sparks = function(d)
	burst(d.Position, 14, { Color = ColorSequence.new(Color3.fromRGB(255, 240, 120)), Size = seq(0.3, 0), Speed = NumberRange.new(6, 12), Lifetime = NumberRange.new(0.2, 0.5), SpreadAngle = Vector2.new(180, 180), LightEmission = 1 })
	-- little lightning beam
	local a = holder(d.Position)
	local b = holder(d.Position + Vector3.new(math.random(-3, 3), math.random(1, 3), math.random(-3, 3)))
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = a, b
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 160))
	beam.LightEmission = 1
	beam.Width0, beam.Width1 = 0.25, 0.05
	beam.CurveSize0 = math.random(-3, 3)
	beam.Parent = a
	Debris:AddItem(a, 0.2)
	Debris:AddItem(b, 0.2)
end
handlers.FrostBurst = function(d)
	ring(d.Position, d.Radius or 10, Color3.fromRGB(190, 235, 255), 0.7)
	burst(d.Position + Vector3.new(0, 1, 0), 30, { Color = ColorSequence.new(Color3.fromRGB(210, 245, 255)), Size = seq(0.4, 0.1), Speed = NumberRange.new(5, 10), Lifetime = NumberRange.new(0.6, 1), SpreadAngle = Vector2.new(180, 30) })
end
handlers.IceShatter = function(d)
	burst(d.Position + Vector3.new(0, 1.5, 0), 20, { Color = ColorSequence.new(Color3.fromRGB(200, 240, 255)), Size = seq(0.4, 0.2), Speed = NumberRange.new(5, 9), Lifetime = NumberRange.new(0.5, 0.9), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -30, 0) })
end
handlers.Puff = function(d)
	burst(d.Position, 12, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(255, 245, 255)), Size = seq(1, 2.5), Transparency = seq(0.2, 1), Speed = NumberRange.new(2, 4), Lifetime = NumberRange.new(0.6, 1), SpreadAngle = Vector2.new(180, 180), LightEmission = 0.2 })
end
handlers.Hatch = function(d)
	handlers.Puff(d)
	burst(d.Position, 30, { Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 160, 220)), Size = seq(0.5, 0), Speed = NumberRange.new(5, 10), Lifetime = NumberRange.new(0.8, 1.5), SpreadAngle = Vector2.new(180, 180), LightEmission = 1 })
	textPop(d.Position + Vector3.new(0, 2, 0), "🐣", nil, 3)
end
handlers.RootsGrow = function(d)
	burst(d.Position, 20, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(140, 110, 80)), Size = seq(1, 2), Transparency = seq(0.3, 1), Speed = NumberRange.new(2, 5), Lifetime = NumberRange.new(0.8, 1.2), SpreadAngle = Vector2.new(180, 20), LightEmission = 0 })
end
handlers.Leaves = function(d)
	burst(d.Position, 18, { Color = ColorSequence.new(Color3.fromRGB(120, 200, 100)), Size = seq(0.5, 0.3), Speed = NumberRange.new(3, 6), Lifetime = NumberRange.new(1, 1.6), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, -6, 0), RotSpeed = NumberRange.new(-180, 180), LightEmission = 0 })
end
handlers.Chomp = function(d)
	textPop(d.Position, "😋", nil, 1.5)
end
handlers.Sparkle = function(d)
	burst(d.Position, 16, { Color = ColorSequence.new(Color3.fromRGB(255, 240, 160)), Size = seq(0.5, 0), Speed = NumberRange.new(2, 5), Lifetime = NumberRange.new(0.6, 1), SpreadAngle = Vector2.new(180, 180), LightEmission = 1 })
end
handlers.Ding = function(d)
	textPop(d.Position, "🔔", nil, 2)
	handlers.Sparkle(d)
end
handlers.Fizz = function(d)
	burst(d.Position + Vector3.new(0, 1, 0), 18, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(230, 230, 235)), Size = seq(1.5, 4), Transparency = seq(0.2, 1), Speed = NumberRange.new(3, 6), Lifetime = NumberRange.new(1, 2), SpreadAngle = Vector2.new(30, 30), LightEmission = 0 })
end
handlers.Steam = handlers.Fizz
handlers.Tantrum = function(d)
	textPop(d.Position + Vector3.new(0, 3, 0), "💢", Color3.fromRGB(255, 80, 80), 2.5)
end
handlers.ChaosWarn = function(d)
	local model
	for _, m in CollectionService:GetTagged("Baby") do
		if m:GetAttribute("Uid") == d.Uid then
			model = m
		end
	end
	local root = model and model.PrimaryPart
	if not root or model:GetAttribute("LocallyVisible") == false then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(70, 70)
	bb.StudsOffset = Vector3.new(0, 4.4, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = root
	bb.LightInfluence = 0
	bb.Parent = player:WaitForChild("PlayerGui")
	local f = Instance.new("TextLabel")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.fromRGB(255, 120, 120)
	f.TextScaled = true
	f.Font = Enum.Font.FredokaOne
	f.Text = "❗" .. (d.Emoji or "")
	f.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = f
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = f
	TweenService:Create(scale, TweenInfo.new(d.Time or 1.5, Enum.EasingStyle.Linear), { Scale = 1.15 }):Play()
	Debris:AddItem(bb, (d.Time or 1.5) + 0.2)
	ring(root.Position - Vector3.new(0, 1.2, 0), 4, Color3.fromRGB(255, 110, 110), d.Time or 1.5)
end
handlers.GhostVanish = function(_d) end
handlers.InspectorNote = function(d)
	textPop(d.Position, "📝❗", Color3.fromRGB(255, 120, 120), 2)
end
handlers.Power = function(d)
	if not d.On then
		local cc = game:GetService("Lighting"):FindFirstChild("ColorCorrection") :: ColorCorrectionEffect?
		if cc then
			for _ = 1, 3 do
				cc.Brightness = -0.6
				task.wait(0.06)
				cc.Brightness = 0.1
				task.wait(0.06)
			end
			cc.Brightness = 0
		end
	end
end
handlers.Storm = function(_d) end
handlers.NetCatch = function(d)
	local a = holder(d.From + Vector3.new(0, 1, 0))
	local b = holder(d.To + Vector3.new(0, 1, 0))
	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = a, b
	local beam = Instance.new("Beam")
	beam.Attachment0, beam.Attachment1 = a0, a1
	beam.Color = ColorSequence.new(Color3.fromRGB(240, 240, 240))
	beam.Width0, beam.Width1 = 0.2, 1.5
	beam.Transparency = NumberSequence.new(0.3)
	beam.Parent = a
	Debris:AddItem(a, 0.35)
	Debris:AddItem(b, 0.35)
end
handlers.Toy = function(d)
	local baby
	for _, m in CollectionService:GetTagged("Baby") do
		if m:GetAttribute("Uid") == d.Uid then
			baby = m
		end
	end
	local root = baby and baby.PrimaryPart
	if not root then
		return
	end
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(0.9, 0.9, 0.9)
	ball.Color = Color3.fromHSV(math.random(), 0.5, 1)
	ball.CanCollide = false
	ball.CanQuery = false
	ball.Anchored = true
	ball.Parent = workspace
	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		if t > (d.Duration or 10) or not root.Parent then
			conn:Disconnect()
			ball:Destroy()
			return
		end
		ball.CFrame = root.CFrame * CFrame.new(math.sin(t * 4) * 1.5, math.abs(math.sin(t * 6)) * 1.5 - 0.6, -1.6)
	end)
end
handlers.Cooking = function(_d) end
handlers.LullabyNotes = function(d)
	local m = d.Model
	if not m or not m.Parent then
		return
	end
	local root = m.PrimaryPart
	if root and not root:FindFirstChild("Notes") then
		local e = emitter(root, { Name = "Notes", Color = ColorSequence.new(Color3.fromRGB(190, 160, 255)), Size = seq(0.5, 0.2), Rate = 3 * quality(), Speed = NumberRange.new(1, 2), Lifetime = NumberRange.new(2, 3), SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, 1, 0) })
		e.Name = "Notes"
	end
end
handlers.FireSneeze = function(d)
	local h = holder(d.Position)
	h.CFrame = CFrame.lookAt(d.Position, d.Position + d.Direction)
	local e = emitter(h, {
		Texture = TEX.Fire,
		Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 90, 40)),
		Size = seq(1.2, 2.5),
		Transparency = seq(0.1, 1),
		Speed = NumberRange.new(14, 18),
		Lifetime = NumberRange.new(0.4, 0.55),
		SpreadAngle = Vector2.new(18, 18),
		EmissionDirection = Enum.NormalId.Front,
		LightEmission = 1,
	})
	e:Emit(math.floor(40 * quality()))
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 150, 60)
	light.Range = 14
	light.Brightness = 3
	light.Parent = h
	Debris:AddItem(h, 1)
end
handlers.ToolUse = function(d)
	if d.Player ~= player then
		EffectsController:ToolSpray(d.Player, d.Tool)
	end
end

-- Tool spray from a character's held item.
function EffectsController:ToolSpray(p: Player, toolId: string)
	local char = p.Character
	local item = char and char:FindFirstChild("HeldItem")
	local handle = item and (item :: Model).PrimaryPart
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not handle or not root then
		return
	end
	local origin = handle.Position
	local cf = CFrame.lookAt(origin, origin + root.CFrame.LookVector)
	local h = holder(origin)
	h.CFrame = cf
	local props
	if toolId == "Extinguisher" then
		props = { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)), Size = seq(0.6, 2.5), Transparency = seq(0.1, 1), Speed = NumberRange.new(16, 22), Lifetime = NumberRange.new(0.4, 0.6), SpreadAngle = Vector2.new(15, 15), LightEmission = 0 }
	elseif toolId == "WateringCan" then
		props = { Color = ColorSequence.new(Color3.fromRGB(120, 190, 255)), Size = seq(0.3, 0.2), Speed = NumberRange.new(10, 14), Lifetime = NumberRange.new(0.5, 0.7), SpreadAngle = Vector2.new(10, 10), Acceleration = Vector3.new(0, -25, 0) }
	elseif toolId == "Mop" then
		h.CFrame = CFrame.new((root.CFrame * CFrame.new(0, -2.8, -3)).Position)
		props = { Color = ColorSequence.new(Color3.fromRGB(230, 245, 255)), Size = seq(0.4, 0.6), Transparency = seq(0.2, 1), Speed = NumberRange.new(1, 3), Lifetime = NumberRange.new(0.6, 1), SpreadAngle = Vector2.new(180, 30) }
		-- mop wiggle
		local w = handle:FindFirstChildWhichIsA("WeldConstraint")
		local _ = w
	else
		props = { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)), Size = seq(0.3, 0), Speed = NumberRange.new(4, 6), Lifetime = NumberRange.new(0.3, 0.4), SpreadAngle = Vector2.new(30, 30) }
	end
	props.EmissionDirection = Enum.NormalId.Front
	local e = emitter(h, props)
	e:Emit(math.floor(14 * quality()))
	Debris:AddItem(h, 1.2)
	if Controllers.SoundController then
		local map = { Extinguisher = "Tool_Extinguisher", Mop = "Tool_Mop", WateringCan = "Tool_Water", Net = "Tool_Net" }
		if map[toolId] then
			Controllers.SoundController:Play(map[toolId], origin)
		end
	end
end

function EffectsController:LocalToolUse(toolId: string)
	self:ToolSpray(player, toolId)
end

-- Tag-driven persistent visuals -----------------------------------------------------------------------

local function setupFire(part: BasePart)
	local fire = Instance.new("Fire")
	fire.Heat = 12
	fire.Size = 5
	fire.Color = Color3.fromRGB(255, 140, 50)
	fire.SecondaryColor = Color3.fromRGB(255, 220, 90)
	fire.Parent = part
	local smoke = emitter(part, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(60, 55, 55)), Size = seq(2, 5), Transparency = seq(0.4, 1), Rate = 4 * quality(), Speed = NumberRange.new(3, 5), Lifetime = NumberRange.new(2, 3), SpreadAngle = Vector2.new(15, 15), LightEmission = 0, EmissionDirection = Enum.NormalId.Top })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 140, 60)
	light.Range = 16
	light.Brightness = 2
	light.Shadows = false
	light.Parent = part
	local embers = emitter(part, { Color = ColorSequence.new(Color3.fromRGB(255, 200, 80)), Size = seq(0.2, 0), Rate = 8 * quality(), Speed = NumberRange.new(3, 6), Lifetime = NumberRange.new(0.8, 1.3), SpreadAngle = Vector2.new(25, 25), LightEmission = 1, EmissionDirection = Enum.NormalId.Top })
	local function update()
		local i = part:GetAttribute("Intensity") or 0.5
		fire.Size = 3 + i * 6
		smoke.Rate = (2 + i * 5) * quality()
		embers.Rate = (4 + i * 10) * quality()
	end
	part:GetAttributeChangedSignal("Intensity"):Connect(update)
	update()
	-- flicker
	task.spawn(function()
		while part.Parent do
			light.Brightness = 1.6 + math.random() * 1.2
			task.wait(0.08 + math.random() * 0.1)
		end
	end)
end

local function setupFireplace(part: BasePart)
	local fire = Instance.new("Fire")
	fire.Heat = 6
	fire.Size = 3
	fire.Color = Color3.fromRGB(255, 150, 60)
	fire.SecondaryColor = Color3.fromRGB(255, 230, 120)
	fire.Parent = part
end

-- Baby status visuals.
local function setupBaby(model: Model)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local visuals = {}
	local function clear(name)
		if visuals[name] then
			visuals[name]:Destroy()
			visuals[name] = nil
		end
	end
	local function refresh()
		local s = model:GetAttribute("Statuses") or ""
		local has = {}
		for name in string.gmatch(s, "[^,]+") do
			has[name] = true
		end
		if has.Burning and not visuals.Burning then
			local f = Instance.new("Fire")
			f.Size = 4
			f.Heat = 9
			f.Parent = root
			visuals.Burning = f
		elseif not has.Burning then
			clear("Burning")
		end
		if has.Frozen and not visuals.Frozen then
			local cube = Instance.new("Part")
			cube.Name = "IceCube"
			cube.Size = Vector3.new(3.4, 3.4, 3.4) * (model:GetAttribute("Scale") or 1)
			cube.Material = Enum.Material.Ice
			cube.Color = Color3.fromRGB(190, 235, 255)
			cube.Transparency = 0.35
			cube.CanCollide = false
			cube.CanQuery = false
			cube.Massless = true
			cube.Anchored = false
			cube.CFrame = root.CFrame
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = cube
			w.Parent = cube
			cube.Parent = model
			visuals.Frozen = cube
		elseif not has.Frozen then
			clear("Frozen")
		end
		if has.Wet and not visuals.Wet then
			visuals.Wet = emitter(root, { Color = ColorSequence.new(Color3.fromRGB(120, 190, 255)), Size = seq(0.2, 0.1), Rate = 6 * quality(), Speed = NumberRange.new(0, 1), Lifetime = NumberRange.new(0.5, 0.8), Acceleration = Vector3.new(0, -20, 0), SpreadAngle = Vector2.new(180, 180) })
		elseif not has.Wet then
			clear("Wet")
		end
		if (has.Inked or model:GetAttribute("Tint") == "Black") and not visuals.Ink then
			local hl = Instance.new("Highlight")
			hl.FillColor = Color3.fromRGB(20, 15, 30)
			hl.FillTransparency = 0.4
			hl.OutlineTransparency = 1
			hl.Parent = model
			visuals.Ink = hl
		elseif not has.Inked and model:GetAttribute("Tint") ~= "Black" then
			clear("Ink")
		end
		if has.Angry and not visuals.Angry then
			visuals.Angry = emitter(root, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(240, 240, 240)), Size = seq(0.6, 1.4), Transparency = seq(0.4, 1), Rate = 4 * quality(), Speed = NumberRange.new(1, 2), Lifetime = NumberRange.new(0.8, 1.2), EmissionDirection = Enum.NormalId.Top, LightEmission = 0 })
		elseif not has.Angry then
			clear("Angry")
		end
	end
	model:GetAttributeChangedSignal("Statuses"):Connect(refresh)
	model:GetAttributeChangedSignal("Tint"):Connect(refresh)
	refresh()
	-- Zzz while sleeping, hearts while very happy, tears when crying
	local zzz = emitter(root, { Color = ColorSequence.new(Color3.fromRGB(200, 210, 255)), Size = seq(0.5, 0.9), Transparency = seq(0, 1), Rate = 0, Speed = NumberRange.new(1, 1.5), Lifetime = NumberRange.new(1.5, 2), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(20, 20), LightEmission = 0.5 })
	local tears = emitter(root, { Color = ColorSequence.new(Color3.fromRGB(140, 200, 255)), Size = seq(0.25, 0.1), Rate = 0, Speed = NumberRange.new(2, 3), Lifetime = NumberRange.new(0.4, 0.6), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, -25, 0) })
	local function onAnim()
		local a = model:GetAttribute("Anim")
		zzz.Rate = if a == "Sleep" then 1.5 * quality() else 0
		tears.Rate = if a == "Cry" or a == "Tantrum" then 10 * quality() else 0
	end
	model:GetAttributeChangedSignal("Anim"):Connect(onAnim)
	onAnim()
	-- birthday hat
	local function birthday()
		clear("Birthday")
		if model:GetAttribute("Birthday") then
			local hat = Instance.new("Part")
			hat.Shape = Enum.PartType.Cylinder
			hat.Size = Vector3.new(1.2, 0.8, 0.8)
			hat.Color = Color3.fromRGB(255, 170, 200)
			hat.Material = Enum.Material.Neon
			hat.CanCollide = false
			hat.Massless = true
			hat.CFrame = root.CFrame * CFrame.new(0, 1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = hat
			w.Parent = hat
			hat.Parent = model
			visuals.Birthday = hat
		end
	end
	model:GetAttributeChangedSignal("Birthday"):Connect(birthday)
	birthday()
	-- ghost trail
	if model:GetAttribute("BabyId") == "Ghostie" then
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.6, 0)
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.6, 0)
		a1.Parent = root
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(Color3.fromRGB(220, 230, 255))
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		trail.Lifetime = 0.6
		trail.LightEmission = 0.7
		trail.Name = "GhostTrail"
		trail.Parent = root
	end
end

-- Appliance progress bubble + steam / smoke.
local function setupAppliance(model: Model)
	local slot = model:FindFirstChild("Slot") :: BasePart?
	if not slot then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "ApplianceGui"
	bb.Size = UDim2.fromOffset(120, 46)
	bb.StudsOffset = Vector3.new(0, 0.5, 0)
	bb.MaxDistance = 45
	bb.LightInfluence = 0
	bb.Parent = slot
	local icons = Instance.new("TextLabel")
	icons.Size = UDim2.new(1, 0, 0, 26)
	icons.BackgroundTransparency = 1
	icons.TextScaled = true
	icons.Text = ""
	icons.Parent = bb
	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.new(0.1, 0, 0, 30)
	barBg.Size = UDim2.new(0.8, 0, 0, 10)
	barBg.BackgroundColor3 = Color3.fromRGB(45, 38, 70)
	barBg.BorderSizePixel = 0
	barBg.Parent = bb
	Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = Color3.fromRGB(168, 230, 207)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	local steam = emitter(slot, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(245, 245, 250)), Size = seq(1, 3), Transparency = seq(0.5, 1), Rate = 0, Speed = NumberRange.new(2, 3), Lifetime = NumberRange.new(1.5, 2), EmissionDirection = Enum.NormalId.Top, LightEmission = 0 })
	local smoke = emitter(slot, { Texture = TEX.Smoke, Color = ColorSequence.new(Color3.fromRGB(30, 25, 25)), Size = seq(1.5, 4), Transparency = seq(0.2, 1), Rate = 0, Speed = NumberRange.new(3, 5), Lifetime = NumberRange.new(2, 3), EmissionDirection = Enum.NormalId.Top, LightEmission = 0 })
	local function refresh()
		local st = model:GetAttribute("State")
		local contents = model:GetAttribute("Contents") or ""
		local parts = {}
		for ing in string.gmatch(contents, "[^,]+") do
			local def = Recipes.Ingredients[ing]
			table.insert(parts, def and def.Emoji or "?")
		end
		local dish = model:GetAttribute("Dish") or ""
		if st == "Ready" and Recipes.Dishes[dish] then
			icons.Text = Recipes.Dishes[dish].Emoji .. " ✅"
		elseif st == "Burnt" then
			icons.Text = "💩 🔥"
		else
			icons.Text = table.concat(parts, " ")
		end
		barBg.Visible = st == "Cooking" or st == "Ready"
		fill.BackgroundColor3 = if st == "Ready" then Color3.fromRGB(255, 205, 60) else Color3.fromRGB(168, 230, 207)
		steam.Rate = if st == "Cooking" or st == "Ready" then 3 * quality() else 0
		smoke.Rate = if st == "Burnt" then 8 * quality() else 0
		bb.Enabled = icons.Text ~= "" or barBg.Visible
	end
	model:GetAttributeChangedSignal("State"):Connect(refresh)
	model:GetAttributeChangedSignal("Contents"):Connect(refresh)
	model:GetAttributeChangedSignal("Progress"):Connect(function()
		local p = model:GetAttribute("Progress") or 0
		fill.Size = UDim2.fromScale(if model:GetAttribute("State") == "Ready" then 1 else p, 1)
	end)
	refresh()
end

local function onTag(tag: string, fn: (Instance) -> ())
	for _, inst in CollectionService:GetTagged(tag) do
		task.spawn(fn, inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
end

function EffectsController:Init(c)
	Controllers = c
end

function EffectsController:Start()
	Remotes.event("Effect").OnClientEvent:Connect(function(name, payload)
		local fn = handlers[name]
		if fn then
			task.spawn(fn, payload or {})
		end
	end)
	onTag("Fire", function(p)
		if p:IsA("BasePart") then
			setupFire(p)
		end
	end)
	onTag("FireplaceFlame", function(p)
		if p:IsA("BasePart") then
			setupFireplace(p)
		end
	end)
	onTag("Baby", function(m)
		if m:IsA("Model") then
			setupBaby(m)
		end
	end)
	onTag("Appliance", function(m)
		if m:IsA("Model") then
			setupAppliance(m)
		end
	end)
	onTag("AmbientParticles", function(p)
		for _, e in p:GetChildren() do
			if e:IsA("ParticleEmitter") then
				e.Rate *= quality()
			end
		end
	end)
	-- bath bubbles drift up from tub water
	onTag("BathWater", function(p)
		if p:IsA("BasePart") then
			emitter(p, { Color = ColorSequence.new(Color3.fromRGB(230, 245, 255)), Size = seq(0.3, 0.6), Transparency = seq(0.3, 1), Rate = 2 * quality(), Speed = NumberRange.new(0.5, 1), Lifetime = NumberRange.new(2, 3), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(30, 30) })
		end
	end)
	local _ = State
end

return EffectsController
