-- CosmeticBuilder: builds cosmetic accessories from parts and welds them to a character or pet.
-- Used by the server (real characters) and the client (wardrobe ViewportFrame preview).
local Cosmetics = require(script.Parent.Parent.Config.Cosmetics)

local CosmeticBuilder = {}

local function part(parent: Instance, className: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?): BasePart
	local p = Instance.new(className) :: BasePart
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weldAll(folder: Instance, to: BasePart)
	for _, p in folder:GetDescendants() do
		if p:IsA("BasePart") then
			local w = Instance.new("WeldConstraint")
			w.Part0 = to
			w.Part1 = p
			w.Parent = p
		end
	end
end

-- Hat styles, built relative to the top of a head CFrame (`top`) with head size `s`.
local hats: { [string]: (Instance, CFrame, number, Color3, Enum.Material?) -> () } = {
	Bow = function(f, top, s, c, m)
		part(f, "Part", Vector3.new(0.5, 0.5, 0.5) * s, top * CFrame.new(0, 0.1 * s, 0), c, m)
		for _, x in { -1, 1 } do
			part(f, "WedgePart", Vector3.new(0.3, 0.6, 0.7) * s, top * CFrame.new(x * 0.45 * s, 0.1 * s, 0) * CFrame.Angles(0, 0, x * math.rad(90)), c, m)
		end
	end,
	Beanie = function(f, top, s, c, m)
		local b = part(f, "Part", Vector3.new(1.25, 1.25, 1.25) * s, top * CFrame.new(0, -0.15 * s, 0), c, Enum.Material.Fabric)
		b.Shape = Enum.PartType.Ball
		local pom = part(f, "Part", Vector3.new(0.45, 0.45, 0.45) * s, top * CFrame.new(0, 0.55 * s, 0), Color3.new(1, 1, 1), Enum.Material.Fabric)
		pom.Shape = Enum.PartType.Ball
	end,
	Crown = function(f, top, s, c, m)
		local ring = part(f, "Part", Vector3.new(0.4, 1.1, 1.1) * s, top * CFrame.new(0, 0.1 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), c, m)
		ring.Shape = Enum.PartType.Cylinder
		for i = 0, 4 do
			local a = i * math.pi * 2 / 5
			part(f, "WedgePart", Vector3.new(0.15, 0.4, 0.25) * s, top * CFrame.new(math.cos(a) * 0.45 * s, 0.45 * s, math.sin(a) * 0.45 * s) * CFrame.Angles(0, -a, 0), c, m)
		end
	end,
	Pumpkin = function(f, top, s, c, m)
		local b = part(f, "Part", Vector3.new(1.3, 1.3, 1.3) * s, top * CFrame.new(0, 0.2 * s, 0), c, m)
		b.Shape = Enum.PartType.Ball
		part(f, "Part", Vector3.new(0.15, 0.4, 0.15) * s, top * CFrame.new(0, 0.95 * s, 0), Color3.fromRGB(90, 150, 80), m)
	end,
	Horns = function(f, top, s, c, m)
		for _, x in { -1, 1 } do
			part(f, "WedgePart", Vector3.new(0.25, 0.7, 0.4) * s, top * CFrame.new(x * 0.4 * s, 0.25 * s, 0) * CFrame.Angles(0, 0, x * math.rad(-15)), c, m)
		end
	end,
	Chef = function(f, top, s, c, m)
		local band = part(f, "Part", Vector3.new(0.4, 1.1, 1.1) * s, top * CFrame.new(0, 0.05 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), c, Enum.Material.Fabric)
		band.Shape = Enum.PartType.Cylinder
		local puff = part(f, "Part", Vector3.new(1.4, 1.4, 1.4) * s, top * CFrame.new(0, 0.75 * s, 0), c, Enum.Material.Fabric)
		puff.Shape = Enum.PartType.Ball
	end,
	Witch = function(f, top, s, c, m)
		local brim = part(f, "Part", Vector3.new(0.1, 2, 2) * s, top * CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90)), c, m)
		brim.Shape = Enum.PartType.Cylinder
		local cone1 = part(f, "Part", Vector3.new(0.7, 1, 1) * s, top * CFrame.new(0, 0.4 * s, 0) * CFrame.Angles(0, 0, math.rad(90)), c, m)
		cone1.Shape = Enum.PartType.Cylinder
		local cone2 = part(f, "Part", Vector3.new(0.6, 0.6, 0.6) * s, top * CFrame.new(0, 0.95 * s, 0.1 * s) * CFrame.Angles(0, 0, math.rad(90)), c, m)
		cone2.Shape = Enum.PartType.Cylinder
		part(f, "Part", Vector3.new(0.3, 0.25, 0.25) * s, top * CFrame.new(0, 1.35 * s, 0.2 * s), c, m)
	end,
}

