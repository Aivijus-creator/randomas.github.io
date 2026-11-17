--[[
	RebirthService – „Močiutės palaiminimas“.
	- Pirmas rebirth: atrakinta Šaltibarščių linija + 1 000 000 Lt; kiti: ankstesnė kaina × 3.
	- Daugiklis: 1 + 0,5 × rebirth skaičius.
	- Išsitrina: litai, pirkiniai, močiutės, bendri patobulinimai.
	- Lieka: rebirth skaičius, gamepass'ai, badge'ai, kosmetika, statistika.
	- Titulai ir apdovanojimai – Settings.Rebirth.
	Užklausos: Remotes.RequestRebirth:InvokeServer("info" | "confirm")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Calc = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Calc"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local TitleItems = require(Lib:WaitForChild("TitleItems"))
local RateLimit = require(Lib:WaitForChild("RateLimit"))

local V = Vector3.new
local C = Color3.fromRGB

local RebirthService = {}
local S
local limiter = RateLimit.new(Settings.RemoteRateLimit)
local busy = {}

function RebirthService:GetInfo(player)
	local data = S.DataService:Get(player)
	if not data then
		return nil
	end
	local nextReward = Calc.GetNextReward(data.rebirths)
	local cost = Calc.GetRebirthCost(data.rebirths)
	local requirementMet = Calc.IsLineUnlocked(data, Settings.Rebirth.RequiredLine)
	return {
		Rebirths = data.rebirths,
		Cost = cost,
		Money = data.money,
		RequirementMet = requirementMet,
		CanRebirth = requirementMet and data.money >= cost,
		CurrentMultiplier = Calc.GetRebirthMultiplier(data.rebirths),
		NewMultiplier = Calc.GetRebirthMultiplier(data.rebirths + 1),
		TitleKey = Calc.GetTitleKey(data.rebirths),
		NextTitleKey = Calc.GetTitleKey(data.rebirths + 1),
		NextRewardAt = nextReward and nextReward.At or nil,
		NextRewardKey = nextReward and nextReward.Key or nil,
	}
end

----------------------------------------------------------------------
-- Titulas virš galvos ir karūna
----------------------------------------------------------------------
function RebirthService:ApplyTitle(player)
	local character = player.Character
	local data = S.DataService:Get(player)
	local head = character and character:FindFirstChild("Head")
	if not head or not data then
		return
	end
	local old = head:FindFirstChild("TitleGui")
	if old then
		old:Destroy()
	end
	Build.Billboard(head, { Name = "TitleGui", TextKey = Calc.GetTitleKey(data.rebirths), Size = UDim2.fromScale(7, 1.1), Offset = V(0, 2.4, 0), MaxDistance = 80, Color = C(255, 215, 120) })
	-- Titulo atributika (prijuostė, šaukštas, šefo kepurė, šalikas, apsiaustas, medalionas, kardas)
	TitleItems.Apply(character, data.rebirths)

	local oldCrown = character:FindFirstChild("RoyalCrown")
	if oldCrown then
		oldCrown:Destroy()
	end
	local hasCrown = false
	for _, reward in ipairs(Settings.Rebirth.Rewards) do
		if reward.Type == "Crown" and data.rebirths >= reward.At then
			hasCrown = true
		end
	end
	if hasCrown then
		local crown = Instance.new("Model")
		crown.Name = "RoyalCrown"
		local base = Build.Part({ Name = "Band", Parent = crown, Shape = Enum.PartType.Cylinder, Size = V(0.5, 1.4, 1.4), CFrame = head.CFrame * CFrame.new(0, 0.85, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = C(255, 205, 50), Material = Enum.Material.Metal, Anchored = false, CanCollide = false, Massless = true })
		for i = 0, 4 do
			local angle = math.rad(i * 72)
			Build.Part({ Name = "Spike", Parent = crown, Size = V(0.2, 0.45, 0.2), CFrame = head.CFrame * CFrame.new(math.cos(angle) * 0.6, 1.25, math.sin(angle) * 0.6), Color = C(255, 205, 50), Material = Enum.Material.Metal, Anchored = false, CanCollide = false, Massless = true })
		end
		Build.Part({ Name = "Gem", Parent = crown, Shape = Enum.PartType.Ball, Size = V(0.3, 0.3, 0.3), CFrame = head.CFrame * CFrame.new(0, 0.85, -0.7), Color = C(200, 30, 40), Material = Enum.Material.Neon, Anchored = false, CanCollide = false, Massless = true })
		for _, part in ipairs(crown:GetChildren()) do
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = head
			weld.Part1 = part
			weld.Parent = part
		end
		crown.PrimaryPart = base
		crown.Parent = character
	end
end

----------------------------------------------------------------------
-- Rebirth
----------------------------------------------------------------------
function RebirthService:DoRebirth(player)
	local data = S.DataService:Get(player)
	if not data or busy[player] then
		return false, "Busy"
	end
	local info = self:GetInfo(player)
	if not info.RequirementMet then
		return false, "RebirthRequirement"
	end
	if not info.CanRebirth then
		return false, "RebirthNotEnough"
	end
	busy[player] = true

	-- Išsitrina
	data.money = 0
	data.purchases = {}
	data.grannies = {}
	data.globalUpgrades = {}
	data.rebirths = data.rebirths + 1

	-- Apdovanojimai (visi pasiekti, nes jie nuolatiniai)
	for _, reward in ipairs(Settings.Rebirth.Rewards) do
		if data.rebirths >= reward.At then
			if reward.Type == "StartMoney" then
				data.money = math.max(data.money, reward.Amount)
			elseif reward.Type == "Skin" then
				data.cosmetics.skins[reward.Skin] = true
			elseif reward.Type == "Crown" then
				data.cosmetics.crown = true
				if reward.Badge then
					S.MonetizationService:AwardBadge(player, reward.Badge)
				end
			end
		end
	end

	S.DataService:UpdateStats(player)
	if S.PlotService:GetPlot(player) then
		S.TycoonService:BuildPlot(player)
		S.PlotService:TeleportToPlot(player)
	end
	self:ApplyTitle(player)
	for _, item in ipairs(TitleItems.NewlyUnlocked(data.rebirths - 1, data.rebirths)) do
		S.DataService:Notify(player, "TitleItemUnlocked", nil, { item = item.Key }, nil, "success")
	end
	S.TycoonService:UpdateIncome(player)
	Remotes.RebirthDone:FireClient(player, data.rebirths, Calc.GetRebirthMultiplier(data.rebirths), Calc.GetTitleKey(data.rebirths))
	task.spawn(function()
		S.DataService:Save(player, false)
	end)
	busy[player] = nil
	return true, "RebirthDone"
end

----------------------------------------------------------------------
-- Init / Start
----------------------------------------------------------------------
function RebirthService:Init(services)
	S = services
end

function RebirthService:Start()
	Remotes.RequestRebirth.OnServerInvoke = function(player, action)
		if not limiter:Check(player) then
			return nil
		end
		if action == "info" then
			return self:GetInfo(player)
		elseif action == "confirm" then
			local ok, key = self:DoRebirth(player)
			return { Success = ok, Key = key, Info = self:GetInfo(player) }
		end
		return nil
	end

	-- Močiutės trobelė lobby
	local door = S.MapBuilder.Anchors.RebirthHutDoor
	if door then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Rebirth"
		prompt.ObjectText = "👵"
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = door
		prompt.Triggered:Connect(function(player)
			Remotes.OpenWindow:FireClient(player, "Rebirth")
		end)
	end

	local function setupCharacter(player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			self:ApplyTitle(player)
		end)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		setupCharacter(player)
	end
	Players.PlayerAdded:Connect(setupCharacter)

	S.DataService:OnPlayerLoaded(function(player)
		if player.Character then
			self:ApplyTitle(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		busy[player] = nil
	end)
end

return RebirthService
