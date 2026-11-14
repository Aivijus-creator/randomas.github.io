-- DaycareTemplate: builds the full daycare (one floor + yard + basement) around the origin.
-- Layout (X east, Z south, floor at Y = 0):
--   Yard      X[-45,45]  Z[-85,-25]
--   Kitchen   X[-83,-43] Z[-25,9]     Playroom X[-43,17] Z[-25,25]
--   Bedroom   X[17,57]   Z[-25,9]     Bathroom X[57,83]  Z[-25,9]
--   Hall      X[-33,7]   Z[25,49]     Stairs   X[-63,-33] Z[29,45]
--   Basement  X[-83,-43] Z[12,52]  at Y = -16
local B = require(script.Parent.Builder)
local F = require(script.Parent.Props.Furniture)
local K = require(script.Parent.Props.Kitchen)
local O = require(script.Parent.Props.Outdoor)
local RoomsFolder = script.Parent.Rooms
local P = B.Palette
local M = Enum.Material

local WALL_H = 14
local WALL_T = 1
local BASE_Y = -16

local Template = {}

-- Exterior: siding skin with brick base and trim on every outer wall, pitched roofs, chimney.
local SIDING = Color3.fromRGB(255, 226, 196)
local BRICK = Color3.fromRGB(196, 128, 112)
local TRIM = Color3.fromRGB(255, 250, 240)
local ROOF = Color3.fromRGB(176, 104, 132)
local ROOF_DARK = Color3.fromRGB(140, 80, 108)

