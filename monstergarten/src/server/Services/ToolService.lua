-- ToolService: what each player holds (one thing at a time), tool racks, dropped items and tool use.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Tools = require(Shared.Config.Tools)
local ServerUtil = require(script.Parent.Parent.ServerUtil)
local Interact = require(script.Parent.Parent.Interact)
local ItemVisuals = require(script.Parent.Parent.World.ItemVisuals)

local ToolService = {}
local S
local visuals: { [Player]: Model } = {}
local savedC0: { [Motor6D]: CFrame } = {}

local HOLD_OFFSET = CFrame.new(0.9, 0.1, -1.5)

-- Arms forward pose while holding something (server-side C0 tweak replicates to everyone).
local function setPose(player: Player, holding: boolean)
	local char = player.Character
	if not char then
		return
	end
	for _, name in { "RightShoulder", "LeftShoulder", "Right Shoulder", "Left Shoulder" } do
		local joint = char:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			if not savedC0[joint] then
				savedC0[joint] = joint.C0
			end
			local base = savedC0[joint]
			local isR6 = name:find(" ") ~= nil
			if holding then
				if isR6 then
					local sign = if name:find("Right") then 1 else -1
					joint.C0 = base * CFrame.Angles(0, 0, sign * math.rad(80))
				else
					joint.C0 = base * CFrame.Angles(math.rad(75), 0, 0)
				end
			else
				joint.C0 = base
			end
		end
	end
end

local function skinFor(player: Player, toolId: string): string?
	local d = S.DataService:Get(player)
	local skins = d and d.Cosmetics.Equipped.ToolSkins
	local s = skins and skins[toolId]
	if s and s ~= "" then
		return s
	end
	return nil
end

local function attachVisual(player: Player, held: any)
	local old = visuals[player]
	if old then
		old:Destroy()
		visuals[player] = nil
	end
	if not held or held.Kind == "Baby" then
		return
	end
	local root = ServerUtil.root(player)
	if not root then
		return
	end
	local m = ItemVisuals.forHeld(held, if held.Kind == "Tool" then skinFor(player, held.Id) else nil)
	if not m then
		return
	end
	m:PivotTo(root.CFrame * HOLD_OFFSET)
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = m.PrimaryPart
	w.Parent = m.PrimaryPart
	m.Name = "HeldItem"
	m.Parent = player.Character
	visuals[player] = m
end

function ToolService:GetHeld(player: Player): any?
	local session = S.ShiftService:SessionOf(player)
	return session and session.Held[player]
end

function ToolService:IsEmpty(player: Player): boolean
	return self:GetHeld(player) == nil
end

function ToolService:SetHeld(player: Player, held: any?)
	local session = S.ShiftService:SessionOf(player)
	if session then
		session.Held[player] = held
	end
	if held then
		player:SetAttribute("Held", held.Kind .. ":" .. held.Id)
		player:SetAttribute("HeldUid", if held.Kind == "Baby" then held.Extra else nil)
		player:SetAttribute("HeldSlow", held.Slow or 0)
		player:SetAttribute("TrashCount", if held.Kind == "Trash" or (held.Kind == "Tool" and held.Id == "TrashBag") then (held.Count or 0) else nil)
	else
		player:SetAttribute("Held", nil)
		player:SetAttribute("HeldUid", nil)
		player:SetAttribute("HeldSlow", nil)
		player:SetAttribute("TrashCount", nil)
	end
	player:SetAttribute("FlashlightOn", nil)
	attachVisual(player, held)
	setPose(player, held ~= nil)
end

-- Clear without dropping (consumed / shift ended). Tools return to their rack.
function ToolService:ClearHeld(player: Player)
	local session = S.ShiftService:SessionOf(player)
	local held = session and session.Held[player]
	if held and held.Kind == "Tool" and session then
		self:ReturnToRack(session, held.Id, held.Rack)
	elseif held and held.Kind == "Baby" and session then
		S.BabyService:ReleaseCarried(session, held.Extra, player)
	end
	self:SetHeld(player, nil)
end

function ToolService:ToolLevel(session, toolId: string): number
	return (session.TeamUpgrades[toolId] or 0) + 1
end

