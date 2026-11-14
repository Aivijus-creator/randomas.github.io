-- PetService: adopt babies (friendship >= 5), rename (filtered), equip; pets follow their owner in the lobby
-- and the rest play inside the pet pen.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Babies = require(Shared.Config.Babies)
local Progression = require(Shared.Config.Progression)
local ModelRegistry = require(Shared.World.ModelRegistry)
local CosmeticBuilder = require(Shared.World.CosmeticBuilder)
local ServerUtil = require(script.Parent.Parent.ServerUtil)

local PetService = {}
local S
local followers: { [Player]: { any } } = {}
local penPets: { any } = {}
local folder: Folder

local function makePet(babyId: string, name: string, owner: Player)
	local m = ModelRegistry.getBaby(babyId)
	m.Name = "Pet_" .. babyId
	m:SetAttribute("Pet", true)
	m:SetAttribute("PetName", name)
	m:SetAttribute("Owner", owner.UserId)
	m:SetAttribute("Anim", "Idle")
	local tag = m:FindFirstChild("NameTag", true)
	if tag then
		local label = tag:FindFirstChildOfClass("TextLabel")
		if label then
			label.Text = name
		end
	end
	CollectionService:AddTag(m, "PetModel")
	m.Parent = folder
	local d = S.DataService:Get(owner)
	if d then
		CosmeticBuilder.petAccessory(m, d.Cosmetics.Equipped.PetAccessory)
	end
	return { Model = m, Pos = m:GetPivot().Position, Offset = m:GetAttribute("FloorOffset") or 1.45 }
end

local function clear(player: Player)
	for _, p in followers[player] or {} do
		p.Model:Destroy()
	end
	followers[player] = nil
	for i = #penPets, 1, -1 do
		if penPets[i].Owner == player then
			penPets[i].Model:Destroy()
			table.remove(penPets, i)
		end
	end
end

function PetService:Refresh(player: Player)
	clear(player)
	local d = S.DataService:Get(player)
	if not d or not player.Parent then
		return
	end
	local inShift = S.ShiftService:SessionOf(player) ~= nil
	local list = {}
	local slots = player:GetAttribute("PetSlots") or 1
	for i, idx in d.EquippedPets do
		local pet = d.Pets[idx]
		if pet and i <= slots and not inShift then
			table.insert(list, makePet(pet.BabyId, pet.Name, player))
		end
	end
	followers[player] = list
	-- the others play in the pen
	local area = CollectionService:GetTagged("PetArea")[1] :: BasePart?
	if area then
		for idx, pet in d.Pets do
			if not table.find(d.EquippedPets, idx) and #penPets < 14 then
				local p = makePet(pet.BabyId, pet.Name, player)
				p.Owner = player
				p.Area = area
				p.Pos = area.Position + Vector3.new(math.random(-8, 8), -1.3, math.random(-5, 5))
				table.insert(penPets, p)
			end
		end
	end
end

