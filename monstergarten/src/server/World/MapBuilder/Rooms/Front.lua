-- Front yard south of the hall: street where parents arrive, sidewalk, path, porch with a little roof,
-- swinging entrance doors, sign, flower beds, lamps, hedges. Markers drive the arrival / pick-up scenes.
return function(ctx)
	local B, F, O, cfAt, R, Markers = ctx.B, ctx.F, ctx.O, ctx.cfAt, ctx.Room, ctx.Markers
	local P = B.Palette
	local M = Enum.Material
	local DOOR_X, WALL_Z = -23, 49

	-- street + sidewalk + curb
	B.part(R, Vector3.new(300, 0.2, 14), CFrame.new(0, 0.1, 100), Color3.fromRGB(120, 115, 128), M.Asphalt, { CanCollide = false, Name = "Street" })
	for x = -140, 140, 12 do
		B.deco(R, Vector3.new(5, 0.05, 0.6), CFrame.new(x, 0.22, 100), Color3.fromRGB(250, 240, 200), M.SmoothPlastic)
	end
	B.part(R, Vector3.new(300, 0.4, 6), CFrame.new(0, 0.2, 90), Color3.fromRGB(215, 205, 195), M.Concrete, { CanCollide = false, Name = "Sidewalk" })
	B.part(R, Vector3.new(300, 0.6, 0.6), CFrame.new(0, 0.3, 93.2), Color3.fromRGB(190, 180, 175), M.Concrete, { CanCollide = false })
	-- path from the sidewalk to the porch (wide enough for the parents)
	B.part(R, Vector3.new(10, 0.3, 30), CFrame.new(DOOR_X, 0.15, 72), Color3.fromRGB(225, 200, 160), M.Cobblestone, { CanCollide = false, Name = "FrontPath" })
	for z = 60, 84, 4 do
		B.deco(R, Vector3.new(11, 0.06, 0.25), CFrame.new(DOOR_X, 0.32, z), Color3.fromRGB(200, 175, 140), M.SmoothPlastic)
	end
	-- porch: deck, steps, posts, little roof
	local porch = B.model(R, "Porch")
	B.part(porch, Vector3.new(16, 0.8, 7), CFrame.new(DOOR_X, 0.4, WALL_Z + 4), P.Wood, M.WoodPlanks)
	B.part(porch, Vector3.new(10, 0.4, 2), CFrame.new(DOOR_X, 0.2, WALL_Z + 8.5), P.DarkWood, M.WoodPlanks)
	for _, sx in { -7.4, 7.4 } do
		B.part(porch, Vector3.new(0.8, 9, 0.8), CFrame.new(DOOR_X + sx, 4.9, WALL_Z + 7), P.White, M.Wood)
		B.ball(porch, 1.1, Vector3.new(DOOR_X + sx, 9.6, WALL_Z + 7), P.Pink, M.SmoothPlastic, { CanCollide = false })
	end
	local roofY = 10
	B.wedge(porch, Vector3.new(17, 2.2, 4.5), CFrame.new(DOOR_X, roofY + 1.1, WALL_Z + 2.25), Color3.fromRGB(176, 104, 132), M.Slate, { CanCollide = false })
	B.wedge(porch, Vector3.new(17, 2.2, 4.5), CFrame.new(DOOR_X, roofY + 1.1, WALL_Z + 6.75) * CFrame.Angles(0, math.pi, 0), Color3.fromRGB(176, 104, 132), M.Slate, { CanCollide = false })
	B.part(porch, Vector3.new(17.4, 0.4, 9.4), CFrame.new(DOOR_X, roofY - 0.2, WALL_Z + 4.5), P.White, M.SmoothPlastic, { CanCollide = false })
	local lamp = B.ball(porch, 1, Vector3.new(DOOR_X, roofY - 1, WALL_Z + 4.5), Color3.fromRGB(255, 200, 130), M.Neon, { CanCollide = false })
	B.pointLight(lamp, Color3.fromRGB(255, 190, 120), 18, 1.2)
	-- sign above the door
	local sign = B.part(porch, Vector3.new(12, 2.4, 0.4), CFrame.new(DOOR_X, roofY + 3.4, WALL_Z + 1) * CFrame.Angles(0, math.pi, 0), P.Plum, M.SmoothPlastic, { CanCollide = false })
	B.surfaceText(sign, Enum.NormalId.Front, "🍼 MONSTERGARTEN", { TextColor3 = Color3.fromRGB(255, 220, 140) })
	-- doormat
	B.deco(porch, Vector3.new(5, 0.05, 2.4), CFrame.new(DOOR_X, 0.83, WALL_Z + 2.2), P.Pumpkin, M.Fabric)

	-- entrance doors (two leaves, opened by the arrival / pick-up scenes)
	local entrance = B.model(R, "EntranceDoor")
	B.root(entrance, CFrame.new(DOOR_X, 4.5, WALL_Z))
	local doors = B.folder(entrance, "Doors")
	for _, sx in { -1, 1 } do
		local hinge = CFrame.new(DOOR_X + sx * 4, 4.5, WALL_Z)
		local leaf = B.part(doors, Vector3.new(3.9, 8.8, 0.35), hinge * CFrame.new(-sx * 1.95, 0, 0), P.Mint, M.WoodPlanks, { Name = "Door" })
		B.deco(doors, Vector3.new(1.6, 1.6, 0.4), hinge * CFrame.new(-sx * 1.95, 2, 0), Color3.fromRGB(200, 230, 255), M.Glass)
		B.ball(doors, 0.45, (hinge * CFrame.new(-sx * 3.4, 0, 0.3)).Position, P.Yellow, M.Metal, { CanCollide = false })
		leaf:SetAttribute("ClosedCF", leaf.CFrame)
		-- doors swing outwards (towards +Z) so they never block the hall
		leaf:SetAttribute("OpenCF", hinge * CFrame.Angles(0, sx * math.rad(100), 0) * CFrame.new(-sx * 1.95, 0, 0))
	end
	B.tag(entrance, "EntranceDoor")
	entrance:SetAttribute("Open", false)

	-- hedges + flower beds along the path, low fence by the sidewalk
	for _, side in { -1, 1 } do
		local x = DOOR_X + side * 9
		B.part(R, Vector3.new(3, 2.6, 22), CFrame.new(x, 1.3, 72), Color3.fromRGB(110, 170, 105), M.Grass, { CanCollide = false })
		O.flowers(R, cfAt(DOOR_X + side * 14, 0, 62), 12, Random.new(70 + side))
		O.flowers(R, cfAt(DOOR_X + side * 14, 0, 80), 12, Random.new(90 + side))
		O.fence(R, Vector3.new(DOOR_X + side * 6, 0, 86), Vector3.new(DOOR_X + side * 58, 0, 86), P.White)
		O.lampPost(R, cfAt(DOOR_X + side * 7, 0, 87, 0, -1), nil)
	end
	-- trees, bench, mailbox, big welcome board
	O.tree(R, cfAt(-62, 0, 64), 1.2, Color3.fromRGB(200, 160, 220))
	O.tree(R, cfAt(20, 0, 66), 1.1)
	O.tree(R, cfAt(-90, 0, 70), 1.0, Color3.fromRGB(255, 170, 120))
	O.tree(R, cfAt(46, 0, 72), 1.3)
	O.bench(R, cfAt(DOOR_X + 16, 0, 56, 0, 1), P.Lavender)
	O.mailbox(R, cfAt(DOOR_X - 8, 0, 88, 0, 1))
	O.pumpkin(R, cfAt(DOOR_X - 6.5, 0.8, WALL_Z + 7.5), 1.6, true)
	O.pumpkin(R, cfAt(DOOR_X + 6.5, 0.8, WALL_Z + 7.5), 1.4, true)
	local board = B.part(R, Vector3.new(10, 5, 0.5), CFrame.new(DOOR_X + 22, 5, 84), P.Cream, M.WoodPlanks, { CanCollide = false })
	B.part(R, Vector3.new(0.6, 5, 0.6), CFrame.new(DOOR_X + 18, 2.5, 84.3), P.DarkWood, M.Wood)
	B.part(R, Vector3.new(0.6, 5, 0.6), CFrame.new(DOOR_X + 26, 2.5, 84.3), P.DarkWood, M.Wood)
	B.surfaceText(board, Enum.NormalId.Back, "MONSTERGARTEN\n🐉 👻 🟢 🦇", { TextColor3 = P.Plum })

	-- markers for the arrival / pick-up scenes
	local function marker(name, x, z, y)
		local m = B.marker(Markers, name, CFrame.new(x, y or 1.5, z))
		B.tag(m, name)
		return m
	end
	marker("ParentStart", -62, 100) -- parents walk in along the street from here
	marker("ParentCorner", DOOR_X, 98) -- turn into the path
	marker("PorchSpot", DOOR_X, 68) -- parents stop here (centre of the group)
	marker("DoorOutside", DOOR_X, WALL_Z + 3)
	marker("DoorInside", DOOR_X, WALL_Z - 5)
	local cam = B.marker(Markers, "FrontCamera", CFrame.lookAt(Vector3.new(DOOR_X + 26, 18, 104), Vector3.new(DOOR_X, 6, 60)))
	B.tag(cam, "FrontCamera")
end
