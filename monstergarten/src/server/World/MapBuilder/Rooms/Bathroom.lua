-- Bathroom X[57,83] Z[-25,9]: 2 tubs with bubbles, sink + mirror, towels, bandage box.
return function(ctx)
	local B, F, cfAt, R = ctx.B, ctx.F, ctx.cfAt, ctx.Room
	local P = B.Palette

	for _, x in { 64, 76 } do
		local tub = F.bathtub(R, cfAt(x, 0.2, -18.5, 0, 1))
		B.tag(tub, "Bath")
		tub:SetAttribute("Need", "Clean")
		tub:SetAttribute("Station", true)
	end
	F.sink(R, cfAt(76, 0.2, 7.2, 0, -1))
	F.mirror(R, CFrame.new(76, 7.5, 8.4), 3, 3.5)
	F.towelRack(R, CFrame.new(82.3, 6.5, -6) * CFrame.Angles(0, math.rad(90), 0))
	F.bandageBox(R, cfAt(82, 0.2, 2, -1, 0))
	local r1 = F.toolRack(R, cfAt(60, 0.2, 7.6, 0, -1), "Bathroom")
	r1:SetAttribute("ToolId", "Mop")
	local r2 = F.toolRack(R, cfAt(65.5, 0.2, 7.6, 0, -1), "Bathroom")
	r2:SetAttribute("ToolId", "Sponge")
	local r3 = F.toolRack(R, cfAt(82, 0.2, -12, -1, 0), "Bathroom")
	r3:SetAttribute("ToolId", "BandageRoll")
	F.plant(R, cfAt(81.5, 0.2, -23), P.Mint, 0.7)
	F.cabinet(R, cfAt(60.5, 0.2, -23.4, 0, 1), 4, P.White)
	F.potty(R, cfAt(78.5, 0.2, 4.5, 0, -1), P.Yellow)
	F.potty(R, cfAt(81, 0.2, 4.5, 0, -1), P.Pink)
	F.laundryBasket(R, cfAt(71, 0.2, 7))
	F.rug(R, cfAt(70, 0.2, -6), Vector2.new(8, 5), P.Pink, "round")
	F.window(R, CFrame.new(70, 9, -25) * CFrame.Angles(0, math.pi, 0), 4, 4, nil)
	F.window(R, CFrame.new(83, 9, -15) * CFrame.Angles(0, math.rad(90), 0), 4, 4, nil)
	F.ceilingLamp(R, Vector3.new(70, 13, -10), P.Mint)
end
