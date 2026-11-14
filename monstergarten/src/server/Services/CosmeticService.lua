-- CosmeticService: equips cosmetics and builds them on characters from parts (hats, aprons, uniforms).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Cosmetics = require(Shared.Config.Cosmetics)
local ServerUtil = require(script.Parent.Parent.ServerUtil)
local CosmeticBuilder = require(Shared.World.CosmeticBuilder)

local CosmeticService = {}
local S

function CosmeticService:Owns(player: Player, id: string): boolean
	local d = S.DataService:Get(player)
	if not d then
		return false
	end
	if d.Cosmetics.Owned[id] then
		return true
	end
	if id == "Apron_VIP" and player:GetAttribute("VIP") then
		return true
	end
	return false
end

function CosmeticService:Apply(player: Player)
	local char = player.Character
	local d = S.DataService:Get(player)
	if not char or not d then
		return
	end
	CosmeticBuilder.apply(char, d.Cosmetics.Equipped)
	local tool = char:FindFirstChild("HeldItem")
	if tool then
		-- tool skins refresh next time the tool is picked up
		local _ = tool
	end
end

function CosmeticService:Init(services)
	S = services
end

function CosmeticService:Start()
	local function hook(player: Player)
		player.CharacterAppearanceLoaded:Connect(function()
			task.wait(0.2)
			CosmeticService:Apply(player)
		end)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			CosmeticService:Apply(player)
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	S.DataService.Loaded:Connect(function(player)
		CosmeticService:Apply(player)
	end)
	Remotes.event("Equip").OnServerEvent:Connect(function(player, slot, id)
		if not ServerUtil.rateLimit(player, "Equip", 5) or type(slot) ~= "string" then
			return
		end
		if id ~= nil and type(id) ~= "string" then
			return
		end
		if id and id ~= "" then
			local def = Cosmetics.Defs[id]
			if not def or def.Slot ~= slot or not CosmeticService:Owns(player, id) then
				ServerUtil.notify(player, "Cosmetic_NotOwned", "error")
				return
			end
		end
		S.DataService:Update(player, function(d)
			if slot == "ToolSkin" then
				local def = id and Cosmetics.Defs[id]
				if def and def.Tool then
					d.Cosmetics.Equipped.ToolSkins[def.Tool] = id
				end
			elseif slot == "ToolSkinClear" and id == nil then
				d.Cosmetics.Equipped.ToolSkins = {}
			elseif d.Cosmetics.Equipped[slot] ~= nil then
				d.Cosmetics.Equipped[slot] = id or ""
			end
		end)
		CosmeticService:Apply(player)
		S.PetService:Refresh(player)
	end)
end

return CosmeticService
