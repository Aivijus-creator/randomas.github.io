-- BabyService: spawning, carrying, stations, all baby interactions, movement loop and animation hints.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Needs = require(Shared.Config.Needs)
local RecipeMatch = require(Shared.Logic.RecipeMatch)
local MathUtil = require(Shared.Util.Math)
local ServerUtil = require(script.Parent.Parent.ServerUtil)
local Interact = require(script.Parent.Parent.Interact)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)
local BabyAI = require(script.Parent.Parent.Babies.BabyAI)

local BabyService = {}
local S

local CARRY_OFFSET = CFrame.new(0, 0.4, -2.2)
local STATION_TAGS = { "Bed", "Bath", "Fireplace", "ChargingStation", "SunSpot", "ColdSpot", "DarkZone" }
local TAG_NEED = { Bed = "Sleep", Bath = "Clean", Fireplace = "Warmth", ChargingStation = "Charge", SunSpot = "Sun", ColdSpot = "Cold", DarkZone = "Darkness" }

local function ctxFor(session)
	return { Session = session, S = S, BabyBase = BabyBase, BabyAI = BabyAI }
end
BabyService.ctxFor = ctxFor

function BabyService:Get(session, uid: string)
	return session.Babies[uid]
end

function BabyService:FromPrompt(session, prompt: Instance)
	for _, b in session.BabyList do
		if prompt:IsDescendantOf(b.Model) then
			return b
		end
	end
	return nil
end

-- Prompt management -----------------------------------------------------------

local function addPrompts(baby)
	local root = baby.Root
	local def = baby.Def
	local prompts = {}
	prompts.PickUp = ServerUtil.prompt(root, "PickUpBaby", { Text = "Pick up", Object = def.Name.en, Need = "Empty", Distance = 7 })
	if def.Eats or def.Id == "Yeti" then
		prompts.Feed = ServerUtil.prompt(root, "Feed", { Text = "Feed", Object = def.Name.en, Need = "Kind:Dish,Kind:Ingredient", Distance = 7 })
	end
	if def.Needs.Fun then
		prompts.Play = ServerUtil.prompt(root, "Play", { Text = "Play", Object = def.Name.en, Need = "Empty", Key = Enum.KeyCode.F, Pad = Enum.KeyCode.ButtonY, Hold = 3, Distance = 7 })
		prompts.Toy = ServerUtil.prompt(root, "GiveToy", { Text = "Give toy", Object = def.Name.en, Need = "Tool:ToyBag", Distance = 7 })
	end
	if def.Needs.Clean then
		prompts.Wash = ServerUtil.prompt(root, "Wash", { Text = "Wash", Object = def.Name.en, Need = "Tool:Sponge", Hold = 4, Distance = 8 })
		prompts.Wash.Enabled = false
	end
	if def.Needs.Water then
		prompts.Water = ServerUtil.prompt(root, "Water", { Text = "Water", Object = def.Name.en, Need = "Tool:WateringCan", Hold = 2, Distance = 8 })
	end
	if def.Needs.Bandages then
		prompts.Bandage = ServerUtil.prompt(root, "Bandage", { Text = "Change bandages", Object = def.Name.en, Need = "Tool:BandageRoll", Hold = 4, Distance = 8 })
	end
	if def.Id == "Ghostie" then
		prompts.Catch = ServerUtil.prompt(root, "CatchGhost", { Text = "Catch", Object = def.Name.en, Need = "Any", Distance = 10 })
		prompts.Catch.Enabled = false
		prompts.Catch:SetAttribute("NeedsReveal", true)
	end
	baby.Prompts = prompts
end

-- Enable/disable prompts by state (server side). Held-item filtering happens on the client.
function BabyService:RefreshPrompts(baby)
	local p = baby.Prompts
	if not p then
		return
	end
	local carried = baby.CarriedBy ~= nil
	local hidden = baby.Hidden
	local leaving = baby.State == "Leaving"
	for name, prompt in p do
		local enabled = not carried and not hidden and not leaving
		if name == "Wash" then
			enabled = enabled and baby.Station ~= nil and baby.Station.Tag == "Bath"
		elseif name == "Catch" then
			enabled = hidden and not carried and not leaving
		elseif name == "Feed" or name == "Play" or name == "Toy" then
			enabled = enabled and not BabyBase.hasStatus(baby, "Frozen")
		end
		prompt.Enabled = enabled
	end
