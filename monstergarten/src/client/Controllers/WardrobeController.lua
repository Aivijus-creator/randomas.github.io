-- WardrobeController: cosmetics by slot with a live 3D preview (ViewportFrame) of your character.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local Cosmetics = require(Shared.Config.Cosmetics)
local CosmeticBuilder = require(Shared.World.CosmeticBuilder)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local WardrobeController = {}
local window
local viewport: ViewportFrame
local list: ScrollingFrame
local slotBar: Frame
local slot = "Hat"
local preview: Model? = nil
local previewEquip: any = nil
local spin = 0

local function owned(id: string): boolean
	local d = State.Data
	return d ~= nil and (d.Cosmetics.Owned[id] == true or (id == "Apron_VIP" and player:GetAttribute("VIP") == true))
end

local function rebuildPreview()
	if preview then
		preview:Destroy()
		preview = nil
	end
	local char = player.Character
	if not char then
		return
	end
	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = false
	if not clone then
		return
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("BillboardGui") or d.Name == "HeldItem" then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	local old = clone:FindFirstChild("Cosmetics")
	if old then
		old:Destroy()
	end
	clone:PivotTo(CFrame.new(0, 0, 0))
	CosmeticBuilder.apply(clone, previewEquip or {})
	-- welds in a viewport don't simulate; re-anchor cosmetic parts in place
	for _, d in clone:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
	clone.Parent = viewport
	preview = clone
	local cam = viewport.CurrentCamera or Instance.new("Camera")
	cam.Parent = viewport
	viewport.CurrentCamera = cam
	cam.CFrame = CFrame.lookAt(Vector3.new(0, 1.5, -8), Vector3.new(0, 0.8, 0))
end

local function render()
	if not window or not window.IsOpen() then
		return
	end
	for _, c in list:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	for _, b in slotBar:GetChildren() do
		if b:IsA("TextButton") then
			b.BackgroundColor3 = if b.Name == slot then C.Yellow else C.Lavender
		end
	end
	local d = State.Data
	if not d then
		return
	end
	local eq = d.Cosmetics.Equipped
	local order = 0
	-- "none" entry
	if slot ~= "ToolSkin" then
		order += 1
		local f = UI.panel({ Size = UDim2.new(1, -10, 0, 54), LayoutOrder = order, Parent = list }, C.Cream)
		local b = UI.button("", C.Pink, function()
			Remotes.event("Equip"):FireServer(slot, "")
		end, { Position = UDim2.fromOffset(6, 5), Size = UDim2.new(1, -12, 0, 44), Parent = f })
		UI.bind(b, "Wardrobe_None")
	end
	for _, id in Cosmetics.Order do
		local def = Cosmetics.Defs[id]
		if def.Slot == slot then
			order += 1
			local has = owned(id)
			local equipped = eq[slot] == id or (slot == "ToolSkin" and def.Tool and eq.ToolSkins[def.Tool] == id)
			local f = UI.panel({ Size = UDim2.new(1, -10, 0, 54), LayoutOrder = order, Parent = list }, if equipped then C.Mint elseif has then C.Cream else Color3.fromRGB(215, 210, 220))
			local swatch = UI.new("Frame", { Position = UDim2.fromOffset(8, 9), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = def.Color, Parent = f })
			UI.corner(swatch, UDim.new(1, 0))
			UI.label(Strings.name(def.Name) .. (if has then "" else " 🔒"), { Position = UDim2.fromOffset(52, 8), Size = UDim2.new(1, -170, 0, 38), TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
			local tryBtn = UI.button("👁", C.Lavender, function()
				previewEquip = table.clone(eq)
				if slot ~= "ToolSkin" then
					previewEquip[slot] = id
				end
				rebuildPreview()
			end, { Position = UDim2.new(1, -112, 0, 6), Size = UDim2.fromOffset(46, 42), Parent = f })
			local _ = tryBtn
			if has then
				UI.button(if equipped then "✔" else "+", C.Mint, function()
					Remotes.event("Equip"):FireServer(slot, id)
				end, { Position = UDim2.new(1, -60, 0, 6), Size = UDim2.fromOffset(52, 42), Parent = f })
			end
		end
	end
end

function WardrobeController:Open()
	if State.inShift() then
		return
	end
	window.Open()
end

function WardrobeController:Init()
	local gui = UI.screen("WardrobeGui", 16)
	window = UI.window(gui, "Wardrobe_Title", UDim2.fromOffset(820, 520), C.Lavender)
	viewport = UI.new("ViewportFrame", { BackgroundColor3 = C.Cream, Size = UDim2.new(0.42, 0, 1, 0), Ambient = Color3.fromRGB(200, 190, 210), LightColor = Color3.new(1, 1, 1), Parent = window.Content })
	UI.corner(viewport)
	local right = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.45, 0, 0, 0), Size = UDim2.new(0.55, 0, 1, 0), Parent = window.Content })
	slotBar = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), Parent = right })
	UI.list(slotBar, 6, true)
	for i, s in Cosmetics.Slots do
		local b = UI.button("", C.Lavender, function()
			slot = s
			render()
		end, { Size = UDim2.new(0.2, -5, 1, 0), LayoutOrder = i, Parent = slotBar })
		b.Name = s
		UI.bind(b, "Slot_" .. s)
	end
	list = UI.scroll(right, { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 1, -54) })
	UI.list(list, 6)
	window.OnOpen = function()
		previewEquip = State.Data and table.clone(State.Data.Cosmetics.Equipped) or {}
		rebuildPreview()
		render()
	end
end

function WardrobeController:Start()
	State.DataChanged:Connect(function(d)
		if window.IsOpen() and d then
			previewEquip = table.clone(d.Cosmetics.Equipped)
			rebuildPreview()
			render()
		end
	end)
	State.LanguageChanged:Connect(render)
	RunService.RenderStepped:Connect(function(dt)
		if preview and window.IsOpen() then
			spin += dt * 0.6
			preview:PivotTo(CFrame.Angles(0, spin, 0))
		end
	end)
end

return WardrobeController
