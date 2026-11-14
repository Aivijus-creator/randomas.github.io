-- Kitchen props: appliances and ingredient sources.
local B = require(script.Parent.Parent.Builder)
local Furniture = require(script.Parent.Furniture)
local P = B.Palette
local M = Enum.Material

local K = {}

local function at(cf: CFrame, x: number, y: number, z: number): CFrame
	return cf * CFrame.new(x, y, z)
end

local function label(part: BasePart, face: Enum.NormalId, text: string)
	B.surfaceText(part, face, text, { TextColor3 = P.Plum })
end

-- Counter with a sink + tap.
function K.sinkCounter(parent: Instance, cf: CFrame, width: number?): Model
	local m = K.counter(parent, cf, width or 6, Color3.fromRGB(168, 230, 207))
	m.Name = "SinkCounter"
	B.disc(m, 2.2, 0.1, at(cf, 0, 3.86, -0.2).Position, Color3.fromRGB(170, 175, 185), M.Metal, { CanCollide = false })
	B.column(m, 1.2, 0.25, at(cf, 0, 4.4, 1).Position, Color3.fromRGB(170, 175, 185), M.Metal, { CanCollide = false })
	B.cyl(m, 1, 0.25, at(cf, 0, 5, 0.6) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(170, 175, 185), M.Metal, { CanCollide = false })
	return m
end

function K.counter(parent: Instance, cf: CFrame, width: number?, color: Color3?): Model
	local w = width or 6
	local m = B.model(parent, "Counter")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(w, 3.4, 3), at(cf, 0, 1.7, 0), color or P.Mint)
	B.part(m, Vector3.new(w + 0.2, 0.4, 3.3), at(cf, 0, 3.6, 0), P.Cream, M.Marble)
	for i = 0, math.floor(w / 3) - 1 do
		local x = -w / 2 + 1.5 + i * 3
		B.deco(m, Vector3.new(2.6, 2.6, 0.1), at(cf, x, 1.7, -1.52), Color3.fromRGB(255, 255, 255), M.SmoothPlastic, { Transparency = 0.6 })
		B.deco(m, Vector3.new(0.8, 0.2, 0.15), at(cf, x, 2.6, -1.6), P.Metal, M.Metal)
	end
	return m
end

local function appliance(m: Model, kind: string, slotCF: CFrame)
	B.tag(m, "Appliance")
	m:SetAttribute("Kind", kind)
	m:SetAttribute("State", "Idle")
	m:SetAttribute("Progress", 0)
	m:SetAttribute("Contents", "")
	local slot = B.marker(m, "Slot", slotCF)
	slot:SetAttribute("Slot", true)
	Furniture.furniture(m, false, 150)
end

function K.oven(parent: Instance, cf: CFrame, name: string?): Model
	local m = B.model(parent, name or "Oven")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(5, 4.4, 3.4), at(cf, 0, 2.2, 0), P.Pink)
	B.part(m, Vector3.new(5.2, 0.3, 3.6), at(cf, 0, 4.5, 0), P.Plum)
	local window = B.part(m, Vector3.new(3.4, 1.8, 0.1), at(cf, 0, 2.1, -1.72), Color3.fromRGB(60, 40, 40), M.Glass, { Transparency = 0.2, Name = "Window" })
	B.tag(window, "OvenWindow")
	B.cyl(m, 3.6, 0.3, at(cf, 0, 3.3, -1.95), P.Metal, M.Metal, { CanCollide = false })
	for i = -2, 2 do
		B.cyl(m, 0.3, 0.55, at(cf, i * 0.9, 4, -1.75) * CFrame.Angles(0, math.rad(90), 0), P.Cream, M.SmoothPlastic, { CanCollide = false })
	end
	for _, sx in { -1.2, 1.2 } do
		for _, sz in { -0.8, 0.8 } do
			B.disc(m, 1.2, 0.1, at(cf, sx, 4.7, sz).Position, P.Black, M.Metal, { CanCollide = false })
		end
	end
	appliance(m, "Oven", cf * CFrame.new(0, 6, 0))
	return m
end

function K.stovePot(parent: Instance, cf: CFrame, name: string?): Model
	local m = B.model(parent, name or "Pot")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(4, 3.6, 3.4), at(cf, 0, 1.8, 0), P.Lavender)
	B.part(m, Vector3.new(4.2, 0.3, 3.6), at(cf, 0, 3.7, 0), P.Plum)
	B.disc(m, 2.2, 0.1, at(cf, 0, 3.9, 0).Position, P.Black, M.Metal, { CanCollide = false })
	B.cyl(m, 1.8, 2.6, at(cf, 0, 4.8, 0) * CFrame.Angles(0, 0, math.rad(90)), P.Metal, M.Metal)
	local soup = B.disc(m, 2.3, 0.1, at(cf, 0, 5.65, 0).Position, Color3.fromRGB(250, 230, 190), M.SmoothPlastic, { CanCollide = false, Name = "Soup" })
	soup.CastShadow = false
	for _, sx in { -1.5, 1.5 } do
		B.deco(m, Vector3.new(0.8, 0.25, 0.25), at(cf, sx, 5.4, 0), P.Black)
	end
	appliance(m, "Pot", cf * CFrame.new(0, 6.6, 0))
	return m
