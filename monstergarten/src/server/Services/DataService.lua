-- DataService: player profiles with session locking, autosave, BindToClose, and an in-memory
-- mock store when DataStores are unavailable (e.g. Studio without API access).
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Signal = require(Shared.Util.Signal)
local TableUtil = require(Shared.Util.TableUtil)
local DataSchema = require(Shared.Logic.DataSchema)
local GameSettings = require(Shared.Config.GameSettings)

local LOCK_TIMEOUT = 150 -- seconds; a lock not refreshed for this long is considered dead
local LOAD_ATTEMPTS = 6

local DataService = {
	Loaded = Signal.new(), -- (player, data)
	Changed = Signal.new(), -- (player, data)
	UseMock = false,
}

local profiles: { [Player]: any } = {}
local dirty: { [Player]: boolean } = {}
local loading: { [Player]: boolean } = {}
local mockStore: { [string]: any } = {}
local store: GlobalDataStore? = nil

local function keyFor(userId: number): string
	return "Player_" .. tostring(userId)
end

local function detectStore()
	local ok, err = pcall(function()
		local s = DataStoreService:GetDataStore(GameSettings.DataStoreName)
		s:GetAsync("__probe")
		store = s
	end)
	if not ok then
		DataService.UseMock = true
		warn("[DataService] DataStores unavailable (" .. tostring(err) .. "). Using in-memory MOCK store: progress will NOT persist. "
			.. "Enable Game Settings > Security > 'Enable Studio Access to API Services' to test saving.")
	end
end

local function loadRecord(userId: number): any?
	local key = keyFor(userId)
	if DataService.UseMock then
		local rec = mockStore[key]
		return rec and TableUtil.deepCopy(rec) or {}
	end
	for attempt = 1, LOAD_ATTEMPTS do
		local result = nil
		local locked = false
		local ok, err = pcall(function()
			(store :: GlobalDataStore):UpdateAsync(key, function(old)
				old = old or {}
				local lock = old.Lock
				if lock and lock.JobId ~= game.JobId and os.time() - (lock.Time or 0) < LOCK_TIMEOUT and attempt < LOAD_ATTEMPTS then
					locked = true
					return nil -- cancel write, retry later
				end
				old.Lock = { JobId = game.JobId, Time = os.time() }
				result = old
				return old
			end)
		end)
		if ok and result then
			return result
		end
		if not ok then
			warn("[DataService] load error", userId, err)
		end
		task.wait(if locked then 5 else 2)
	end
	return nil
end

local function writeRecord(player: Player, release: boolean): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	local key = keyFor(player.UserId)
	if DataService.UseMock then
		mockStore[key] = { Data = TableUtil.deepCopy(data) }
		return true
	end
	local ok, err = pcall(function()
		(store :: GlobalDataStore):UpdateAsync(key, function(old)
			old = old or {}
			local lock = old.Lock
			if lock and lock.JobId ~= game.JobId then
				-- Another server stole the session; do not overwrite its data.
				warn("[DataService] session lock lost for", player.UserId)
				return nil
			end
			old.Data = data
			old.Lock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return old
		end)
	end)
	if not ok then
		warn("[DataService] save error", player.UserId, err)
	end
	return ok
end

local function snapshot(data: any): any
	local copy = TableUtil.deepCopy(data)
	copy.ProcessedReceipts = nil
	return copy
end

function DataService:Get(player: Player): any?
	return profiles[player]
end

function DataService:WaitFor(player: Player, timeout: number?): any?
	local t0 = os.clock()
	while player.Parent and not profiles[player] and os.clock() - t0 < (timeout or 30) do
		task.wait(0.1)
	end
	return profiles[player]
end

-- Mutate data through a function; marks it for replication.
function DataService:Update(player: Player, fn: (any) -> ())
	local data = profiles[player]
	if not data then
		return
	end
	fn(data)
	dirty[player] = true
	self.Changed:Fire(player, data)
end

function DataService:MarkDirty(player: Player)
	dirty[player] = true
end

function DataService:Save(player: Player): boolean
	return writeRecord(player, false)
end

function DataService:Snapshot(player: Player): any?
	local d = profiles[player]
	return d and snapshot(d)
end

local function onPlayerAdded(player: Player)
	if loading[player] or profiles[player] then
		return
	end
	loading[player] = true
	local record = loadRecord(player.UserId)
	loading[player] = nil
	if not player.Parent then
		return
	end
	if not record then
		player:Kick("Could not load your save data. Please rejoin in a minute.")
		return
	end
	local data = DataSchema.migrate(record.Data)
	profiles[player] = data
	if not DataService.UseMock then
		-- Write back immediately so the migrated schema + lock are stored.
		task.spawn(writeRecord, player, false)
	end
	DataService.Loaded:Fire(player, data)
	Remotes.event("DataChanged"):FireClient(player, snapshot(data))
end

local function onPlayerRemoving(player: Player)
	if profiles[player] then
		writeRecord(player, true)
		profiles[player] = nil
		dirty[player] = nil
	end
end

function DataService:Init()
	detectStore()
	Remotes.func("GetData").OnServerInvoke = function(player)
		local d = DataService:WaitFor(player, 15)
		return d and snapshot(d)
	end
end

function DataService:Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	-- Replicate dirty profiles at most 4x per second.
	task.spawn(function()
		local ev = Remotes.event("DataChanged")
		while true do
			task.wait(0.25)
			for player in dirty do
				dirty[player] = nil
				local d = profiles[player]
				if d and player.Parent then
					ev:FireClient(player, snapshot(d))
				end
			end
		end
	end)

	-- Autosave.
	task.spawn(function()
		while true do
			task.wait(GameSettings.AutosaveInterval)
			for player in profiles do
				task.spawn(writeRecord, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() and DataService.UseMock then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				writeRecord(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
