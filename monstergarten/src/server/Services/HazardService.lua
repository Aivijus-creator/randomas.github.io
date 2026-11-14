-- HazardService: fires, puddles (ink/slime/water/ice), wall splats, trash, roots and bandage trails.
-- Also resolves cone-shaped tool use (extinguisher, mop, watering can).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.Config.GameSettings)
local MathUtil = require(Shared.Util.Math)
local ServerUtil = require(script.Parent.Parent.ServerUtil)
local Interact = require(script.Parent.Parent.Interact)
local ItemVisuals = require(script.Parent.Parent.World.ItemVisuals)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local HazardService = {}
local S

local PUDDLE_STYLE = {
	Ink = { Color = Color3.fromRGB(25, 20, 35), Material = Enum.Material.Glass, Transparency = 0.1, Slippery = true, Spill = true },
	Slime = { Color = Color3.fromRGB(120, 230, 100), Material = Enum.Material.SmoothPlastic, Transparency = 0.3, Slippery = true, Spill = true },
	Water = { Color = Color3.fromRGB(120, 190, 255), Material = Enum.Material.Glass, Transparency = 0.45, Slippery = true, Spill = false },
	Ice = { Color = Color3.fromRGB(200, 240, 255), Material = Enum.Material.Ice, Transparency = 0.15, Slippery = true, Spill = false },
}

local function floorY(session, pos: Vector3): number
	local y = S.BabyService and require(script.Parent.Parent.Babies.BabyAI).floorAt(session, pos)
	return y or pos.Y
end

-- Fires -------------------------------------------------------------------------

function HazardService:SpawnFire(session, pos: Vector3, target: Instance?): any?
	if not session:IsLive() then
		return nil
	end
	for _, f in session.Fires do
		if (f.Pos - pos).Magnitude < 3 then
			f.HP = math.min(100, f.HP + 30)
			return f
		end
	end
	if #session.Fires >= GameSettings.MaxFires then
		return nil
	end
	local y = floorY(session, pos)
	local part = ServerUtil.part({
		Name = "Fire",
		Size = Vector3.new(3, 4, 3),
		CFrame = CFrame.new(pos.X, y + 2, pos.Z),
		Transparency = 1,
		CanQuery = false,
	})
	part:SetAttribute("Intensity", 0.4)
	CollectionService:AddTag(part, "Fire")
	part.Parent = session.Dynamic
	local fire = { Uid = session:NextUid("f"), Part = part, Pos = part.Position, HP = 40, Target = target, SpreadT = 0 }
	if target and target:IsA("Model") then
		target:SetAttribute("Burning", true)
	end
	table.insert(session.Fires, fire)
	session:Sound("Env_Fire", part.Position)
	S.EventService:OnMess(session, "Fire")
	return fire
end

local function removeFire(session, fire, player: Player?)
	local i = table.find(session.Fires, fire)
	if i then
		table.remove(session.Fires, i)
	end
	if fire.Target and fire.Target:IsA("Model") and fire.Target.Parent then
		local still = false
		for _, f in session.Fires do
			if f.Target == fire.Target then
				still = true
			end
		end
		if not still then
			fire.Target:SetAttribute("Burning", nil)
		end
	end
	session:Effect("Fizz", { Position = fire.Pos })
	session:Sound("Env_Fizz", fire.Pos)
	fire.Part:Destroy()
	if player then
		session:AddAction(player)
		S.QuestService:Track(player, "FirePutOut", 1)
		S.DataService:Update(player, function(d)
			d.Stats.FiresPutOut += 1
		end)
		S.TutorialService:OnEvent(session, "FireOut", player)
	end
end

function HazardService:DamageFire(session, fire, amount: number, player: Player?)
	fire.HP -= amount
	if fire.HP <= 0 then
		removeFire(session, fire, player)
	end
end

function HazardService:ExtinguishNear(session, pos: Vector3, radius: number)
	for i = #session.Fires, 1, -1 do
		local f = session.Fires[i]
		if (f.Pos - pos).Magnitude <= radius then
			removeFire(session, f, nil)
		end
	end
