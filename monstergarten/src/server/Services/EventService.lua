-- EventService: random shift events (Storm, Birthday, Inspector, Mystery Egg, Full Moon, Mess Rain, Escape).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Events = require(Shared.Config.Events)
local Babies = require(Shared.Config.Babies)
local GameSettings = require(Shared.Config.GameSettings)
local MathUtil = require(Shared.Util.Math)
local ModelRegistry = require(Shared.World.ModelRegistry)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local EventService = {}
local S

local function banner(session, id: string, phase: string, extra: any?)
	local ev = Remotes.event("Banner")
	for _, p in session.Players do
		ev:FireClient(p, id, phase, extra or {})
	end
	if phase == "start" then
		session:Sound("Shift_Banner")
	end
end

local function timeForHour(h: number): number
	return (h - GameSettings.ClockStart) / (GameSettings.ClockEnd - GameSettings.ClockStart) * GameSettings.ShiftDuration
end

function EventService:SetupSession(session)
	session.EventSchedule = {}
	if session.Tutorial then
		return
	end
	local count = session.Difficulty.Events
	local pool = table.clone(Events.Order)
	local last = -math.huge
	for i = 1, count do
		local anchor = Events.Anchors[i] or (Events.Anchors[#Events.Anchors] + 100 * i)
		local t = anchor + math.random(-Events.Jitter, Events.Jitter)
		t = math.max(t, last + Events.MinGap)
		local id = MathUtil.weightedPick(pool, function(e)
			return Events.Defs[e].Weight
		end)
		if id == "FullMoon" then
			local minT = timeForHour(Events.Defs.FullMoon.MinClock or 16)
			if t < minT then
				if minT + 10 < GameSettings.ParentsWarningAt - 40 then
					t = minT + 5
				else
					id = "MessRain"
				end
			end
		end
		if id then
			local idx = table.find(pool, id)
			if idx then
				table.remove(pool, idx)
			end
			table.insert(session.EventSchedule, { Time = t, Id = id })
			last = t
		end
	end
end

function EventService:CleanupSession(session)
	local ev = session.ActiveEvent
	if ev and ev.Data.Inspector then
		ev.Data.Inspector:Destroy()
	end
end

local function finish(session, success: boolean, coins: number?, bonus: number?)
	local ev = session.ActiveEvent
	if not ev then
		return
	end
	session.ActiveEvent = nil
	if success then
		local def = Events.Defs[ev.Id]
		local c = coins or def.Reward
		session.EventCoins += c
		session.EventBonus = math.min(Events.MaxBonusScore, session.EventBonus + (bonus or 2))
		banner(session, ev.Id, "success", { Coins = c })
	else
		banner(session, ev.Id, "fail", {})
	end
	if ev.Cleanup then
		pcall(ev.Cleanup)
	end
end

function EventService:EndActive(session, atShiftEnd: boolean)
	local ev = session.ActiveEvent
	if not ev then
		return
	end
	if ev.Evaluate then
		local ok, success, coins, bonus = pcall(ev.Evaluate, atShiftEnd)
		finish(session, ok and success == true, coins, bonus)
	else
		finish(session, false)
	end
end

-- Event implementations ----------------------------------------------------------------

-- helper: per-event interval timer
local function ChanceEvery(ev, key: string, interval: number, dt: number): boolean
	ev.Data["_t" .. key] = (ev.Data["_t" .. key] or 0) + dt
	if ev.Data["_t" .. key] >= interval then
		ev.Data["_t" .. key] = 0
		return true
	end
	return false
end

local starters: { [string]: (any, any) -> () } = {}

starters.Storm = function(session, ev)
	session.Storm = true
	session.Model:SetAttribute("Storm", true)
	session:Effect("Storm", { On = true })
	ev.Data.PowerCutAt = session.Time + 10
	ev.Data.Restored = false
	ev.Tick = function(dt)
		if ev.Data.PowerCutAt and session.Time >= ev.Data.PowerCutAt then
			ev.Data.PowerCutAt = nil
			ev.Data.OutAt = session.Time
			session:Sound("Env_Thunder")
			S.FurnitureService:SetPower(session, false)
		end
		if ChanceEvery(ev, "Rain", 5, dt) then
			local yard = session.Model:FindFirstChild("Room_Yard", true) :: BasePart?
			if yard then
				local p = yard.Position + Vector3.new(math.random(-40, 40), 0, math.random(-25, 25))
				S.HazardService:SpawnPuddle(session, p, "Water", 4)
			end
		end
	end
	ev.OnPower = function(on: boolean)
		if on and ev.Data.OutAt and session.Time - ev.Data.OutAt <= 20 then
			ev.Data.Restored = true
		end
	end
	ev.Evaluate = function()
		return ev.Data.Restored
	end
	ev.Cleanup = function()
		session.Storm = false
		session.Model:SetAttribute("Storm", false)
		session:Effect("Storm", { On = false })
	end
end

starters.Birthday = function(session, ev)
	local eaters = {}
	for _, b in session.BabyList do
		if b.Def.Eats then
			table.insert(eaters, b)
		end
	end
	if #eaters == 0 then
		ev.Evaluate = function()
			return false
		end
		ev.EndsAt = session.Time + 1
		return
	end
	local b = eaters[math.random(1, #eaters)]
	ev.Data.Baby = b
	b.Model:SetAttribute("Birthday", true)
	ev.Extra = { Baby = b.Id }
	ev.Evaluate = function()
		return ev.Data.Done == true
	end
	ev.OnFed = function(baby, dish)
		if baby == b and dish == "Cake" then
			ev.Data.Done = true
			for n in baby.Needs do
				BabyBase.set(baby, n, 100)
			end
			finish(session, true)
		end
	end
	ev.Cleanup = function()
		if b.Model then
			b.Model:SetAttribute("Birthday", nil)
		end
	end
end

starters.Inspector = function(session, ev)
	local points = session:Tagged("InspectorPoint")
	local npc = ModelRegistry.getNPC("Inspector")
	npc.Name = "Inspector"
	local start = (points[1] :: BasePart).Position
	npc:PivotTo(CFrame.new(start + Vector3.new(0, (npc:GetAttribute("FloorOffset") or 3) - 1.3, 0)))
	npc.Parent = session.Dynamic
	ev.Data.Inspector = npc
	ev.Data.Penalties = 0
	ev.Data.Seen = {}
	ev.Data.Index = 1
	ev.Data.Pos = start - Vector3.new(0, 1.3, 0)
	ev.Data.Target = nil
	-- Simple straight walking between points (glides through doors; slow and stately).
	ev.Tick = function(dt)
		if not ev.Data.Target or (ev.Data.Target - ev.Data.Pos).Magnitude < 1 then
			ev.Data.Index = (ev.Data.Index % #points) + 1
			local p = (points[ev.Data.Index] :: BasePart).Position
			ev.Data.Target = Vector3.new(p.X, p.Y - 1.3, p.Z)
		end
		local d = ev.Data.Target - ev.Data.Pos
		local step = math.min(d.Magnitude, 7 * dt)
		if d.Magnitude > 0.01 then
			ev.Data.Pos += d.Unit * step
			local dir = Vector3.new(d.X, 0, d.Z)
			local look = if dir.Magnitude > 0.01 then dir.Unit else Vector3.new(0, 0, -1)
			npc:PivotTo(CFrame.lookAt(ev.Data.Pos, ev.Data.Pos + look) + Vector3.new(0, npc:GetAttribute("FloorOffset") or 3, 0))
		end
		if ChanceEvery(ev, "Check", 2, dt) then
			local pos = ev.Data.Pos
			local function note(key, p: Vector3)
				if not ev.Data.Seen[key] and (p - pos).Magnitude < 18 then
					ev.Data.Seen[key] = true
					ev.Data.Penalties += 1
					session:Effect("InspectorNote", { Position = pos + Vector3.new(0, 7, 0) })
				end
			end
			for _, f in session.Fires do
				note(f, f.Pos)
			end
			for _, p in session.Puddles do
				if p.Kind == "Ink" or p.Kind == "Slime" or p.Kind == "Splat" then
					note(p, p.Pos)
				end
			end
			for _, t in session.Trash do
				note(t, t.Pos)
			end
			for _, b in session.BabyList do
				local _, low = BabyBase.lowestNeed(b)
				if b.Tantrum or low < 15 then
					note(b.Uid .. "_" .. math.floor(session.Time / 20), BabyBase.position(b))
				end
			end
			session.Model:SetAttribute("InspectorPenalties", ev.Data.Penalties)
		end
	end
	ev.Evaluate = function()
		return ev.Data.Penalties == 0, nil, 5
	end
	ev.Cleanup = function()
		npc:Destroy()
		session.Model:SetAttribute("InspectorPenalties", nil)
	end
end

starters.MysteryEgg = function(session, ev)
	local spot = session:Tagged("EggSpot")[1] :: BasePart?
	local pos = if spot then spot.Position else session:Origin()
	local item = S.ToolService:SpawnItem(session, { Kind = "Egg", Id = "Egg" }, pos - Vector3.new(0, 0.8, 0))
	ev.Data.Progress = 0
	ev.Data.Item = item
	session:Sound("Env_Egg", pos)
	local function eggPos(): Vector3?
		for _, it in session.Items do
			if it.Held.Kind == "Egg" and it.Model then
				return it.Model:GetPivot().Position
			end
		end
		for p, held in session.Held do
			if held.Kind == "Egg" then
				local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				return r and r.Position
			end
		end
		return nil
	end
	ev.Tick = function(dt)
		local p = eggPos()
		if not p then
			return
		end
		for _, st in session.Stations do
			if st.Tag == "Fireplace" and (st.Slot.Position - p).Magnitude < 8 then
				ev.Data.Progress += dt
				session.Model:SetAttribute("EggProgress", math.clamp(ev.Data.Progress / 20, 0, 1))
				break
			end
		end
		if ev.Data.Progress >= 20 and not ev.Data.Hatched then
			ev.Data.Hatched = true
			-- remove the egg wherever it is
			for i = #session.Items, 1, -1 do
				local it = session.Items[i]
				if it.Held.Kind == "Egg" then
					it.Model:Destroy()
					table.remove(session.Items, i)
				end
			end
			for pl, held in session.Held do
				if held.Kind == "Egg" then
					S.ToolService:SetHeld(pl, nil)
				end
			end
			local locked, any = {}, {}
			for _, id in Babies.Order do
				table.insert(any, id)
				if not session.IsUnlocked("Baby:" .. id) then
					table.insert(locked, id)
				end
			end
			local pick = if #locked > 0 then locked[math.random(1, #locked)] else any[math.random(1, #any)]
			local baby = S.BabyService:SpawnBaby(session, pick, CFrame.new(p + Vector3.new(0, 1.5, 0)))
			session:Effect("Hatch", { Position = p })
			session:Notify({ "Toast_EggHatched", pick }, "good")
			ev.Data.HatchedId = pick
			finish(session, true, 0, 2)
			local _ = baby
		end
	end
	ev.Evaluate = function()
		return ev.Data.Hatched == true, 0, 2
	end
	ev.Cleanup = function()
		session.Model:SetAttribute("EggProgress", nil)
		if not ev.Data.Hatched then
			for i = #session.Items, 1, -1 do
				local it = session.Items[i]
				if it.Held.Kind == "Egg" then
					it.Model:Destroy()
					table.remove(session.Items, i)
				end
			end
			for pl, held in session.Held do
				if held.Kind == "Egg" then
					S.ToolService:SetHeld(pl, nil)
				end
			end
		end
	end
end

starters.FullMoon = function(session, ev)
	session.FullMoon = true
	session.Model:SetAttribute("FullMoon", true)
	ev.Data.Tantrums = 0
	ev.OnTantrum = function()
		ev.Data.Tantrums += 1
	end
	ev.Evaluate = function()
		return ev.Data.Tantrums == 0
	end
	ev.Cleanup = function()
		session.FullMoon = false
		session.Model:SetAttribute("FullMoon", false)
	end
end

starters.MessRain = function(session, ev)
	local vols = session.Model:FindFirstChild("RoomVolumes")
	local rooms = {}
	if vols then
		for _, v in vols:GetChildren() do
			local n = v:GetAttribute("RoomName")
			if n == "Kitchen" or n == "Playroom" or n == "Hall" or n == "Bedroom" then
				table.insert(rooms, v)
			end
		end
	end
	for _ = 1, 10 do
		local v = rooms[math.random(1, math.max(1, #rooms))] :: BasePart?
		if v then
			local half = v.Size / 2
			local p = v.Position + Vector3.new(math.random(-100, 100) / 100 * (half.X - 3), -half.Y + 1, math.random(-100, 100) / 100 * (half.Z - 3))
			S.HazardService:SpawnTrash(session, p, 1)
			session:Effect("Puff", { Position = p + Vector3.new(0, 10, 0) })
		end
	end
	ev.Data.Binned = 0
	ev.OnTrashBinned = function(n)
		ev.Data.Binned += n
	end
	ev.Evaluate = function()
		local coins = ev.Data.Binned * Events.Defs.MessRain.Reward
		return coins > 0, coins, 1
	end
end

starters.Escape = function(session, ev)
	S.FurnitureService:SetGate(session, true)
	ev.Data.Escaped = 0
	local best, bestC = nil, -1
	for _, b in session.BabyList do
		if BabyBase.free(b) and not b.Escaped and b.Def.Curiosity > bestC then
			best, bestC = b, b.Def.Curiosity
		end
	end
	if best then
		BabyBase.setState(best, "Escaping")
		best.Path = nil
		ev.Extra = { Baby = best.Id }
		ev.Data.Runner = best
	end
	ev.OnEscaped = function()
		ev.Data.Escaped += 1
	end
	ev.Evaluate = function()
		local anyOut = false
		for _, b in session.BabyList do
			if b.Escaped then
				anyOut = true
			end
		end
		return ev.Data.Escaped == 0 and not anyOut
	end
	ev.Cleanup = function()
		S.FurnitureService:SetGate(session, false)
		local r = ev.Data.Runner
		if r and r.State == "Escaping" and not r.Tantrum then
			BabyBase.setState(r, "Idle")
			r.Path = nil
		end
	end
end

function EventService:Trigger(session, id: string)
	if not starters[id] then
		return
	end
	if session.ActiveEvent then
		self:EndActive(session, false)
	end
	local def = Events.Defs[id]
	local ev = { Id = id, StartedAt = session.Time, EndsAt = session.Time + def.Duration, Data = {} }
	session.ActiveEvent = ev
	starters[id](session, ev)
	banner(session, id, "start", ev.Extra or {})
end

function EventService:Tick(session, dt)
	local ev = session.ActiveEvent
	if ev then
		if ev.Tick then
			local ok, err = pcall(ev.Tick, dt)
			if not ok then
				warn("[EventService]", ev.Id, err)
			end
		end
		if session.ActiveEvent == ev and session.Time >= ev.EndsAt then
			self:EndActive(session, false)
		end
		return
	end
	local nextEv = session.EventSchedule[1]
	if nextEv and session.Time >= nextEv.Time then
		table.remove(session.EventSchedule, 1)
		self:Trigger(session, nextEv.Id)
	end
end

-- Hooks called by other services ------------------------------------------------------------

local function hook(session, name: string, ...)
	local ev = session.ActiveEvent
	if ev and ev[name] then
		ev[name](...)
	end
end

function EventService:OnFed(session, baby, dish, _player)
	hook(session, "OnFed", baby, dish)
end
function EventService:OnPower(session, on)
	hook(session, "OnPower", on)
end
function EventService:OnTantrum(session, baby)
	hook(session, "OnTantrum", baby)
end
function EventService:OnEscaped(session, baby)
	hook(session, "OnEscaped", baby)
end
function EventService:OnMess(session, kind)
	hook(session, "OnMess", kind)
end
function EventService:OnTrashBinned(session, _player, n)
	hook(session, "OnTrashBinned", n)
end

function EventService:Init(services)
	S = services
end

return EventService
