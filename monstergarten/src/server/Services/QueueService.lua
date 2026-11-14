-- QueueService: lobby doors (4 shift doors, solo, tutorial). Stand on a pad to join.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local GameSettings = require(Shared.Config.GameSettings)
local Difficulty = require(Shared.Config.Difficulty)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local QueueService = {}
local S
local queues: { [string]: any } = {} -- DoorId -> queue
local playerQueue: { [Player]: string } = {}
local pads: { [string]: BasePart } = {}
local recentLeave: { [Player]: number } = {}

local function newQueue(doorId: string, mode: string)
	return {
		DoorId = doorId,
		Mode = mode,
		Players = {} :: { Player },
		Difficulty = "Easy",
		StartAt = nil :: number?,
		PreferredBabies = nil :: { string }?,
	}
end

local function queueState(q)
	local ids = {}
	for _, p in q.Players do
		table.insert(ids, p.UserId)
	end
	return {
		DoorId = q.DoorId,
		Mode = q.Mode,
		Host = q.Players[1] and q.Players[1].UserId or 0,
		Players = ids,
		Difficulty = q.Difficulty,
		Countdown = if q.StartAt then math.max(0, math.ceil(q.StartAt - os.clock())) else nil,
		Waiting = not S.ShiftService:FreeSlotAvailable(),
		PreferredBabies = q.PreferredBabies,
	}
end

local function sendState(q)
	local ev = Remotes.event("QueueUpdate")
	local state = queueState(q)
	for _, p in q.Players do
		ev:FireClient(p, state)
	end
end