function ToolService:ToolStat(session, toolId: string, stat: string): number?
	local def = Tools.Defs[toolId]
	if not def then
		return nil
	end
	local lvl = self:ToolLevel(session, toolId)
	local levels = def.Levels
	if levels then
		local row = levels[math.min(lvl, #levels)]
		if row[stat] ~= nil then
			return row[stat]
		end
	end
	return (def :: any)[stat]
end

-- Racks ----------------------------------------------------------------------

local function rackVisual(rack)
	if rack.Visual then
		rack.Visual:Destroy()
		rack.Visual = nil
	end
	if rack.Available then
		local m = ItemVisuals.tool(rack.ToolId)
		ItemVisuals.anchor(m, rack.Slot.CFrame)
		m.Parent = rack.Model
		rack.Visual = m
	end
	rack.Prompt.Enabled = rack.Available and rack.Unlocked
	rack.Model:SetAttribute("Available", rack.Available)
end

function ToolService:ReturnToRack(session, toolId: string, preferred: any?)
	local target = preferred
	if not target or target.Available or target.ToolId ~= toolId then
		target = nil
		for _, r in session.Racks do
			if r.ToolId == toolId and not r.Available then
				target = r
				break
			end
		end
	end
	if target then
		target.Available = true
		rackVisual(target)
	end
end

function ToolService:SetupSession(session)
	session.Racks = {}
	for _, m in session:Tagged("ToolRack") do
		local toolId = m:GetAttribute("ToolId")
		local slot = m:FindFirstChild("Slot")
		if toolId and slot and Tools.Defs[toolId] then
			local unlocked = session.IsUnlocked("Tool:" .. toolId)
			local rack = {
				Model = m,
				ToolId = toolId,
				Slot = slot,
				Available = true,
				Unlocked = unlocked,
				Prompt = ServerUtil.prompt(slot, "TakeTool", { Text = "Take", Object = toolId, Need = "Empty", Distance = 7 }),
			}
			rack.Prompt:SetAttribute("ToolId", toolId)
			ServerUtil.prompt(slot, "ReturnTool", { Text = "Return", Object = toolId, Need = "Tool:" .. toolId, Distance = 7 })
			m:SetAttribute("Locked", not unlocked)
			table.insert(session.Racks, rack)
			rackVisual(rack)
		end
	end
end

function ToolService:CleanupSession(session)
	for _, p in session.Players do
		local v = visuals[p]
		if v then
			v:Destroy()
			visuals[p] = nil
		end
	end
end

local function rackFor(session, slot: Instance)
	for _, r in session.Racks do
		if r.Slot == slot then
			return r
		end
	end
	return nil
end

-- World items ----------------------------------------------------------------

function ToolService:SpawnItem(session, held: any, pos: Vector3)
	if held.Kind == "Trash" then
		S.HazardService:SpawnTrash(session, pos, held.Count or 1)
		return
	end
	local m = ItemVisuals.forHeld(held, nil)
	if not m then
		return
	end
	ItemVisuals.anchor(m, CFrame.new(pos + Vector3.new(0, 0.7, 0)))
	m.Name = "Item"
	m.Parent = session.Dynamic
	local item = { Model = m, Held = held, DroppedAt = session.Time }
	local prompt = ServerUtil.prompt(m.PrimaryPart, "PickUpItem", { Text = "Pick up", Object = held.Id, Need = "Empty", Distance = 6 })
	prompt:SetAttribute("ItemKind", held.Kind)
	m:SetAttribute("ItemKind", held.Kind)
	m:SetAttribute("ItemId", held.Id)
	table.insert(session.Items, item)
	-- Lullaby player placed on the floor works as a sleep booster.
	if held.Kind == "Tool" and held.Id == "Lullaby" then
		m:SetAttribute("Lullaby", true)
		session:Effect("LullabyNotes", { Model = m, On = true })
	end
	return item
end

local function removeItem(session, item)
	local i = table.find(session.Items, item)
	if i then
		table.remove(session.Items, i)
	end
	if item.Model then
		item.Model:Destroy()
	end
end

function ToolService:DropHeld(player: Player)
	local session = S.ShiftService:SessionOf(player)
	if not session or session.Phase ~= "Playing" then
		return
	end
	local held = session.Held[player]
	local root = ServerUtil.root(player)
	if not held or not root then
		return
	end
	local pos = (root.CFrame * CFrame.new(0, -2.5, -2.5)).Position
	if held.Kind == "Baby" then
		S.BabyService:DropBaby(session, held.Extra, player, pos)
		self:SetHeld(player, nil)
	else
		self:SetHeld(player, nil)
		self:SpawnItem(session, held, pos)
	end
	session:Sound("Drop", pos)
end

-- Tool use -------------------------------------------------------------------

local function onUse(player: Player, dir: any)
	if not ServerUtil.rateLimit(player, "UseTool", 12) then
		return
	end
	local session = S.ShiftService:SessionOf(player)
	if not session or not session:IsLive() then
		return
	end
	local held = session.Held[player]
	local root = ServerUtil.root(player)
	if not held or held.Kind ~= "Tool" or not root then
		return
	end
	local def = Tools.Defs[held.Id]
	-- Direction: trust only a normalized, mostly-horizontal client aim; fall back to facing.
	local look = root.CFrame.LookVector
	if typeof(dir) == "Vector3" and dir.Magnitude > 0.1 then
		local flat = Vector3.new(dir.X, math.clamp(dir.Y, -0.6, 0.6), dir.Z)
		if flat.Magnitude > 0.1 then
			look = flat.Unit
		end
	end
	local origin = root.Position
	if def.Use == "Cone" then
		local range = ToolService:ToolStat(session, held.Id, "Range") or 8
		local angle = def.Angle or 30
		local power = ToolService:ToolStat(session, held.Id, "Power") or 1
		S.HazardService:ApplyCone(session, player, held.Id, origin, look, range, angle, power)
		session:Effect("ToolUse", { Player = player, Tool = held.Id })
	elseif def.Use == "Toggle" then
		local on = not player:GetAttribute("FlashlightOn")
		player:SetAttribute("FlashlightOn", on)
		player:SetAttribute("FlashlightRange", ToolService:ToolStat(session, "Flashlight", "Range"))
		player:SetAttribute("FlashlightAngle", ToolService:ToolStat(session, "Flashlight", "Angle"))
		local v = visuals[player]
		local lens = v and v:FindFirstChild("Lens")
		local beam = lens and lens:FindFirstChild("Beam") :: SpotLight?
		if beam then
			beam.Enabled = on
			beam.Range = ToolService:ToolStat(session, "Flashlight", "Range") or 30
		end
		session:Sound("Tool_FlashlightClick", origin)
	elseif def.Use == "Net" then
		local range = ToolService:ToolStat(session, "Net", "Range") or 12
		S.BabyService:NetCatch(session, player, origin, look, range)
		session:Effect("ToolUse", { Player = player, Tool = held.Id })
	end
end

function ToolService:Tick(session, dt)
	-- Dropped tools return after a while; dropped food vanishes after a minute.
	for i = #session.Items, 1, -1 do
		local item = session.Items[i]
		local age = session.Time - item.DroppedAt
		if item.Held.Kind == "Tool" and item.Held.Id ~= "Lullaby" and age > Tools.ReturnAfter then
			removeItem(session, item)
			self:ReturnToRack(session, item.Held.Id, item.Held.Rack)
		elseif item.Held.Kind ~= "Tool" and age > 60 then
			removeItem(session, item)
		end
	end
end

function ToolService:Init(services)
	S = services
	Interact.setSessionResolver(function(p)
		return S.ShiftService:SessionOf(p)
	end)

	Interact.on("TakeTool", function(player, prompt, session)
		if not session or not self:IsEmpty(player) then
			return
		end
		local rack = rackFor(session, prompt.Parent)
		if not rack or not rack.Available then
			return
		end
		if not rack.Unlocked then
			ServerUtil.notify(player, { "Tool_Locked", rack.ToolId }, "error")
			return
		end
		rack.Available = false
		rackVisual(rack)
		local held = { Kind = "Tool", Id = rack.ToolId, Rack = rack, Count = 0 }
		self:SetHeld(player, held)
		session:Sound("Pickup", prompt.Parent.Position)
		S.TutorialService:OnEvent(session, "PickUp", player)
	end)

	Interact.on("ReturnTool", function(player, prompt, session)
		if not session then
			return
		end
		local held = session.Held[player]
		local rack = rackFor(session, prompt.Parent)
		if held and held.Kind == "Tool" and rack and held.Id == rack.ToolId then
			self:SetHeld(player, nil)
			self:ReturnToRack(session, held.Id, rack)
		end
	end)

	Interact.on("PickUpItem", function(player, prompt, session)
		if not session or not self:IsEmpty(player) then
			return
		end
		for _, item in session.Items do
			if item.Model and prompt:IsDescendantOf(item.Model) then
				removeItem(session, item)
				if item.Held.Id == "Lullaby" then
					session:Effect("LullabyNotes", { Model = item.Model, On = false })
				end
				self:SetHeld(player, item.Held)
				session:Sound("Pickup", item.Model:GetPivot().Position)
				S.TutorialService:OnEvent(session, "PickUp", player)
				return
			end
		end
	end)
end

function ToolService:Start()
	Interact.start()
	Remotes.event("DropHeld").OnServerEvent:Connect(function(player)
		if ServerUtil.rateLimit(player, "Drop", 5) then
			ToolService:DropHeld(player)
		end
	end)
	Remotes.event("UseTool").OnServerEvent:Connect(onUse)
end

return ToolService