end

-- Ignite a furniture model / baby at a position (used by chaos).
function HazardService:Ignite(session, target: Instance?, pos: Vector3)
	if target and target:IsA("Model") and not CollectionService:HasTag(target, "Flammable") then
		return
	end
	self:SpawnFire(session, pos, target)
end

local function fireTick(session, dt)
	local fireproof = session.Upgrades.FireproofFurniture
	for i = #session.Fires, 1, -1 do
		local f = session.Fires[i]
		f.HP = math.min(100, f.HP + 4 * dt)
		f.Part:SetAttribute("Intensity", math.clamp(f.HP / 100, 0.2, 1))
		if f.Target and f.Target.Parent and f.Target:IsA("Model") then
			S.FurnitureService:Damage(session, f.Target, (if fireproof then 1.2 else 3) * dt)
		end
		-- ice melts near fire
		for j = #session.Puddles, 1, -1 do
			local p = session.Puddles[j]
			if p.Kind == "Ice" and (p.Pos - f.Pos).Magnitude < p.Size / 2 + 3 then
				HazardService:ConvertPuddle(session, p, "Water")
				f.HP -= 40
			end
		end
		if f.HP <= 0 then
			removeFire(session, f, nil)
			continue
		end
		f.SpreadT += dt
		if f.SpreadT >= 4 and f.HP > 50 then
			f.SpreadT = 0
			-- spread to nearby flammable furniture
			for model in session.Furniture do
				if CollectionService:HasTag(model, "Flammable") and not model:GetAttribute("Burning") then
					local p = model:GetPivot().Position
					if (Vector3.new(p.X, f.Pos.Y, p.Z) - f.Pos).Magnitude < 7 and math.random() < 0.45 then
						HazardService:SpawnFire(session, p, model)
						break
					end
				end
			end
			-- and to babies standing in it
			for _, b in session.BabyList do
				if (BabyBase.position(b) - f.Pos).Magnitude < 4 then
					S.StatusEffectService:Apply(session, b, "Burning", 5)
				end
			end
		end
	end
	-- burning babies spread fire to flammable babies next to them
	for _, b in session.BabyList do
		if BabyBase.hasStatus(b, "Burning") then
			for _, o in session.BabyList do
				if o ~= b and o.Def.Flammable and not BabyBase.hasStatus(o, "Burning") then
					if (BabyBase.position(o) - BabyBase.position(b)).Magnitude < 4 and math.random() < 0.5 * dt then
						S.StatusEffectService:Apply(session, o, "Burning", 5)
					end
				end
			end
		end
	end
end

-- Puddles ---------------------------------------------------------------------------

local function styleP(part: BasePart, kind: string, size: number)
	local st = PUDDLE_STYLE[kind]
	part.Color = st.Color
	part.Material = st.Material
	part.Transparency = st.Transparency
	part.Size = Vector3.new(0.12, size, size)
	part:SetAttribute("Kind", kind)
	part:SetAttribute("Slippery", st.Slippery)
end

