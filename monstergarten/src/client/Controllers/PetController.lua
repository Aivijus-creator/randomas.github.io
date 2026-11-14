-- PetController: adopt babies you're friends with, equip pets (they follow you in the lobby), rename them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local Babies = require(Shared.Config.Babies)
local Progression = require(Shared.Config.Progression)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local PetController = {}
local window
local list: ScrollingFrame

local function render()
	if not window or not window.IsOpen() then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local d = State.Data
	if not d then
		return
	end
	local order = 0
	local slots = player:GetAttribute("PetSlots") or 1
	local header = UI.label("", { Size = UDim2.new(1, -10, 0, 30), LayoutOrder = 0, Parent = list })
	header.Text = Strings.t("Pets_Slots", #d.EquippedPets, slots)
	header.Parent = list
	-- owned pets
	for idx, pet in d.Pets do
		order += 1
		local def = Babies.Defs[pet.BabyId]
		local equipped = table.find(d.EquippedPets, idx) ~= nil
		local f = UI.panel({ Size = UDim2.new(1, -10, 0, 64), LayoutOrder = order, Parent = list }, if equipped then C.Mint else C.Cream)
		UI.label(def and def.Emoji or "?", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(48, 48), Parent = f })
		local box = UI.new("TextBox", {
			Position = UDim2.fromOffset(62, 12),
			Size = UDim2.new(1, -310, 0, 40),
			BackgroundColor3 = C.White,
			Font = UI.Theme.Font,
			TextScaled = true,
			TextColor3 = C.Plum,
			Text = pet.Name,
			ClearTextOnFocus = false,
			Parent = f,
		})
		UI.corner(box, UDim.new(0, 10))
		local rename = UI.button("", C.Lavender, function()
			Remotes.event("PetAction"):FireServer("Rename", idx, box.Text)
		end, { Position = UDim2.new(1, -240, 0, 10), Size = UDim2.fromOffset(110, 44), Parent = f })
		UI.bind(rename, "Pets_Rename")
		local eq = UI.button("", if equipped then C.Pink else C.Mint, function()
			Remotes.event("PetAction"):FireServer("Equip", idx)
		end, { Position = UDim2.new(1, -122, 0, 10), Size = UDim2.fromOffset(112, 44), Parent = f })
		UI.bind(eq, if equipped then "Pets_Unequip" else "Pets_Equip")
	end
	-- adoptable babies (friendship progress)
	for _, id in Babies.Order do
		local has = false
		for _, p in d.Pets do
			if p.BabyId == id then
				has = true
			end
		end
		local seen = d.SeenBabies[id] or (d.BabyFriendship[id] or 0) > 0
		if not has and seen then
			order += 1
			local def = Babies.Defs[id]
			local fr = d.BabyFriendship[id] or 0
			local f = UI.panel({ Size = UDim2.new(1, -10, 0, 64), LayoutOrder = order, Parent = list }, C.Peach)
			UI.label(def.Emoji, { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(48, 48), Parent = f })
			UI.label(Strings.name(def.Name), { Position = UDim2.fromOffset(62, 6), Size = UDim2.new(1, -250, 0, 28), TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
			local _, set = UI.bar({ Position = UDim2.fromOffset(62, 40), Size = UDim2.new(1, -250, 0, 12), Parent = f }, C.Pink)
			set(fr / Progression.FriendshipToAdopt)
			local can = fr >= Progression.FriendshipToAdopt
			local b = UI.button("", if can then C.Mint else Color3.fromRGB(190, 190, 190), function()
				if can then
					Remotes.event("PetAction"):FireServer("Adopt", id)
				end
			end, { Position = UDim2.new(1, -170, 0, 10), Size = UDim2.fromOffset(160, 44), Parent = f })
			b.Text = if can then Strings.t("Pets_Adopt") else ("❤️ " .. fr .. "/" .. Progression.FriendshipToAdopt)
		end
	end
	if order == 0 then
		local l = UI.label("", { Size = UDim2.new(1, -10, 0, 80), TextWrapped = true, LayoutOrder = 1, Parent = list })
		UI.bind(l, "Pets_Empty")
	end
end

function PetController:Open()
	if State.inShift() then
		return
	end
	window.Open()
end

function PetController:Init()
	local gui = UI.screen("PetsGui", 16)
	window = UI.window(gui, "Pets_Title", UDim2.fromOffset(700, 520), C.Peach)
	list = UI.scroll(window.Content)
	UI.list(list, 8)
	window.OnOpen = render
end

function PetController:Start()
	State.DataChanged:Connect(render)
	State.LanguageChanged:Connect(render)
end

return PetController