local function torsoOf(char: Model): BasePart?
	return (char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")) :: BasePart?
end

function CosmeticBuilder.apply(char: Model, equipped: any)
	local old = char:FindFirstChild("Cosmetics")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Cosmetics"
	local head = char:FindFirstChild("Head") :: BasePart?
	local torso = torsoOf(char)
	local hatId = equipped.Hat
	if head and hatId and hatId ~= "" then
		local def = Cosmetics.Defs[hatId]
		local builder = def and hats[def.Style]
		if builder then
			local hatFolder = Instance.new("Folder")
			hatFolder.Name = "Hat"
			local s = head.Size.Y
			builder(hatFolder, head.CFrame * CFrame.new(0, head.Size.Y / 2, 0), s, def.Color, def.Material)
			weldAll(hatFolder, head)
			hatFolder.Parent = folder
		end
	end
	local apronId = equipped.Apron
	if torso and apronId and apronId ~= "" then
		local def = Cosmetics.Defs[apronId]
		if def then
			local f = Instance.new("Folder")
			f.Name = "Apron"
			local t = torso.Size
			local front = torso.CFrame * CFrame.new(0, -t.Y * 0.1, -t.Z / 2 - 0.06)
			part(f, "Part", Vector3.new(t.X * 0.8, t.Y * 1.1, 0.1), front, def.Color, def.Material or Enum.Material.Fabric)
			part(f, "Part", Vector3.new(t.X * 0.5, 0.35, 0.12), front * CFrame.new(0, -t.Y * 0.25, -0.03), Color3.new(1, 1, 1), Enum.Material.Fabric)
			if def.Style == "ApronStars" then
				for i = -1, 1 do
					part(f, "Part", Vector3.new(0.22, 0.22, 0.05), front * CFrame.new(i * 0.4, 0.3, -0.07) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(255, 225, 110), Enum.Material.Neon)
				end
			end
			weldAll(f, torso)
			f.Parent = folder
		end
	end
	local uniformId = equipped.Uniform
	if uniformId and uniformId ~= "" then
		local def = Cosmetics.Defs[uniformId]
		if def then
			local f = Instance.new("Folder")
			f.Name = "Uniform"
			for _, name in { "UpperTorso", "LowerTorso", "Torso", "LeftUpperArm", "RightUpperArm", "Left Arm", "Right Arm" } do
				local bp = char:FindFirstChild(name) :: BasePart?
				if bp and bp:IsA("BasePart") then
					local shell = part(f, "Part", bp.Size + Vector3.new(0.08, 0.04, 0.08), bp.CFrame, def.Color, Enum.Material.Fabric)
					shell.Name = "Shell_" .. name
					local w = Instance.new("WeldConstraint")
					w.Part0 = bp
					w.Part1 = shell
					w.Parent = shell
				end
			end
			f.Parent = folder
		end
	end
	folder.Parent = char
end

-- Small accessory on a pet model (root = HumanoidRootPart).
function CosmeticBuilder.petAccessory(model: Model, id: string?)
	local old = model:FindFirstChild("PetAccessory")
	if old then
		old:Destroy()
	end
	if not id or id == "" then
		return
	end
	local def = Cosmetics.Defs[id]
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	local builder = def and hats[def.Style]
	if not root or not builder then
		return
	end
	local f = Instance.new("Folder")
	f.Name = "PetAccessory"
	builder(f, root.CFrame * CFrame.new(0, 1.1, 0), 1.4, def.Color, def.Material)
	weldAll(f, root)
	f.Parent = model
end

return CosmeticBuilder