function HazardService:SpawnPuddle(session, pos: Vector3, kind: string, size: number): any?
	if not PUDDLE_STYLE[kind] then
		return nil
	end
	local y = floorY(session, pos)
	local at = Vector3.new(pos.X, y, pos.Z)
	-- merge / combine with existing puddles
	for _, p in session.Puddles do
		local d = (p.Pos - at).Magnitude
		if d < (p.Size + size) / 2 then
			if p.Kind == kind then
				p.Size = math.min(16, p.Size + size * 0.35)
				styleP(p.Part, p.Kind, p.Size)
				return p
			elseif (p.Kind == "Ink" and kind == "Water") or (p.Kind == "Water" and kind == "Ink") then
				-- ink + water: ink spreads twice as big
				local ink = if p.Kind == "Ink" then p else nil
				if ink then
					ink.Size = math.min(18, ink.Size * 2)
					styleP(ink.Part, "Ink", ink.Size)
					return ink
				else
					local newSize = math.min(18, math.max(size, p.Size) * 2)
					self:ConvertPuddle(session, p, "Ink")
					p.Size = newSize
					styleP(p.Part, "Ink", newSize)
					return p
				end
			end
		end
	end
	if #session.Puddles >= GameSettings.MaxPuddles then
		return nil
	end
	local part = ServerUtil.part({
		Name = "Puddle",
		Shape = Enum.PartType.Cylinder,
		CFrame = CFrame.new(at + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		CanQuery = false,
	})
	styleP(part, kind, size)
	CollectionService:AddTag(part, "Puddle")
	part.Parent = session.Dynamic
	local puddle = { Part = part, Pos = at, Size = size, Kind = kind }
	table.insert(session.Puddles, puddle)
	if PUDDLE_STYLE[kind].Spill then
		S.EventService:OnMess(session, kind)
	end
	return puddle
end

function HazardService:ConvertPuddle(session, puddle, kind: string)
	puddle.Kind = kind
	styleP(puddle.Part, kind, puddle.Size)
end

function HazardService:RemovePuddle(session, puddle)
	local i = table.find(session.Puddles, puddle)
	if i then
		table.remove(session.Puddles, i)
	end
	puddle.Part:Destroy()
end

-- Ink splat on the nearest wall (counts as a spill).
function HazardService:SplatWall(session, origin: Vector3)
	local structure = session.Model:FindFirstChild("Structure")
	if not structure then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { structure }
	local a = math.random() * math.pi * 2
	local dir = Vector3.new(math.cos(a), 0, math.sin(a)) * 14
	local r = workspace:Raycast(origin + Vector3.new(0, 2.5, 0), dir, params)
	if r then
		local s = math.random(20, 40) / 10
		local part = ServerUtil.part({
			Name = "Splat",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.1, s, s),
			CFrame = CFrame.lookAt(r.Position + r.Normal * 0.06, r.Position + r.Normal) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(25, 20, 35),
			Material = Enum.Material.Glass,
		})
		CollectionService:AddTag(part, "Splat")
		part.Parent = session.Dynamic
		table.insert(session.Puddles, { Part = part, Pos = part.Position, Size = s, Kind = "Splat" })
	end
end

-- Trash --------------------------------------------------------------------------------

function HazardService:SpawnTrash(session, pos: Vector3, count: number?)
	for _ = 1, (count or 1) do
		if #session.Trash >= GameSettings.MaxTrash then
			return
		end
		local p = pos + Vector3.new(math.random(-15, 15) / 10, 0, math.random(-15, 15) / 10)
		local y = floorY(session, p)
		local m = ItemVisuals.trash()
		ItemVisuals.anchor(m, CFrame.new(p.X, y + 0.45, p.Z) * CFrame.Angles(0, math.random() * 6, 0))
		m.Name = "Trash"
		CollectionService:AddTag(m, "Trash")
		m.Parent = session.Dynamic
		ServerUtil.prompt(m.PrimaryPart, "CollectTrash", { Text = "Pick up", Object = "Trash", Need = "Empty,Tool:TrashBag,Kind:Trash", Distance = 6 })
		table.insert(session.Trash, { Model = m, Pos = p })
	end
	S.EventService:OnMess(session, "Trash")
end

-- Roots -----------------------------------------------------------------------------------

