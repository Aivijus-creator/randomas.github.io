-- QueueController: panel shown while waiting at a shift door (players, difficulty, start now, leave,
-- Head Nanny baby picker). Also hides the tutorial door once the tutorial is done.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Strings = require(Shared.Strings)
local Difficulty = require(Shared.Config.Difficulty)
local Babies = require(Shared.Config.Babies)
local P = require(Shared.Logic.ProgressionMath)
local State = require(script.Parent.Parent.State)
local UI = require(script.Parent.Parent.UI.Components)

local player = Players.LocalPlayer
local C = UI.Theme.Colors
local QueueController = {}
local panel: Frame
local title: TextLabel
local avatars: Frame
local diffRow: Frame
local startBtn: TextButton
local babyRow: Frame
local current: any = nil
local thumbs: { [number]: string } = {}
local picked: { string } = {}

local function thumb(userId: number): string
	if thumbs[userId] then
		return thumbs[userId]
	end
	local ok, img = pcall(Players.GetUserThumbnailAsync, Players, userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	thumbs[userId] = if ok then img else ""
	return thumbs[userId]
end

local function render()
	local q = current
	panel.Visible = q ~= nil
	if not q then
		return
	end
	local isHost = q.Host == player.UserId
	local modeKey = if q.Mode == "Shift" then "Queue_Title" elseif q.Mode == "Solo" then "Queue_Solo" else "Queue_Tutorial"
	if q.Waiting then
		title.Text = Strings.t("Queue_Waiting")
	elseif q.Countdown then
		title.Text = Strings.t(modeKey) .. "  ⏱ " .. Strings.t("Queue_Starting", q.Countdown)
	else
		title.Text = Strings.t(modeKey)
	end
	for _, c in avatars:GetChildren() do
		if c:IsA("ImageLabel") then
			c:Destroy()
		end
	end
	for i, uid in q.Players do
		local img = UI.new("ImageLabel", { Size = UDim2.fromOffset(52, 52), BackgroundColor3 = if uid == q.Host then C.Yellow else C.Lavender, Image = "", LayoutOrder = i, Parent = avatars })
		UI.corner(img, UDim.new(1, 0))
		task.spawn(function()
			img.Image = thumb(uid)
		end)
	end
	local d = State.Data
	local level = d and P.daycareLevel(d.TotalStars) or 1
	for _, b in diffRow:GetChildren() do
		if b:IsA("TextButton") then
			local id = b.Name
			local def = Difficulty.Defs[id]
			local unlocked = level >= def.UnlockLevel or (d and d.DebugUnlockAll)
			b.BackgroundColor3 = if q.Difficulty == id then C.Yellow elseif unlocked then def.Color else Color3.fromRGB(180, 180, 180)
			b.Text = Strings.t("Difficulty_" .. id) .. (if unlocked then "" else (" 🔒" .. def.UnlockLevel))
			b.AutoButtonColor = false
		end
	end
	diffRow.Visible = q.Mode == "Shift" or q.Mode == "Solo"
	startBtn.Visible = isHost and q.Mode ~= "Tutorial"
	babyRow.Visible = isHost and player:GetAttribute("HeadNanny") == true and q.Mode ~= "Tutorial"
end

local function buildBabyRow()
	for _, c in babyRow:GetChildren() do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local d = State.Data
	for i, id in Babies.Order do
		local def = Babies.Defs[id]
		local unlocked = d and (P.isUnlocked(d.TotalStars, "Baby:" .. id) or d.DebugUnlockAll)
		if unlocked then
			local b = UI.button(def.Emoji, if table.find(picked, id) then C.Yellow else C.Cream, nil, { Size = UDim2.fromOffset(44, 44), LayoutOrder = i, Parent = babyRow })
			b.Activated:Connect(function()
				local at = table.find(picked, id)
				if at then
					table.remove(picked, at)
				else
					table.insert(picked, id)
				end
				b.BackgroundColor3 = if table.find(picked, id) then C.Yellow else C.Cream
				Remotes.event("QueueAction"):FireServer("Babies", picked)
			end)
		end
	end
end

function QueueController:Init()
	local gui = UI.screen("QueueGui", 8)
	panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(560, 230), Visible = false, Parent = gui }, C.Cream)
	title = UI.label("", { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 34), Parent = panel })
	avatars = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 46), Size = UDim2.new(1, -28, 0, 54), Parent = panel })
	UI.list(avatars, 6, true, Enum.HorizontalAlignment.Center)
	diffRow = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 106), Size = UDim2.new(1, -28, 0, 44), Parent = panel })
	UI.list(diffRow, 8, true, Enum.HorizontalAlignment.Center)
	for i, id in Difficulty.Order do
		local b = UI.button(id, Difficulty.Defs[id].Color, function()
			if not current then
				return
			end
			local hud = State.Controllers.HUDController
			if current.Host ~= player.UserId then
				if hud then
					hud:Toast("Queue_OnlyHost", "error")
				end
				return
			end
			local d = State.Data
			local def = Difficulty.Defs[id]
			if d and P.daycareLevel(d.TotalStars) < def.UnlockLevel and not d.DebugUnlockAll then
				if hud then
					hud:Toast({ "Queue_LockedLevel", "Difficulty_" .. id, def.UnlockLevel }, "error")
				end
				return
			end
			Remotes.event("QueueAction"):FireServer("Difficulty", id)
		end, { Size = UDim2.fromOffset(160, 44), LayoutOrder = i, Parent = diffRow })
		b.Name = id
	end
	babyRow = UI.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, -54), Size = UDim2.new(1, -28, 0, 46), Parent = panel })
	UI.list(babyRow, 4, true, Enum.HorizontalAlignment.Center)
	startBtn = UI.button("", C.Mint, function()
		Remotes.event("QueueAction"):FireServer("StartNow")
	end, { Position = UDim2.new(0.5, -180, 1, -60), Size = UDim2.fromOffset(170, 48), Parent = panel })
	UI.bind(startBtn, "Queue_StartNow")
	local leave = UI.button("", C.Pink, function()
		Remotes.event("QueueAction"):FireServer("Leave")
	end, { Position = UDim2.new(0.5, 10, 1, -60), Size = UDim2.fromOffset(170, 48), Parent = panel })
	UI.bind(leave, "Queue_Leave")
end

function QueueController:Start()
	Remotes.event("QueueUpdate").OnClientEvent:Connect(function(state)
		local wasNil = current == nil
		current = state
		if state and wasNil then
			picked = state.PreferredBabies and table.clone(state.PreferredBabies) or {}
			buildBabyRow()
		end
		render()
	end)
	State.LanguageChanged:Connect(render)
	-- hide the tutorial door after the tutorial is done
	State.DataChanged:Connect(function(d)
		for _, door in CollectionService:GetTagged("QueueDoor") do
			if door:GetAttribute("DoorId") == "Tutorial" then
				for _, p in door:GetDescendants() do
					if p:IsA("BasePart") then
						p.LocalTransparencyModifier = if d and d.TutorialDone then 0.85 else 0
					end
				end
			end
		end
	end)
end

return QueueController
