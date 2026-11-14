-- Yetiny: freezes the floor (slippery ice), freezes other babies for 10 s and puts out fires nearby.
local B = {}

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	if S.ChaosService.every(baby, "Freeze", baby.Def.ChaosInterval, dt) then
		local pos = ctx.BabyBase.position(baby)
		ctx.BabyBase.anim(baby, "Chaos", 1)
		session:Effect("FrostBurst", { Position = pos, Radius = 10 })
		session:Sound("Env_Freeze", pos)
		S.HazardService:SpawnPuddle(session, pos, "Ice", 6)
		S.HazardService:ExtinguishNear(session, pos, 10)
		local best, bestD = nil, 10
		for _, o in S.ChaosService:BabiesNear(session, pos, 10, baby) do
			local d = (ctx.BabyBase.position(o) - pos).Magnitude
			if d < bestD and not ctx.BabyBase.hasStatus(o, "Frozen") then
				best, bestD = o, d
			end
		end
		if best then
			S.StatusEffectService:Apply(session, best, "Frozen", 10)
		end
	end
end

return B