function HazardService:SpawnRoot(session, pos: Vector3, yaw: number)
	if #session.Roots >= 6 then
		return
	end
	local y = floorY(session, pos)
	local cf = CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, yaw, 0)
	local m = Instance.new("Model")
	m.Name = "Root"
	local wall = ServerUtil.part({
		Name = "RootWall",
		Size = Vector3.new(7, 0.2, 1.4),
		CFrame = cf * CFrame.new(0, 0.1, 0),
		Color = Color3.fromRGB(110, 80, 55),
		Material = Enum.Material.Wood,
		CanCollide = true,
	})
	wall.Parent = m
	m.PrimaryPart = wall
	TweenService:Create(wall, TweenInfo.new(2.5, Enum.EasingStyle.Back), { Size = Vector3.new(7, 5, 1.4), CFrame = cf * CFrame.new(0, 2.5, 0) }):Play()
	for i = 1, 4 do
		local tendril = ServerUtil.part({
			Name = "Tendril",
			Size = Vector3.new(0.6, 0.2, 0.6),
			CFrame = cf * CFrame.new(-3 + i * 1.3, 0.1, -0.6),
			Color = Color3.fromRGB(90, 160, 80),
			Material = Enum.Material.Grass,
		})
		tendril.Parent = m
		TweenService:Create(tendril, TweenInfo.new(2.5 + i * 0.2, Enum.EasingStyle.Back), { Size = Vector3.new(0.6, 5.6 + (i % 2), 0.6), CFrame = cf * CFrame.new(-3 + i * 1.3, 2.9, -0.6) }):Play()
	end
	CollectionService:AddTag(m, "Root")
	m.Parent = session.Dynamic
	local hold = S.ToolService:ToolStat(session, "Shears", "Time") or 1.5
	ServerUtil.prompt(wall, "CutRoot", { Text = "Cut", Object = "Roots", Need = "Tool:Shears", Hold = hold, Distance = 8 })
	table.insert(session.Roots, { Model = m, Pos = cf.Position })
	session:Effect("RootsGrow", { Position = cf.Position })
end

-- Bandage trails ------------------------------------------------------------------------

function HazardService:SpawnTrail(session, pos: Vector3, yaw: number)
	if #session.Trails >= 24 then
		local old = table.remove(session.Trails, 1)
		if old then
			old.Part:Destroy()
		end
	end
	local y = floorY(session, pos)
	local part = ServerUtil.part({
		Name = "BandageTrail",
		Size = Vector3.new(1, 0.08, 4),
		CFrame = CFrame.new(pos.X, y + 0.06, pos.Z) * CFrame.Angles(0, yaw + (math.random() - 0.5), 0),
		Color = Color3.fromRGB(240, 230, 205),
		Material = Enum.Material.Fabric,
	})
	CollectionService:AddTag(part, "BandageTrail")
	part.Parent = session.Dynamic
	table.insert(session.Trails, { Part = part, Pos = part.Position })
end

-- Cone tool use ---------------------------------------------------------------------------

function HazardService:ApplyCone(session, player: Player, toolId: string, origin: Vector3, dir: Vector3, range: number, angle: number, power: number)
	local flatDir = Vector3.new(dir.X, 0, dir.Z)
	flatDir = if flatDir.Magnitude > 0.01 then flatDir.Unit else Vector3.new(0, 0, -1)
	local function inCone(p: Vector3, extra: number?): boolean
		local o = Vector3.new(origin.X, p.Y, origin.Z)
		return MathUtil.inCone(o, flatDir, p, range + (extra or 0), angle + 10)
	end
	if toolId == "Extinguisher" or toolId == "WateringCan" then
		for i = #session.Fires, 1, -1 do
			local f = session.Fires[i]
			if f and inCone(f.Pos, 1.5) then
				local dmg = if toolId == "Extinguisher" then 30 * power else (if f.HP < 60 then 18 else 6) * power / 0.5
				self:DamageFire(session, f, dmg, player)
			end
		end
		for _, b in session.BabyList do
			if inCone(BabyBase.position(b), 1) then
				if BabyBase.hasStatus(b, "Burning") then
					S.StatusEffectService:Remove(session, b, "Burning")
					session:AddAction(player)
				end
				S.StatusEffectService:Apply(session, b, "Wet", 4)
				if toolId == "WateringCan" and b.Needs.Water then
					BabyBase.change(b, "Water", 6)
				end
			end
		end
		if toolId == "WateringCan" and math.random() < 0.15 then
			local p = origin + flatDir * math.min(range, 5)
			self:SpawnPuddle(session, p, "Water", 2)
		end
	elseif toolId == "Mop" then
		local cleaned = 0
		for i = #session.Puddles, 1, -1 do
			local p = session.Puddles[i]
			if p and inCone(p.Pos, p.Size / 2) then
				p.Size -= 1.6 * power
				if p.Size < 1 then
					self:RemovePuddle(session, p)
					cleaned += 1
				elseif p.Kind ~= "Splat" then
					styleP(p.Part, p.Kind, p.Size)
				else
					p.Part.Size = Vector3.new(0.1, p.Size, p.Size)
				end
			end
		end
		for i = #session.Trails, 1, -1 do
			local t = session.Trails[i]
			if inCone(t.Pos, 1.5) then
				t.Part:Destroy()
				table.remove(session.Trails, i)
				cleaned += 1
			end
		end
		if cleaned > 0 then
			session:AddAction(player, cleaned)
			S.QuestService:Track(player, "Cleaned", cleaned)
		end
	end