end

function K.blender(parent: Instance, cf: CFrame, name: string?): Model
	local m = Furniture.table(parent, cf, Vector2.new(4, 3), P.Peach)
	m.Name = name or "Blender"
	B.cyl(m, 0.9, 1.6, at(cf, 0, 3.45, 0) * CFrame.Angles(0, 0, math.rad(90)), P.Plum, M.SmoothPlastic)
	local jug = B.cyl(m, 2, 1.3, at(cf, 0, 4.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(200, 230, 255), M.Glass, { Transparency = 0.4, Name = "Jug" })
	jug.CastShadow = false
	B.cyl(m, 0.3, 1.4, at(cf, 0, 6, 0) * CFrame.Angles(0, 0, math.rad(90)), P.Plum, M.SmoothPlastic, { CanCollide = false })
	B.deco(m, Vector3.new(0.4, 0.3, 0.2), at(cf, 0, 3.4, -0.8), P.Red)
	-- table() already tagged it as furniture; add appliance tags
	B.tag(m, "Appliance")
	m:SetAttribute("Kind", "Blender")
	m:SetAttribute("State", "Idle")
	m:SetAttribute("Progress", 0)
	m:SetAttribute("Contents", "")
	local slot = B.marker(m, "Slot", cf * CFrame.new(0, 7, 0))
	slot:SetAttribute("Slot", true)
	return m
end

function K.freezer(parent: Instance, cf: CFrame, name: string?): Model
	local m = B.model(parent, name or "Freezer")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(5, 3.4, 3.4), at(cf, 0, 1.7, 0), Color3.fromRGB(200, 230, 250))
	B.part(m, Vector3.new(5.2, 0.5, 3.6), at(cf, 0, 3.6, 0), Color3.fromRGB(150, 200, 235))
	B.deco(m, Vector3.new(3, 0.3, 0.3), at(cf, 0, 3.4, -1.8), P.Metal, M.Metal)
	local frost = B.deco(m, Vector3.new(4.6, 0.1, 3), at(cf, 0, 3.9, 0), Color3.fromRGB(235, 250, 255), M.Ice, { Transparency = 0.3 })
	frost.CastShadow = false
	label(B.deco(m, Vector3.new(1.5, 1.5, 0.05), at(cf, 0, 1.8, -1.73), P.White), Enum.NormalId.Front, "❄️")
	appliance(m, "Freezer", cf * CFrame.new(0, 5.5, 0))
	return m
end

