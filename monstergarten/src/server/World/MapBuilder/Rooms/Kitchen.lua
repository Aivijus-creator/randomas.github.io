-- Kitchen X[-83,-43] Z[-25,9]: appliances in a ring, ingredient sources, table in the middle.
return function(ctx)
	local B, F, K, cfAt, R = ctx.B, ctx.F, ctx.K, ctx.cfAt, ctx.Room
	local P = B.Palette

	-- North wall (front faces +Z): oven, counters, pot, blender
	K.oven(R, cfAt(-76, 0.2, -22.6, 0, 1))
	K.counter(R, cfAt(-70, 0.2, -22.9, 0, 1), 6, P.Mint)
	K.stovePot(R, cfAt(-64, 0.2, -22.6, 0, 1))
	K.counter(R, cfAt(-58, 0.2, -22.9, 0, 1), 6, P.Mint)
	K.blender(R, cfAt(-51, 0.2, -22.6, 0, 1))
	-- West wall (front faces +X): fridges
	K.source(R, cfAt(-80.6, 0.2, -16, 1, 0), "Meat", "🥩", "fridge")
	K.source(R, cfAt(-80.6, 0.2, -11.5, 1, 0), "Milk", "🥛", "fridge")
	K.source(R, cfAt(-80.6, 0.2, -2, 1, 0), "Fish", "🐟", "fridge")
	-- South wall (front faces -Z): freezer appliance, ice box, pepper, beets, flour
	K.freezer(R, cfAt(-76, 0.2, 6.6, 0, -1))
	K.source(R, cfAt(-69.5, 0.2, 6.8, 0, -1), "Ice", "🧊", "icebox")
	K.source(R, cfAt(-63, 0.2, 7, 0, -1), "Pepper", "🌶️", "jar")
	K.source(R, cfAt(-57, 0.2, 7, 0, -1), "Beet", "🫜", "crate")
	K.source(R, cfAt(-51, 0.2, 7, 0, -1), "Flour", "🌾", "sack")
	-- Freezer corner (always available cold spot)
	local corner = F.iceMat(R, cfAt(-80, 0.2, 4, 1, 0))
	corner.Name = "FreezerCorner"
	-- Upgrades: second oven, double pot, mega blender, auto feeder
	local oven2 = K.oven(R, cfAt(-45.8, 0.2, -19, -1, 0), "Oven2")
	oven2:SetAttribute("RequiresUnlock", "Upgrade:SecondOven")
	local pot2 = K.stovePot(R, cfAt(-45.8, 0.2, 2, -1, 0), "Pot2")
	pot2:SetAttribute("RequiresUnlock", "Upgrade:DoublePot")
	local feeder = K.autoFeeder(R, cfAt(-63, 0.2, -2, 0, -1))
	feeder:SetAttribute("RequiresUnlock", "Upgrade:AutoFeeder")
	-- Table with little chairs in the middle
	F.table(R, cfAt(-64, 0.2, -11, 0, 1), Vector2.new(7, 4), P.Peach)
	for _, o in { { -66.5, -14 }, { -61.5, -14 }, { -66.5, -8 }, { -61.5, -8 } } do
		F.chair(R, cfAt(o[1], 0.2, o[2], 0, if o[2] < -11 then 1 else -1), P.Lavender)
	end
	K.hangingPans(R, CFrame.new(-64, 11, -11))
	K.dishShelf(R, CFrame.new(-64, 8, -24.2))
	K.dishShelf(R, CFrame.new(-82.2, 8, -7) * CFrame.Angles(0, math.rad(90), 0))
	-- Tool rack + extra rack upgrade
	local r1 = F.toolRack(R, cfAt(-44.8, 0.2, 6, -1, 0), "Kitchen")
	r1:SetAttribute("ToolId", "Extinguisher")
	local r2 = F.toolRack(R, cfAt(-44.8, 0.2, -1, -1, 0), "Kitchen")
	r2:SetAttribute("ToolId", "Mop")
	r2:SetAttribute("RequiresUnlock", "Upgrade:ExtraRacks")
	F.trashBin(R, cfAt(-81.5, 0.2, 7.5, 1, 0))
	-- Windows
	F.window(R, CFrame.new(-63, 7, -25) * CFrame.Angles(0, math.pi, 0), 8, 6, P.Pink)
	F.window(R, CFrame.new(-71, 7, 9), 6, 6, P.Pink)
	F.window(R, CFrame.new(-55, 7, 9), 6, 6, P.Pink)
	F.window(R, CFrame.new(-83, 7, -8) * CFrame.Angles(0, math.rad(-90), 0), 6, 6, P.Pink)
	F.plant(R, cfAt(-46, 0.2, -23.5), P.Pumpkin, 0.8)
	-- Lights
	F.ceilingLamp(R, Vector3.new(-72, 13, -10), P.Peach)
	F.ceilingLamp(R, Vector3.new(-54, 13, -10), P.Peach)
	F.ceilingLamp(R, Vector3.new(-63, 13, 2), P.Peach)
end
