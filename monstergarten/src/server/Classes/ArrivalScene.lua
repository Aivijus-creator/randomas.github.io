-- ArrivalScene: the parents walk along the street with their babies to the front porch, the entrance doors
-- open and the babies walk inside to their spots (and the reverse at pick-up time). Everything is server-side,
-- so every player sees the same thing; the client only moves the camera.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ModelRegistry = require(Shared.World.ModelRegistry)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local ArrivalScene = {}

local PARENT_SPEED = 17
local BABY_SPEED = 15

local function marker(session, tag: string): Vector3?
	local m = session:Tagged(tag)[1]
	return m and (m :: BasePart).Position - Vector3.new(0, 1.5, 0) or nil
end

-- Moves something along a polyline. setPos(pos, dir) is called every frame. Returns when finished.
local function walk(points: { Vector3 }, speed: number, setPos: (Vector3, Vector3) -> (), alive: () -> boolean)
	local pos = points[1]
	for i = 2, #points do
		local target = points[i]
		while alive() do
			local d = target - pos
			local flat = Vector3.new(d.X, 0, d.Z)
			if flat.Magnitude < 0.2 then
				pos = target
				break
			end
			local dt = RunService.Heartbeat:Wait()
			local step = math.min(flat.Magnitude, speed * dt)
			pos += flat.Unit * step + Vector3.new(0, (target.Y - pos.Y) * math.min(1, step / flat.Magnitude), 0)
			setPos(pos, flat.Unit)
		end
	end
	return pos
end

local function placeBaby(baby, pos: Vector3, dir: Vector3)
	baby.Pos = pos
	baby.Yaw = math.atan2(-dir.X, -dir.Z)
	BabyBase.place(baby)
end

local function spawnParent(session, babyId: string, at: Vector3)
	local ok, m = pcall(ModelRegistry.getParent, babyId)
	if not ok or not m then
		return nil
	end
	m:SetAttribute("Anim", "Walk")
	m:SetAttribute("ParentOf", babyId)
	game:GetService("CollectionService"):AddTag(m, "ParentModel")
	local offset = m:GetAttribute("FloorOffset") or 6
	m:PivotTo(CFrame.new(at + Vector3.new(0, offset, 0)))
	m.Parent = session.Dynamic
	return { Model = m, Offset = offset }
end

local function moveParent(p, pos: Vector3, dir: Vector3)
	if p.Model.Parent then
		p.Model:PivotTo(CFrame.lookAt(pos + Vector3.new(0, p.Offset, 0), pos + Vector3.new(0, p.Offset, 0) + dir))
	end
end

