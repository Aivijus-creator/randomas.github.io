-- ModelRegistry: returns the author's model from ReplicatedStorage/Assets if present, otherwise a placeholder.
-- Author models only need a PrimaryPart named HumanoidRootPart (see README "Character models").
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Placeholders = require(script.Parent.Placeholders)
local CharacterBuilder = require(script.Parent.CharacterBuilder)

local ModelRegistry = {}

local function assets(): Instance?
	return ReplicatedStorage:FindFirstChild("Assets")
end

local function findAuthor(folderName: string, id: string): Model?
	local a = assets()
	local folder = a and a:FindFirstChild(folderName)
	local m = folder and folder:FindFirstChild(id)
	if m and m:IsA("Model") then
		local root = m:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			return m
		end
		warn(("[ModelRegistry] %s/%s has no HumanoidRootPart part; using placeholder"):format(folderName, id))
	end
	return nil
end

-- Normalize a cloned model so gameplay code can move it by its anchored root.
local function prepare(m: Model): Model
	local root = m:FindFirstChild("HumanoidRootPart") :: BasePart
	m.PrimaryPart = root
	root.Anchored = true
	root.CanCollide = false
	root.Transparency = 1
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			if d.Anchored then
				-- Unrigged loose part: glue it to the root.
				d.Anchored = false
				local w = Instance.new("WeldConstraint")
				w.Part0 = root
				w.Part1 = d
				w.Parent = d
			end
			d.CanCollide = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	local hum = m:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.PlatformStand = true
		hum.BreakJointsOnDeath = false
		hum.RequiresNeck = false
	end
	if m:GetAttribute("FloorOffset") == nil then
		local cf, size = m:GetBoundingBox()
		m:SetAttribute("FloorOffset", root.Position.Y - (cf.Position.Y - size.Y / 2))
	end
	return m
end

function ModelRegistry.hasAuthorBaby(id: string): boolean
	return findAuthor("Babies", id) ~= nil or CharacterBuilder.has("Babies", id)
end

-- Priority: model placed in ReplicatedStorage/Assets  >  designed character (CharacterData)  >  placeholder.
function ModelRegistry.getBaby(id: string): Model
	local author = findAuthor("Babies", id)
	local m = if author then author:Clone() else (CharacterBuilder.build("Babies", id) or Placeholders.baby(id))
	m.Name = id
	return prepare(m)
end

function ModelRegistry.getParent(id: string): Model
	local author = findAuthor("Parents", id)
	if author then
		return prepare(author:Clone())
	end
	local designed = CharacterBuilder.build("Parents", id)
	if designed then
		designed.Name = id .. "_Parent"
		return prepare(designed)
	end
	local babyAuthor = findAuthor("Babies", id)
	local m = Placeholders.parent(id, if babyAuthor then prepare(babyAuthor:Clone()) else nil)
	return prepare(m)
end

function ModelRegistry.getNPC(name: string): Model
	local author = findAuthor("NPCs", name)
	local m = if author then author:Clone() else (CharacterBuilder.build("NPCs", name) or Placeholders.npc(name))
	m.Name = name
	return prepare(m)
end

-- Optional icon image id for a baby (Assets/Icons/<Id> ImageLabel or Decal). Returns nil if missing.
function ModelRegistry.getIcon(id: string): string?
	local a = assets()
	local icons = a and a:FindFirstChild("Icons")
	local inst = icons and icons:FindFirstChild(id)
	if inst then
		if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
			return inst.Image
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			return inst.Texture
		end
	end
	return nil
end

return ModelRegistry
