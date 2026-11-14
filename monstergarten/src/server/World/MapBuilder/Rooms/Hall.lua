-- Hall X[-33,7] Z[25,49]: parent drop-off window, tool racks, big clock, shift board, spawns.
return function(ctx)
	local B, F, O, cfAt, R, Markers = ctx.B, ctx.F, ctx.O, ctx.cfAt, ctx.Room, ctx.Markers
	local P = B.Palette

	-- Parent window in the south wall (opening at x = -3); front faces into the hall (-Z)
	O.dropoffWindow(R, CFrame.new(-3, 5.5, 49) * CFrame.Angles(0, 0, 0))
	-- Tool racks: east wall (front -X) and west wall (front +X)
	local racks = {
		{ cfAt(5.8, 0.2, 29, -1, 0), "Extinguisher" },
		{ cfAt(5.8, 0.2, 33.6, -1, 0), "Mop" },
		{ cfAt(5.8, 0.2, 42, -1, 0), "Flashlight" },
		{ cfAt(5.8, 0.2, 46.4, -1, 0), "Net" },
		{ cfAt(-31.8, 0.2, 28.4, 1, 0), "Hammer" },
		{ cfAt(-31.8, 0.2, 45.6, 1, 0), "TrashBag" },
	}
	for _, r in racks do
		local m = F.toolRack(R, r[1], "Hall")
		m:SetAttribute("ToolId", r[2])
	end
	-- Window on the east wall between racks
	F.window(R, CFrame.new(7, 7, 37) * CFrame.Angles(0, math.rad(90), 0), 6, 6, P.Peach)
	-- Big clock + shift board on the north wall (front faces +Z)
	F.wallClock(R, CFrame.new(-25, 10, 25.6) * CFrame.Angles(0, math.pi, 0), 5)
	F.shiftBoard(R, CFrame.new(1, 8, 25.7) * CFrame.Angles(0, math.pi, 0))
	-- Coat rack, shoe rack, plants, bench
	F.coatRack(R, CFrame.new(-16, 0, 48.3) * CFrame.Angles(0, 0, 0))
	F.shoeRack(R, cfAt(-30, 0.2, 47.6, 0, -1))
	F.plant(R, cfAt(-31.5, 0.2, 42.2), P.Pumpkin, 0.9)
	F.plant(R, cfAt(5.5, 0.2, 38), P.Lavender, 0.9)
	O.bench(R, cfAt(-8, 0.2, 47.2, 0, -1), P.Mint)
	F.rug(R, cfAt(-13, 0.2, 37), Vector2.new(14, 9), P.Peach, "round")
	F.trashBin(R, cfAt(1.5, 0.2, 27, 0, 1))
	-- Heater (warmth station)
	F.heater(R, cfAt(-30, 0.2, 26.4, 0, 1))
	-- Electric panel used while the basement is still locked
	local panel = F.electricPanel(R, cfAt(-25.4, 0.2, 26.4, 0, 1))
	panel.Name = "HallElectricPanel"
	panel:SetAttribute("RemoveIfUnlocked", "Room:Basement")
	-- Spawns
	for i = 0, 5 do
		local m = B.marker(Markers, "PlayerSpawn", CFrame.new(-19 + (i % 3) * 4, 2, 33 + math.floor(i / 3) * 4))
		B.tag(m, "PlayerSpawn")
	end
	for i = 0, 9 do
		local m = B.marker(Markers, "BabySpawn", CFrame.new(-11 + (i % 5) * 3, 1.5, 41 + math.floor(i / 5) * 3))
		B.tag(m, "BabySpawn")
	end
	-- Inspector walk points (one per room)
	for _, p in { { -13, 37 }, { -13, 0 }, { -63, -8 }, { 37, -8 }, { 70, -5 }, { 0, -55 }, { -13, 15 } } do
		local m = B.marker(Markers, "InspectorPoint", CFrame.new(p[1], 1.5, p[2]))
		B.tag(m, "InspectorPoint")
	end
	-- Mystery egg spot near the entrance
	local egg = B.marker(Markers, "EggSpot", CFrame.new(-23, 1, 45))
	B.tag(egg, "EggSpot")
	F.ceilingLamp(R, Vector3.new(-23, 13, 37), P.Peach)
	F.ceilingLamp(R, Vector3.new(-3, 13, 37), P.Peach)
end
