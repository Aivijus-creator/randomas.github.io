-- Dragling: sneezes fire every 6 s during a tantrum (even while carried). Scared -> sneezes at once.
local B = {}

function B.tantrumTick(baby, dt, ctx)
	local Chaos = ctx.S.ChaosService
	if Chaos.every(baby, "Sneeze", baby.Def.ChaosInterval, dt) and not ctx.BabyBase.hasStatus(baby, "Frozen") then
		ctx.BabyBase.anim(baby, "Chaos", 1)
		task.delay(0.5, function()
			if baby.Model.Parent then
				Chaos:FireCone(ctx.Session, baby, 8)
			end
		end)
	end
end

function B.onScared(baby, ctx)
	ctx.BabyBase.anim(baby, "Chaos", 1)
	ctx.S.ChaosService:FireCone(ctx.Session, baby, 8)
end

return B
