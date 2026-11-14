-- Procedural placeholder models for babies / parents / NPCs (used until the author drops in real models).
-- Contract (same as for author models): PrimaryPart "HumanoidRootPart", optional Attachments HeadTop/Mouth/Hands.
-- The visible body hangs off the root via a Weld named "BodyJoint" so the client can animate it procedurally.
local Babies = require(script.Parent.Parent.Config.Babies)

local Placeholders = {}

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(25, 25, 30)

local function newPart(className: string, props: { [string]: any }): BasePart
	local p = Instance.new(className) :: BasePart
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function ball(parent: Instance, d: number, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = newPart("Part", { Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = cf, Color = color, Name = "Ball" })
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function block(parent: Instance, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = newPart("Part", { Size = size, CFrame = cf, Color = color, Name = "Block" })
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function wedge(parent: Instance, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = newPart("WedgePart", { Size = size, CFrame = cf, Color = color, Name = "Wedge" })
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function cyl(parent: Instance, length: number, d: number, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = newPart("Part", { Shape = Enum.PartType.Cylinder, Size = Vector3.new(length, d, d), CFrame = cf, Color = color, Name = "Cyl" })
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function eyes(model: Model, body: BasePart, c: CFrame, spread: number, size: number, single: boolean?)
	local positions = if single then { 0 } else { -spread, spread }
	for i, x in positions do
		local eye = ball(model, size, c * CFrame.new(x, 0.25, -0.95), WHITE, { Name = "Eye" .. i })
		weld(body, eye)
		local pupil = ball(model, size * 0.5, c * CFrame.new(x, 0.25, -0.95 - size * 0.38), BLACK, { Name = "Pupil" .. i })
		weld(body, pupil)
		local shine = ball(model, size * 0.18, c * CFrame.new(x + size * 0.12, 0.25 + size * 0.15, -0.95 - size * 0.48), WHITE, { Name = "Shine" .. i, Material = Enum.Material.Neon })
		weld(body, shine)
	end
end

local function mouth(model: Model, body: BasePart, c: CFrame, color: Color3?)
	local m = block(model, Vector3.new(0.5, 0.12, 0.1), c * CFrame.new(0, -0.3, -1.08), color or Color3.fromRGB(120, 40, 60), { Name = "Mouth" })
	weld(body, m)
	return m
end

local function feet(model: Model, body: BasePart, c: CFrame, color: Color3)
	for _, x in { -0.55, 0.55 } do
		local f = ball(model, 0.75, c * CFrame.new(x, -1.05, -0.1), color:Lerp(BLACK, 0.15), { Name = "Foot" })
		weld(body, f)
	end
end

local features: { [string]: (Model, BasePart, CFrame, Color3) -> () } = {}

features.Dragling = function(m, body, c, col)
	for _, x in { -0.45, 0.45 } do
		local horn = wedge(m, Vector3.new(0.25, 0.6, 0.4), c * CFrame.new(x, 1.15, 0.1), Color3.fromRGB(255, 230, 170), { Name = "Horn" })
		weld(body, horn)
	end
	for _, s in { -1, 1 } do
		local wing = wedge(m, Vector3.new(0.12, 0.9, 1.1), c * CFrame.new(s * 1.15, 0.35, 0.35) * CFrame.Angles(0, 0, s * math.rad(-25)), col:Lerp(Color3.fromRGB(255, 80, 80), 0.4), { Name = "Wing" })
		weld(body, wing)
	end
	local belly = ball(m, 1.5, c * CFrame.new(0, -0.25, -0.45), Color3.fromRGB(255, 220, 170), { Name = "Belly" })
	weld(body, belly)
	local tail = wedge(m, Vector3.new(0.3, 0.4, 1), c * CFrame.new(0, -0.6, 1.3) * CFrame.Angles(math.rad(20), math.pi, 0), col, { Name = "Tail" })
	weld(body, tail)
end

features.Slimy = function(m, body, c, col)
	body.Transparency = 0.25
	body.Material = Enum.Material.Glass
	for i = 1, 3 do
		local drip = ball(m, 0.4, c * CFrame.new(-0.6 + i * 0.3, -0.95, -0.4 + (i % 2) * 0.3), col, { Name = "Drip", Transparency = 0.25, Material = Enum.Material.Glass })
		weld(body, drip)
	end
	local core = ball(m, 0.8, c * CFrame.new(0.3, -0.2, 0.2), col:Lerp(WHITE, 0.4), { Name = "Core", Transparency = 0.4 })
	weld(body, core)
end

features.Ghostie = function(m, body, c, col)
	body.Transparency = 0.15
	local skirt = cyl(m, 1, 2.1, c * CFrame.new(0, -0.6, 0) * CFrame.Angles(0, 0, math.rad(90)), col, { Name = "Skirt", Transparency = 0.15 })
	weld(body, skirt)
	for i = 0, 4 do
		local a = i * math.pi * 2 / 5
		local wisp = ball(m, 0.55, c * CFrame.new(math.cos(a) * 0.75, -1.15, math.sin(a) * 0.75), col, { Name = "Wisp", Transparency = 0.15 })
		weld(body, wisp)
	end
	local cheek = ball(m, 0.3, c * CFrame.new(0.65, -0.05, -0.85), Color3.fromRGB(255, 180, 200), { Name = "Cheek" })
	weld(body, cheek)
end

features.Vampy = function(m, body, c, col)
	for _, s in { -1, 1 } do
		local wing = wedge(m, Vector3.new(0.12, 0.8, 1.2), c * CFrame.new(s * 1.2, 0.5, 0.2) * CFrame.Angles(0, 0, s * math.rad(-35)), Color3.fromRGB(70, 40, 90), { Name = "Wing" })
		weld(body, wing)
		local fang = wedge(m, Vector3.new(0.12, 0.25, 0.1), c * CFrame.new(s * 0.15, -0.45, -1.06) * CFrame.Angles(math.rad(180), 0, 0), WHITE, { Name = "Fang" })
		weld(body, fang)
		local ear = wedge(m, Vector3.new(0.2, 0.55, 0.35), c * CFrame.new(s * 0.6, 1.05, 0), col, { Name = "Ear" })
		weld(body, ear)
	end
	local cape = block(m, Vector3.new(1.8, 1.6, 0.15), c * CFrame.new(0, -0.3, 1.0), Color3.fromRGB(120, 20, 50), { Name = "Cape" })
	weld(body, cape)
end

features.Octo = function(m, body, c, col)
	for i = 0, 5 do
		local a = i * math.pi * 2 / 6
		local t = cyl(m, 0.9, 0.35, c * CFrame.new(math.cos(a) * 0.75, -1.05, math.sin(a) * 0.75) * CFrame.Angles(0, -a, math.rad(70)), col:Lerp(Color3.fromRGB(200, 90, 150), 0.2), { Name = "Tentacle" })
		weld(body, t)
	end
	for i = 1, 4 do
		local spot = ball(m, 0.3, c * CFrame.new(-0.6 + i * 0.3, 0.7, 0.6), col:Lerp(WHITE, 0.4), { Name = "Spot" })
		weld(body, spot)
	end
end

features.Golem = function(m, body, c, col)
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(2.2, 2, 2)
	body.Material = Enum.Material.Slate
	local moss = block(m, Vector3.new(1.4, 0.3, 1.2), c * CFrame.new(0.2, 1.05, 0.1), Color3.fromRGB(110, 170, 90), { Name = "Moss", Material = Enum.Material.Grass })
	weld(body, moss)
	for _, s in { -1, 1 } do
		local arm = block(m, Vector3.new(0.6, 1.1, 0.6), c * CFrame.new(s * 1.35, -0.2, 0) * CFrame.Angles(0, 0, s * 0.2), col:Lerp(BLACK, 0.1), { Name = "Arm", Material = Enum.Material.Slate })
		weld(body, arm)
	end
	local crack = block(m, Vector3.new(0.08, 0.8, 0.05), c * CFrame.new(-0.6, 0.4, -1.01) * CFrame.Angles(0, 0, 0.4), BLACK, { Name = "Crack" })
	weld(body, crack)
end

features.Sparky = function(m, body, c, col)
	local antenna = block(m, Vector3.new(0.1, 0.6, 0.1), c * CFrame.new(0, 1.3, 0), BLACK, { Name = "Antenna" })
	weld(body, antenna)
	local bolt = wedge(m, Vector3.new(0.15, 0.6, 0.4), c * CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, math.rad(20)), Color3.fromRGB(255, 250, 150), { Name = "Bolt", Material = Enum.Material.Neon })
	weld(body, bolt)
	for _, s in { -1, 1 } do
		local cheek = ball(m, 0.4, c * CFrame.new(s * 0.7, -0.05, -0.8), Color3.fromRGB(255, 120, 80), { Name = "Cheek" })
		weld(body, cheek)
	end
end

features.Sprout = function(m, body, c, col)
	local stem = block(m, Vector3.new(0.12, 0.6, 0.12), c * CFrame.new(0, 1.3, 0), Color3.fromRGB(90, 150, 80), { Name = "Stem" })
	weld(body, stem)
	for _, s in { -1, 1 } do
		local leaf = wedge(m, Vector3.new(0.1, 0.4, 0.9), c * CFrame.new(s * 0.45, 1.55, 0) * CFrame.Angles(0, s * math.rad(90), s * math.rad(-30)), Color3.fromRGB(130, 220, 110), { Name = "Leaf" })
		weld(body, leaf)
	end
	local flower = ball(m, 0.45, c * CFrame.new(0, 1.7, 0), Color3.fromRGB(255, 170, 200), { Name = "Flower" })
	weld(body, flower)
end

features.Yeti = function(m, body, c, col)
	for i = 0, 7 do
		local a = i * math.pi * 2 / 8
		local fur = ball(m, 0.9, c * CFrame.new(math.cos(a) * 0.9, 0.3 * math.sin(i), math.sin(a) * 0.9), WHITE, { Name = "Fur" })
		weld(body, fur)
	end
	for _, s in { -1, 1 } do
		local horn = wedge(m, Vector3.new(0.2, 0.5, 0.3), c * CFrame.new(s * 0.55, 1.2, 0), Color3.fromRGB(180, 200, 230), { Name = "Horn" })
		weld(body, horn)
	end
	local face = ball(m, 1.3, c * CFrame.new(0, 0.1, -0.55), Color3.fromRGB(170, 200, 240), { Name = "Face" })
	weld(body, face)
end

features.Mummy = function(m, body, c, col)
	for i = -2, 2 do
		local strip = block(m, Vector3.new(2.3, 0.18, 2.3), c * CFrame.new(0, i * 0.4, 0) * CFrame.Angles(0, 0, math.rad(i * 6)), col:Lerp(WHITE, 0.3), { Name = "Bandage", Material = Enum.Material.Fabric, Transparency = 0.05 })
		weld(body, strip)
	end
	local loose = block(m, Vector3.new(0.25, 0.9, 0.08), c * CFrame.new(0.7, -0.9, -0.6) * CFrame.Angles(0, 0, 0.3), col, { Name = "Loose", Material = Enum.Material.Fabric })
	weld(body, loose)
end

local function nameTag(model: Model, text: string)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NameTag"
	bb.Size = UDim2.fromOffset(100, 22)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 40
	bb.LightInfluence = 0
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.FredokaOne
	tl.TextScaled = true
	tl.TextColor3 = WHITE
	tl.TextStrokeTransparency = 0.4
	tl.Text = text
	tl.Parent = bb
	bb.Parent = model:FindFirstChild("HumanoidRootPart")
end

-- Build a placeholder baby at the origin. Returns an unparented Model.
function Placeholders.baby(id: string): Model
	local def = Babies.Defs[id]
	local col = def and def.Color or Color3.fromRGB(200, 200, 200)
	local m = Instance.new("Model")
	m.Name = id
	local root = newPart("Part", { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), Transparency = 1, CFrame = CFrame.new(0, 0, 0) })
	root.Anchored = true
	root.Massless = false
	root.Parent = m
	m.PrimaryPart = root
	local c = CFrame.new(0, 0, 0)
	local body = ball(m, 2.2, c, col, { Name = "Body" })
	local joint = Instance.new("Weld")
	joint.Name = "BodyJoint"
	joint.Part0 = root
	joint.Part1 = body
	joint.C0 = CFrame.new()
	joint.Parent = root
	body:SetAttribute("SquashPart", true)
	eyes(m, body, c, 0.42, if id == "Golem" then 0.45 else 0.55, id == "Mummy")
	if id ~= "Ghostie" and id ~= "Octo" then
		feet(m, body, c, col)
	end
	mouth(m, body, c)
	local f = features[id]
	if f then
		f(m, body, c, col)
	end
	for _, info in { { "HeadTop", Vector3.new(0, 1.7, 0) }, { "Mouth", Vector3.new(0, -0.3, -1.1) }, { "Hands", Vector3.new(0, -0.4, -0.9) } } do
		local a = Instance.new("Attachment")
		a.Name = info[1]
		a.Position = info[2]
		a.Parent = root
	end
	if def then
		nameTag(m, def.Emoji)
	end
	m:SetAttribute("Placeholder", true)
	m:SetAttribute("FloorOffset", 1.45)
	return m
end

-- Giant dark parent silhouette with glowing eyes (client-only visuals).
function Placeholders.parent(id: string, babyModel: Model?): Model
	local m = if babyModel then babyModel:Clone() else Placeholders.baby(id)
	m.Name = id .. "_Parent"
	local tag = m:FindFirstChild("NameTag", true)
	if tag then
		tag:Destroy()
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name:match("^Eye") or d.Name:match("^Shine") then
				d.Color = Color3.fromRGB(255, 230, 120)
				d.Material = Enum.Material.Neon
			elseif d.Name:match("^Pupil") then
				d.Transparency = 1
			elseif d.Name ~= "HumanoidRootPart" then
				d.Color = d.Color:Lerp(Color3.fromRGB(20, 15, 35), 0.85)
				d.Material = Enum.Material.SmoothPlastic
				d.Transparency = 0
			end
		end
	end
	m:ScaleTo(6)
	return m
end

local function humanoidish(name: string, bodyColor: Color3, extra: (Model, BasePart) -> ()): Model
	local m = Instance.new("Model")
	m.Name = name
	local root = newPart("Part", { Name = "HumanoidRootPart", Size = Vector3.new(2, 2, 1), Transparency = 1, CFrame = CFrame.new(0, 3, 0) })
	root.Anchored = true
	root.Parent = m
	m.PrimaryPart = root
	local body = cyl(m, 4, 2.6, CFrame.new(0, 2.6, 0) * CFrame.Angles(0, 0, math.rad(90)), bodyColor, { Name = "Body" })
	local joint = Instance.new("Weld")
	joint.Name = "BodyJoint"
	joint.Part0 = root
	joint.Part1 = body
	joint.C0 = root.CFrame:ToObjectSpace(body.CFrame)
	joint.Parent = root
	local head = ball(m, 2.4, CFrame.new(0, 5.6, 0), bodyColor:Lerp(WHITE, 0.2), { Name = "Head" })
	weld(body, head)
	eyes(m, head, CFrame.new(0, 5.6, 0) * CFrame.new(0, 0, 0.15), 0.45, 0.6)
	for _, x in { -0.6, 0.6 } do
		local leg = cyl(m, 1, 0.8, CFrame.new(x, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)), bodyColor:Lerp(BLACK, 0.3), { Name = "Leg" })
		weld(body, leg)
	end
	extra(m, body)
	m:SetAttribute("Placeholder", true)
	m:SetAttribute("FloorOffset", 3)
	return m
end

function Placeholders.npc(name: string): Model
	if name == "Inspector" then
		return humanoidish("Inspector", Color3.fromRGB(110, 120, 150), function(m, body)
			local hat = cyl(m, 1.2, 2.2, CFrame.new(0, 7.2, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, { Name = "Hat" })
			weld(body, hat)
			local brim = cyl(m, 0.15, 3.2, CFrame.new(0, 6.6, 0) * CFrame.Angles(0, 0, math.rad(90)), BLACK, { Name = "Brim" })
			weld(body, brim)
			local board = block(m, Vector3.new(1.4, 1.8, 0.15), CFrame.new(0.9, 3, -1.4) * CFrame.Angles(math.rad(-20), 0, 0), Color3.fromRGB(150, 110, 70), { Name = "Clipboard" })
			weld(body, board)
			local paper = block(m, Vector3.new(1.2, 1.5, 0.05), CFrame.new(0.9, 3, -1.5) * CFrame.Angles(math.rad(-20), 0, 0), WHITE, { Name = "Paper" })
			weld(body, paper)
		end)
	end
	return humanoidish(name, Color3.fromRGB(255, 190, 150), function(m, body)
		local apron = block(m, Vector3.new(2, 2.6, 0.2), CFrame.new(0, 2.4, -1.3), Color3.fromRGB(168, 230, 207), { Name = "Apron" })
		weld(body, apron)
		for _, s in { -1, 1 } do
			local horn = wedge(m, Vector3.new(0.3, 0.8, 0.5), CFrame.new(s * 0.7, 7, 0), Color3.fromRGB(255, 240, 200), { Name = "Horn" })
			weld(body, horn)
		end
	end)
end

return Placeholders
