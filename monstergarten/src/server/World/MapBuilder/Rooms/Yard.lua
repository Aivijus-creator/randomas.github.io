-- Yard X[-45,45] Z[-85,-25]: sandbox, swings, berry bushes, rocks, moving sun spots, greenhouse, gate.
return function(ctx)
	local B, F, O, cfAt, R, Markers = ctx.B, ctx.F, ctx.O, ctx.cfAt, ctx.Room, ctx.Markers
	local P = B.Palette

	-- Paths
	O.path(R, Vector3.new(-13, 0, -25), Vector3.new(-13, 0, -55), 5)
	O.path(R, Vector3.new(-13, 0.02, -55), Vector3.new(0, 0.02, -84), 5)
	O.path(R, Vector3.new(41, 0.06, -25), Vector3.new(30, 0.06, -50), 4)
	O.path(R, Vector3.new(30, 0.04, -50), Vector3.new(-13, 0.04, -55), 4)
	O.sandbox(R, cfAt(-30, 0, -42), 10)
	O.swing(R, cfAt(18, 0, -40, 0, 1))
	for _, z in { -50, -60, -70 } do
		O.bush(R, cfAt(-41, 0, z), true)
	end
	O.bush(R, cfAt(40, 0, -32), false)
	O.bush(R, cfAt(-8, 0, -30), false)
	O.rockPile(R, cfAt(36, 0, -72))
	O.sunSpot(R, Vector3.new(-18, 0.2, -62), 7)
	O.sunSpot(R, Vector3.new(8, 0.2, -66), 7)
	O.sunSpot(R, Vector3.new(-28, 0.2, -74), 6)
	O.greenhouse(R, cfAt(34, 0, -58, -1, 0))
	-- Trees, flowers, benches, lamps
	O.tree(R, cfAt(-38, 0, -80), 1.1)
	O.tree(R, cfAt(38, 0, -82), 1.2, Color3.fromRGB(150, 200, 120))
	O.tree(R, cfAt(-40, 0, -30), 0.9, Color3.fromRGB(200, 170, 220))
	O.tree(R, cfAt(14, 0, -78), 0.8)
	for _, p in { { -20, -30 }, { 0, -44 }, { 25, -30 }, { -30, -58 }, { 20, -75 } } do
		O.flowers(R, cfAt(p[1], 0, p[2]), 10, Random.new(p[1] * 7 + p[2]))
	end
	O.bench(R, cfAt(0, 0, -30, 0, -1), P.Peach)
	O.picnicTable(R, cfAt(-26, 0, -60))
	O.playhouse(R, cfAt(22, 0, -70, 0, 1))
	O.hopscotch(R, cfAt(-3, 0, -40))
	for _, p in { { -42, -40 }, { -42, -80 }, { 42, -45 }, { 42, -64 }, { 30, -82 }, { -20, -82 } } do
		O.bush(R, cfAt(p[1], 0, p[2]), false)
	end
	O.lampPost(R, cfAt(-16, 0, -50), "RoomLight")
	O.lampPost(R, cfAt(10, 0, -80), "RoomLight")
	-- Fences around (north fence has the gate at x = 0)
	O.fence(R, Vector3.new(-45, 0, -85), Vector3.new(-5, 0, -85), P.White)
	O.fence(R, Vector3.new(5, 0, -85), Vector3.new(45, 0, -85), P.White)
	O.fence(R, Vector3.new(-45, 0, -85), Vector3.new(-45, 0, -25), P.White)
	O.fence(R, Vector3.new(45, 0, -85), Vector3.new(45, 0, -25), P.White)
	O.gate(R, CFrame.new(0, 0, -85), 8)
	-- Yard tool racks on the playroom's outer wall (front faces -Z)
	for i, tool in { "Net", "Shears", "WateringCan" } do
		local m = F.toolRack(R, cfAt(-26 - (i - 1) * 5, 0, -25.6, 0, -1), "Yard")
		m:SetAttribute("ToolId", tool)
	end
	-- Butterflies (ambient particles)
	local bf = B.marker(R, "Butterflies", CFrame.new(0, 4, -55), Vector3.new(80, 2, 50))
	B.particles(bf, {
		Texture = "rbxasset://textures/particles/sparkles_main.dds",
		Color = ColorSequence.new(P.Pink, P.Yellow),
		Size = NumberSequence.new(0.35),
		Rate = 3,
		Lifetime = NumberRange.new(4, 7),
		Speed = NumberRange.new(1, 2),
		SpreadAngle = Vector2.new(180, 180),
		LightEmission = 0.4,
	})
	B.tag(bf, "AmbientParticles")
	-- Street outside the gate (where escaping babies run)
	O.path(R, Vector3.new(-100, 0, -100), Vector3.new(100, 0, -100), 12, Color3.fromRGB(120, 115, 125))
	for _, x in { -60, -20, 20, 60 } do
		O.lampPost(R, cfAt(x, 0, -108), nil)
	end
	O.tree(R, cfAt(-70, 0, -90), 1.2)
	O.tree(R, cfAt(70, 0, -92), 1.0)
	local esc = B.marker(Markers, "EscapePoint", CFrame.new(0, 1.5, -105))
	B.tag(esc, "EscapePoint")
end
