-- Kitchen X[-83,-43] Z[-25,9]: cooking line on the north wall, fridges west, pantry south, table in the middle.
return function(ctx)
	local B, F, K, cfAt, R = ctx.B, ctx.F, ctx.K, ctx.cfAt, ctx.Room
	local P = B.Palette

	-- North wall (front faces +Z): oven, counter, pot, sink, blender, auto feeder in the corner
	K.oven(R, cfAt(-77, 0.2, -22.6, 0, 1))
	K.counter(R, cfAt(-71.5, 0.2, -22.9, 0, 1), 6, P.Mint)
	K.stovePot(R, cfAt(-66, 0.2, -22.6, 0, 1))
	K.sinkCounter(R, cfAt(-60, 0.2, -22.9, 0, 1), 6)
	K.blender(R, cfAt(-53, 0.2, -22.6, 0, 1))
	local feeder = K.autoFeeder(R, cfAt(-47, 0.2, -22.4, 0, 1))
	feeder:SetAttribute("RequiresUnlock", "Upgrade:AutoFeeder")
	-- West wall (front faces +X): fridges, window between them, freezer corner
	K.source(R, cfAt(-80.6, 0.2, -21, 1, 0), "Meat", "🥩", "fridge")
	K.source(R, cfAt(-80.6, 0.2, -16.5, 1, 0), "Milk", "🥛", "fridge")
	K.source(R, cfAt(-80.6, 0.2, -1, 1, 0), "Fish", "🐟", "fridge")
	local corner = F.iceMat(R, cfAt(-79.3, 0.2, 5.3, 1, 0))
	corner.Name = "FreezerCorner"
	-- South wall (front faces -Z): freezer appliance, ice box, pepper, beets, flour
	K.freezer(R, cfAt(-73.5, 0.2, 6.6, 0, -1))
	K.source(R, cfAt(-67.5, 0.2, 6.8, 0, -1), "Ice", "🧊", "icebox")
	K.source(R, cfAt(-62.5, 0.2, 7, 0, -1), "Pepper", "🌶️", "jar")
	K.source(R, cfAt(-57.5, 0.2, 7, 0, -1), "Beet", "🫜", "crate")
	K.source(R, cfAt(-52.5, 0.2, 7, 0, -1), "Flour", "🌾", "sack")
	F.trashBin(R, cfAt(-48, 0.2, 7.3, 0, -1))
	-- East wall (front faces -X): upgrades north of the door, tool racks south of it
	local oven2 = K.oven(R, cfAt(-45.8, 0.2, -21, -1, 0), "Oven2")
	oven2:SetAttribute("RequiresUnlock", "Upgrade:SecondOven")
	local pot2 = K.stovePot(R, cfAt(-45.8, 0.2, -15.6, -1, 0), "Pot2")
	pot2:SetAttribute("RequiresUnlock", "Upgrade:DoublePot")
	local r1 = F.toolRack(R, cfAt(-44.8, 0.2, 1.2, -1, 0), "Kitchen")
	r1:SetAttribute("ToolId", "Extinguisher")
	local r2 = F.toolRack(R, cfAt(-44.8, 0.2, -3.6 + 9.4, -1, 0), "Kitchen")
	r2:SetAttribute("ToolId", "Mop")
	r2:SetAttribute("RequiresUnlock", "Upgrade:ExtraRacks")
	-- Table with chairs and two high chairs in the middle
	F.rug(R, cfAt(-64, 0.2, -9), Vector2.new(16, 11), P.Lavender, "round")
	F.table(R, cfAt(-64, 0.2, -9, 0, 1), Vector2.new(8, 4.5), P.Peach)
	for _, o in { { -66.5, -12.3, 1 }, { -61.5, -12.3, 1 }, { -66.5, -5.7, -1 }, { -61.5, -5.7, -1 } } do
		F.chair(R, cfAt(o[1], 0.2, o[2], 0, o[3]), P.Lavender)
	end
	F.highChair(R, cfAt(-69.8, 0.2, -9, 1, 0), P.Pink)
	F.highChair(R, cfAt(-58.2, 0.2, -9, -1, 0), P.Mint)
	K.hangingPans(R, CFrame.new(-64, 11, -9))
	K.dishShelf(R, CFrame.new(-71.5, 8, -24.2))
	K.dishShelf(R, CFrame.new(-82.2, 8, -13.5) * CFrame.Angles(0, math.rad(90), 0))
	-- Windows
	F.window(R, CFrame.new(-63, 7, -25) * CFrame.Angles(0, math.pi, 0), 8, 6, P.Pink)
	F.window(R, CFrame.new(-71, 7, 9), 6, 6, P.Pink)
	F.window(R, CFrame.new(-55, 7, 9), 6, 6, P.Pink)
	F.window(R, CFrame.new(-83, 7, -8) * CFrame.Angles(0, math.rad(-90), 0), 6, 6, P.Pink)
	F.plant(R, cfAt(-81.3, 0.2, -6.8), P.Pumpkin, 0.7)
	-- Lights
	F.ceilingLamp(R, Vector3.new(-72, 13, -10), P.Peach)
	F.ceilingLamp(R, Vector3.new(-54, 13, -10), P.Peach)
	F.ceilingLamp(R, Vector3.new(-63, 13, 2), P.Peach)
end
