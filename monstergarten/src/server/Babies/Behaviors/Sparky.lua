-- Sparky: 5 s of warning sparks, then a daycare-wide blackout (fix it at the electric panel).
local B = {}

function B.tantrumStart(baby, ctx)
	baby.Data.Warn = 5
	baby.Data.Cooldown = 0
end

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if ctx.BabyBase.hasStatus(baby, "Frozen") then
		return
	end
	if baby.Data.Cooldown and baby.Data.Cooldown > 0 then
		baby.Data.Cooldown -= dt
		return
	end
	if not session.PowerOn then
		return
	end
	if S.ChaosService.every(baby, "Sparks", 1, dt) then
		session:Effect("Sparks", { Uid = baby.Uid, Position = ctx.BabyBase.position(baby) + Vector3.new(0, 1, 0) })
		session:Sound("Env_Spark", ctx.BabyBase.position(baby))
	end
	baby.Data.Warn = (baby.Data.Warn or 5) - dt
	if baby.Data.Warn <= 0 then
		baby.Data.Warn = 5
		baby.Data.Cooldown = baby.Def.ChaosInterval
		ctx.BabyBase.anim(baby, "Chaos", 1)
		S.FurnitureService:SetPower(session, false)
	end
end

return B
