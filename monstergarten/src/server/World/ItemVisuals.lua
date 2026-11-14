-- ItemVisuals: small procedural models for held / dropped items. Each returns a Model whose
-- PrimaryPart is "Handle"; all other parts are welded to it and unanchored.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Tools = require(Shared.Config.Tools)
local Recipes = require(Shared.Config.Recipes)
local Cosmetics = require(Shared.Config.Cosmetics)

local ItemVisuals = {}

local function part(model: Model, className: string, size: Vector3, cf: CFrame, color: Color3, props: { [string]: any }?): BasePart
	local p = Instance.new(className) :: BasePart
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = model
	if model.PrimaryPart and model.PrimaryPart ~= p then
		local w = Instance.new("WeldConstraint")
		w.Part0 = model.PrimaryPart
		w.Part1 = p
		w.Parent = p
	end
	return p
end

local function handle(model: Model, size: Vector3?): BasePart
	local h = part(model, "Part", size or Vector3.new(0.4, 0.4, 0.4), CFrame.new(), Color3.new(1, 1, 1), { Name = "Handle", Transparency = 1 })
	model.PrimaryPart = h
	return h
end

local function cyl(model: Model, length: number, d: number, cf: CFrame, color: Color3, props: { [string]: any }?)
	local p = part(model, "Part", Vector3.new(length, d, d), cf, color, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function ball(model: Model, d: number, cf: CFrame, color: Color3, props: { [string]: any }?)
	local p = part(model, "Part", Vector3.new(d, d, d), cf, color, props)
	p.Shape = Enum.PartType.Ball
	return p
end

local function emojiTag(model: Model, emoji: string, offset: number?)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Emoji"
	bb.Size = UDim2.fromOffset(36, 36)
	bb.StudsOffset = Vector3.new(0, offset or 1.4, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 50
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.TextScaled = true
	t.Text = emoji
	t.Parent = bb
	bb.Parent = model.PrimaryPart
end

local V = Vector3.new
local up = CFrame.Angles(0, 0, math.rad(90)) -- turns X-axis cylinders upright

local toolBuilders: { [string]: (Model, Color3) -> () } = {
	Extinguisher = function(m, c)
		cyl(m, 1.8, 0.8, CFrame.new(0, 0, 0) * up, c)
		cyl(m, 0.3, 0.5, CFrame.new(0, 1.05, 0) * up, Color3.fromRGB(40, 40, 45))
		part(m, "Part", V(0.15, 0.15, 0.9), CFrame.new(0, 1.15, -0.45), Color3.fromRGB(40, 40, 45), { Name = "Nozzle" })
		part(m, "Part", V(0.5, 0.3, 0.05), CFrame.new(0, 0.2, -0.41), Color3.fromRGB(255, 255, 255))
	end,
	Mop = function(m, c)
		part(m, "Part", V(0.2, 4.5, 0.2), CFrame.new(0, 0.8, 0), Color3.fromRGB(190, 150, 105), { Material = Enum.Material.Wood })
		part(m, "Part", V(1.4, 0.3, 0.6), CFrame.new(0, -1.5, 0), c)
		for i = -2, 2 do
			part(m, "Part", V(0.15, 0.6, 0.15), CFrame.new(i * 0.3, -1.9, 0), Color3.fromRGB(240, 240, 240), { Material = Enum.Material.Fabric })
		end
	end,
	Flashlight = function(m, c)
		cyl(m, 1.3, 0.45, CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(60, 60, 70))
		cyl(m, 0.35, 0.65, CFrame.new(0, 0, -0.75) * CFrame.Angles(0, math.rad(90), 0), c)
		local lens = cyl(m, 0.06, 0.55, CFrame.new(0, 0, -0.95) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(255, 250, 200), { Material = Enum.Material.Neon, Name = "Lens" })
		local light = Instance.new("SpotLight")
		light.Name = "Beam"
		light.Face = Enum.NormalId.Right -- cylinder axis (X) was rotated to -Z
		light.Range = 34
		light.Angle = 45
		light.Brightness = 4
		light.Color = Color3.fromRGB(255, 245, 210)
		light.Shadows = true
		light.Enabled = false
		light.Parent = lens
	end,
	ToyBag = function(m, c)
		ball(m, 1.4, CFrame.new(0, 0, 0), c, { Material = Enum.Material.Fabric })
		ball(m, 0.6, CFrame.new(0.3, 0.8, 0), Color3.fromRGB(255, 225, 110))
		part(m, "Part", V(0.5, 0.5, 0.5), CFrame.new(-0.3, 0.75, 0.1) * CFrame.Angles(0.3, 0.4, 0), Color3.fromRGB(110, 160, 235))
	end,
	Lullaby = function(m, c)
		part(m, "Part", V(1.2, 0.9, 0.9), CFrame.new(0, 0, 0), c, { Material = Enum.Material.Wood })
		part(m, "Part", V(1.3, 0.15, 1), CFrame.new(0, 0.5, 0), Color3.fromRGB(255, 225, 110))
		part(m, "Part", V(0.15, 0.6, 0.15), CFrame.new(0.3, 0.85, 0), Color3.fromRGB(75, 63, 114))
		ball(m, 0.3, CFrame.new(0.2, 1.15, 0), Color3.fromRGB(75, 63, 114))
		cyl(m, 0.3, 0.15, CFrame.new(-0.75, 0, 0), Color3.fromRGB(255, 225, 110))
	end,
	Net = function(m, c)
		part(m, "Part", V(0.15, 3.5, 0.15), CFrame.new(0, 0.5, 0), Color3.fromRGB(190, 150, 105), { Material = Enum.Material.Wood })
		cyl(m, 0.1, 1.8, CFrame.new(0, 2.6, 0) * CFrame.Angles(0, math.rad(90), 0), c)
		ball(m, 1.6, CFrame.new(0, 2.6, 0.5), Color3.fromRGB(240, 240, 240), { Transparency = 0.6, Material = Enum.Material.Fabric })
	end,
	Hammer = function(m, c)
		part(m, "Part", V(0.2, 1.8, 0.2), CFrame.new(0, 0, 0), Color3.fromRGB(190, 150, 105), { Material = Enum.Material.Wood })
		part(m, "Part", V(0.9, 0.4, 0.4), CFrame.new(0, 0.9, 0), Color3.fromRGB(130, 130, 140), { Material = Enum.Material.Metal })
	end,
	Shears = function(m, c)
		part(m, "Part", V(0.15, 1.4, 0.3), CFrame.new(-0.15, 0.4, 0) * CFrame.Angles(0, 0, 0.15), Color3.fromRGB(190, 190, 200), { Material = Enum.Material.Metal })
		part(m, "Part", V(0.15, 1.4, 0.3), CFrame.new(0.15, 0.4, 0) * CFrame.Angles(0, 0, -0.15), Color3.fromRGB(190, 190, 200), { Material = Enum.Material.Metal })
		ball(m, 0.45, CFrame.new(-0.25, -0.45, 0), c)
		ball(m, 0.45, CFrame.new(0.25, -0.45, 0), c)
	end,
	WateringCan = function(m, c)
		cyl(m, 1, 0.9, CFrame.new(0, 0, 0) * up, c)
		part(m, "Part", V(0.2, 0.2, 1.2), CFrame.new(0, 0.2, -0.8) * CFrame.Angles(math.rad(25), 0, 0), c, { Name = "Spout" })
		cyl(m, 0.1, 0.7, CFrame.new(0, 0.6, 0.3) * CFrame.Angles(0, math.rad(90), 0), c)
	end,
	Sponge = function(m, c)
		part(m, "Part", V(0.9, 0.5, 0.6), CFrame.new(), c, { Material = Enum.Material.Fabric })
		part(m, "Part", V(0.92, 0.15, 0.62), CFrame.new(0, -0.2, 0), Color3.fromRGB(110, 190, 120))
	end,
	BandageRoll = function(m, c)
		cyl(m, 0.7, 0.9, CFrame.new(), c, { Material = Enum.Material.Fabric })
		part(m, "Part", V(0.6, 0.05, 1.2), CFrame.new(0, -0.45, -0.5), c, { Material = Enum.Material.Fabric })
	end,
	TrashBag = function(m, c)
		ball(m, 1.5, CFrame.new(), c)
		part(m, "Part", V(0.4, 0.4, 0.4), CFrame.new(0, 0.85, 0), Color3.fromRGB(255, 225, 110))
	end,
}

function ItemVisuals.tool(toolId: string, skinId: string?): Model
	local m = Instance.new("Model")
	m.Name = "Tool_" .. toolId
	handle(m)
	local def = Tools.Defs[toolId]
	local color = def and def.Color or Color3.new(1, 1, 1)
	local skin = skinId and Cosmetics.Defs[skinId]
	if skin and skin.Tool == toolId then
		color = skin.Color
	end
	local builder = toolBuilders[toolId]
	if builder then
		builder(m, color)
	else
		ball(m, 1, CFrame.new(), color)
	end
	if skin and skin.Material then
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p.Name ~= "Handle" and p.Name ~= "Lens" then
				p.Material = skin.Material
			end
		end
	end
	return m
end

function ItemVisuals.ingredient(id: string): Model
	local m = Instance.new("Model")
	m.Name = "Ingredient_" .. id
	handle(m)
	local def = Recipes.Ingredients[id]
	local color = def and def.Color or Color3.new(1, 1, 1)
	if id == "Ice" then
		part(m, "Part", V(0.9, 0.9, 0.9), CFrame.Angles(0.3, 0.4, 0), color, { Material = Enum.Material.Ice, Transparency = 0.2 })
	elseif id == "Rocks" then
		for i = 1, 3 do
			part(m, "Part", V(0.6, 0.5, 0.6), CFrame.new((i - 2) * 0.45, 0, 0) * CFrame.Angles(i, i * 2, 0), color, { Material = Enum.Material.Slate })
		end
	elseif id == "Flour" or id == "Milk" then
		part(m, "Part", V(0.8, 1.1, 0.6), CFrame.new(), color, { Material = Enum.Material.Fabric })
	elseif id == "Fish" then
		ball(m, 0.8, CFrame.new(), color)
		part(m, "WedgePart", V(0.2, 0.6, 0.5), CFrame.new(0, 0, 0.6), color)
	else
		ball(m, 0.9, CFrame.new(), color)
	end
	emojiTag(m, def and def.Emoji or "?", 1.2)
	return m
end

function ItemVisuals.dish(id: string): Model
	local m = Instance.new("Model")
	m.Name = "Dish_" .. id
	handle(m)
	local def = Recipes.Dishes[id]
	cyl(m, 0.12, 1.6, CFrame.new(0, -0.3, 0) * up, Color3.fromRGB(250, 250, 250))
	if id == "BeetJuice" or id == "BerryIceCream" then
		cyl(m, 0.9, 0.6, CFrame.new(0, 0.2, 0) * up, Color3.fromRGB(230, 240, 255), { Transparency = 0.3, Material = Enum.Material.Glass })
		ball(m, 0.6, CFrame.new(0, 0.6, 0), def.Color)
	elseif id == "Cake" then
		cyl(m, 0.6, 1.2, CFrame.new(0, 0, 0) * up, def.Color)
		cyl(m, 0.15, 1.25, CFrame.new(0, 0.3, 0) * up, Color3.fromRGB(255, 255, 255))
		part(m, "Part", V(0.1, 0.4, 0.1), CFrame.new(0, 0.55, 0), Color3.fromRGB(255, 225, 110), { Material = Enum.Material.Neon })
	else
		ball(m, 0.9, CFrame.new(0, 0, 0), def and def.Color or Color3.new(1, 1, 1))
	end
	emojiTag(m, def and def.Emoji or "?", 1.2)
	return m
end

function ItemVisuals.trash(count: number?): Model
	local m = Instance.new("Model")
	m.Name = "TrashItem"
	handle(m)
	ball(m, 0.8, CFrame.new(), Color3.fromRGB(150, 150, 140), { Material = Enum.Material.Fabric })
	part(m, "Part", V(0.5, 0.2, 0.6), CFrame.new(0.3, 0.3, 0) * CFrame.Angles(0.5, 0.2, 0), Color3.fromRGB(230, 120, 120))
	if count and count > 1 then
		emojiTag(m, "🗑️×" .. count, 1.2)
	end
	return m
end

function ItemVisuals.forHeld(held: any, skinId: string?): Model?
	if held.Kind == "Tool" then
		return ItemVisuals.tool(held.Id, skinId)
	elseif held.Kind == "Ingredient" then
		return ItemVisuals.ingredient(held.Id)
	elseif held.Kind == "Dish" then
		return ItemVisuals.dish(held.Id)
	elseif held.Kind == "Trash" then
		return ItemVisuals.trash(held.Extra)
	end
	return nil
end

-- Anchor every part of a visual (for items lying on the floor or hanging on racks).
function ItemVisuals.anchor(m: Model, cf: CFrame)
	m:PivotTo(cf)
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			p.Anchored = true
		end
	end
end

return ItemVisuals
