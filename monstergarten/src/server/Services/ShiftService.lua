-- ShiftService: starts/ends shifts, runs the central update loop for all sessions.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local GameSettings = require(Shared.Config.GameSettings)
local Difficulty = require(Shared.Config.Difficulty)
local ShiftSession = require(script.Parent.Parent.Classes.ShiftSession)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local ShiftService = {}
local S
local sessions: { [number]: any } = {}
local playerSession: { [Player]: any } = {}

local SUBSYSTEMS = { "FurnitureService", "HazardService", "ToolService", "KitchenService", "BabyService", "NeedService", "StatusEffectService", "ChaosService", "EventService", "TutorialService" }

function ShiftService:Init(services)
	S = services
end

function ShiftService:SessionOf(player: Player): any?
	return playerSession[player]
end

function ShiftService:Sessions(): { [number]: any }
	return sessions
end

function ShiftService:FreeSlotAvailable(): boolean
	return S.MapService:FreeSlot() ~= nil
end

local function lobbySpawnCF(): CFrame
	local spawn = workspace:FindFirstChild("LobbySpawn", true)
	if spawn and spawn:IsA("BasePart") then
		return spawn.CFrame + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3))
	end
	return CFrame.new(0, 5, 18)
end

local function spawnCF(session, index: number): CFrame
	local spawns = session:Tagged("PlayerSpawn")
	if #spawns == 0 then
		return CFrame.new(session:Origin() + Vector3.new(-13, 3, 37))
	end
	local s = spawns[((index - 1) % #spawns) + 1] :: BasePart
	return s.CFrame
end

-- Pick baby species for a shift (GDD 12).
function ShiftService:PickBabies(host: Player, difficulty, playerCount: number, preferred: { string }?): { string }
	local unlocked = S.ProgressionService:UnlockedBabies(host)
	if #unlocked == 0 then
		unlocked = { "Dragling", "Slimy", "Ghostie" }
	end
	local count = math.clamp(playerCount + difficulty.BabyBonus, difficulty.MinBabies, difficulty.MaxBabies)
	local pool = unlocked
	if preferred and #preferred > 0 then
		local filtered = {}
		for _, id in preferred do
			if table.find(unlocked, id) then
				table.insert(filtered, id)
			end
		end
		if #filtered > 0 then
			pool = filtered
		end
	end
	local result, counts = {}, {}
	-- at least one of the newest unlocked species
	local newest = pool[#pool]
	table.insert(result, newest)
	counts[newest] = 1
	local maxSame = Difficulty.MaxSameSpecies
	if #pool * maxSame < count then
		maxSame = math.ceil(count / #pool)
	end
	local guard = 0
	while #result < count and guard < 200 do
		guard += 1
		local id = pool[math.random(1, #pool)]
		if (counts[id] or 0) < maxSame then
			counts[id] = (counts[id] or 0) + 1
			table.insert(result, id)
		end
	end
	return result
end

local function teamUpgrades(session)
	-- Tool upgrades apply to the whole team if anyone owns them (max level).
	local levels = {}
	for _, p in session.Players do
		local d = S.DataService:Get(p)
		if d then
			for tool, lvl in d.ToolUpgrades do
				levels[tool] = math.max(levels[tool] or 0, lvl)
			end
		end
	end
	session.TeamUpgrades = levels
	local hd = S.DataService:Get(session.Host)
	session.Upgrades = if hd then table.clone(hd.DaycareUpgrades) else {}
end

function ShiftService:SendState(session)
	local babies = {}
	for _, b in session.BabyList do
		table.insert(babies, { Uid = b.Uid, Id = b.Id })
	end
	local state = {
		Slot = session.Slot,
		Phase = session.Phase,
		Time = session.Time,
		Duration = session.Duration,
		Clock = session:ClockHour(),
		Difficulty = session.Difficulty.Id,
		Tutorial = session.Tutorial,
		Babies = babies,
		PowerOn = session.PowerOn,
		Event = session.ActiveEvent and session.ActiveEvent.Id or nil,
		EventEnds = session.ActiveEvent and session.ActiveEvent.EndsAt or nil,
		Building = S.FurnitureService:BuildingHealth(session),
		DaycareName = session.Model.Name,
		ClockFrozen = session.ClockFrozen == true,
	}
	local ev = Remotes.event("ShiftState")
	for _, p in session.Players do
		ev:FireClient(p, state)
	end
end

function ShiftService:StartShift(players: { Player }, opts: any): any?
	local valid = {}
	for _, p in players do
		if p.Parent and not playerSession[p] then
			table.insert(valid, p)
		end
	end
	if #valid == 0 then
		return nil
	end
	local slot = S.MapService:FreeSlot()
	if not slot then
		return nil
	end
	local host = valid[1]
	local difficulty = Difficulty.Defs[opts.Difficulty or "Easy"] or Difficulty.Defs.Easy
	local hostData = S.DataService:Get(host)
	local isUnlocked = function(id: string): boolean
		local kind, name = id:match("^(%w+):(%w+)$")
		if kind == "Upgrade" then
			return hostData ~= nil and hostData.DaycareUpgrades[name] == true
		end
		return S.ProgressionService:IsUnlocked(host, id)
	end
	local model = S.MapService:CloneDaycare(slot, isUnlocked, valid)
	if not model then
		return nil
	end
	local session = ShiftSession.new(slot, model, valid, {
		Difficulty = difficulty,
		Solo = opts.Solo,
		Tutorial = opts.Tutorial,
		PreferredBabies = opts.PreferredBabies,
		DoorId = opts.DoorId,
	})
	session.IsUnlocked = isUnlocked
	sessions[slot] = session
	for _, p in valid do
		playerSession[p] = session
		p:SetAttribute("InShift", slot)
	end
	teamUpgrades(session)

	for _, name in SUBSYSTEMS do
		local svc = S[name]
		if svc and svc.SetupSession then
			local ok, err = pcall(svc.SetupSession, svc, session)
			if not ok then
				warn("[ShiftService] SetupSession failed:", name, err)
			end
		end
	end

	task.spawn(function()
		self:RunIntro(session)
	end)
	return session
end

function ShiftService:TeleportIn(session)
	local fade = Remotes.event("Fade")
	for _, p in session.Players do
		fade:FireClient(p, true, 0.5)
	end
	task.wait(0.6)
	for i, p in session.Players do
		local cf = spawnCF(session, i)
		pcall(function()
			p:RequestStreamAroundAsync(cf.Position, 5)
		end)
		ServerUtil.teleport(p, cf)
	end
	task.wait(0.2)
	for _, p in session.Players do
		fade:FireClient(p, false, 0.6)
	end
end

function ShiftService:RunIntro(session)
	self:TeleportIn(session)
	session.Phase = "Intro"
	-- Spawn babies (they fly in through the parents' window during the cutscene).
	local list
	if session.Tutorial then
		list = { "Dragling" }
	else
		list = self:PickBabies(session.Host, session.Difficulty, #session.Players, session.PreferredBabies)
	end
	S.BabyService:SpawnBabies(session, list, true)
	self:SendState(session)
	local cutscene = Remotes.event("Cutscene")
	local babyInfo = {}
	for _, b in session.BabyList do
		table.insert(babyInfo, { Uid = b.Uid, Id = b.Id })
	end
	for _, p in session.Players do
		cutscene:FireClient(p, "Arrival", { Slot = session.Slot, Babies = babyInfo })
	end
	self:WaitCutscene(session, GameSettings.CutsceneLength)
	if session.Phase == "Ended" then
		return
	end
	session.Phase = "Playing"
	session.Time = 0
	if session.Tutorial then
		session.ClockFrozen = true
		S.TutorialService:Begin(session)
	end
	self:SendState(session)
end

function ShiftService:WaitCutscene(session, duration: number)
	session.SkipVotes = {}
	local t0 = os.clock()
	while os.clock() - t0 < duration and session.Phase ~= "Ended" do
		local all = #session.Players > 0
		for _, p in session.Players do
			if not session.SkipVotes[p] then
				all = false
				break
			end
		end
		if all then
			break
		end
		task.wait(0.1)
	end
	for _, p in session.Players do
		Remotes.event("Cutscene"):FireClient(p, "End", {})
	end
end

-- Normal end of a shift: return cutscene, scoring, rewards, results screen.
function ShiftService:Finish(session)
	if session.Phase ~= "Playing" then
		return
	end
	session.Phase = "Outro"
	S.EventService:EndActive(session, true)
	local results = S.ScoringService:Compute(session)
	session.Results = results
	S.BabyService:PrepareReturn(session)
	local babyInfo = {}
	for _, b in results.Babies do
		table.insert(babyInfo, { Uid = b.Uid, Id = b.BabyId, Score = b.Score })
	end
	for _, p in session.Players do
		Remotes.event("Cutscene"):FireClient(p, "Return", { Slot = session.Slot, Babies = babyInfo, Stars = results.Stars })
	end
	self:WaitCutscene(session, GameSettings.CutsceneLength)
	if session.Phase == "Ended" then
		return
	end
	S.RewardService:Grant(session, results)
	session.Phase = "Results"
	session.Choices = {}
	for _, p in session.Players do
		Remotes.event("Results"):FireClient(p, S.RewardService:ResultsFor(session, p))
	end
	local t0 = os.clock()
	while os.clock() - t0 < GameSettings.ResultsTimeout and session.Phase == "Results" do
		local allChosen = true
		for _, p in session.Players do
			if not session.Choices[p] then
				allChosen = false
			end
		end
		if allChosen then
			break
		end
		task.wait(0.2)
	end
	local again = {}
	for _, p in session.Players do
		if session.Choices[p] == "Again" then
			table.insert(again, p)
		end
	end
	local opts = {
		Difficulty = session.Difficulty.Id,
		Solo = session.Solo,
		PreferredBabies = session.PreferredBabies,
		DoorId = session.DoorId,
	}
	local wasTutorial = session.Tutorial
	self:Teardown(session, true)
	if #again > 0 and not wasTutorial then
		-- Same team, new shift right away (falls back to lobby if no slot).
		if not self:StartShift(again, opts) then
			for _, p in again do
				ServerUtil.notify(p, "Queue_NoSlot", "error")
			end
		end
	end
end

-- Destroy the session; optionally return players to the lobby.
function ShiftService:Teardown(session, returnPlayers: boolean)
	if session.Phase == "Ended" then
		return
	end
	session.Phase = "Ended"
	for _, name in SUBSYSTEMS do
		local svc = S[name]
		if svc and svc.CleanupSession then
			pcall(svc.CleanupSession, svc, session)
		end
	end
	local players = table.clone(session.Players)
	if returnPlayers then
		local fade = Remotes.event("Fade")
		for _, p in players do
			fade:FireClient(p, true, 0.4)
		end
		task.wait(0.45)
	end
	for _, p in players do
		if playerSession[p] == session then
			playerSession[p] = nil
		end
		if p.Parent then
			p:SetAttribute("InShift", nil)
			S.ToolService:ClearHeld(p)
			Remotes.event("ShiftState"):FireClient(p, nil)
			if returnPlayers then
				ServerUtil.teleport(p, lobbySpawnCF())
				Remotes.event("Fade"):FireClient(p, false, 0.6)
			end
		end
	end
	sessions[session.Slot] = nil
	S.MapService:Release(session.Slot)
	session:Destroy()
	session.Ended:Fire()
	S.QueueService:RefreshScreens()
end

function ShiftService:Abort(session)
	self:Teardown(session, true)
end

function ShiftService:LeaveShift(player: Player)
	local session = playerSession[player]
	if not session then
		return
	end
	S.ToolService:ClearHeld(player)
	session:RemovePlayer(player)
	playerSession[player] = nil
	player:SetAttribute("InShift", nil)
	if #session.Players == 0 then
		self:Teardown(session, false)
	end
end

local function update(dt: number)
	for _, session in sessions do
		if session.Phase == "Playing" then
			local step = dt * session.TimeScale
			if not session.ClockFrozen and not session.Paused then
				session.Time += step
			end
			for _, name in SUBSYSTEMS do
				local svc = S[name]
				if svc and svc.Tick then
					local ok, err = pcall(svc.Tick, svc, session, step)
					if not ok then
						warn("[ShiftService] Tick error in", name, err)
					end
				end
			end
			if not session.WarningSent and session.Time >= GameSettings.ParentsWarningAt and not session.ClockFrozen then
				session.WarningSent = true
				for _, p in session.Players do
					Remotes.event("Banner"):FireClient(p, "ParentsComing", "start", {})
				end
				session:Sound("Shift_ParentsComing")
			end
			if session.Time >= session.Duration and not session.ClockFrozen then
				task.spawn(function()
					ShiftService:Finish(session)
				end)
			end
		end
	end
end

-- Service startup: central update loop + remote handlers.
function ShiftService:Start()
	local acc = 0
	local stateAcc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		stateAcc += dt
		if acc >= 0.1 then
			update(acc)
			acc = 0
		end
		if stateAcc >= 1 then
			stateAcc = 0
			for _, session in sessions do
				if session.Phase == "Playing" or session.Phase == "Intro" then
					ShiftService:SendState(session)
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		ShiftService:LeaveShift(p)
	end)
	-- Drop whatever a nanny holds the moment they die (a carried baby must not fall with the body).
	local function watchDeath(p: Player, char: Model)
		local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
		if hum then
			hum.Died:Connect(function()
				if playerSession[p] then
					S.ToolService:ClearHeld(p)
				end
			end)
		end
	end
	local function hookDeaths(p: Player)
		p.CharacterAdded:Connect(function(char)
			watchDeath(p, char)
		end)
		if p.Character then
			task.spawn(watchDeath, p, p.Character)
		end
	end
	Players.PlayerAdded:Connect(hookDeaths)
	for _, p in Players:GetPlayers() do
		hookDeaths(p)
	end
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function(char)
			local session = playerSession[p]
			if session then
				task.wait(0.2)
				local i = table.find(session.Players, p) or 1
				char:PivotTo(spawnCF(session, i) + Vector3.new(0, 3, 0))
				S.ToolService:ClearHeld(p)
			end
		end)
	end)
	for _, p in Players:GetPlayers() do
		p.CharacterAdded:Connect(function(char)
			local session = playerSession[p]
			if session then
				task.wait(0.2)
				char:PivotTo(spawnCF(session, 1) + Vector3.new(0, 3, 0))
			end
		end)
	end

	Remotes.event("CutsceneSkip").OnServerEvent:Connect(function(p)
		local session = playerSession[p]
		if session then
			session.SkipVotes[p] = true
		end
	end)
	Remotes.event("ResultsChoice").OnServerEvent:Connect(function(p, choice)
		local session = playerSession[p]
		if session and session.Phase == "Results" and (choice == "Again" or choice == "Lobby") then
			session.Choices[p] = choice
		end
	end)
end

return ShiftService
