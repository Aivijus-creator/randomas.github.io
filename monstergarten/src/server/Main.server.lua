-- Monstergarten server entry point. Loads every service, calls Init() on all, then Start() on all.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
Remotes.setup()

local ServicesFolder = script.Parent:WaitForChild("Services")
local Services = {}

local ORDER = {
	"DataService", "ProgressionService", "MonetizationService", "QuestService", "CosmeticService",
	"MapService", "FurnitureService", "StatusEffectService", "HazardService", "ToolService",
	"KitchenService", "BabyService", "NeedService", "ChaosService", "EventService", "ScoringService",
	"RewardService", "ShiftService", "QueueService", "ShopService", "PetService", "LeaderboardService",
	"TutorialService", "DebugService",
}

for _, name in ORDER do
	local mod = ServicesFolder:FindFirstChild(name)
	if mod then
		local ok, svc = pcall(require, mod)
		if ok then
			Services[name] = svc
		else
			warn("[Main] failed to load", name, svc)
		end
	end
end

for _, name in ORDER do
	local svc = Services[name]
	if svc and svc.Init then
		local ok, err = pcall(svc.Init, svc, Services)
		if not ok then
			warn("[Main] Init failed", name, err)
		end
	end
end

for _, name in ORDER do
	local svc = Services[name]
	if svc and svc.Start then
		task.spawn(function()
			local ok, err = pcall(svc.Start, svc)
			if not ok then
				warn("[Main] Start failed", name, err)
			end
		end)
	end
end

-- Optional unit tests in Studio.
local GameSettings = require(Shared.Config.GameSettings)
if RunService:IsStudio() and (GameSettings.RunTestsOnStart or workspace:GetAttribute("RunTests")) then
	require(script.Parent.Tests.TestRunner).run(script.Parent.Tests)
end

print("[Monstergarten] server ready")