-- Group babies into families (one parent per species, at most 4 parents on screen).
local function families(babies)
	local fams, byId = {}, {}
	for _, b in babies do
		local f = byId[b.Id]
		if not f then
			if #fams < 4 then
				f = { Id = b.Id, Babies = {} }
				table.insert(fams, f)
				byId[b.Id] = f
			else
				f = fams[#fams]
			end
		end
		table.insert(f.Babies, b)
	end
	return fams
end

-- Returns true when the scene finished (or was skipped); `skip()` is polled every frame.
function ArrivalScene.arrive(session, babies, S, skip: () -> boolean): ()
	local start, corner, porch = marker(session, "ParentStart"), marker(session, "ParentCorner"), marker(session, "PorchSpot")
	local doorOut, doorIn = marker(session, "DoorOutside"), marker(session, "DoorInside")
	local spawns = session:Tagged("BabySpawn")
	if not (start and corner and porch and doorOut and doorIn) then
		return
	end
	local alive = function()
		return session.Phase ~= "Ended" and not skip()
	end
	S.FurnitureService:SetEntrance(session, true)
	local fams = families(babies)
	local pending = 0
	local spawnIndex = 0
	for fi, fam in fams do
		local lane = (fi - (#fams + 1) / 2) * 15
		local back = Vector3.new(-(fi - 1) * 20, 0, 0)
		local parent = spawnParent(session, fam.Id, start + back)
		local parentStop = porch + Vector3.new(lane, 0, 6)
		if parent then
			task.spawn(function()
				walk({ start + back, corner + Vector3.new(lane * 0.5, 0, 0), parentStop }, PARENT_SPEED, function(pos, dir)
					moveParent(parent, pos, dir)
				end, alive)
				parent.Model:SetAttribute("Anim", "Happy")
			end)
		end
		for bi, baby in fam.Babies do
			spawnIndex += 1
			local marker = spawns[((spawnIndex - 1) % math.max(1, #spawns)) + 1] :: BasePart?
			local final = if marker then marker.Position - Vector3.new(0, 1.45, 0) else doorIn
			local side = Vector3.new((bi - 1) * 3 - 2, 0, -4)
			local route = {
				start + back + side,
				corner + Vector3.new(lane * 0.5, 0, 0) + side,
				porch + Vector3.new(lane * 0.4 + (bi - 1) * 2.5, 0, -2),
				doorOut + Vector3.new((bi % 2) * 2 - 1, 0.8, 0),
				doorIn + Vector3.new(0, 0.2, 0),
				Vector3.new(final.X, doorIn.Y + 0.2, final.Z),
			}
			baby.Model:SetAttribute("Anim", "Walk")
			placeBaby(baby, route[1], Vector3.new(1, 0, 0))
			pending += 1
			task.spawn(function()
				task.wait((bi - 1) * 0.25)
				walk(route, BABY_SPEED, function(pos, dir)
					placeBaby(baby, pos, dir)
				end, alive)
				baby.Model:SetAttribute("Anim", "Happy")
				pending -= 1
			end)
		end
	end
	-- wait until every baby is inside (or skipped / timed out)
	local t0 = os.clock()
	while pending > 0 and alive() and os.clock() - t0 < 16 do
		task.wait(0.1)
	end
	-- snap everyone into place (skip or timeout) and let the parents wave + walk away
	spawnIndex = 0
	for _, fam in fams do
		for _, baby in fam.Babies do
			spawnIndex += 1
			local m = spawns[((spawnIndex - 1) % math.max(1, #spawns)) + 1] :: BasePart?
			if m and (skip() or pending > 0) then
				BabyBase.placeAt(baby, m.CFrame)
			end
		end
	end
	S.FurnitureService:SetEntrance(session, false)
	task.spawn(function()
		task.wait(1.5)
		for _, p in session:Tagged("ParentModel") do
			if p:IsA("Model") and p.Parent then
				local pos = p:GetPivot().Position - Vector3.new(0, p:GetAttribute("FloorOffset") or 6, 0)
				p:SetAttribute("Anim", "Walk")
				task.spawn(function()
					walk({ pos, Vector3.new(pos.X, pos.Y, start.Z), start + Vector3.new(-60, 0, 0) }, PARENT_SPEED, function(np, dir)
						moveParent({ Model = p, Offset = p:GetAttribute("FloorOffset") or 6 }, np, dir)
					end, function()
						return session.Phase ~= "Ended" and p.Parent ~= nil
					end)
					p:Destroy()
				end)
			end
		end
	end)
end

-- Pick-up: parents walk to the porch, babies walk out to them. Blocks for about the scene length.
function ArrivalScene.depart(session, S, skip: () -> boolean, faces: { [string]: number })
	local start, corner, porch = marker(session, "ParentStart"), marker(session, "ParentCorner"), marker(session, "PorchSpot")
	local doorOut, doorIn = marker(session, "DoorOutside"), marker(session, "DoorInside")
	if not (start and corner and porch and doorOut and doorIn) then
		return
	end
	local alive = function()
		return session.Phase ~= "Ended" and not skip()
	end
	S.FurnitureService:SetEntrance(session, true)
	local fams = families(session.BabyList)
	for fi, fam in fams do
		local lane = (fi - (#fams + 1) / 2) * 15
		local back = Vector3.new(-(fi - 1) * 14, 0, 0)
		local parent = spawnParent(session, fam.Id, start + back)
		local parentStop = porch + Vector3.new(lane, 0, 8)
		if parent then
			task.spawn(function()
				walk({ start + back, corner + Vector3.new(lane * 0.5, 0, 0), parentStop }, PARENT_SPEED * 1.2, function(pos, dir)
					moveParent(parent, pos, Vector3.new(0, 0, -1):Lerp(dir, 0.6))
				end, alive)
				-- happy parents jump, unhappy ones shake their head (the client adds hearts / storm clouds)
				local avg, n = 0, 0
				for _, b in fam.Babies do
					avg += faces[b.Uid] or 70
					n += 1
				end
				parent.Model:SetAttribute("Anim", if n > 0 and avg / n >= 60 then "Celebrate" else "Sad")
			end)
		end
		for bi, baby in fam.Babies do
			local from = baby.Pos
			local route = {
				from,
				doorIn + Vector3.new((bi % 2) * 2 - 1, 0.2, 0),
				doorOut + Vector3.new(0, 0.8, 0),
				porch + Vector3.new(lane + (bi - 1) * 3 - 1.5, 0, 3),
			}
			baby.Model:SetAttribute("Anim", "Walk")
			task.spawn(function()
				task.wait(1 + bi * 0.3)
				walk(route, BABY_SPEED, function(pos, dir)
					placeBaby(baby, pos, dir)
				end, alive)
				local score = faces[baby.Uid] or 70
				baby.Model:SetAttribute("Anim", if score >= 60 then "Celebrate" else "Sad")
			end)
		end
	end
end

return ArrivalScene
