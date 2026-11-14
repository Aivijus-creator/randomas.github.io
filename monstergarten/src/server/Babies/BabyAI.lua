-- BabyAI: decides where free babies walk (wander / seek a station / escape) and moves them smoothly.
-- Decisions run every 0.3-0.6 s per baby; movement is integrated every frame by BabyService.
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needs = require(Shared.Config.Needs)
local BabyBase = require(script.Parent.BabyBase)

local BabyAI = {}

local pending: { [any]: number } = {} -- session -> pathfinding jobs in flight
local MAX_PENDING = 3

local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include

local function floorAt(session, pos: Vector3): number?
	if not session.Floors then
		return nil
	end
	floorParams.FilterDescendantsInstances = { session.Floors }
	local r = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), floorParams)
	return r and r.Position.Y
end
BabyAI.floorAt = floorAt

local function requestPath(baby, session, target: Vector3, onDone: ((boolean) -> ())?)
	if (pending[session] or 0) >= MAX_PENDING then
		return
	end
	pending[session] = (pending[session] or 0) + 1
	baby.PathPending = true
	task.spawn(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 1.6,
			AgentHeight = 3,
			AgentCanJump = false,
			WaypointSpacing = 3,
		})
		local ok = pcall(function()
			path:ComputeAsync(baby.Pos + Vector3.new(0, 1, 0), target)
		end)
		pending[session] = math.max(0, (pending[session] or 1) - 1)
		baby.PathPending = false
		if session.Phase == "Ended" or not baby.Model.Parent then
			return
		end
		if ok and path.Status == Enum.PathStatus.Success then
			local pts = {}
			for _, w in path:GetWaypoints() do
				table.insert(pts, w.Position)
			end
			baby.Path = pts
			baby.PathIndex = 2
			if onDone then
				onDone(true)
			end
		else
			baby.Path = nil
			if onDone then
				onDone(false)
			end
		end
	end)
end
BabyAI.requestPath = requestPath

-- Random walkable point near the baby, inside the daycare (never outside the fence).
local function wanderTarget(baby, session): Vector3?
	local r = baby.Def.WanderRadius
	for _ = 1, 6 do
		local offset = Vector3.new(math.random(-r, r), 0, math.random(-r, r))
		local p = baby.Pos + offset
		local room = session:RoomAt(p + Vector3.new(0, 2, 0))
		if room and room ~= "Outside" and room ~= "Stairs" and room ~= "Front" then
			local y = floorAt(session, p)
			if y then
				return Vector3.new(p.X, y, p.Z)
			end
		end
	end
	return nil
end

local function nearestStation(baby, session, needId: string): any?
	local best, bestD = nil, math.huge
	for _, st in session.Stations do
		if st.Need == needId then
			local d = (st.Slot.Position - baby.Pos).Magnitude
			if d < bestD then
				best, bestD = st, d
			end
		end
	end
	return best
end

-- Called ~3x per second for each baby.
function BabyAI.think(baby, session)
	if not BabyBase.free(baby) then
		return
	end
	-- Behaviors may fully drive movement during a tantrum (ghost, mummy...).
	if baby.Tantrum and baby.Behavior.drivesMovement and baby.Behavior.drivesMovement(baby) then
		return
	end
	if baby.State == "Escaping" then
		if not baby.Path and not baby.PathPending then
			local gate = session.Gate
			if gate then
				local out = if gate.Open then gate.Outside else gate.Inside
				requestPath(baby, session, out)
			end
		end
		return
	end
	if baby.Escaped then
		-- Wander around just outside the gate.
		if not baby.Path and not baby.PathPending and math.random() < 0.3 then
			local p = (session.EscapePoint or baby.Pos) + Vector3.new(math.random(-10, 10), 0, math.random(-6, 6))
			baby.Path = { baby.Pos, Vector3.new(p.X, baby.Pos.Y, p.Z) }
			baby.PathIndex = 2
		end
		return
	end
	if baby.Path or baby.PathPending then
		return
	end
	-- Seek: slowly drift towards the station for the lowest need (a hint for players).
	local need, value = BabyBase.lowestNeed(baby)
	if need and value < Needs.Thresholds.Bubble and Needs.Defs[need].Station and math.random() < 0.5 then
		local st = nearestStation(baby, session, need)
		if st then
			local dir = (baby.Pos - st.Slot.Position)
			local stop = st.Slot.Position + (if dir.Magnitude > 0.1 then dir.Unit * 5 else Vector3.new(5, 0, 0))
			local y = floorAt(session, stop)
			if y and (stop - baby.Pos).Magnitude > 3 then
				BabyBase.setState(baby, "Seek")
				requestPath(baby, session, Vector3.new(stop.X, y, stop.Z))
				return
			end
		end
	end
	if math.random() < 0.35 then
		local t = wanderTarget(baby, session)
		if t then
			BabyBase.setState(baby, "Wander")
			requestPath(baby, session, t)
		end
	else
		BabyBase.setState(baby, if baby.Tantrum then "Tantrum" else "Idle")
	end
end

-- Integrate movement along the current path. Returns true if the baby moved.
function BabyAI.move(baby, dt: number): boolean
	local path = baby.Path
	if not path or not BabyBase.free(baby) then
		return false
	end
	local target = path[baby.PathIndex]
	if not target then
		baby.Path = nil
		if baby.State == "Wander" or baby.State == "Seek" then
			BabyBase.setState(baby, if baby.Tantrum then "Tantrum" else "Idle")
		end
		return false
	end
	local speed = baby.Def.WalkSpeed
	if baby.State == "Seek" then
		speed *= 0.6
	elseif baby.State == "Escaping" then
		speed *= 1.3
	end
	if baby.Scale > 1 then
		speed /= baby.Scale ^ 0.5
	end
	if BabyBase.hasStatus(baby, "Burning") then
		speed *= 1.4
	end
	local delta = target - baby.Pos
	local flat = Vector3.new(delta.X, 0, delta.Z)
	local dist = flat.Magnitude
	local step = speed * dt
	if dist <= step or dist < 0.05 then
		baby.Pos = target
		baby.PathIndex += 1
	else
		local dir = flat.Unit
		local yStep = delta.Y * math.min(1, step / math.max(dist, 0.01))
		baby.Pos += dir * step + Vector3.new(0, yStep, 0)
		baby.Yaw = math.atan2(-dir.X, -dir.Z)
	end
	BabyBase.place(baby)
	return true
end

-- Straight-line glide (ghosts drift through walls).
function BabyAI.glideTo(baby, target: Vector3)
	baby.Path = { baby.Pos, target }
	baby.PathIndex = 2
end

return BabyAI
