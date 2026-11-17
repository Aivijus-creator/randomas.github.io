--[[
	JailService – bausmė nusikaltusiam žaidėjui (tik savininkas / admin):
	  /jail <vardas>    – žaidėjas nukeliamas į miško aikštelę, pasodinamas ant kėdės,
	                      aplink jį sukasi močiutės ir kočėlais „auklėja“ (tik animacija, be žalos).
	                      Jis negali nei vaikščioti, nei šokti, nei teleportuotis; išėjus ir grįžus –
	                      vėl atsiduria ant kėdės (data.jailed išsaugoma).
	  /unjail <vardas>  – paleidžia ir nukelia į turgų.

	Močiučių sukimąsi ir smūgius rodo klientai (EffectsController, žymė "JailGranny"),
	serveris tik pastato kamerą ir kas pusę sekundės prižiūri, kad kalinys sėdėtų.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Config = ReplicatedStorage:WaitForChild("Config")
local Settings = require(Config:WaitForChild("Settings"))
local Lib = script.Parent.Parent:WaitForChild("Lib")
local Build = require(Lib:WaitForChild("Build"))
local GrannyModels = require(Lib:WaitForChild("GrannyModels"))

local J = Settings.Jail
local C = Color3.fromRGB
local V = Vector3.new
local CF = CFrame.new
local M = Enum.Material

local JailService = {}
local S
local cells = {}          -- [userId] = { Folder, Seat, Center, Index }
local usedIndex = {}

local function cellCenter(index)
	local a = math.rad(J.Angle + (index - 1) * 6)
	local r = J.Radius
	return V(math.cos(a) * r, 0, math.sin(a) * r)
end

local function clearTrees(center, radius)
	local map = workspace:FindFirstChild("Map")
	local nature = map and map:FindFirstChild("Nature")
	if not nature then
		return
	end
	for _, child in ipairs(nature:GetChildren()) do
		local ok, pivot = pcall(function()
			return child:GetPivot()
		end)
		if ok and pivot then
			local p = pivot.Position
			if V(p.X - center.X, 0, p.Z - center.Z).Magnitude < radius then
				child:Destroy()
			end
		end
	end
end

local function buildCell(index)
	local center = cellCenter(index)
	clearTrees(center, 16)
	local folder = Build.Folder("JailCell_" .. index, workspace)
	local facing = CFrame.lookAt(center, V(0, 0, 0))
	-- Pievelė ir kelmas-ženklas
	Build.Part({ Name = "Clearing", Parent = folder, Shape = Enum.PartType.Cylinder, Size = V(0.3, 26, 26), CFrame = CF(center + V(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = C(95, 125, 60), Material = M.Grass, CanCollide = true })
	-- Medinė kėdė
	local seatCF = facing * CF(0, 1.6, 0)
	local seat = Instance.new("Seat")
	seat.Name = "JailSeat"
	seat.Size = V(2.2, 0.4, 2.2)
	seat.CFrame = seatCF
	seat.Anchored = true
	seat.Color = C(120, 80, 45)
	seat.Material = M.WoodPlanks
	seat.Parent = folder
	for _, x in ipairs({ -0.95, 0.95 }) do
		for _, z in ipairs({ -0.95, 0.95 }) do
			Build.Part({ Name = "ChairLeg", Parent = folder, Size = V(0.3, 1.5, 0.3), CFrame = facing * CF(x, 0.75, z), Color = C(90, 58, 30), Material = M.Wood })
		end
	end
	Build.Part({ Name = "ChairBack", Parent = folder, Size = V(2.2, 2.6, 0.3), CFrame = facing * CF(0, 3.1, 1.05), Color = C(120, 80, 45), Material = M.WoodPlanks })
	Build.Part({ Name = "ChairTop", Parent = folder, Size = V(2.5, 0.35, 0.4), CFrame = facing * CF(0, 4.5, 1.05), Color = C(90, 58, 30), Material = M.Wood })
	local signPost = Build.Part({ Name = "SignPost", Parent = folder, Size = V(0.4, 5, 0.4), CFrame = facing * CF(5, 2.5, -6), Color = C(90, 58, 30), Material = M.Wood })
	Build.Sign(signPost, { Name = "JailSign", TextKey = "JailSign", Size = UDim2.fromScale(8, 2), Offset = V(0, 3.5, 0), MaxDistance = 120 })
	-- Močiutės aplink (klientai suka ratu ir animuoja smūgius)
	for i = 1, J.Grannies do
		local level = ((i - 1) % 3) + 1
		local granny = GrannyModels.Build(level)
		granny.Name = "JailGranny"
		-- Pirma pastatom ant žemės (kojos ant aikštelės), tik tada duodam kočėlą
		local a = (i - 1) * (2 * math.pi / J.Grannies)
		local pos = V(center.X + math.cos(a) * J.CircleRadius, 0.3, center.Z + math.sin(a) * J.CircleRadius)
		Build.PlaceOnFloor(granny, CFrame.lookAt(pos, V(center.X, pos.Y, center.Z)))
		local rightArm = granny:FindFirstChild("RightArm")
		if rightArm then
			local pinCF = rightArm.CFrame * CF(0, -1.7, 0) * CFrame.Angles(0, 0, math.rad(90))
			local pin = Build.Part({ Name = "RollingPin", Parent = granny, Shape = Enum.PartType.Cylinder, Size = V(2.6, 0.38, 0.38), CFrame = pinCF, Color = C(215, 175, 115), Material = M.Wood, Anchored = false, CanCollide = false })
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rightArm
			weld.Part1 = pin
			weld.Parent = pin
		end
		for _, d in ipairs(granny:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		granny:SetAttribute("CenterX", center.X)
		granny:SetAttribute("CenterZ", center.Z)
		granny:SetAttribute("Phase", a)
		granny:SetAttribute("SeatY", seatCF.Position.Y)
		granny.Parent = folder
		CollectionService:AddTag(granny, "JailGranny")
	end
	return { Folder = folder, Seat = seat, Center = center, Index = index }
end

local function getCell(player)
	local cell = cells[player.UserId]
	if cell and cell.Folder.Parent then
		return cell
	end
	local index = 1
	while usedIndex[index] do
		index = index + 1
	end
	usedIndex[index] = true
	cell = buildCell(index)
	cells[player.UserId] = cell
	return cell
end

local function freeCell(userId)
	local cell = cells[userId]
	if cell then
		usedIndex[cell.Index] = nil
		cell.Folder:Destroy()
		cells[userId] = nil
	end
end

local function lockMovement(humanoid, locked)
	humanoid.WalkSpeed = locked and 0 or 16
	humanoid.JumpPower = locked and 0 or 50
	humanoid.JumpHeight = locked and 0 or 7.2
	humanoid.UseJumpPower = true
end

-- Pasodina ant kėdės (jei dar nesėdi)
local function seatPrisoner(player)
	local cell = cells[player.UserId]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not cell or not humanoid or not root then
		return
	end
	lockMovement(humanoid, true)
	humanoid:UnequipTools()
	if humanoid.SeatPart ~= cell.Seat then
		humanoid.Sit = false
		character:PivotTo(cell.Seat.CFrame * CF(0, 2, 0))
		cell.Seat:Sit(humanoid)
	end
end

function JailService:IsJailed(player)
	local data = S.DataService:Get(player)
	return data ~= nil and data.jailed == true
end

function JailService:Jail(player)
	local data = S.DataService:Get(player)
	if not data then
		return false
	end
	data.jailed = true
	player:SetAttribute("Jailed", true)
	getCell(player)
	seatPrisoner(player)
	S.DataService:Notify(player, "JailYou", nil, nil, nil, "error")
	return true
end

function JailService:Release(player)
	local data = S.DataService:Get(player)
	if data then
		data.jailed = false
	end
	player:SetAttribute("Jailed", false)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Sit = false
		lockMovement(humanoid, false)
	end
	freeCell(player.UserId)
	if character then
		task.delay(0.2, function()
			if character.Parent then
				character:PivotTo(S.MapBuilder:GetLobbySpawnCFrame())
			end
		end)
	end
	S.DataService:Notify(player, "JailReleased", nil, nil, nil, "success")
	return true
end

function JailService:Init(services)
	S = services
end

function JailService:Start()
	local function onPlayer(player)
		player.CharacterAdded:Connect(function()
			task.delay(1, function()
				if self:IsJailed(player) then
					getCell(player)
					seatPrisoner(player)
				end
			end)
		end)
		task.spawn(function()
			-- Grįžus į žaidimą bausmė tęsiasi
			for _ = 1, 30 do
				if S.DataService:Get(player) or not player.Parent then
					break
				end
				task.wait(1)
			end
			if player.Parent and self:IsJailed(player) then
				player:SetAttribute("Jailed", true)
				getCell(player)
				task.wait(1)
				seatPrisoner(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		freeCell(player.UserId)
	end)
	-- Prižiūrėtojas: kalinys visada ant kėdės
	task.spawn(function()
		while true do
			task.wait(0.5)
			for userId, cell in pairs(cells) do
				local player = Players:GetPlayerByUserId(userId)
				if player and player.Character then
					local root = player.Character:FindFirstChild("HumanoidRootPart")
					local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
					if root and humanoid and (humanoid.SeatPart ~= cell.Seat or (root.Position - cell.Seat.Position).Magnitude > 6) then
						seatPrisoner(player)
					end
				end
			end
		end
	end)
end

return JailService