end

-- Prompts ---------------------------------------------------------------------------------

function HazardService:Init(services)
	S = services

	Interact.on("CollectTrash", function(player, prompt, session)
		if not session then
			return
		end
		local entry, idx
		for i, t in session.Trash do
			if prompt:IsDescendantOf(t.Model) then
				entry, idx = t, i
				break
			end
		end
		if not entry then
			return
		end
		local held = S.ToolService:GetHeld(player)
		if held == nil then
			S.ToolService:SetHeld(player, { Kind = "Trash", Id = "Trash", Count = 1, Extra = 1 })
		elseif held.Kind == "Tool" and held.Id == "TrashBag" then
			local cap = S.ToolService:ToolStat(session, "TrashBag", "Capacity") or 5
			if (held.Count or 0) >= cap then
				ServerUtil.notify(player, "Trash_BagFull", "error")
				return
			end
			held.Count = (held.Count or 0) + 1
			player:SetAttribute("TrashCount", held.Count)
		elseif held.Kind == "Trash" then
			ServerUtil.notify(player, "Hands_Full", "error")
			return
		else
			return
		end
		table.remove(session.Trash, idx)
		entry.Model:Destroy()
		session:Sound("Pickup", entry.Pos)
	end)

	Interact.on("EmptyTrash", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		if not held then
			return
		end
		local n = 0
		if held.Kind == "Trash" then
			n = held.Count or 1
			S.ToolService:SetHeld(player, nil)
		elseif held.Kind == "Tool" and held.Id == "TrashBag" then
			n = held.Count or 0
			held.Count = 0
			player:SetAttribute("TrashCount", 0)
		elseif held.Kind == "Dish" and held.Id == "Burnt" then
			S.ToolService:SetHeld(player, nil)
			n = 1
		end
		if n > 0 then
			session:AddAction(player, n)
			S.QuestService:Track(player, "Cleaned", n)
			S.EventService:OnTrashBinned(session, player, n)
			session:Sound("Drop", prompt.Parent.Position)
		end
	end)

	Interact.on("CutRoot", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		if not held or held.Id ~= "Shears" then
			return
		end
		for i, r in session.Roots do
			if prompt:IsDescendantOf(r.Model) then
				table.remove(session.Roots, i)
				session:Effect("Leaves", { Position = r.Pos + Vector3.new(0, 2, 0) })
				session:Sound("Tool_Shears", r.Pos)
				r.Model:Destroy()
				session:AddAction(player)
				S.QuestService:Track(player, "Cleaned", 1)
				return
			end
		end
	end)
end

function HazardService:SetupSession(session)
	for _, bin in session:Tagged("TrashBin") do
		local root = (bin :: Model).PrimaryPart
		if root then
			ServerUtil.prompt(root, "EmptyTrash", { Text = "Throw away", Object = "Bin", Need = "Kind:Trash,Tool:TrashBag,Dish:Burnt", Distance = 7 })
		end
	end
end

function HazardService:Tick(session, dt)
	fireTick(session, dt)
end

-- Scoring helpers
function HazardService:Counts(session): (number, number, boolean)
	local spills = 0
	for _, p in session.Puddles do
		if p.Kind == "Ink" or p.Kind == "Slime" or p.Kind == "Splat" then
			spills += 1
		end
	end
	return #session.Trash, spills, #session.Fires > 0
end

return HazardService
