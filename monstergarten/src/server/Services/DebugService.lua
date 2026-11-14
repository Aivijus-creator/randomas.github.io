-- DebugService: F2 debug menu commands (Studio, the place creator, or GameSettings.DebugUserIds only).
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local GameSettings = require(Shared.Config.GameSettings)
local Babies = require(Shared.Config.Babies)
local Events = require(Shared.Config.Events)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local DebugService = {}
local S

function DebugService:Allowed(player: Player): boolean
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(GameSettings.DebugUserIds, player.UserId) ~= nil
end

local commands: { [string]: (Player, any, ...any) -> () } = {
	SpawnBaby = function(player, session, id)
		if session and Babies.Defs[id] then
			local root = ServerUtil.root(player)
			if root then
				S.BabyService:SpawnBaby(session, id, root.CFrame * CFrame.new(0, -1.5, -5))
				S.ShiftService:SendState(session)
			end
		end
	end,
	SetNeeds = function(_, session, value)
		if session and type(value) == "number" then
			S.NeedService:SetAll(session, math.clamp(value, 0, 100))
		end
	end,
	TriggerEvent = function(_, session, id)
		if session and Events.Defs[id] then
			S.EventService:Trigger(session, id)
		end
	end,
	TimeScale = function(_, session, x)
		if session and type(x) == "number" then
			session.TimeScale = math.clamp(x, 0.25, 10)
		end
	end,
	AddCoins = function(player, _, n)
		if type(n) == "number" then
			S.ProgressionService:AddCoins(player, math.clamp(n, -1e6, 1e6))
		end
	end,
	AddStars = function(player, _, n)
		if type(n) == "number" then
			S.ProgressionService:AddStars(player, math.clamp(n, 0, 1000))
		end
	end,
	UnlockAll = function(player)
		S.DataService:Update(player, function(d)
			d.DebugUnlockAll = true
			d.TotalStars = math.max(d.TotalStars, 300)
		end)
		S.ProgressionService:Refresh(player)
	end,
	ShowAI = function(_, _, on)
		workspace:SetAttribute("DebugAI", on == true)
	end,
	EndShift = function(_, session)
		if session then
			session.ClockFrozen = false
			session.Time = session.Duration
		end
	end,
	PowerOff = function(_, session)
		if session then
			S.FurnitureService:SetPower(session, false)
		end
	end,
	Friendship = function(player, _, id)
		if Babies.Defs[id] then
			S.DataService:Update(player, function(d)
				d.BabyFriendship[id] = 5
			end)
		end
	end,
	ResetData = function(player)
		S.DataService:Update(player, function(d)
			local fresh = require(Shared.Logic.DataSchema).template()
			for k in d do
				d[k] = nil
			end
			for k, v in fresh do
				d[k] = v
			end
		end)
		S.ProgressionService:Refresh(player)
	end,
}

function DebugService:Init(services)
	S = services
end

function DebugService:Start()
	Remotes.event("DebugCommand").OnServerEvent:Connect(function(player, cmd, ...)
		if not DebugService:Allowed(player) or type(cmd) ~= "string" then
			return
		end
		local fn = commands[cmd]
		if fn then
			local ok, err = pcall(fn, player, S.ShiftService:SessionOf(player), ...)
			if not ok then
				warn("[Debug]", cmd, err)
			end
			ServerUtil.notify(player, { "Debug_Done", cmd }, "info")
		end
	end)
	local function mark(p: Player)
		p:SetAttribute("DebugAllowed", DebugService:Allowed(p))
	end
	game:GetService("Players").PlayerAdded:Connect(mark)
	for _, p in game:GetService("Players"):GetPlayers() do
		mark(p)
	end
	-- AI state labels for the debug overlay (only when enabled)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if workspace:GetAttribute("DebugAI") then
				for _, session in S.ShiftService:Sessions() do
					for _, b in session.BabyList do
						b.Model:SetAttribute("DebugState", ("%s %s %s"):format(b.State, b.Tantrum or "", b.Path and "→" or ""))
					end
				end
			end
		end
	end)
end

return DebugService