local function buildExterior(ctx)
	local ext = B.folder(ctx.Model, "Exterior")
	local V = Vector2.new
	-- { a, b, outward normal, window/door openings, door-only openings (for the brick base) }
	local walls = {
		{ V(-83, -25), V(83, -25), V(0, -1), {
			{ at = 20, width = 8, bottom = 4, height = 10 }, { at = 50, width = 6, bottom = 4, height = 10 }, { at = 70, width = 8, height = 9 },
			{ at = 90, width = 6, bottom = 4, height = 10 }, { at = 112, width = 6, bottom = 4, height = 10 }, { at = 124, width = 6, height = 9 },
			{ at = 153, width = 4, bottom = 7, height = 11 } }, { { at = 70, width = 8, height = 9 }, { at = 124, width = 6, height = 9 } } },
		{ V(-83, -25), V(-83, 9), V(-1, 0), { { at = 17, width = 6, bottom = 4, height = 10 } }, {} },
		{ V(-83, 9), V(-43, 9), V(0, 1), { { at = 12, width = 6, bottom = 4, height = 10 }, { at = 28, width = 6, bottom = 4, height = 10 } }, {} },
		{ V(-43, 9), V(-43, 25), V(-1, 0), { { at = 8, width = 5, bottom = 4, height = 10 } }, {} },
		{ V(-43, 25), V(-33, 25), V(0, 1), {}, {} },
		{ V(7, 25), V(17, 25), V(0, 1), {}, {} },
		{ V(17, 9), V(17, 25), V(1, 0), { { at = 8, width = 5, bottom = 4, height = 10 } }, {} },
		{ V(17, 9), V(57, 9), V(0, 1), { { at = 20, width = 6, bottom = 4, height = 10 } }, {} },
		{ V(57, 9), V(83, 9), V(0, 1), {}, {} },
		{ V(83, -25), V(83, 9), V(1, 0), { { at = 10, width = 4, bottom = 7, height = 11 } }, {} },
		{ V(-33, 25), V(-33, 29), V(-1, 0), {}, {} },
		{ V(-33, 45), V(-33, 49), V(-1, 0), {}, {} },
		{ V(7, 25), V(7, 49), V(1, 0), { { at = 12, width = 6, bottom = 4, height = 10 } }, {} },
		{ V(-33, 49), V(7, 49), V(0, 1), { { at = 10, width = 8, height = 9 }, { at = 30, width = 7, bottom = 3, height = 8 } }, { { at = 10, width = 8, height = 9 }, { at = 30, width = 7, bottom = 3, height = 8 } } },
		{ V(-63, 29), V(-43, 29), V(0, -1), {}, {} },
		{ V(-63, 45), V(-43, 45), V(0, 1), {}, {} },
		{ V(-63, 29), V(-63, 45), V(-1, 0), {}, {} },
	}
	for _, w in walls do
		local a, b, n = w[1], w[2], w[3]
		local function off(d)
			return a + n * d, b + n * d
		end
		local a1, b1 = off(0.6)
		B.wall(ext, a1, b1, 0, WALL_H + 0.2, 0.2, SIDING, M.WoodPlanks, w[4])
		local a2, b2 = off(0.75)
		B.wall(ext, a2, b2, 0, 2.6, 0.12, BRICK, M.Brick, w[5])
		B.wall(ext, a2, b2, WALL_H - 0.4, 0.8, 0.14, TRIM, M.SmoothPlastic, {})
	end
	-- Pitched roofs. ridgeAlongX: slopes run along Z; otherwise along X.
	local function roof(x0, x1, z0, z1, ridgeAlongX, rise, color)
		local y0 = WALL_H + 1
		local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
		local parts = {}
		if ridgeAlongX then
			local half = (z1 - z0) / 2
			table.insert(parts, B.wedge(ext, Vector3.new(x1 - x0, rise, half), CFrame.new(cx, y0 + rise / 2, z0 + half / 2), color, M.Slate))
			table.insert(parts, B.wedge(ext, Vector3.new(x1 - x0, rise, half), CFrame.new(cx, y0 + rise / 2, z1 - half / 2) * CFrame.Angles(0, math.pi, 0), color, M.Slate))
			B.part(ext, Vector3.new(x1 - x0 + 0.6, 0.6, 0.9), CFrame.new(cx, y0 + rise + 0.1, cz), ROOF_DARK, M.Slate, { CanCollide = false })
		else
			local half = (x1 - x0) / 2
			table.insert(parts, B.wedge(ext, Vector3.new(z1 - z0, rise, half), CFrame.new(x0 + half / 2, y0 + rise / 2, cz) * CFrame.Angles(0, math.rad(90), 0), color, M.Slate))
			table.insert(parts, B.wedge(ext, Vector3.new(z1 - z0, rise, half), CFrame.new(x1 - half / 2, y0 + rise / 2, cz) * CFrame.Angles(0, math.rad(-90), 0), color, M.Slate))
			B.part(ext, Vector3.new(0.9, 0.6, z1 - z0 + 0.6), CFrame.new(cx, y0 + rise + 0.1, cz), ROOF_DARK, M.Slate, { CanCollide = false })
		end
		-- eaves board all around
		B.part(ext, Vector3.new(x1 - x0 + 0.4, 0.5, z1 - z0 + 0.4), CFrame.new(cx, y0 - 0.25, cz), TRIM, M.SmoothPlastic, { CanCollide = false })
		for _, p in parts do
			p.CanCollide = false
		end
	end
	roof(-85, 85, -27.5, 11.5, true, 10, ROOF) -- main row of rooms
	roof(-44.5, 18.5, 10.5, 26.5, false, 8, ROOF) -- playroom bump
	roof(-34.5, 8.5, 26, 50.5, false, 8, ROOF) -- hall
	roof(-64.5, -32.5, 28, 46, true, 6, ROOF_DARK) -- stair house
	-- chimney above the playroom fireplace
	B.part(ext, Vector3.new(4, 14, 4), CFrame.new(-41, WALL_H + 7, 13), BRICK, M.Brick, { CanCollide = false })
	B.part(ext, Vector3.new(4.8, 0.8, 4.8), CFrame.new(-41, WALL_H + 14.2, 13), ROOF_DARK, M.Slate, { CanCollide = false })
	-- little dormer sign on the front roof
	for _, d in ext:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanCollide = false
			B.tag(d, "Roof")
		end
	end
	-- the roof/skins should not hide the yard sign etc. for pathfinding: make skins non-collidable too
end

