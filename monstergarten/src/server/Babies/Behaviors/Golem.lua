-- Pebble the golem: stomps every 4 s - camera shake, things fall off shelves (trash), nearby furniture damage.
local CollectionService = game:GetService("CollectionService")
local B = {}

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	if S.ChaosService.every(baby, "Stomp", baby.Def.ChaosInterval, dt) then
		local pos = ctx.BabyBase.position(baby)
		ctx.BabyBase.anim(baby, "Chaos", 0.8)
		session:Effect("Stomp", { Position = pos })
		session:Sound("Env_Stomp", pos)
		session:Shake(0.6, pos, 25)
		for model in session.Furniture do
			if model.Parent then
				local p = model:GetPivot().Position
				local d = (Vector3.new(p.X, pos.Y, p.Z) - pos).Magnitude
				if d < 10 then
					S.FurnitureService:Damage(session, model, 8)
				end
				if d < 15 and CollectionService:HasTag(model, "Shelf") and math.random() < 0.6 then
					S.HazardService:SpawnTrash(session, p + (pos - p).Unit * 2, math.random(1, 2))
				end
			end
		end
	end
end

return B
