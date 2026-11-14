-- ChaosService: tantrum lifecycle + reusable chaos actions used by baby behaviors.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MathUtil = require(Shared.Util.Math)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local ChaosService = {}
local S

local function ctx(session)
	return S.BabyService.ctxFor(session)
end

function ChaosService:StartTantrum(session, baby, needId: string)
	if baby.Tantrum or baby.State == "Leaving" then
		return
	end
	baby.Tantrum = needId
	baby.ChaosTimer = 1.5
	baby.Model:SetAttribute("Tantrum", needId)
	if baby.State == "Asleep" or baby.State == "Placed" then
		-- tantrums don't stop a baby sitting at the right station, but beds wake them up
		if baby.State == "Asleep" and needId ~= "Sleep" then
			S.BabyService:LeaveStation(session, baby)
		end
	end
	if baby.State == "Idle" or baby.State == "Wander" or baby.State == "Seek" then
		BabyBase.setState(baby, "Tantrum")
	end
	session:Effect("Tantrum", { Uid = baby.Uid, Position = BabyBase.position(baby) })
	session:Sound("Baby_" .. baby.Id .. "_Cry", BabyBase.position(baby))
	if baby.Behavior.tantrumStart then
		baby.Behavior.tantrumStart(baby, ctx(session))
	end
	S.TutorialService:OnEvent(session, "Tantrum", nil)
	S.EventService:OnTantrum(session, baby)
end

function ChaosService:EndTantrum(session, baby)
	if not baby.Tantrum then
		return
	end
	baby.Tantrum = nil
	baby.Model:SetAttribute("Tantrum", "")
	if baby.State == "Tantrum" then
		BabyBase.setState(baby, "Idle")
	end
	if baby.Behavior.tantrumEnd then
		baby.Behavior.tantrumEnd(baby, ctx(session))
	end
	S.BabyService.happy(session, baby, nil)
end

function ChaosService:Tick(session, dt)
	local strength = session:ChaosStrength()
	local c = ctx(session)
	for _, baby in session.BabyList do
		if baby.State == "Leaving" or baby.Arriving then
			continue
		end
		local b = baby.Behavior
		if baby.Tantrum then
			if b.tantrumTick then
				-- chaos interval shrinks with strength
				b.tantrumTick(baby, dt * strength, c)
			end
		elseif b.happyTick then
			b.happyTick(baby, dt, c)
		end
		if b.alwaysTick then
			b.alwaysTick(baby, dt, c)
		end
	end
end

-- Helper: count down a timer on the baby; returns true when it fires (and re-arms).
function ChaosService.every(baby, key: string, interval: number, dt: number): boolean
	local t = (baby.Data[key] or interval) - dt
	if t <= 0 then
		baby.Data[key] = interval
		return true
	end
	baby.Data[key] = t
	return false
end

function ChaosService:OnPowerChanged(session, on: boolean)
	-- Ghosts vanish in the dark unless lit by a flashlight (client renders by PowerOn + flashlight).
	for _, b in session.BabyList do
		if b.Behavior.onPower then
			b.Behavior.onPower(b, on, ctx(session))
		end
	end
end

-- Shared chaos actions --------------------------------------------------------------

-- Dragling fire cone: ignites flammable furniture and babies in front.
function ChaosService:FireCone(session, baby, range: number)
	local pos = BabyBase.position(baby)
	local look = baby.Root.CFrame.LookVector
	local dir = Vector3.new(look.X, 0, look.Z)
	dir = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
	session:Effect("FireSneeze", { Uid = baby.Uid, Position = pos + Vector3.new(0, 1, 0), Direction = dir, Range = range })
	session:Sound("Baby_Dragling_Chaos", pos)
	for _, o in session.BabyList do
		if o ~= baby and MathUtil.inCone(pos, dir, BabyBase.position(o), range, 30) then
			S.StatusEffectService:Apply(session, o, "Burning", 5)
		end
	end
	local hitFurniture = false
	for model in session.Furniture do
		if model.Parent then
			local p = model:GetPivot().Position
			if MathUtil.inCone(pos, dir, Vector3.new(p.X, pos.Y, p.Z), range + 1.5, 30) then
				S.HazardService:Ignite(session, model, p)
				hitFurniture = true
				break
			end
		end
	end
	if not hitFurniture and math.random() < 0.35 then
		S.HazardService:SpawnFire(session, pos + dir * (range * 0.6), nil)
	end
	-- fire melts ice in the cone
	for i = #session.Puddles, 1, -1 do
		local p = session.Puddles[i]
		if p.Kind == "Ice" and MathUtil.inCone(pos, dir, p.Pos, range, 35) then
			S.HazardService:ConvertPuddle(session, p, "Water")
		end
	end
end

-- Scare one baby (ghost chaos). Draglings sneeze fire immediately when scared.
function ChaosService:Scare(session, target)
	S.StatusEffectService:Apply(session, target, "Scared", 3)
	BabyBase.change(target, "Fun", -20)
	session:Effect("Scared", { Position = BabyBase.position(target) + Vector3.new(0, 2.5, 0) })
	if target.Behavior.onScared then
		target.Behavior.onScared(target, ctx(session))
	end
end

-- Babies near a position (excluding one).
function ChaosService:BabiesNear(session, pos: Vector3, radius: number, except: any?): { any }
	local out = {}
	for _, b in session.BabyList do
		if b ~= except and b.State ~= "Leaving" and (BabyBase.position(b) - pos).Magnitude <= radius then
			table.insert(out, b)
		end
	end
	return out
end

function ChaosService:Init(services)
	S = services
end

return ChaosService
