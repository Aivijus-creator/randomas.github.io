-- MapService: builds the world at startup and hands out daycare copies for shifts.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.Config.GameSettings)
local MapBuilder = require(script.Parent.Parent.World.MapBuilder)
local ModelRegistry = require(Shared.World.ModelRegistry)

local MapService = {}
local template: Model? = nil
local active: { [number]: Model } = {}
local container: Folder

function MapService:Init()
	MapBuilder.setupLighting()
	local ok, err = pcall(MapBuilder.buildLobby)
	if not ok then
		warn("[MapService] lobby build failed:", err)
	end
	local ok2, t = pcall(MapBuilder.buildTemplate)
	if ok2 then
		template = t
	else
		warn("[MapService] daycare template build failed:", t)
	end
	-- Lobby NPCs (e.g. the shopkeeper behind the kiosk)
	for _, spot in CollectionService:GetTagged("NPCSpot") do
		local name = spot:GetAttribute("NPC")
		if spot:IsA("BasePart") and type(name) == "string" then
			local ok, npc = pcall(ModelRegistry.getNPC, name)
			if ok and npc then
				local floorY = spot.Position.Y - spot.Size.Y / 2 - 2.5
				local look = spot.CFrame.LookVector
				local pos = Vector3.new(spot.Position.X, floorY + (npc:GetAttribute("FloorOffset") or 3), spot.Position.Z)
				npc:PivotTo(CFrame.lookAt(pos, pos + look))
				npc:SetAttribute("Anim", "Idle")
				CollectionService:AddTag(npc, "NPCModel")
				npc.Parent = workspace
			end
		end
	end
	container = Instance.new("Folder")
	container.Name = "Daycares"
	container.Parent = workspace
end

function MapService:Template(): Model?
	return template
end

-- Returns a free slot index (1..MaxSessions) or nil.
function MapService:FreeSlot(): number?
	for i = 1, GameSettings.MaxSessions do
		if not active[i] then
			return i
		end
	end
	return nil
end

function MapService:SlotOrigin(slot: number): CFrame
	return CFrame.new(slot * GameSettings.SessionSpacing, 0, 0)
end

-- Clone the template into a slot. `isUnlocked(id)` decides optional content (host's unlocks).
function MapService:CloneDaycare(slot: number, isUnlocked: (string) -> boolean, players: { Player }): Model?
	if not template or active[slot] then
		return nil
	end
	local m = template:Clone()
	m.Name = "Daycare_" .. slot
	-- Remove optional content first (cheaper to move fewer parts).
	for _, d in m:GetDescendants() do
		if d.Parent then
			local req = d:GetAttribute("RequiresUnlock")
			if req and not isUnlocked(req) then
				d:Destroy()
				continue
			end
			local rem = d:GetAttribute("RemoveIfUnlocked")
			if rem and isUnlocked(rem) then
				d:Destroy()
			end
		end
	end
	m:PivotTo(self:SlotOrigin(slot))
	m:SetAttribute("Slot", slot)
	m.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
	m.Parent = container
	for _, p in players do
		pcall(function()
			m:AddPersistentPlayer(p)
		end)
	end
	-- Moving clones keeps "Origin"-relative attributes valid except world-space ones; fix those.
	local offset = self:SlotOrigin(slot).Position
	for _, d in m:GetDescendants() do
		local origin = d:GetAttribute("Origin")
		if typeof(origin) == "Vector3" then
			d:SetAttribute("Origin", origin + offset)
		end
		for _, key in { "ClosedCF", "OpenCF", "PivotCF" } do
			local v = d:GetAttribute(key)
			if typeof(v) == "CFrame" then
				d:SetAttribute(key, v + offset)
			end
		end
		local center = d:GetAttribute("Center")
		if typeof(center) == "Vector3" then
			d:SetAttribute("Center", center + offset)
		end
	end
	active[slot] = m
	return m
end

function MapService:Release(slot: number)
	local m = active[slot]
	active[slot] = nil
	if m then
		m:Destroy()
	end
end

-- Helper: tagged instances inside a given daycare.
function MapService:Tagged(daycare: Instance, tag: string): { Instance }
	local out = {}
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsDescendantOf(daycare) then
			table.insert(out, inst)
		end
	end
	return out
end

return MapService