local function filterName(player: Player, text: string): string?
	text = text:sub(1, 20)
	local ok, result = pcall(function()
		local r = TextService:FilterStringAsync(text, player.UserId)
		return r:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" and result ~= "" then
		return result
	end
	return nil
end

local function onAction(player: Player, action: string, index: any, arg: any)
	if not ServerUtil.rateLimit(player, "Pets", 3) then
		return
	end
	local d = S.DataService:Get(player)
	if not d then
		return
	end
	if action == "Adopt" and type(index) == "string" then
		local def = Babies.Defs[index]
		if not def then
			return
		end
		if (d.BabyFriendship[index] or 0) < Progression.FriendshipToAdopt then
			ServerUtil.notify(player, "Pet_NotFriends", "error")
			return
		end
		for _, p in d.Pets do
			if p.BabyId == index then
				ServerUtil.notify(player, "Pet_Already", "error")
				return
			end
		end
		S.DataService:Update(player, function(data)
			table.insert(data.Pets, { BabyId = index, Name = def.Name.en })
			if #data.EquippedPets == 0 then
				table.insert(data.EquippedPets, #data.Pets)
			end
		end)
		ServerUtil.notify(player, { "Toast_Adopted", index }, "unlock")
	elseif action == "Equip" and type(index) == "number" then
		if not d.Pets[index] then
			return
		end
		local slots = player:GetAttribute("PetSlots") or 1
		S.DataService:Update(player, function(data)
			local at = table.find(data.EquippedPets, index)
			if at then
				table.remove(data.EquippedPets, at)
			else
				table.insert(data.EquippedPets, index)
				while #data.EquippedPets > slots do
					table.remove(data.EquippedPets, 1)
				end
			end
		end)
	elseif action == "Rename" and type(index) == "number" and type(arg) == "string" then
		if not d.Pets[index] then
			return
		end
		local name = filterName(player, arg)
		if not name then
			ServerUtil.notify(player, "Pet_NameRejected", "error")
			return
		end
		S.DataService:Update(player, function(data)
			data.Pets[index].Name = name
		end)
	else
		return
	end
	PetService:Refresh(player)
end

function PetService:Init(services)
	S = services
	folder = Instance.new("Folder")
	folder.Name = "Pets"
	folder.Parent = workspace
end

function PetService:Start()
	S.DataService.Loaded:Connect(function(p)
		task.wait(2)
		PetService:Refresh(p)
	end)
	Players.PlayerRemoving:Connect(clear)
	Remotes.event("PetAction").OnServerEvent:Connect(onAction)
	-- refresh when entering / leaving shifts
	local function watch(p: Player)
		p:GetAttributeChangedSignal("InShift"):Connect(function()
			task.wait(1)
			PetService:Refresh(p)
		end)
		p.CharacterAdded:Connect(function()
			task.wait(1)
			PetService:Refresh(p)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 20 then
			return
		end
		local step = acc
		acc = 0
		for player, list in followers do
			local root = ServerUtil.root(player)
			if root then
				for i, pet in list do
					local side = if i % 2 == 1 then 1 else -1
					local target = (root.CFrame * CFrame.new(side * 3, 0, 4)).Position
					local groundY = root.Position.Y - 3
					local cur = pet.Pos
					local goal = Vector3.new(target.X, groundY, target.Z)
					local d = goal - cur
					local moving = d.Magnitude > 1.5
					if d.Magnitude > 60 then
						cur = goal
					elseif moving then
						cur = cur + d * math.min(1, step * 4)
					end
					pet.Pos = cur
					local look = Vector3.new(d.X, 0, d.Z)
					local yawCF = if look.Magnitude > 0.2 then CFrame.lookAt(Vector3.zero, look) else (pet.LastRot or CFrame.new())
					pet.LastRot = yawCF
					pet.Model:PivotTo(CFrame.new(cur + Vector3.new(0, pet.Offset, 0)) * yawCF.Rotation)
					pet.Model:SetAttribute("Anim", if moving then "Walk" else "Happy")
				end
			end
		end
		for _, pet in penPets do
			if not pet.Target or (pet.Target - pet.Pos).Magnitude < 0.5 then
				local a = pet.Area
				pet.Target = a.Position + Vector3.new(math.random(-100, 100) / 100 * (a.Size.X / 2), -1.3, math.random(-100, 100) / 100 * (a.Size.Z / 2))
			end
			local d = pet.Target - pet.Pos
			pet.Pos += d.Unit * math.min(d.Magnitude, 4 * step)
			local look = Vector3.new(d.X, 0, d.Z)
			local rot = if look.Magnitude > 0.1 then CFrame.lookAt(Vector3.zero, look).Rotation else CFrame.new()
			pet.Model:PivotTo(CFrame.new(pet.Pos + Vector3.new(0, pet.Offset, 0)) * rot)
			pet.Model:SetAttribute("Anim", "Walk")
		end
	end)
end

return PetService
