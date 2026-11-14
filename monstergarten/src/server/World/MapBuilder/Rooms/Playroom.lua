-- Playroom X[-43,17] Z[-25,25]: fireplace, charging station, toys, ball pit, slide.
return function(ctx)
	local B, F, cfAt, R = ctx.B, ctx.F, ctx.cfAt, ctx.Room
	local P = B.Palette

	F.rug(R, cfAt(-13, 0.2, 0), Vector2.new(28, 22), P.Cream, "puzzle")
	F.fireplace(R, cfAt(-40.6, 0.2, 13, 1, 0))
	local fp2 = F.fireplace(R, cfAt(14.6, 0.2, 14, -1, 0))
	fp2.Name = "Fireplace2"
	fp2:SetAttribute("RequiresUnlock", "Upgrade:SecondFireplace")
	F.chargingStation(R, cfAt(-26, 0.2, 19))
	F.ballPit(R, cfAt(-33, 0.2, -15), 9)
	F.slide(R, cfAt(6, 0.2, -16, 0, 1))
	F.toyBlocks(R, cfAt(-22, 0.2, 9), 6)
	F.toyBlocks(R, cfAt(-19, 0.2, 11), 4)
	F.toyBlocks(R, cfAt(-3, 0.2, 8), 5)
	F.toyShelf(R, cfAt(-24, 0.2, -23.6, 0, 1))
	F.shelf(R, cfAt(-2, 0.2, -23.6, 0, 1), 5, P.Lavender, Random.new(21))
	F.couch(R, cfAt(4, 0.2, 21.5, 0, -1), P.Lavender)
	F.floorLamp(R, cfAt(10.5, 0.2, 22), P.Peach)
	F.floorLamp(R, cfAt(-40, 0.2, 22), P.Mint)
	F.plant(R, cfAt(14.5, 0.2, -22.5), P.Lavender, 1)
	F.plant(R, cfAt(-40.5, 0.2, -22.5), P.Pink, 1)
	F.drawingWall(R, CFrame.new(-13, 11, -24.4) * CFrame.Angles(0, math.pi, 0), 26, Random.new(8))
	F.garland(R, Vector3.new(-42, 12.5, -24), Vector3.new(16, 12.5, -24), 18)
	F.garland(R, Vector3.new(-42, 12.5, 24), Vector3.new(16, 12.5, 24), 18)
	F.window(R, CFrame.new(-33, 7, -25) * CFrame.Angles(0, math.pi, 0), 6, 6, P.Mint)
	F.window(R, CFrame.new(7, 7, -25) * CFrame.Angles(0, math.pi, 0), 6, 6, P.Mint)
	F.window(R, CFrame.new(-43, 7, 17) * CFrame.Angles(0, math.rad(-90), 0), 5, 6, P.Mint)
	F.window(R, CFrame.new(17, 7, 17) * CFrame.Angles(0, math.rad(90), 0), 5, 6, P.Mint)
	local wall = F.wallClock(R, CFrame.new(-13, 11.5, 24.4), 3)
	wall.Name = "PlayroomClock"
	-- Toy bag rack + extra rack (extinguisher)
	local toy = F.toolRack(R, cfAt(-35, 0.2, 23.6, 0, -1), "Playroom")
	toy:SetAttribute("ToolId", "ToyBag")
	local ex = F.toolRack(R, cfAt(-3, 0.2, 23.6, 0, -1), "Playroom")
	ex:SetAttribute("ToolId", "Extinguisher")
	ex:SetAttribute("RequiresUnlock", "Upgrade:ExtraRacks")
	-- Ice mat (level 12)
	local ice = F.iceMat(R, cfAt(8, 0.2, 4))
	ice:SetAttribute("RequiresUnlock", "Room:IceMat")
	-- Lights
	for _, p in { { -28, -12 }, { 2, -12 }, { -28, 12 }, { 2, 12 } } do
		F.ceilingLamp(R, Vector3.new(p[1], 13, p[2]), P.Pink)
	end
end