local function updateScreen(q)
	local pad = pads[q.DoorId]
	local door = pad and pad.Parent
	local screen = door and door:FindFirstChild("Screen")
	local gui = screen and screen:FindFirstChild("ScreenGui")
	if not gui then
		return
	end
	local info = gui:FindFirstChild("Info") :: TextLabel?
	local title = gui:FindFirstChild("Title") :: TextLabel?
	if title then
		title.Text = if q.Mode == "Shift" then ("🍼 " .. q.Difficulty) elseif q.Mode == "Solo" then "🙋 SOLO" else "📖 TUTORIAL"
	end
	if info then
		local free = S.ShiftService:FreeSlotAvailable()
		if not free then
			info.Text = "⏳ ..."
		elseif #q.Players == 0 then
			info.Text = if q.Mode == "Shift" then "0/" .. GameSettings.MaxPlayersPerShift else "▶"
		elseif q.StartAt then
			info.Text = ("%d/%d  ⏱ %ds"):format(#q.Players, GameSettings.MaxPlayersPerShift, math.max(0, math.ceil(q.StartAt - os.clock())))
		else
			info.Text = ("%d/%d"):format(#q.Players, GameSettings.MaxPlayersPerShift)
		end
	end
end

function QueueService:RefreshScreens()
	for _, q in queues do
		updateScreen(q)
		sendState(q)
	end
end

function QueueService:Leave(player: Player)
	local id = playerQueue[player]
	if not id then
		return
	end
	playerQueue[player] = nil
	recentLeave[player] = os.clock()
	local q = queues[id]
	local i = table.find(q.Players, player)
	if i then
		table.remove(q.Players, i)
	end
	if #q.Players == 0 then
		q.StartAt = nil
		q.PreferredBabies = nil
		q.Difficulty = "Easy"
	end
	Remotes.event("QueueUpdate"):FireClient(player, nil)
	sendState(q)
	updateScreen(q)
end

function QueueService:Join(player: Player, doorId: string)
	local q = queues[doorId]
	if not q or playerQueue[player] == doorId then
		return
	end
	if S.ShiftService:SessionOf(player) then
		return
	end
	if not S.DataService:Get(player) then
		return
	end
	if playerQueue[player] then
		self:Leave(player)
	end
	if q.Mode ~= "Shift" and #q.Players >= 1 then
		ServerUtil.notify(player, "Queue_Busy", "error")
		return
	end
	if #q.Players >= GameSettings.MaxPlayersPerShift then
		ServerUtil.notify(player, "Queue_Full", "error")
		return
	end
	table.insert(q.Players, player)
	playerQueue[player] = doorId
	if #q.Players == 1 then
		q.Difficulty = "Easy"
		q.StartAt = os.clock() + (if q.Mode == "Shift" then GameSettings.QueueCountdown else 3)
	end
	sendState(q)
	updateScreen(q)
end

local function tryStart(q)
	if #q.Players == 0 then
		return
	end
	if not S.ShiftService:FreeSlotAvailable() then
		q.StartAt = os.clock() + 2 -- keep waiting for a free daycare
		return
	end
	local players = table.clone(q.Players)
	local opts = {
		Difficulty = q.Difficulty,
		Solo = q.Mode == "Solo",
		Tutorial = q.Mode == "Tutorial",
		PreferredBabies = q.PreferredBabies,
		DoorId = q.DoorId,
	}
	for _, p in players do
		playerQueue[p] = nil
		Remotes.event("QueueUpdate"):FireClient(p, nil)
	end
	table.clear(q.Players)
	q.StartAt = nil
	q.PreferredBabies = nil
	q.Difficulty = "Easy"
	local session = S.ShiftService:StartShift(players, opts)
	if not session then
		for _, p in players do
			ServerUtil.notify(p, "Queue_NoSlot", "error")
		end
	end
	updateScreen(q)
end

local function onAction(player: Player, action: string, arg: any)
	if not ServerUtil.rateLimit(player, "Queue", 5) then
		return
	end
	local id = playerQueue[player]
	local q = id and queues[id]
	if action == "Leave" then
		QueueService:Leave(player)
		return
	end
	if not q then
		return
	end
	local isHost = q.Players[1] == player
	if action == "Difficulty" and isHost and type(arg) == "string" then
		local def = Difficulty.Defs[arg]
		if def and S.ProgressionService:IsUnlocked(player, "Difficulty:" .. arg) then
			q.Difficulty = arg
			sendState(q)
			updateScreen(q)
		else
			ServerUtil.notify(player, "Queue_DifficultyLocked", "error")
		end
	elseif action == "StartNow" and isHost then
		q.StartAt = os.clock()
	elseif action == "Babies" and isHost and type(arg) == "table" then
		if not S.MonetizationService:OwnsPass(player, "HeadNanny") then
			ServerUtil.notify(player, "Pass_Required", "error")
			return
		end
		local unlocked = S.ProgressionService:UnlockedBabies(player)
		local list = {}
		for _, v in arg do
			if type(v) == "string" and table.find(unlocked, v) and not table.find(list, v) then
				table.insert(list, v)
			end
		end
		q.PreferredBabies = if #list > 0 then list else nil
		sendState(q)
	end
end

function QueueService:Init(services)
	S = services
end

function QueueService:Start()
	for _, pad in CollectionService:GetTagged("QueuePad") do
		if pad:IsA("BasePart") then
			local id = pad:GetAttribute("DoorId")
			local mode = pad:GetAttribute("Mode")
			pads[id] = pad
			queues[id] = newQueue(id, mode)
			pad.Touched:Connect(function(hit)
				local char = hit.Parent
				local player = char and Players:GetPlayerFromCharacter(char)
				if player and os.clock() - (recentLeave[player] or 0) > 4 then
					QueueService:Join(player, id)
				end
			end)
			updateScreen(queues[id])
		end
	end
	Remotes.event("QueueAction").OnServerEvent:Connect(onAction)
	Players.PlayerRemoving:Connect(function(p)
		QueueService:Leave(p)
		recentLeave[p] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, q in queues do
				-- drop players who walked far away from the door
				for i = #q.Players, 1, -1 do
					local p = q.Players[i]
					local pad = pads[q.DoorId]
					local root = ServerUtil.root(p)
					if not root or (root.Position - pad.Position).Magnitude > 40 then
						QueueService:Leave(p)
					end
				end
				if q.StartAt and os.clock() >= q.StartAt then
					tryStart(q)
				end
				updateScreen(q)
				if #q.Players > 0 then
					sendState(q)
				end
			end
		end
	end)
end

return QueueService