-- Ingredient source (crate, fridge door, sack ...). Electric sources stop during blackouts.
function K.source(parent: Instance, cf: CFrame, ingredient: string, emoji: string, style: string?): Model
	local m = B.model(parent, ingredient .. "Source")
	B.root(m, cf * CFrame.new(0, 2, 0))
	local labelPart: BasePart
	if style == "fridge" then
		B.part(m, Vector3.new(3.6, 7, 3.4), at(cf, 0, 3.5, 0), P.White)
		B.part(m, Vector3.new(3.4, 0.1, 0.1), at(cf, 0, 4.6, -1.72), P.Metal, M.Metal)
		B.deco(m, Vector3.new(0.25, 1.6, 0.3), at(cf, 1.4, 5.6, -1.8), P.Metal, M.Metal)
		B.deco(m, Vector3.new(0.25, 1.6, 0.3), at(cf, 1.4, 3.2, -1.8), P.Metal, M.Metal)
		labelPart = B.deco(m, Vector3.new(1.6, 1.6, 0.05), at(cf, -0.4, 5.6, -1.73), P.Cream)
		B.deco(m, Vector3.new(0.4, 0.4, 0.05), at(cf, -1.2, 3, -1.73), P.Pink, M.Neon)
		m:SetAttribute("Electric", true)
	elseif style == "sack" then
		B.ball(m, 2.6, at(cf, 0, 1.3, 0).Position, Color3.fromRGB(230, 210, 170), M.Fabric, { Size = Vector3.new(2.6, 3, 2.4) })
		B.deco(m, Vector3.new(1.2, 0.4, 1.2), at(cf, 0, 2.9, 0), Color3.fromRGB(200, 180, 140), M.Fabric)
		labelPart = B.deco(m, Vector3.new(1.4, 1.4, 0.05), at(cf, 0, 1.4, -1.25), P.Cream)
	elseif style == "jar" then
		B.part(m, Vector3.new(3, 3.4, 2), at(cf, 0, 1.7, 0), P.Wood, M.Wood)
		B.cyl(m, 1.6, 1.4, at(cf, 0, 4.2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(255, 220, 220), M.Glass, { Transparency = 0.3 })
		for i = 1, 4 do
			B.deco(m, Vector3.new(0.3, 0.6, 0.3), at(cf, (i - 2.5) * 0.3, 4.1, 0), P.Red, M.SmoothPlastic)
		end
		labelPart = B.deco(m, Vector3.new(1.4, 1.4, 0.05), at(cf, 0, 1.8, -1.03), P.Cream)
	elseif style == "icebox" then
		B.part(m, Vector3.new(3.4, 2.8, 2.6), at(cf, 0, 1.4, 0), Color3.fromRGB(150, 210, 240))
		B.part(m, Vector3.new(3.6, 0.4, 2.8), at(cf, 0, 3, 0), P.White)
		for i = 1, 3 do
			B.deco(m, Vector3.new(0.9, 0.9, 0.9), at(cf, (i - 2) * 1, 3.6, 0) * CFrame.Angles(0, i, 0.3), Color3.fromRGB(210, 245, 255), M.Ice, { Transparency = 0.3 })
		end
		labelPart = B.deco(m, Vector3.new(1.4, 1.4, 0.05), at(cf, 0, 1.4, -1.33), P.Cream)
		m:SetAttribute("Electric", true)
	else -- crate
		B.part(m, Vector3.new(3, 2.2, 2.4), at(cf, 0, 1.1, 0), P.Wood, M.WoodPlanks)
		for i = 1, 5 do
			B.ball(m, 0.8, at(cf, (i - 3) * 0.5, 2.5, (i % 2) * 0.4 - 0.2).Position, emoji == "🫜" and Color3.fromRGB(150, 30, 80) or Color3.fromRGB(230, 60, 40), M.SmoothPlastic, { CanCollide = false })
		end
		labelPart = B.deco(m, Vector3.new(1.4, 1.4, 0.05), at(cf, 0, 1.1, -1.23), P.Cream)
	end
	label(labelPart, Enum.NormalId.Front, emoji)
	B.tag(m, "IngredientSource")
	m:SetAttribute("Ingredient", ingredient)
	return m
end

function K.hangingPans(parent: Instance, cf: CFrame)
	local m = B.model(parent, "HangingPans")
	B.tag(m, "CeilingDecor")
	B.cyl(m, 8, 0.25, cf, P.Metal, M.Metal, { CanCollide = false })
	for i = -3, 3, 2 do
		B.deco(m, Vector3.new(0.08, 1, 0.08), cf * CFrame.new(i, -0.5, 0), P.Metal, M.Metal)
		B.cyl(m, 0.2, 1.4 + (i % 3) * 0.2, cf * CFrame.new(i, -1.3, 0) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(70, 70, 75), M.Metal, { CanCollide = false })
	end
	return m
end

function K.dishShelf(parent: Instance, cf: CFrame)
	local m = B.model(parent, "DishShelf")
	B.part(m, Vector3.new(6, 0.3, 1.4), cf, P.Wood, M.Wood, { CanCollide = false })
	local colors = { P.Pink, P.Mint, P.Lavender, P.Peach, P.Yellow }
	for i = 1, 5 do
		B.cyl(m, 0.15, 1.2, cf * CFrame.new(-2.4 + (i - 1) * 1.2, 0.75, 0.2) * CFrame.Angles(0, math.rad(90), 0), colors[i], M.SmoothPlastic, { CanCollide = false })
	end
	for i = 1, 3 do
		B.column(m, 0.8, 0.7, (cf * CFrame.new(-1.8 + i * 0.9, 0.55, -0.3)).Position, P.White, M.SmoothPlastic, { CanCollide = false })
	end
	return m
end

function K.autoFeeder(parent: Instance, cf: CFrame): Model
	local m = B.model(parent, "AutoFeeder")
	B.root(m, cf * CFrame.new(0, 2, 0))
	B.part(m, Vector3.new(3, 5, 3), at(cf, 0, 2.5, 0), P.Metal, M.Metal)
	B.ball(m, 2.6, at(cf, 0, 5.6, 0).Position, Color3.fromRGB(200, 240, 255), M.Glass, { Transparency = 0.4 })
	B.deco(m, Vector3.new(1.6, 0.6, 0.2), at(cf, 0, 3.5, -1.55), P.Green, M.Neon)
	B.deco(m, Vector3.new(0.4, 0.4, 0.2), at(cf, -0.6, 4.4, -1.55), P.Red, M.Neon)
	B.deco(m, Vector3.new(0.4, 0.4, 0.2), at(cf, 0.6, 4.4, -1.55), P.Red, M.Neon)
	B.tag(m, "AutoFeeder")
	return m
end

return K
