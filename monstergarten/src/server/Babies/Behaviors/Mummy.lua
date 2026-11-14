-- Mumbles: bandages unravel into trails that slow nannies; it wanders off and may escape through the gate.
local B = {}

function B.tantrumStart(baby, ctx)
	baby.Data.GateTime = 0
	if ctx.BabyBase.free(baby) then
		ctx.BabyBase.setState(baby, "Escaping")
	end
end

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	if baby.State ~= "Escaping" and ctx.BabyBase.free(baby) and not baby.Escaped then
		ctx.BabyBase.setState(baby, "Escaping")
	end
	if baby.Path and S.ChaosService.every(baby, "Trail", 1.2, dt) then
		S.HazardService:SpawnTrail(session, ctx.BabyBase.position(baby), baby.Yaw)
	end
	-- pushing at the closed gate long enough opens it
	local gate = session.Gate
	if gate and not gate.Open and (ctx.BabyBase.position(baby) - gate.Inside).Magnitude < 7 then
		baby.Data.GateTime = (baby.Data.GateTime or 0) + dt
		if baby.Data.GateTime > 20 then
			S.FurnitureService:SetGate(session, true)
			baby.Path = nil
		end
	end
end

function B.tantrumEnd(baby, ctx)
	if baby.State == "Escaping" then
		ctx.BabyBase.setState(baby, "Idle")
	end
end

return B
