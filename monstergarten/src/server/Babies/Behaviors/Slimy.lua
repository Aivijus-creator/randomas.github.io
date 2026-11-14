-- Slimy: eats furniture and grows (x1 -> x2.5), leaves slippery slime; feeding shrinks it back over 5 s.
-- When big it blocks doorways. Touching ink turns it black and it eats the ink.
local B = {}

local MAX_SCALE = 2.5

local function applyScale(baby, scale)
	scale = math.clamp(scale, 1, MAX_SCALE)
	if math.abs(scale - (baby.Data.AppliedScale or 1)) >= 0.05 or scale == 1 then
		baby.Data.AppliedScale = scale
		baby.Scale = scale
		pcall(function()
			baby.Model:ScaleTo(scale)
		end)
		baby.Model:SetAttribute("Scale", scale)
	end
	baby.Scale = scale
end

local function updateBlocker(baby, ctx)
	local big = baby.Scale >= 2 and not baby.CarriedBy
	local blocker = baby.Data.Blocker
	if big then
		if not blocker then
			blocker = Instance.new("Part")
			blocker.Name = "SlimeBlocker"
			blocker.Anchored = true
			blocker.Transparency = 1
			blocker.CanQuery = false
			blocker.CanTouch = false
			blocker.Parent = ctx.Session.Dynamic
			baby.Data.Blocker = blocker
		end
		local s = 2.2 * baby.Scale
		blocker.Size = Vector3.new(s, s, s)
		blocker.CFrame = CFrame.new(baby.Pos + Vector3.new(0, s / 2, 0))
	elseif blocker then
		blocker:Destroy()
		baby.Data.Blocker = nil
	end
end

function B.tantrumTick(baby, dt, ctx)
	if not ctx.BabyBase.canChaos(baby) then
		return
	end
	local S, session = ctx.S, ctx.Session
	local pos = ctx.BabyBase.position(baby)
	local target = S.FurnitureService:Nearest(session, pos, 8)
	if target then
		S.FurnitureService:Damage(session, target, 4 * dt)
		applyScale(baby, baby.Scale + 0.05 * dt)
		if S.ChaosService.every(baby, "Chomp", 1.5, dt) then
			session:Effect("Chomp", { Position = pos + Vector3.new(0, 1, 0) })
		end
	else
		applyScale(baby, baby.Scale + 0.02 * dt)
	end
	if baby.Path and S.ChaosService.every(baby, "Trail", 3, dt) then
		S.HazardService:SpawnPuddle(session, pos, "Slime", 3)
	end
end

function B.alwaysTick(baby, dt, ctx)
	local session = ctx.Session
	if baby.Data.Shrinking then
		applyScale(baby, baby.Scale - (baby.Data.ShrinkRate or 0.3) * dt)
		if baby.Scale <= 1.001 then
			baby.Data.Shrinking = false
			applyScale(baby, 1)
		end
	end
	updateBlocker(baby, ctx)
	-- eat ink
	if not baby.CarriedBy then
		local pos = ctx.BabyBase.position(baby)
		for i = #session.Puddles, 1, -1 do
			local p = session.Puddles[i]
			if p.Kind == "Ink" and (p.Pos - pos).Magnitude < p.Size / 2 + 1 then
				ctx.S.HazardService:RemovePuddle(session, p)
				baby.Model:SetAttribute("Tint", "Black")
				baby.Data.BlackUntil = os.clock() + 12
				session:Effect("Chomp", { Position = pos })
				break
			end
		end
	end
	if baby.Data.BlackUntil and os.clock() > baby.Data.BlackUntil then
		baby.Data.BlackUntil = nil
		baby.Model:SetAttribute("Tint", nil)
	end
end

function B.onFed(baby, _result, _ctx)
	if baby.Scale > 1 then
		baby.Data.Shrinking = true
		baby.Data.ShrinkRate = (baby.Scale - 1) / 5
	end
end

return B
