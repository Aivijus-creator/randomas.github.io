-- Ghostie: in a tantrum turns invisible and drifts through walls to other rooms, scaring babies every 10 s.
-- Find it with a flashlight and Catch it, then give it a toy. When happy it sometimes plays hide & seek.
local B = {}

local function randomRoomPoint(session)
	local vols = session.Model:FindFirstChild("RoomVolumes")
	if not vols then
		return nil
	end
	local list = {}
	for _, v in vols:GetChildren() do
		local name = v:GetAttribute("RoomName")
		if name and name ~= "Outside" and name ~= "Stairs" and (name ~= "Basement" or session.IsUnlocked("Room:Basement")) then
			table.insert(list, v)
		end
	end
	local v = list[math.random(1, #list)] :: BasePart
	if not v then
		return nil
	end
	local half = v.Size / 2
	local p = v.Position + Vector3.new(math.random(-100, 100) / 100 * (half.X - 4), 0, math.random(-100, 100) / 100 * (half.Z - 4))
	return Vector3.new(p.X, v.Position.Y - half.Y + 0.2, p.Z)
end

local function drift(baby, ctx)
	local p = randomRoomPoint(ctx.Session)
	if p then
		ctx.BabyAI.glideTo(baby, p)
	end
end

function B.drivesMovement(baby)
	return baby.Hidden
end

function B.tantrumStart(baby, ctx)
	baby.Data.Caught = false
	if baby.CarriedBy then
		return
	end
	ctx.S.BabyService:SetHidden(ctx.Session, baby, true)
	ctx.Session:Effect("GhostVanish", { Uid = baby.Uid })
	drift(baby, ctx)
end

function B.tantrumTick(baby, dt, ctx)
	local S, session = ctx.S, ctx.Session
	if not baby.Hidden then
		return
	end
	if not baby.Path and S.ChaosService.every(baby, "Drift", 12, dt) then
		drift(baby, ctx)
	end
	if S.ChaosService.every(baby, "Haunt", baby.Def.ChaosInterval, dt) then
		local near = S.ChaosService:BabiesNear(session, ctx.BabyBase.position(baby), 16, baby)
		if #near > 0 then
			S.ChaosService:Scare(session, near[math.random(1, #near)])
			session:Sound("Baby_Ghostie_Chaos", ctx.BabyBase.position(baby))
		else
			drift(baby, ctx)
		end
	end
end

function B.tantrumEnd(baby, ctx)
	if baby.Hidden and not baby.HideAndSeek then
		ctx.S.BabyService:SetHidden(ctx.Session, baby, false)
	end
end

function B.happyTick(baby, dt, ctx)
	if baby.Hidden or baby.CarriedBy or baby.State ~= "Idle" and baby.State ~= "Wander" then
		return
	end
	if ctx.S.ChaosService.every(baby, "HideSeek", 60, dt) and ctx.BabyBase.allHappy(baby) and math.random() < 0.35 then
		baby.HideAndSeek = true
		ctx.S.BabyService:SetHidden(ctx.Session, baby, true)
		ctx.Session:Notify("Toast_HideAndSeek", "info")
		drift(baby, ctx)
	end
end

return B
