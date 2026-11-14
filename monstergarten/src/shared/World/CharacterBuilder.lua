-- CharacterBuilder: turns the author's character designs (CharacterData, imported from the 3D character
-- sheet) into Roblox models that follow the model contract:
--   PrimaryPart "HumanoidRootPart" (anchored, invisible), a "Body" part welded to it with the Weld
--   "BodyJoint" (procedural animations move it), every visible part welded to Body,
--   attachments HeadTop / Mouth / Hands, and the FloorOffset attribute.
local CharacterData = require(script.Parent.CharacterData)
local Babies = require(script.Parent.Parent.Config.Babies)

local CharacterBuilder = {}

local function newPart(className: string): BasePart
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
	return p
end

function CharacterBuilder.has(folder: string, id: string): boolean
	local f = (CharacterData :: any)[folder]
	return f ~= nil and f[id] ~= nil
end

function CharacterBuilder.build(folder: string, id: string): Model?
	local f = (CharacterData :: any)[folder]
	local def = f and f[id]
	if not def then
		return nil
	end
	local s: number = def.Scale
	local lift: number = def.Lift or 0
	local height = def.Height * s
	local centerY = height / 2 + lift

	local m = Instance.new("Model")
	m.Name = id
	local root = newPart("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Massless = false
	root.Transparency = 1
	root.Size = if folder == "Babies" then Vector3.new(2, 2, 1) else Vector3.new(2, 2, 1) * math.max(1, s / 2)
	root.CFrame = CFrame.new(0, centerY, 0)
	root.Parent = m
	m.PrimaryPart = root

	local body = newPart("Part")
	body.Name = "Body"
	body.Transparency = 1
	body.Size = Vector3.new(0.2, 0.2, 0.2)
	body.CFrame = root.CFrame
	body.Parent = m
	local joint = Instance.new("Weld")
	joint.Name = "BodyJoint"
	joint.Part0 = root
	joint.Part1 = body
	joint.C0 = CFrame.new()
	joint.Parent = root

	local rad = math.rad
	for i, p in def.Parts do
		local shape, pos, size, hex, rot, transparency, glow = p[1], p[2], p[3], p[4], p[5], p[6], p[7]
		if transparency >= 1 then
			continue
		end
		local part = newPart("Part")
		part.Name = "P" .. i
		local sz = Vector3.new(size[1], size[2], size[3]) * s
		if shape == "b" then
			part.Size = sz
		elseif shape == "c" then
			part.Shape = Enum.PartType.Cylinder -- axis along X, same as the sheet
			part.Size = sz
		else
			-- ellipsoid: a SpecialMesh sphere stretches to the part size
			part.Size = sz
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
		end
		part.Color = Color3.fromHex(hex)
		part.Transparency = transparency
		if glow == 1 then
			part.Material = Enum.Material.Neon
		end
		part.CFrame = CFrame.new(pos[1] * s, pos[2] * s + lift, pos[3] * s) * CFrame.Angles(rad(rot[1]), rad(rot[2]), rad(rot[3]))
		local w = Instance.new("WeldConstraint")
		w.Part0 = body
		w.Part1 = part
		w.Parent = part
		part.Parent = m
	end

	-- attachments relative to the root
	local width = def.Width * s
	for _, info in {
		{ "HeadTop", Vector3.new(0, height / 2 + 0.3, 0) },
		{ "Mouth", Vector3.new(0, height * 0.1, -width * 0.4) },
		{ "Hands", Vector3.new(0, -height * 0.1, -width * 0.35) },
	} do
		local a = Instance.new("Attachment")
		a.Name = info[1]
		a.Position = info[2]
		a.Parent = root
	end

	if folder == "Babies" then
		local bdef = Babies.Defs[id]
		local bb = Instance.new("BillboardGui")
		bb.Name = "NameTag"
		bb.Size = UDim2.fromOffset(100, 22)
		bb.StudsOffsetWorldSpace = Vector3.new(0, height / 2 + 1, 0)
		bb.MaxDistance = 40
		bb.LightInfluence = 0
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.FredokaOne
		tl.TextScaled = true
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.TextStrokeTransparency = 0.4
		tl.Text = if bdef then bdef.Emoji else id
		tl.Parent = bb
		bb.Parent = root
	end

	m:SetAttribute("FloorOffset", centerY)
	m:SetAttribute("Designed", true)
	m:SetAttribute("DisplayName", def.Name)
	return m
end

return CharacterBuilder