-- CFrame at floor position (x, y, z) whose front (LookVector) points along (dx, dz).
local function cfAt(x: number, y: number, z: number, dx: number?, dz: number?): CFrame
	local pos = Vector3.new(x, y, z)
	return CFrame.lookAt(pos, pos + Vector3.new(dx or 0, 0, dz or -1))
end

local function buildStructure(ctx)
	local model, floors, structure = ctx.Model, ctx.Floors, ctx.Structure

	-- Ground (grass) with a hole above the basement, plus basement roof cap.
	local grassTop = 0
	local function grass(x0, z0, x1, z1)
		B.floor(floors, x0, z0, x1, z1, grassTop, P.Grass, M.Grass, 2)
	end
	grass(-110, -130, 110, 12) -- north of the basement band (includes yard + street)
	grass(-110, 12, -83, 80)
	grass(-150, 80, 150, 150) -- front yard + street area
	grass(-33, 12, 110, 80)
	grass(-43, 12, -33, 29)
	grass(-43, 45, -33, 80)
	grass(-83, 52, -43, 80)
	-- basement roof (concrete underside + grass cap) minus the stair shaft X[-63,-43] Z[29,45]
	local function roof(x0, z0, x1, z1)
		B.floor(structure, x0, z0, x1, z1, -0.2, Color3.fromRGB(70, 66, 76), M.Concrete, 1)
		grass(x0, z0, x1, z1)
	end
	roof(-83, 12, -43, 29)
	roof(-83, 45, -43, 52)
	roof(-83, 29, -63, 45)

	-- Room floors (top at 0.2).
	local FT = 0.2
	B.floor(floors, -83, -25, -43, 9, FT, P.Cream, M.SmoothPlastic, 0.4).Name = "KitchenFloor"
	B.floor(floors, -43, -25, 17, 25, FT, Color3.fromRGB(235, 205, 165), M.WoodPlanks, 0.4).Name = "PlayroomFloor"
	B.floor(floors, 17, -25, 57, 9, FT, Color3.fromRGB(60, 70, 120), M.Fabric, 0.4).Name = "BedroomFloor"
	B.floor(floors, 57, -25, 83, 9, FT, Color3.fromRGB(220, 240, 245), M.SmoothPlastic, 0.4).Name = "BathroomFloor"
	B.floor(floors, -33, 25, 7, 49, FT, Color3.fromRGB(200, 160, 120), M.WoodPlanks, 0.4).Name = "HallFloor"
	-- stair house: landing + side walkways
	B.floor(floors, -37, 29, -33, 45, FT, Color3.fromRGB(170, 130, 95), M.WoodPlanks, 0.4)
	B.floor(floors, -63, 29, -37, 33, FT, Color3.fromRGB(170, 130, 95), M.WoodPlanks, 0.4)
	B.floor(floors, -63, 41, -37, 45, FT, Color3.fromRGB(170, 130, 95), M.WoodPlanks, 0.4)
	-- basement floor
	B.floor(floors, -83, 12, -43, 52, BASE_Y, Color3.fromRGB(110, 105, 115), M.Concrete, 1).Name = "BasementFloor"

	-- Kitchen checker tiles.
	for i = 0, 9 do
		for j = 0, 8 do
			if (i + j) % 2 == 0 then
				B.deco(structure, Vector3.new(4, 0.05, 4), CFrame.new(-81 + i * 4, FT + 0.03, -23 + j * 4), Color3.fromRGB(255, 200, 200), M.SmoothPlastic)
			end
		end
	end
	-- Bathroom tiles.
	for x = 58, 82, 2 do
		for z = -24, 8, 2 do
			if ((x + z) / 2) % 2 == 0 then
				B.deco(structure, Vector3.new(2, 0.05, 2), CFrame.new(x, FT + 0.03, z), Color3.fromRGB(180, 225, 240), M.SmoothPlastic)
			end
		end
	end

	-- Walls ---------------------------------------------------------------
	local cream, mint, peach, night = P.Cream, P.Mint, P.Peach, Color3.fromRGB(45, 55, 105)
	local W = function(a, b, color, openings, y0, h, mat)
		return B.wall(structure, a, b, y0 or 0, h or WALL_H, WALL_T, color, mat or M.SmoothPlastic, openings)
	end
	local V = Vector2.new
	-- north wall of the main row (to yard / outside); doors to yard + windows
	W(V(-83, -25), V(-43, -25), cream, { { at = 20, width = 8, bottom = 4, height = 10 } })
	W(V(-43, -25), V(17, -25), peach, {
		{ at = 10, width = 6, bottom = 4, height = 10 },
		{ at = 30, width = 8, height = 9 },
		{ at = 50, width = 6, bottom = 4, height = 10 },
	})
	W(V(17, -25), V(57, -25), night, { { at = 12, width = 6, bottom = 4, height = 10 }, { at = 24, width = 6, height = 9 } })
	W(V(57, -25), V(83, -25), mint, { { at = 13, width = 4, bottom = 7, height = 11 } })
	-- south walls
	W(V(-83, 9), V(-43, 9), cream, { { at = 12, width = 6, bottom = 4, height = 10 }, { at = 28, width = 6, bottom = 4, height = 10 } })
	W(V(-43, 25), V(17, 25), peach, { { at = 30, width = 8, height = 9 } })
	W(V(17, 9), V(57, 9), night, { { at = 20, width = 6, bottom = 4, height = 10 } })
	W(V(57, 9), V(83, 9), mint)
	-- vertical walls (along Z)
	W(V(-83, -25), V(-83, 9), cream, { { at = 17, width = 6, bottom = 4, height = 10 } })
	W(V(-43, -25), V(-43, 25), peach, { { at = 17, width = 8, height = 9 }, { at = 42, width = 5, bottom = 4, height = 10 } })
	W(V(17, -25), V(17, 25), peach, { { at = 17, width = 6, height = 9 }, { at = 42, width = 5, bottom = 4, height = 10 } })
	W(V(57, -25), V(57, 9), night, { { at = 17, width = 5, height = 9 } })
	W(V(83, -25), V(83, 9), mint, { { at = 10, width = 4, bottom = 7, height = 11 } })
	-- hall
	W(V(-33, 25), V(-33, 49), cream, { { at = 12, width = 7, height = 9 } })
	W(V(7, 25), V(7, 49), cream, { { at = 12, width = 6, bottom = 4, height = 10 } })
	W(V(-33, 49), V(7, 49), cream, { { at = 10, width = 8, height = 9 }, { at = 30, width = 7, bottom = 3, height = 8 } })
	-- stair house (above ground) and stair shaft (below ground, outside the basement box)
	local stone = Color3.fromRGB(150, 140, 135)
	W(V(-63, 29), V(-33, 29), cream)
	W(V(-63, 45), V(-33, 45), cream)
	W(V(-63, 29), V(-63, 45), cream)
	W(V(-43, 29), V(-33, 29), stone, nil, BASE_Y, -BASE_Y, M.Brick)
	W(V(-43, 45), V(-33, 45), stone, nil, BASE_Y, -BASE_Y, M.Brick)
	W(V(-33, 29), V(-33, 45), stone, nil, BASE_Y, -BASE_Y, M.Brick)
	-- basement walls
	local bh = -BASE_Y - 1
	W(V(-83, 12), V(-43, 12), stone, nil, BASE_Y, bh, M.Brick)
	W(V(-83, 52), V(-43, 52), stone, nil, BASE_Y, bh, M.Brick)
	W(V(-83, 12), V(-83, 52), stone, nil, BASE_Y, bh, M.Brick)
	W(V(-43, 12), V(-43, 52), stone, { { at = 25, width = 16, height = bh } }, BASE_Y, bh, M.Brick)

	-- Door frames (wood trim) on main doorways for a finished look.
	local function doorFrame(pos: Vector3, alongX: boolean, width: number, height: number)
		local trimC = P.Wood
		local size = if alongX then Vector3.new(0.4, height, WALL_T + 0.3) else Vector3.new(WALL_T + 0.3, height, 0.4)
		local off = if alongX then Vector3.new(width / 2, 0, 0) else Vector3.new(0, 0, width / 2)
		B.deco(structure, size, CFrame.new(pos + off + Vector3.new(0, height / 2, 0)), trimC, M.Wood)
		B.deco(structure, size, CFrame.new(pos - off + Vector3.new(0, height / 2, 0)), trimC, M.Wood)
		local top = if alongX then Vector3.new(width + 0.8, 0.5, WALL_T + 0.3) else Vector3.new(WALL_T + 0.3, 0.5, width + 0.8)
		B.deco(structure, top, CFrame.new(pos + Vector3.new(0, height + 0.25, 0)), trimC, M.Wood)
	end
	doorFrame(Vector3.new(-13, 0, -25), true, 8, 9)
	doorFrame(Vector3.new(41, 0, -25), true, 6, 9)
	doorFrame(Vector3.new(-13, 0, 25), true, 8, 9)
	doorFrame(Vector3.new(-43, 0, -8), false, 8, 9)
	doorFrame(Vector3.new(17, 0, -8), false, 6, 9)
	doorFrame(Vector3.new(57, 0, -8), false, 5, 9)
	doorFrame(Vector3.new(-33, 0, 37), false, 7, 9)
	doorFrame(Vector3.new(-23, 0, 49), true, 8, 9)

	-- Baseboards along the inside of main rooms.
	for _, seg in {
		{ -83, -24.4, -43, -24.4 }, { -43, -24.4, 17, -24.4 }, { 17, -24.4, 57, -24.4 }, { 57, -24.4, 83, -24.4 },
	} do
		B.deco(structure, Vector3.new(math.abs(seg[3] - seg[1]), 0.6, 0.2), CFrame.new((seg[1] + seg[3]) / 2, 0.5, seg[2]), P.White)
	end

	-- Ceilings (client hides them while the local player is inside).
	local function ceiling(x0, z0, x1, z1, color)
		local c = B.floor(structure, x0, z0, x1, z1, WALL_H + 1, color, M.SmoothPlastic, 1)
		c.CastShadow = true
		B.tag(c, "Ceiling")
		return c
	end
	ceiling(-83.5, -25.5, -42.5, 9.5, P.Cream)
	ceiling(-43, -25.5, 17, 25.5, P.Cream)
	ceiling(17, -25.5, 57, 9.5, night)
	ceiling(57, -25.5, 83.5, 9.5, P.White)
	ceiling(-33.5, 25, 7.5, 49.5, P.Cream)
	ceiling(-63.5, 28.5, -33, 45.5, P.Cream)

	-- Stairs down to the basement: steps from x = -37 (y 0) to x = -61 (y -16), z 33..41.
	local steps = 16
	for i = 1, steps do
		local x = -37 - (i - 0.5) * (24 / steps)
		local topY = -(i * 16 / steps)
		B.part(floors, Vector3.new(24 / steps, 1, 8), CFrame.new(x, topY - 0.5, 37), Color3.fromRGB(160, 120, 90), M.WoodPlanks)
	end
	-- A smooth invisible ramp so babies (pathfinding) and players move nicely.
	local rampLen = math.sqrt(24 ^ 2 + 16 ^ 2)
	B.part(floors, Vector3.new(8, 0.4, rampLen), CFrame.new(-49, -8, 37) * CFrame.Angles(0, math.rad(90), 0) * CFrame.Angles(-math.atan2(16, 24), 0, 0), P.White, M.SmoothPlastic, { Transparency = 1, Name = "StairRamp" })
	-- railings along the stair edges (prevent falling into the shaft from the walkways)
	for _, z in { 33, 41 } do
		B.part(structure, Vector3.new(26, 3, 0.4), CFrame.new(-50, 1.5, z), P.Wood, M.Wood)
		for x = -62, -38, 3 do
			B.deco(structure, Vector3.new(0.3, 3, 0.3), CFrame.new(x, 1.5, z), P.DarkWood, M.Wood)
		end
	end

	-- Basement locked boards (removed when Room:Basement is unlocked).
	local boards = B.model(model, "BasementBoards")
	for i = 0, 3 do
		B.part(boards, Vector3.new(0.6, 0.8, 8), CFrame.new(-33.4, 1.5 + i * 2, 37) * CFrame.Angles(math.rad((i % 2) * 8 - 4), 0, 0), P.DarkWood, M.WoodPlanks)
	end
	B.part(boards, Vector3.new(0.8, 9, 7), CFrame.new(-33.6, 4.5, 37), P.DarkWood, M.WoodPlanks, { Transparency = 1 })
	local sign = B.deco(boards, Vector3.new(0.2, 1.6, 4), CFrame.new(-32.6, 6, 37), P.Yellow)
	B.surfaceText(sign, Enum.NormalId.Right, "⛔ 5", { TextColor3 = P.Plum })
	boards:SetAttribute("RemoveIfUnlocked", "Room:Basement")

	-- Room volumes (room detection, darkness etc.)
	local rv = ctx.RoomVolumes
	B.roomVolume(rv, "Kitchen", -83, -25, -43, 9, 0, WALL_H)
	B.roomVolume(rv, "Playroom", -43, -25, 17, 25, 0, WALL_H)
	B.roomVolume(rv, "Bedroom", 17, -25, 57, 9, 0, WALL_H)
	B.roomVolume(rv, "Bathroom", 57, -25, 83, 9, 0, WALL_H)
	B.roomVolume(rv, "Hall", -33, 25, 7, 49, 0, WALL_H)
	B.roomVolume(rv, "Stairs", -63, 29, -33, 45, BASE_Y, WALL_H - BASE_Y)
	B.roomVolume(rv, "Basement", -83, 12, -43, 52, BASE_Y, -BASE_Y)
	B.roomVolume(rv, "Yard", -45, -85, 45, -25, 0, 30)
	B.roomVolume(rv, "Outside", -110, -130, 110, -85, -5, 40)
	B.roomVolume(rv, "Front", -110, 49.5, 110, 150, -5, 40)
