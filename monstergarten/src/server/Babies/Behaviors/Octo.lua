-- Octo: sprays ink - black slippery floor puddles and splats on walls (lower the building score).
local B = {}

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	if S.ChaosService.every(baby, "Ink", baby.Def.ChaosInterval, dt) then
		local pos = ctx.BabyBase.position(baby)
		ctx.BabyBase.anim(baby, "Chaos", 1)
		session:Effect("InkSpray", { Position = pos + Vector3.new(0, 1, 0) })
		session:Sound("Env_Splat", pos)
		S.HazardService:SpawnPuddle(session, pos + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2)), "Ink", 5)
		if math.random() < 0.6 then
			S.HazardService:SplatWall(session, pos)
		end
		for _, o in S.ChaosService:BabiesNear(session, pos, 4, baby) do
			S.StatusEffectService:Apply(session, o, "Inked", 8)
		end
	end
end

return B
