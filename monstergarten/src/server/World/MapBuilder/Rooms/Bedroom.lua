-- Bedroom X[17,57] Z[-25,9]: 8 cribs, curtains, night lights, starry walls.
return function(ctx)
	local B, F, cfAt, R = ctx.B, ctx.F, ctx.cfAt, ctx.Room
	local P = B.Palette
	local blankets = { P.Lavender, P.Mint, P.Pink, P.Peach, P.Yellow, P.Blue, P.Cream, P.Pumpkin }

	local n = 0
	for _, x in { 24, 32, 52 } do
		n += 1
		F.crib(R, cfAt(x, 0.2, -19.5, 0, 1), blankets[n])
		F.mobile(R, Vector3.new(x, 11, -19.5))
	end
	for _, x in { 22, 29.5, 37, 44.5, 52 } do
		n += 1
		F.crib(R, cfAt(x, 0.2, 3, 0, -1), blankets[n])
		F.mobile(R, Vector3.new(x, 11, 3))
	end
	F.rug(R, cfAt(37, 0.2, -8), Vector2.new(30, 6), P.Lavender, nil)
	-- Night lamps
	F.floorLamp(R, cfAt(19, 0.2, -23), P.Lavender)
	F.floorLamp(R, cfAt(55, 0.2, -23.2), P.Lavender)
	F.floorLamp(R, cfAt(55, 0.2, 7.5), P.Mint)
	-- Curtain switch by the playroom door + curtains on windows
	F.curtainSwitch(R, cfAt(17.8, 0.2, -2.5, 1, 0))
	local curtains = B.folder(R, "Curtains")
	F.window(R, CFrame.new(29, 7, -25) * CFrame.Angles(0, math.pi, 0), 6, 6, nil)
	F.curtain(curtains, CFrame.new(29, 7, -24.2), 7, 7, P.Plum)
	F.window(R, CFrame.new(37, 7, 9), 6, 6, nil)
	F.curtain(curtains, CFrame.new(37, 7, 8.2) * CFrame.Angles(0, math.pi, 0), 7, 7, P.Plum)
	-- Door curtain to the yard (drawn with the others)
	-- Darkness zone (active when curtains are closed or power is out)
	local zone = B.marker(R, "DarkZone", CFrame.new(37, 6, -8), Vector3.new(38, 12, 32))
	B.tag(zone, "DarkZone")
	zone:SetAttribute("Need", "Darkness")
	zone:SetAttribute("Rate", 10)
	zone:SetAttribute("Room", "Bedroom")
	zone:SetAttribute("Active", false)
	-- Glowing stars on the walls and ceiling
	local r = Random.new(42)
	local stars = B.folder(R, "Stars")
	for _ = 1, 60 do
		local side = r:NextInteger(1, 4)
		local pos
		if side == 1 then
			pos = Vector3.new(r:NextNumber(18, 56), r:NextNumber(8, 13.5), -24.4)
		elseif side == 2 then
			pos = Vector3.new(r:NextNumber(18, 56), r:NextNumber(8, 13.5), 8.4)
		elseif side == 3 then
			pos = Vector3.new(56.4, r:NextNumber(8, 13.5), r:NextNumber(-24, 8))
		else
			pos = Vector3.new(r:NextNumber(18, 56), 14.4, r:NextNumber(-24, 8))
		end
		local s = r:NextNumber(0.2, 0.45)
		local star = B.deco(stars, Vector3.new(s, s, s), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(255, 245, 190), Enum.Material.Neon)
		if side == 4 then
			B.tag(star, "CeilingDecor")
		end
	end
	B.ball(stars, 2, Vector3.new(50, 12, -24.2), Color3.fromRGB(255, 240, 200), Enum.Material.Neon, { CanCollide = false })
	-- Lullaby rack
	local lr = F.toolRack(R, cfAt(46.5, 0.2, -23.6, 0, 1), "Bedroom")
	lr:SetAttribute("ToolId", "Lullaby")
	local mop = F.toolRack(R, cfAt(55.6, 0.2, -12, -1, 0), "Bedroom")
	mop:SetAttribute("ToolId", "Mop")
	mop:SetAttribute("RequiresUnlock", "Upgrade:ExtraRacks")
	F.changingTable(R, cfAt(19.1, 0.2, -21, 1, 0))
	F.armchair(R, cfAt(54.6, 0.2, -18.5, -1, 0), P.Lavender)
	-- Soft lights
	F.ceilingLamp(R, Vector3.new(27, 13, -8), P.Lavender, 22)
	F.ceilingLamp(R, Vector3.new(47, 13, -8), P.Lavender, 22)
end
