-- NeedService: need decay, passive refills from stations/zones, tantrum start/end and attribute replication.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needs = require(Shared.Config.Needs)
local GameSettings = require(Shared.Config.GameSettings)
local NeedMath = require(Shared.Logic.NeedMath)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local NeedService = {}
local S

local TICK = GameSettings.NeedTickRate
local REPLICATE = 1 / GameSettings.NeedReplicateRate

function NeedService:Init(services)
	S = services
end

function NeedService:SetupSession(session)
	session.NeedAcc = 0
	session.ReplicateAcc = 0
	session.DarkZones = session:Tagged("DarkZone")
	session.SunSpots = {}
	for _, st in session.Stations do
		if st.Tag == "SunSpot" and st.Model:GetAttribute("Moving") then
			table.insert(session.SunSpots, st)
		end
	end
end

local function stationWorks(session, st): boolean
	if st.Electric and not session.PowerOn then
		return false
	end
	if st.Model:GetAttribute("Active") == false then
		return false
	end
	if st.Tag == "SunSpot" and st.Model:GetAttribute("Moving") then
		-- outdoor sun only shines during the day and not in a storm
		local h = session:ClockHour()
		return h >= 8 and h <= 18.5 and not session.Storm
	end
	return true
end

local function lullabyNear(session, pos: Vector3): boolean
	local range = S.ToolService:ToolStat(session, "Lullaby", "Range") or 16
	local noPower = (S.ToolService:ToolStat(session, "Lullaby", "NoPower") or 0) > 0
	if not session.PowerOn and not noPower then
		return false
	end
	for _, item in session.Items do
		if item.Model and item.Model:GetAttribute("Lullaby") then
			if (item.Model:GetPivot().Position - pos).Magnitude <= range then
				return true
			end
		end
	end
	return false
end

-- Is it dark where the baby is? (bedroom with curtains, basement coffins, blackout indoors)
local function isDark(session, baby, pos: Vector3): boolean
	if not session.PowerOn and session:IsIndoor(pos) then
		return true
	end
	local room = session:RoomAt(pos + Vector3.new(0, 2, 0))
	for _, z in session.DarkZones do
		if z:GetAttribute("Active") and z:GetAttribute("Room") and z:GetAttribute("Room") == room then
			return true
		end
	end
	if room == "Basement" then
		return true
	end
	return false
end

