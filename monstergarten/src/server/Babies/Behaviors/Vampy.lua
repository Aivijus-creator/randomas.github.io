-- Vampy: wails loudly (ring, 20 studs) waking everyone: Sleep -30. Needs darkness (curtains, coffins, blackout).
local B = {}

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	if S.ChaosService.every(baby, "Wail", baby.Def.ChaosInterval, dt) then
		local pos = ctx.BabyBase.position(baby)
		ctx.BabyBase.anim(baby, "Chaos", 1.2)
		session:Effect("Wail", { Position = pos, Radius = 20 })
		session:Sound("Env_Wail", pos)
		for _, o in S.ChaosService:BabiesNear(session, pos, 20, baby) do
			ctx.BabyBase.change(o, "Sleep", -30)
			if o.State == "Asleep" then
				S.BabyService:LeaveStation(session, o)
			end
		end
	end
end

return B
