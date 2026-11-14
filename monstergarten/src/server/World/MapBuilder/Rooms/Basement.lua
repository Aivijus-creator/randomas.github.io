-- Basement X[-83,-43] Z[12,52] at Y = -16: electric panel, coffin cribs, charger, workbench, pipes.
return function(ctx)
	local B, F, cfAt, R = ctx.B, ctx.F, ctx.cfAt, ctx.Room
	local P = B.Palette
	local Y = ctx.BaseY

	R:SetAttribute("RequiresUnlock", "Room:Basement")
	F.electricPanel(R, cfAt(-82.4, Y, 22, 1, 0))
	for _, x in { -78, -72, -66 } do
		F.coffinCrib(R, cfAt(x, Y, 15.8, 0, 1))
	end
	F.chargingStation(R, cfAt(-50, Y, 47))
	F.workbench(R, cfAt(-74, Y, 49.4, 0, -1))
	local r1 = F.toolRack(R, cfAt(-64, Y, 50.6, 0, -1), "Basement")
	r1:SetAttribute("ToolId", "Hammer")
	local r2 = F.toolRack(R, cfAt(-58.5, Y, 50.6, 0, -1), "Basement")
	r2:SetAttribute("ToolId", "Flashlight")
	F.shelf(R, cfAt(-82, Y, 40, 1, 0), 6, P.DarkWood, Random.new(31))
	F.shelf(R, cfAt(-82, Y, 32, 1, 0), 6, P.DarkWood, Random.new(32))
	-- boxes
	local r = Random.new(77)
	for i = 1, 7 do
		local s = r:NextNumber(1.5, 2.6)
		B.part(R, Vector3.new(s, s, s), CFrame.new(-46 - r:NextNumber(0, 4), Y + s / 2 + (if i > 5 then 2 else 0), 16 + i * 2.2) * CFrame.Angles(0, r:NextNumber(0, 1), 0), Color3.fromRGB(180, 140, 100), Enum.Material.Cardboard)
	end
	-- pipes along the ceiling
	F.pipes(R, Vector3.new(-83, Y + 14, 14), Vector3.new(-43, Y + 14, 14), 0.9)
	F.pipes(R, Vector3.new(-83, Y + 13.5, 26), Vector3.new(-63, Y + 13.5, 26), 0.6, Color3.fromRGB(120, 130, 140))
	F.pipes(R, Vector3.new(-82, Y, 50), Vector3.new(-82, Y + 15, 50), 0.8)
	F.pipes(R, Vector3.new(-82, Y + 13, 14), Vector3.new(-82, Y + 13, 50), 0.6, Color3.fromRGB(150, 90, 80))
	-- cobwebs in corners
	F.cobweb(R, Vector3.new(-82.5, Y + 14, 12.5), CFrame.new(-82.5, Y + 14, 12.5))
	F.cobweb(R, Vector3.new(-82.5, Y + 14, 51.5), CFrame.new(-82.5, Y + 14, 51.5) * CFrame.Angles(0, math.rad(90), 0))
	F.cobweb(R, Vector3.new(-43.5, Y + 14, 12.5), CFrame.new(-43.5, Y + 14, 12.5) * CFrame.Angles(0, math.rad(-90), 0))
	-- flickering bulbs (client tag "Flicker")
	for _, p in { { -73, 22 }, { -55, 22 }, { -65, 42 } } do
		local lamp = F.ceilingLamp(R, Vector3.new(p[1], Y + 13.5, p[2]), P.Metal, 22)
		B.tag(lamp, "Flicker")
	end
	-- dust particles
	local dust = B.marker(R, "Dust", CFrame.new(-63, Y + 6, 32), Vector3.new(38, 10, 38))
	B.particles(dust, {
		Color = ColorSequence.new(Color3.fromRGB(220, 210, 190)),
		Size = NumberSequence.new(0.12),
		Transparency = NumberSequence.new(0.4),
		Rate = 8,
		Lifetime = NumberRange.new(6, 10),
		Speed = NumberRange.new(0.2, 0.6),
		SpreadAngle = Vector2.new(180, 180),
		LightEmission = 0.2,
	})
	B.tag(dust, "AmbientParticles")
end