end

function Template.build(parent: Instance?): Model
	local model = B.model(nil, "DaycareTemplate")
	local origin = B.root(model, CFrame.new(0, 0, 0))
	origin.Name = "Origin"
	local ctx = {
		Model = model,
		Floors = B.folder(model, "Floors"),
		Structure = B.folder(model, "Structure"),
		Rooms = B.folder(model, "Rooms"),
		Markers = B.folder(model, "Markers"),
		RoomVolumes = B.folder(model, "RoomVolumes"),
		B = B,
		F = F,
		K = K,
		O = O,
		cfAt = cfAt,
		BaseY = BASE_Y,
		WallH = WALL_H,
	}
	B.folder(model, "Dynamic")
	buildStructure(ctx)
	buildExterior(ctx)
	local scenery = B.model(model, "Scenery")
	O.forest(scenery, -145, -128, 145, 145, Vector3.new(0, 0, -10), 150, {
		{ -92, -30, 92, 56 }, -- the building
		{ -50, -90, 50, -20 }, -- yard
		{ -150, -110, 150, -88 }, -- back street
		{ -70, 44, 30, 96 }, -- front yard + porch
		{ -150, 84, 150, 110 }, -- front street + sidewalk
	}, 14, 77)
	for _, name in { "Kitchen", "Playroom", "Bedroom", "Bathroom", "Hall", "Yard", "Basement", "Front" } do
		local mod = RoomsFolder:FindFirstChild(name)
		if mod then
			local ok, err = pcall(function()
				local roomModel = B.model(ctx.Rooms, name)
				ctx.Room = roomModel
				require(mod)(ctx)
			end)
			if not ok then
				warn("[MapBuilder] room failed:", name, err)
			end
		end
	end
	-- Optimization: small decorative parts never collide; everything is anchored.
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d.Size.Magnitude < 1.2 then
				d.CastShadow = false
				d.CanCollide = false
			end
		end
	end
	model.Parent = parent
	return model
end

return Template
