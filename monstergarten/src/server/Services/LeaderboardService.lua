-- LeaderboardService: OrderedDataStores for total stars and this week's best shift; lobby boards refresh every 60 s.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local GameSettings = require(Shared.Config.GameSettings)

local LeaderboardService = {}
local S
local pendingSubmit: { [Player]: boolean } = {}
local cache: { [string]: { { Name: string, Value: number } } } = { Stars = {}, Weekly = {} }
local names: { [number]: string } = {}

local function weekKey(): string
	return tostring(math.floor((os.time() / 86400 + 3) / 7))
end

local function store(board: string): OrderedDataStore?
	if S.DataService.UseMock then
		return nil
	end
	local ok, s = pcall(function()
		if board == "Stars" then
			return DataStoreService:GetOrderedDataStore("MG_TotalStars")
		end
		return DataStoreService:GetOrderedDataStore("MG_WeeklyBest_" .. weekKey())
	end)
	return if ok then s else nil
end

local function nameOf(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, n = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok then n else ("#" .. userId)
	return names[userId]
end

function LeaderboardService:Submit(player: Player)
	pendingSubmit[player] = true
end

local function flush()
	for player in pendingSubmit do
		pendingSubmit[player] = nil
		local d = S.DataService:Get(player)
		if d then
			local key = tostring(player.UserId)
			local s1, s2 = store("Stars"), store("Weekly")
			if s1 then
				pcall(s1.SetAsync, s1, key, d.TotalStars)
			end
			if s2 and d.WeeklyBest.Week == weekKey() then
				pcall(s2.SetAsync, s2, key, d.WeeklyBest.Score)
			end
		end
	end
end

local function refresh()
	for _, board in { "Stars", "Weekly" } do
		local s = store(board)
		local entries = {}
		if s then
			local ok, pages = pcall(s.GetSortedAsync, s, false, 10)
			if ok and pages then
				for _, e in pages:GetCurrentPage() do
					table.insert(entries, { Name = nameOf(tonumber(e.key) or 0), Value = e.value })
				end
			end
		else
			-- mock: online players only
			for _, p in Players:GetPlayers() do
				local d = S.DataService:Get(p)
				if d then
					table.insert(entries, { Name = p.DisplayName, Value = if board == "Stars" then d.TotalStars else d.WeeklyBest.Score })
				end
			end
			table.sort(entries, function(a, b)
				return a.Value > b.Value
			end)
		end
		cache[board] = entries
	end
	for _, m in CollectionService:GetTagged("Leaderboard") do
		local board = m:GetAttribute("Board")
		local panel = m:FindFirstChild("Panel")
		local gui = panel and panel:FindFirstChild("BoardGui")
		local list = gui and gui:FindFirstChild("List") :: TextLabel?
		if list and cache[board] then
			local lines = {}
			for i, e in cache[board] do
				if i > 10 then
					break
				end
				table.insert(lines, ("%d. %s  —  %s%d"):format(i, e.Name, if board == "Stars" then "⭐" else "🏆", e.Value))
			end
			list.Text = if #lines > 0 then table.concat(lines, "\n") else "—"
		end
	end
end

function LeaderboardService:Init(services)
	S = services
	Remotes.func("GetLeaderboard").OnServerInvoke = function(_, board)
		return cache[board] or {}
	end
end

function LeaderboardService:Start()
	Players.PlayerRemoving:Connect(function(p)
		pendingSubmit[p] = nil
	end)
	S.DataService.Loaded:Connect(function(p)
		LeaderboardService:Submit(p)
	end)
	task.spawn(function()
		task.wait(5)
		while true do
			flush()
			refresh()
			task.wait(GameSettings.LeaderboardInterval)
		end
	end)
end

return LeaderboardService
