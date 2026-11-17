--[[
	Build – pagalbinės funkcijos modeliams iš Parts kurti (placeholder'iai, žemėlapis).
]]

local CollectionService = game:GetService("CollectionService")

local Build = {}

local SKIP = { Parent = true, Shape = true, Tags = true, Attributes = true }

-- Sukuria Part. props – bet kokios Part savybės + Parent, Shape, Tags, Attributes.
function Build.Part(props)
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		part.Shape = props.Shape
	end
	for key, value in pairs(props) do
		if not SKIP[key] then
			part[key] = value
		end
	end
	if props.Tags then
		for _, tag in ipairs(props.Tags) do
			CollectionService:AddTag(part, tag)
		end
	end
	if props.Attributes then
		for key, value in pairs(props.Attributes) do
			part:SetAttribute(key, value)
		end
	end
	part.Parent = props.Parent
	return part
end

-- Tas pats, tik WedgePart
function Build.Wedge(props)
	local part = Instance.new("WedgePart")
	part.Anchored = true
	for key, value in pairs(props) do
		if not SKIP[key] then
			part[key] = value
		end
	end
	part.Parent = props.Parent
	return part
end

function Build.Model(name, parent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent
	return model
end

function Build.Folder(name, parent)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- Prideda SpecialMesh (pvz. elipsoidas iš Block dalies)
function Build.Mesh(part, meshType, scale)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = meshType
	if scale then
		mesh.Scale = scale
	end
	mesh.Parent = part
	return mesh
end

-- Pažymi TextLabel, kad klientas jį išverstų pagal žaidėjo kalbą.
-- args: { item = "Cepelinai_3" } -> verčiama kaip raktas (ArgKey_),
--       { name = "Jonas" }       -> paprastas tekstas (Arg_),
--       nums: { price = 50 }     -> sutrumpintas skaičius (ArgNum_).
function Build.Localize(label, key, args, nums, keys)
	label:SetAttribute("TextKey", key)
	if args then
		for name, value in pairs(args) do
			label:SetAttribute("Arg_" .. name, value)
		end
	end
	if nums then
		for name, value in pairs(nums) do
			label:SetAttribute("ArgNum_" .. name, value)
		end
	end
	if keys then
		for name, value in pairs(keys) do
			label:SetAttribute("ArgKey_" .. name, value)
		end
	end
	CollectionService:AddTag(label, "Loc")
end

-- BillboardGui su vienu TextLabel.
function Build.Billboard(parent, opts)
	opts = opts or {}
	local gui = Instance.new("BillboardGui")
	gui.Name = opts.Name or "Billboard"
	gui.Size = opts.Size or UDim2.fromScale(8, 2)
	gui.StudsOffset = opts.Offset or Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = opts.AlwaysOnTop == true
	gui.MaxDistance = opts.MaxDistance or 120
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.Font = opts.Font or Enum.Font.Fondamento
	label.TextColor3 = opts.Color or Color3.fromRGB(255, 240, 200)
	label.TextStrokeTransparency = 0.15
	label.TextStrokeColor3 = Color3.fromRGB(45, 28, 12)
	label.Text = opts.Text or ""
	label.Parent = gui

	if opts.TextKey then
		Build.Localize(label, opts.TextKey, opts.Args, opts.Nums, opts.Keys)
	end
	return gui, label
end

-- Viduramžiška lentelė (pergamentas su mediniu rėmu) kaip BillboardGui
function Build.Sign(parent, opts)
	opts = opts or {}
	local gui = Instance.new("BillboardGui")
	gui.Name = opts.Name or "Sign"
	gui.Size = opts.Size or UDim2.fromScale(7, 2.2)
	gui.StudsOffset = opts.Offset or Vector3.new(0, 4, 0)
	gui.AlwaysOnTop = opts.AlwaysOnTop == true
	gui.MaxDistance = opts.MaxDistance or 90
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = opts.Background or Color3.fromRGB(232, 211, 162)
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = opts.Border or Color3.fromRGB(92, 58, 30)
	stroke.Thickness = 3
	stroke.Parent = frame

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.92, 0.86)
	label.Position = UDim2.fromScale(0.04, 0.07)
	label.TextScaled = true
	label.Font = opts.Font or Enum.Font.Fondamento
	label.TextColor3 = opts.Color or Color3.fromRGB(60, 35, 15)
	label.Text = opts.Text or ""
	label.Parent = frame

	if opts.TextKey then
		Build.Localize(label, opts.TextKey, opts.Args, opts.Nums, opts.Keys)
	end
	return gui, label
end

-- Pastato modelį taip, kad jo apačia būtų ant cf aukščio.
function Build.PlaceOnFloor(model, cf)
	model:PivotTo(cf)
	local bbCFrame, bbSize = model:GetBoundingBox()
	local bottom = bbCFrame.Position.Y - bbSize.Y / 2
	local delta = cf.Position.Y - bottom
	model:PivotTo(cf + Vector3.new(0, delta, 0))
end

-- Suvirina (WeldConstraint) visas modelio dalis prie root ir atanchorina jas.
function Build.WeldAll(model, root)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = d
			weld.Parent = d
			d.Anchored = false
		end
	end
end

-- Nustato modelio savybę visoms dalims
function Build.SetAll(model, prop, value)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d[prop] = value
		end
	end
end

return Build
