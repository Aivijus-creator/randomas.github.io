-- Sprout: roots burst through the floor and block paths - cut them with garden shears. Hates fire.
local B = {}

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	if S.ChaosService.every(baby, "Roots", baby.Def.ChaosInterval, dt) then
		local a = math.random() * math.pi * 2
		local pos = ctx.BabyBase.position(baby) + Vector3.new(math.cos(a), 0, math.sin(a)) * 4
		ctx.BabyBase.anim(baby, "Chaos", 1)
		S.HazardService:SpawnRoot(session, pos, a)
	end
end

return B