local function moveSunSpots(session)
	local h = session:ClockHour()
	local t = (h - 7) / 12 -- 0..1 over the day
	for _, st in session.SunSpots do
		local origin = st.Model:GetAttribute("Origin")
		if typeof(origin) == "Vector3" then
			local offset = Vector3.new(math.cos(t * math.pi) * 6, 0, math.sin(t * math.pi) * 3 - 1.5)
			local glow = st.Model:FindFirstChild("Glow") :: BasePart?
			local newPos = origin + offset
			if glow then
				glow.CFrame = CFrame.new(newPos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
				glow.Transparency = if stationWorks(session, st) then 0.55 else 0.95
			end
			st.Slot.CFrame = CFrame.new(newPos + Vector3.new(0, 1.45, 0))
			if st.Occupant then
				BabyBase.placeAt(st.Occupant, st.Slot.CFrame)
			end
		end
	end
end

local function needTick(session, dt: number)
	local mult = session:NeedMultiplier()
	local sat = session:SatisfyMultiplier()
	local hour = session:ClockHour()
	local daylight = hour >= 10 and hour <= 16
	-- warmth / cold aura sources: happy draglings
	local auras = {}
	for _, b in session.BabyList do
		if b.Def.Id == "Dragling" and not b.Tantrum and BabyBase.mood(b) > Needs.Thresholds.Happy then
			table.insert(auras, BabyBase.position(b))
		end
	end

	for _, baby in session.BabyList do
		if baby.State == "Leaving" or baby.Arriving then
			continue
		end
		local pos = BabyBase.position(baby)
		local asleep = baby.State == "Asleep"
		for needId, bm in baby.Def.Needs do
			local rate = NeedMath.decayRate(needId, bm, 1, 1) * mult
			if asleep and needId ~= "Sleep" then
				rate *= Needs.AsleepOtherDecay
			end
			if needId == "Fun" and session.Storm then
				rate *= 1.5
			end
			if needId == "Darkness" and daylight and not isDark(session, baby, pos) then
				rate *= 2
			end
			if baby.Escaped then
				rate *= 1.5
			end
			BabyBase.change(baby, needId, -rate * dt)
		end
		-- placed at a station
		local st = baby.Station
		if st and stationWorks(session, st) then
			local gain = st.Rate
			if st.Tag == "Bed" then
				gain = if lullabyNear(session, st.Slot.Position) then Needs.Restore.SleepLullaby else st.Rate
			end
			if st.Tag ~= "Bath" then
				BabyBase.change(baby, st.Need, gain * sat * dt)
			end
			local v = baby.Needs[st.Need]
			if v and v >= 99.5 and st.Tag ~= "Bath" then
				S.BabyService:LeaveStation(session, baby)
				S.BabyService.happy(session, baby, nil)
			end
		end
		-- passive: standing near a station (not placed)
		if not st and not baby.CarriedBy then
			for _, s2 in session.Stations do
				if s2.Tag ~= "Bed" and s2.Tag ~= "Bath" and baby.Needs[s2.Need] ~= nil and stationWorks(session, s2) then
					if (s2.Slot.Position - pos).Magnitude <= s2.Radius + 1.5 then
						BabyBase.change(baby, s2.Need, s2.Rate * 0.6 * sat * dt)
					end
				end
			end
		end
		-- darkness zones
		if baby.Needs.Darkness and isDark(session, baby, pos) then
			BabyBase.change(baby, "Darkness", 10 * sat * dt)
		end
		-- warmth aura from happy draglings (yetis hate it)
		for _, a in auras do
			if (a - pos).Magnitude < 10 and a ~= pos then
				if baby.Needs.Warmth then
					BabyBase.change(baby, "Warmth", 3 * dt)
				end
				if baby.Needs.Cold then
					BabyBase.change(baby, "Cold", -2 * dt)
				end
			end
		end
		-- tantrum transitions
		if baby.Tantrum then
			baby.TantrumSeconds += dt
			local v = baby.Needs[baby.Tantrum] or 100
			if v >= Needs.Thresholds.TantrumEnd then
				S.ChaosService:EndTantrum(session, baby)
			end
		else
			for needId, v in baby.Needs do
				if v <= 0 then
					S.ChaosService:StartTantrum(session, baby, needId)
					break
				end
			end
		end
	end
end

local function replicate(session)
	for _, baby in session.BabyList do
		local m = baby.Model
		for needId, v in baby.Needs do
			local iv = math.floor(v + 0.5)
			if baby.LastAttr[needId] ~= iv then
				baby.LastAttr[needId] = iv
				m:SetAttribute("N_" .. needId, iv)
			end
		end
		local mood = math.floor(BabyBase.mood(baby))
		if baby.LastAttr.__mood ~= mood then
			baby.LastAttr.__mood = mood
			m:SetAttribute("Mood", mood)
		end
		local tantrum = baby.Tantrum or ""
		if m:GetAttribute("Tantrum") ~= tantrum then
			m:SetAttribute("Tantrum", tantrum)
		end
	end
end

function NeedService:Tick(session, dt)
	session.NeedAcc = (session.NeedAcc or 0) + dt
	session.ReplicateAcc = (session.ReplicateAcc or 0) + dt
	if session.NeedAcc >= TICK then
		local step = session.NeedAcc
		session.NeedAcc = 0
		needTick(session, step)
		moveSunSpots(session)
	end
	if session.ReplicateAcc >= REPLICATE then
		session.ReplicateAcc = 0
		replicate(session)
	end
end

-- Debug helper: set every need of every baby.
function NeedService:SetAll(session, value: number)
	for _, b in session.BabyList do
		for n in b.Needs do
			BabyBase.set(b, n, value)
		end
	end
	replicate(session)
end

return NeedService
