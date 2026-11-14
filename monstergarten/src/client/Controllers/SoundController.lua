-- SoundController: SoundRegistry for SFX (2D or 3D), music with crossfades, ambience. Ids of 0 are skipped silently.
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Assets = require(Shared.Config.Assets)
local State = require(script.Parent.Parent.State)

local SoundController = {}
local Controllers
local musicGroup: SoundGroup
local sfxGroup: SoundGroup
local currentMusic: Sound? = nil
local currentMusicName: string? = nil
local ambience: { [string]: Sound } = {}
local musicBoxTrack: number? = nil

local function asset(id: number): string
	return "rbxassetid://" .. tostring(id)
end

function SoundController:Play(name: string, position: Vector3?)
	local id = Assets.Sounds[name]
	if not id or id == 0 then
		return
	end
	local props = Assets.SoundProps[name] or {}
	local s = Instance.new("Sound")
	s.SoundId = asset(id)
	s.Volume = props.Volume or 0.6
	s.SoundGroup = sfxGroup
	if position then
		local holder = Instance.new("Part")
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.Transparency = 1
		holder.Size = Vector3.one
		holder.CFrame = CFrame.new(position)
		holder.Parent = workspace
		s.RollOffMaxDistance = props.MaxDistance or 50
		s.RollOffMinDistance = 6
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.Parent = holder
		s:Play()
		Debris:AddItem(holder, 8)
	else
		s.Parent = SoundService
		s:Play()
		Debris:AddItem(s, 8)
	end
end

function SoundController:Music(name: string?)
	if name == currentMusicName then
		return
	end
	currentMusicName = name
	local id = name and Assets.Music[name] or 0
	if name == "Lobby" and musicBoxTrack then
		id = musicBoxTrack
	end
	local old = currentMusic
	if old then
		TweenService:Create(old, TweenInfo.new(1.5), { Volume = 0 }):Play()
		Debris:AddItem(old, 1.6)
	end
	currentMusic = nil
	if id and id ~= 0 then
		local s = Instance.new("Sound")
		s.SoundId = asset(id)
		s.Looped = true
		s.Volume = 0
		s.SoundGroup = musicGroup
		s.Parent = SoundService
		s:Play()
		TweenService:Create(s, TweenInfo.new(1.5), { Volume = 0.5 }):Play()
		currentMusic = s
	end
end

function SoundController:SetMusicBox(id: number?)
	musicBoxTrack = id
	if currentMusicName == "Lobby" then
		currentMusicName = nil
		self:Music("Lobby")
	end
end

local function setAmbience(name: string, on: boolean)
	local id = Assets.Sounds[name]
	if not id or id == 0 then
		return
	end
	local s = ambience[name]
	if on and not s then
		s = Instance.new("Sound")
		s.SoundId = asset(id)
		s.Looped = true
		s.Volume = 0.3
		s.SoundGroup = sfxGroup
		s.Parent = SoundService
		s:Play()
		ambience[name] = s
	elseif not on and s then
		s:Destroy()
		ambience[name] = nil
	end
end

function SoundController:ApplyVolumes(settings)
	musicGroup.Volume = settings.MusicVolume or 0.5
	sfxGroup.Volume = settings.SfxVolume or 0.8
end

function SoundController:Init(c)
	Controllers = c
	musicGroup = Instance.new("SoundGroup")
	musicGroup.Name = "Music"
	musicGroup.Parent = SoundService
	sfxGroup = Instance.new("SoundGroup")
	sfxGroup.Name = "SFX"
	sfxGroup.Parent = SoundService
	local UI = require(script.Parent.Parent.UI.Components)
	UI.setClickSound(function()
		SoundController:Play("UI_Click")
	end)
end

local function countTantrums(): number
	local n = 0
	local slot = State.Shift and State.Shift.Slot
	for _, b in CollectionService:GetTagged("Baby") do
		if b:GetAttribute("Session") == slot and (b:GetAttribute("Tantrum") or "") ~= "" then
			n += 1
		end
	end
	return n
end

function SoundController:Start()
	Remotes.event("Sound").OnClientEvent:Connect(function(name, pos)
		self:Play(name, pos)
	end)
	State.DataChanged:Connect(function(d)
		if d and d.Settings then
			self:ApplyVolumes(d.Settings)
		end
	end)
	self:Music("Lobby")
	setAmbience("Env_Crickets", true)
	task.spawn(function()
		while true do
			task.wait(1)
			local shift = State.Shift
			if shift then
				setAmbience("Env_Crickets", false)
				setAmbience("Env_Birds", shift.Clock < 17)
				local storm = false
				local dc = workspace:FindFirstChild("Daycares")
				local m = dc and dc:FindFirstChild("Daycare_" .. tostring(shift.Slot))
				if m then
					storm = m:GetAttribute("Storm") == true
					if m:GetAttribute("FullMoon") then
						self:Music("FullMoon")
						setAmbience("Env_Rain", storm)
						continue
					end
				end
				setAmbience("Env_Rain", storm)
				if shift.Tutorial then
					self:Music("Tutorial")
				elseif countTantrums() >= 3 then
					self:Music("ShiftIntense")
				else
					self:Music("ShiftCalm")
				end
			elseif not (Controllers.ResultsController and Controllers.ResultsController.Showing) then
				setAmbience("Env_Birds", false)
				setAmbience("Env_Rain", false)
				setAmbience("Env_Crickets", true)
				self:Music("Lobby")
			end
		end
	end)
end

return SoundController
