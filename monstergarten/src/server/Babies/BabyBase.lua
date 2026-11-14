-- BabyBase: a baby instance (state, needs, model) + helpers shared by every behavior.
-- Behaviors (Behaviors/<Id>.lua) receive the baby table and may override hooks:
--   onSpawn(baby, ctx), tantrumStart(baby, ctx), tantrumTick(baby, dt, ctx), tantrumEnd(baby, ctx),
--   happyTick(baby, dt, ctx), onFed(baby, result, ctx), onScared(baby, ctx)
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BabiesConfig = require(Shared.Config.Babies)
local Needs = require(Shared.Config.Needs)
local NeedMath = require(Shared.Logic.NeedMath)
local ModelRegistry = require(Shared.World.ModelRegistry)

local BehaviorsFolder = script.Parent.Behaviors

local BabyBase = {}

local DefaultBehavior = {}

local behaviorCache: { [string]: any } = {}
local function behaviorFor(id: string)
	if behaviorCache[id] ~= nil then
		return behaviorCache[id]
	end
	local mod = BehaviorsFolder:FindFirstChild(id)
	local b = DefaultBehavior
	if mod then
		local ok, res = pcall(require, mod)
		if ok then
			b = res
		else
			warn("[BabyBase] behavior failed to load", id, res)
		end
	end
	behaviorCache[id] = b
	return b
end

function BabyBase.new(session, id: string, uid: string, cf: CFrame)
	local def = BabiesConfig.Defs[id]
	assert(def, "Unknown baby " .. tostring(id))
	local model = ModelRegistry.getBaby(id)
	local root = model.PrimaryPart :: BasePart
	local baby = {
		Uid = uid,
		Id = id,
		Def = def,
		Session = session,
		Model = model,
		Root = root,
		FloorOffset = model:GetAttribute("FloorOffset") or 1.45,
		Pos = cf.Position - Vector3.new(0, 1.45, 0),
		Yaw = 0,
		Needs = {} :: { [string]: number },
		Tantrum = nil :: string?,
		TantrumSeconds = 0,
		State = "Idle",
		Statuses = {} :: { [string]: number },
		CarriedBy = nil :: Player?,
		Station = nil :: any,
		Path = nil :: { Vector3 }?,
		PathIndex = 1,
		NextThink = 0,
		ChaosTimer = 0,
		Scale = 1,
		Escaped = false,
		Hidden = false,
		HideAndSeek = false,
		AnimUntil = 0,
		AnimOverride = nil :: string?,
		LastAttr = {} :: { [string]: number },
		Behavior = behaviorFor(id),
		Data = {} :: { [string]: any }, -- per-behavior scratch space
	}
	for needId in def.Needs do
		baby.Needs[needId] = math.random(60, 90)
	end
	model:SetAttribute("BabyId", id)
	model:SetAttribute("Uid", uid)
	model:SetAttribute("State", "Idle")
	model:SetAttribute("Anim", "Idle")
	model:SetAttribute("Session", session.Slot)
	local needList = {}
	for _, n in Needs.Order do
		if def.Needs[n] then
			table.insert(needList, n)
		end
	end
	model:SetAttribute("NeedList", table.concat(needList, ","))
	for n, v in baby.Needs do
		model:SetAttribute("N_" .. n, math.floor(v))
	end
	CollectionService:AddTag(model, "Baby")
	return baby
end

function BabyBase.def(): any
	return DefaultBehavior
end

-- Position the anchored root at the logical floor position.
function BabyBase.place(baby)
	if baby.CarriedBy then
		return
	end
	local y = baby.FloorOffset * baby.Scale
	if baby.Def.Id == "Ghostie" and baby.Model:GetAttribute("Placeholder") then
		y += 0.6 -- designed models carry their own float height (Lift)
	end
	baby.Root.CFrame = CFrame.new(baby.Pos + Vector3.new(0, y, 0)) * CFrame.Angles(0, baby.Yaw, 0)
end

function BabyBase.placeAt(baby, cf: CFrame)
	-- Slot markers mark the placeholder root height (floor + 1.45).
	baby.Pos = cf.Position - Vector3.new(0, 1.45, 0)
	local _, yaw = cf:ToEulerAnglesYXZ()
	baby.Yaw = yaw
	BabyBase.place(baby)
end

function BabyBase.setState(baby, state: string)
	if baby.State ~= state then
		baby.State = state
		baby.Model:SetAttribute("State", state)
		if state ~= "Wander" and state ~= "Seek" and state ~= "Escaping" then
			baby.Path = nil
		end
	end
end

function BabyBase.change(baby, needId: string, delta: number): number?
	local v = baby.Needs[needId]
	if v == nil then
		return nil
	end
	v = math.clamp(v + delta, 0, 100)
	baby.Needs[needId] = v
	return v
end

function BabyBase.set(baby, needId: string, value: number)
	if baby.Needs[needId] ~= nil then
		baby.Needs[needId] = math.clamp(value, 0, 100)
	end
end

function BabyBase.changeAll(baby, delta: number)
	for n in baby.Needs do
		BabyBase.change(baby, n, delta)
	end
end

function BabyBase.mood(baby): number
	return NeedMath.mood(baby.Needs)
end

function BabyBase.allHappy(baby): boolean
	for _, v in baby.Needs do
		if v <= Needs.Thresholds.Happy then
			return false
		end
	end
	return true
end

function BabyBase.lowestNeed(baby): (string?, number)
	local best, bestV = nil, math.huge
	for n, v in baby.Needs do
		if v < bestV then
			best, bestV = n, v
		end
	end
	return best, bestV
end

function BabyBase.position(baby): Vector3
	if baby.CarriedBy then
		return baby.Root.Position
	end
	return baby.Pos
end

function BabyBase.anim(baby, name: string, duration: number)
	baby.AnimOverride = name
	baby.AnimUntil = os.clock() + duration
end

function BabyBase.hasStatus(baby, name: string): boolean
	local t = baby.Statuses[name]
	return t ~= nil and t > os.clock()
end

-- Can the baby act on its own (walk / do chaos)?
function BabyBase.free(baby): boolean
	return baby.CarriedBy == nil
		and baby.State ~= "Placed"
		and baby.State ~= "Asleep"
		and not BabyBase.hasStatus(baby, "Frozen")
		and baby.State ~= "Leaving"
end

-- Is chaos allowed? (carried babies don't, except sneezes / sparks handled by behaviors)
function BabyBase.canChaos(baby): boolean
	return baby.CarriedBy == nil and not BabyBase.hasStatus(baby, "Frozen") and baby.State ~= "Leaving"
end

function BabyBase.destroy(baby)
	if baby.Model then
		baby.Model:Destroy()
	end
end

return BabyBase