end

-- Spawning --------------------------------------------------------------------

function BabyService:SpawnBaby(session, id: string, cf: CFrame)
	local uid = session:NextUid("b")
	local baby = BabyBase.new(session, id, uid, cf)
	BabyBase.placeAt(baby, cf)
	baby.Model.Parent = session.Dynamic
	addPrompts(baby)
	session.Babies[uid] = baby
	table.insert(session.BabyList, baby)
	if baby.Behavior.onSpawn then
		baby.Behavior.onSpawn(baby, ctxFor(session))
	end
	-- remember that this species has been seen (for the pets / collection screen)
	for _, p in session.Players do
		S.DataService:Update(p, function(d)
			d.SeenBabies[id] = true
		end)
	end
	return baby
end

function BabyService:SpawnBabies(session, list: { string }, arrival: boolean)
	local spawns = session:Tagged("BabySpawn")
	local window = session:Tagged("ParentDropoff")[1]
	local windowPos = if window then (window :: Model):GetPivot().Position else session:Origin()
	for i, id in list do
		local marker = spawns[((i - 1) % math.max(1, #spawns)) + 1] :: BasePart?
		local cf = if marker then marker.CFrame else CFrame.new(session:Origin() + Vector3.new(-10 + i * 2, 1.5, 40))
		local baby = self:SpawnBaby(session, id, cf)
		if arrival then
			-- fly in through the window on a soft arc
			local finalPos = baby.Root.Position
			local startPos = windowPos + Vector3.new(0, 2, 2)
			baby.Arriving = true
			task.delay(0.6 + i * 0.45, function()
				if session.Phase == "Ended" then
					return
				end
				local t0 = os.clock()
				local dur = 1.1
				while os.clock() - t0 < dur and baby.Model.Parent do
					local t = (os.clock() - t0) / dur
					local p = startPos:Lerp(finalPos, t) + Vector3.new(0, math.sin(t * math.pi) * 5, 0)
					baby.Root.CFrame = CFrame.new(p) * CFrame.Angles(0, t * math.pi * 2, 0)
					RunService.Heartbeat:Wait()
				end
				baby.Arriving = false
				BabyBase.place(baby)
				session:Effect("Puff", { Position = finalPos })
			end)
			baby.Root.CFrame = CFrame.new(startPos)
		end
	end
end

function BabyService:SetupSession(session)
	session.Stations = {}
	for _, tag in STATION_TAGS do
		for _, inst in session:Tagged(tag) do
			local slot = inst:FindFirstChild("Slot")
			if slot and inst:GetAttribute("Station") ~= false and (inst:GetAttribute("Station") or tag == "Bed") then
				local st = {
					Model = inst,
					Slot = slot,
					Tag = tag,
					Need = inst:GetAttribute("Need") or TAG_NEED[tag],
					Rate = inst:GetAttribute("Rate") or 10,
					Radius = inst:GetAttribute("Radius") or 4,
					Electric = inst:GetAttribute("Electric") == true,
					Occupant = nil,
				}
				st.Prompt = ServerUtil.prompt(slot, "PlaceBaby", { Text = "Place", Object = tag, Need = "Baby", Distance = 8 })
				table.insert(session.Stations, st)
			end
		end
	end
	local esc = session:Tagged("EscapePoint")[1]
	session.EscapePoint = if esc then (esc :: BasePart).Position - Vector3.new(0, 1.3, 0) else nil
end

function BabyService:CleanupSession(session)
	for _, b in session.BabyList do
		BabyBase.destroy(b)
	end
	table.clear(session.BabyList)
	table.clear(session.Babies)
end

-- Carrying --------------------------------------------------------------------

local function freeStation(baby)
	if baby.Station then
		baby.Station.Occupant = nil
		baby.Station = nil
	end
end

function BabyService:LeaveStation(session, baby)
	local st = baby.Station
	freeStation(baby)
	if st then
		-- hop off in front of the station
		local front = st.Slot.CFrame * CFrame.new(0, 0, -4)
		local y = BabyAI.floorAt(session, front.Position) or (st.Slot.Position.Y - 1.45)
		baby.Pos = Vector3.new(front.Position.X, y, front.Position.Z)
		BabyBase.place(baby)
	end
	if baby.State == "Placed" or baby.State == "Asleep" then
		BabyBase.setState(baby, if baby.Tantrum then "Tantrum" else "Idle")
	end
	baby.Statuses.Asleep = nil
	self:RefreshPrompts(baby)
end

function BabyService:Carry(session, baby, player: Player)
	local root = ServerUtil.root(player)
	if not root then
		return false
	end
	freeStation(baby)
	baby.Statuses.Asleep = nil
	baby.Path = nil
	baby.CarriedBy = player
	BabyBase.setState(baby, "Carried")
	baby.Root.Anchored = false
	baby.Root.Massless = true
	baby.Model:PivotTo(root.CFrame * CARRY_OFFSET)
	local w = Instance.new("WeldConstraint")
	w.Name = "CarryWeld"
	w.Part0 = root
	w.Part1 = baby.Root
	w.Parent = baby.Root
	pcall(function()
		baby.Root:SetNetworkOwner(player)
	end)
	S.ToolService:SetHeld(player, { Kind = "Baby", Id = baby.Id, Extra = baby.Uid, Slow = baby.Def.CarrySlowdown })
	self:RefreshPrompts(baby)
	session:Sound("Pickup", baby.Root.Position)
	return true
end

local function unweld(baby)
	local w = baby.Root:FindFirstChild("CarryWeld")
	if w then
		w:Destroy()
	end
	baby.Root.Anchored = true
	baby.CarriedBy = nil
end

-- Put a carried baby on the floor at `pos`.
function BabyService:DropBaby(session, uid: string, player: Player?, pos: Vector3)
	local baby = session.Babies[uid]
	if not baby then
		return
	end
	unweld(baby)
	local y = BabyAI.floorAt(session, pos) or pos.Y
	baby.Pos = Vector3.new(pos.X, y, pos.Z)
	BabyBase.place(baby)
	local room = session:RoomAt(baby.Pos + Vector3.new(0, 2, 0))
	if room and room ~= "Outside" then
		if baby.Escaped and player then
			session:AddAction(player, 2)
			session:Notify({ "Toast_BabyReturned", baby.Id }, "good")
		end
		baby.Escaped = false
	end
	if baby.State == "Carried" then
		BabyBase.setState(baby, if baby.Tantrum then "Tantrum" else "Idle")
	end
	baby.NextThink = os.clock() + 1.5
	self:RefreshPrompts(baby)
end

-- Release a carried baby wherever the carrier is (player left / shift ended).
function BabyService:ReleaseCarried(session, uid: string, player: Player)
	local baby = session.Babies[uid]
	if not baby or baby.CarriedBy ~= player then
		return
	end
	local pos = baby.Root.Position
	self:DropBaby(session, uid, nil, pos)
end

function BabyService:PlaceAtStation(session, baby, st, player: Player?)
	unweld(baby)
	st.Occupant = baby
	baby.Station = st
	BabyBase.placeAt(baby, st.Slot.CFrame)
	if st.Tag == "Bed" then
		BabyBase.setState(baby, "Asleep")
		baby.Statuses.Asleep = math.huge
		if player then
			S.QuestService:Track(player, "PutToBed", 1)
			S.TutorialService:OnEvent(session, "PutToBed", player)
		end
	else
		BabyBase.setState(baby, "Placed")
	end
	baby.Escaped = false
	self:RefreshPrompts(baby)
	if player then
		session:AddAction(player)
	end
end

-- Net / catching ---------------------------------------------------------------

function BabyService:NetCatch(session, player: Player, origin: Vector3, dir: Vector3, range: number)
	local best, bestD = nil, math.huge
	for _, b in session.BabyList do
		if not b.CarriedBy and b.State ~= "Leaving" and not b.Hidden then
			local p = BabyBase.position(b)
			if MathUtil.inCone(origin, dir, p, range, 35) then
				local d = (p - origin).Magnitude
				-- escaping / frozen / tantrum babies get priority
				if b.State == "Escaping" or b.Escaped or BabyBase.hasStatus(b, "Frozen") or b.Tantrum then
					d -= 100
				end
				if d < bestD then
					best, bestD = b, d
				end
			end
		end
	end
	if not best then
		return
	end
	local held = S.ToolService:GetHeld(player)
	S.ToolService:SetHeld(player, nil)
	if held and held.Kind == "Tool" then
		S.ToolService:ReturnToRack(session, held.Id, held.Rack)
	end
	if best.State == "Escaping" then
		BabyBase.setState(best, "Idle")
	end
	session:Effect("NetCatch", { From = origin, To = BabyBase.position(best) })
	session:Sound("Tool_Net", origin)
	self:Carry(session, best, player)
	session:AddAction(player)
end

-- Interactions ------------------------------------------------------------------

local function happy(session, baby, player: Player?)
	BabyBase.anim(baby, "Happy", 1.6)
	session:Effect("Hearts", { Position = BabyBase.position(baby) + Vector3.new(0, 2, 0) })
	session:Sound("Baby_" .. baby.Id .. "_Happy", BabyBase.position(baby))
	if player then
		session:AddAction(player)
	end
end
BabyService.happy = happy

function BabyService:Feed(session, baby, player: Player, held)
	local result = RecipeMatch.feedResult(baby.Def, held.Kind, held.Id)
	if result == "NoEat" then
		ServerUtil.notify(player, { "Baby_DoesNotEat", baby.Id }, "error")
		return
	end
	S.ToolService:SetHeld(player, nil)
	local mult = session:SatisfyMultiplier()
	local R = Needs.Restore
	if result == "Favorite" then
		BabyBase.change(baby, "Hunger", R.FeedFavorite * mult)
	elseif result == "Suitable" then
		BabyBase.change(baby, "Hunger", R.FeedSuitable * mult)
	elseif result == "Cake" then
		BabyBase.change(baby, "Hunger", R.FeedCake * mult)
	elseif result == "Raw" then
		BabyBase.change(baby, "Hunger", R.FeedRaw * mult)
	elseif result == "Ice" then
		BabyBase.change(baby, "Cold", R.IceFeedCold * mult)
		BabyBase.change(baby, "Hunger", 10)
	else
		BabyBase.change(baby, "Hunger", R.FeedWrong)
		baby.Statuses.Angry = os.clock() + 4
		session:Effect("Angry", { Position = BabyBase.position(baby) + Vector3.new(0, 2.5, 0) })
		session:Sound("Baby_" .. baby.Id .. "_Cry", BabyBase.position(baby))
		return
	end
	BabyBase.anim(baby, "Eat", 2)
	session:Effect("Eat", { Position = BabyBase.position(baby) + Vector3.new(0, 1, 0), Dish = held.Id })
	happy(session, baby, player)
	S.QuestService:Track(player, "Fed", 1)
	S.DataService:Update(player, function(d)
		d.Stats.BabiesFed += 1
	end)
	if baby.Behavior.onFed then
		baby.Behavior.onFed(baby, result, ctxFor(session))
	end
	S.EventService:OnFed(session, baby, held.Id, player)
	S.TutorialService:OnEvent(session, "Fed", player)
end

function BabyService:Init(services)
	S = services

	Interact.on("PickUpBaby", function(player, prompt, session)
		if not session or not S.ToolService:IsEmpty(player) then
			return
		end
		local baby = self:FromPrompt(session, prompt)
		if not baby or baby.CarriedBy or baby.Hidden or baby.Arriving then
			return
		end
		self:Carry(session, baby, player)
		S.TutorialService:OnEvent(session, "PickUp", player)
	end)

	Interact.on("PlaceBaby", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		if not held or held.Kind ~= "Baby" then
			return
		end
		local baby = session.Babies[held.Extra]
		if not baby then
			return
		end
		for _, st in session.Stations do
			if st.Slot == prompt.Parent then
				if st.Occupant and st.Occupant ~= baby then
					ServerUtil.notify(player, "Station_Occupied", "error")
					return
				end
				if st.Model:GetAttribute("Active") == false and st.Tag ~= "DarkZone" then
					return
				end
				if baby.Needs[st.Need] == nil then
					ServerUtil.notify(player, { "Station_NotNeeded", baby.Id }, "error")
					return
				end
				S.ToolService:SetHeld(player, nil)
				self:PlaceAtStation(session, baby, st, player)
				return
			end
		end
	end)

	Interact.on("Feed", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		local baby = self:FromPrompt(session, prompt)
		if baby and held and (held.Kind == "Dish" or held.Kind == "Ingredient") then
			self:Feed(session, baby, player, held)
		end
	end)

	Interact.on("Play", function(player, prompt, session)
		if not session or not S.ToolService:IsEmpty(player) then
			return
		end
		local baby = self:FromPrompt(session, prompt)
		if baby then
			BabyBase.change(baby, "Fun", Needs.Restore.PlayFun * session:SatisfyMultiplier())
			happy(session, baby, player)
		end
	end)

	Interact.on("GiveToy", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		local baby = self:FromPrompt(session, prompt)
		if baby and held and held.Kind == "Tool" and held.Id == "ToyBag" then
			if (baby.Data.ToyUntil or 0) > os.clock() then
				return
			end
			BabyBase.change(baby, "Fun", Needs.Restore.ToyFun * session:SatisfyMultiplier())
			baby.Data.ToyUntil = os.clock() + 10
			BabyBase.anim(baby, "Happy", 2)
			session:Effect("Toy", { Uid = baby.Uid, Duration = 10 })
			happy(session, baby, player)
		end
	end)

	Interact.on("Wash", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		local baby = self:FromPrompt(session, prompt)
		if baby and held and held.Id == "Sponge" and baby.Station and baby.Station.Tag == "Bath" then
			BabyBase.change(baby, "Clean", Needs.Restore.Wash * session:SatisfyMultiplier())
			S.StatusEffectService:Apply(session, baby, "Wet", 12)
			S.StatusEffectService:Remove(session, baby, "Inked")
			S.StatusEffectService:Remove(session, baby, "Slimed")
			session:Effect("Bubbles", { Position = BabyBase.position(baby) + Vector3.new(0, 1, 0) })
			happy(session, baby, player)
		end
	end)

	Interact.on("Water", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		local baby = self:FromPrompt(session, prompt)
		if baby and held and held.Id == "WateringCan" then
			BabyBase.change(baby, "Water", Needs.Restore.Water * session:SatisfyMultiplier())
			S.StatusEffectService:Apply(session, baby, "Wet", 10)
			S.StatusEffectService:Remove(session, baby, "Burning")
			session:Effect("Splash", { Position = BabyBase.position(baby) + Vector3.new(0, 1.5, 0) })
			session:Sound("Tool_Water", BabyBase.position(baby))
			happy(session, baby, player)
		end
	end)

	Interact.on("Bandage", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		local baby = self:FromPrompt(session, prompt)
		if baby and held and held.Id == "BandageRoll" then
			BabyBase.change(baby, "Bandages", Needs.Restore.Bandage * session:SatisfyMultiplier())
			happy(session, baby, player)
		end
	end)

	Interact.on("CatchGhost", function(player, prompt, session)
		if not session then
			return
		end
		local baby = self:FromPrompt(session, prompt)
		if not baby or not baby.Hidden then
			return
		end
		-- Someone must be shining a flashlight on the ghost (or the power must be on and it's not a tantrum hide).
		if not self:IsRevealed(session, baby) then
			ServerUtil.notify(player, "Ghost_NeedLight", "error")
			return
		end
		self:SetHidden(session, baby, false)
		session:AddAction(player, 2)
		S.QuestService:Track(player, "GhostFound", 1)
		S.DataService:Update(player, function(d)
			d.Stats.GhostsFound += 1
		end)
		if baby.HideAndSeek then
			baby.HideAndSeek = false
			BabyBase.change(baby, "Fun", 50)
			S.ProgressionService:AddCoins(player, 10)
			session:Notify({ "Toast_GhostFound", player.DisplayName }, "good")
		end
		happy(session, baby, player)
	end)
end

-- Ghost visibility ------------------------------------------------------------------

function BabyService:SetHidden(session, baby, hidden: boolean)
	baby.Hidden = hidden
	baby.Model:SetAttribute("Hidden", hidden)
	self:RefreshPrompts(baby)
end

-- Is any player's flashlight cone on this baby?
function BabyService:IsRevealed(session, baby): boolean
	local pos = BabyBase.position(baby)
	for _, p in session.Players do
		if p:GetAttribute("FlashlightOn") then
			local root = ServerUtil.root(p)
			if root then
				local range = (p:GetAttribute("FlashlightRange") or 30) + 4
				local angle = (p:GetAttribute("FlashlightAngle") or 22) + 10
				if MathUtil.inCone(root.Position, root.CFrame.LookVector, pos, range, angle) then
					return true
				end
			end
		end
	end
	return false
end

-- End of shift: everyone walks to the parents' window.
function BabyService:PrepareReturn(session)
	for _, b in session.BabyList do
		if b.CarriedBy then
			local p = b.CarriedBy
			S.ToolService:SetHeld(p, nil)
			self:DropBaby(session, b.Uid, nil, b.Root.Position)
		end
		freeStation(b)
		b.Statuses = {}
		b.Model:SetAttribute("Statuses", "")
		self:SetHidden(session, b, false)
		BabyBase.setState(b, "Leaving")
	end
	-- babies that ran outside are brought back to the hall so they can walk out to their parents
	local spawns = session:Tagged("BabySpawn")
	for i, b in session.BabyList do
		local room = session:RoomAt(b.Pos + Vector3.new(0, 2, 0))
		if room == "Outside" or room == "Yard" or room == "Basement" or room == "Stairs" or room == nil then
			local m = spawns[((i - 1) % math.max(1, #spawns)) + 1] :: BasePart?
			if m then
				BabyBase.placeAt(b, m.CFrame)
			end
		end
	end
end

-- Movement + animation hints ----------------------------------------------------------

local function animFor(baby): string
	if os.clock() < baby.AnimUntil and baby.AnimOverride then
		return baby.AnimOverride
	end
	if BabyBase.hasStatus(baby, "Frozen") then
		return "Frozen"
	end
	if baby.CarriedBy then
		return "Carried"
	end
	if baby.State == "Asleep" then
		return "Sleep"
	end
	-- danger! (the nanny should help right now)
	if BabyBase.hasStatus(baby, "Burning") or baby.State == "Escaping" then
		return "Panic"
	end
	if BabyBase.hasStatus(baby, "Scared") then
		return "Shiver"
	end
	if baby.Tantrum then
		return "Tantrum"
	end
	local _, low = BabyBase.lowestNeed(baby)
	if low < Needs.Thresholds.Crying then
		return "Cry"
	end
	if baby.Path then
		return "Walk"
	end
	if BabyBase.allHappy(baby) then
		return "Happy"
	end
	return "Idle"
end

function BabyService:Tick(session, dt)
	local now = os.clock()
	for _, baby in session.BabyList do
		if now >= baby.NextThink and not baby.Arriving then
			baby.NextThink = now + 0.3 + math.random() * 0.3
			BabyAI.think(baby, session)
		end
		local anim = animFor(baby)
		if baby.Model:GetAttribute("Anim") ~= anim then
			baby.Model:SetAttribute("Anim", anim)
		end
		-- Escapes: crossing out of the fenced area.
		if not baby.CarriedBy and not baby.Escaped and baby.State ~= "Leaving" then
			local room = session:RoomAt(baby.Pos + Vector3.new(0, 2, 0))
			if room == "Outside" then
				baby.Escaped = true
				baby.Model:SetAttribute("Escaped", true)
				BabyBase.setState(baby, "Idle")
				baby.Path = nil
				session:Notify({ "Toast_BabyEscaped", baby.Id }, "bad")
				S.EventService:OnEscaped(session, baby)
			end
		elseif baby.Model:GetAttribute("Escaped") ~= baby.Escaped then
			baby.Model:SetAttribute("Escaped", baby.Escaped)
		end
	end
end

function BabyService:Start()
	RunService.Heartbeat:Connect(function(dt)
		for _, session in S.ShiftService:Sessions() do
			if session.Phase == "Playing" then
				for _, baby in session.BabyList do
					if not baby.Arriving then
						BabyAI.move(baby, dt * session.TimeScale)
					end
				end
			end
		end
	end)
end

return BabyService
