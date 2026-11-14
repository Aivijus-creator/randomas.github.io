-- LightingController: lobby dusk vs. shift day cycle (07:00 -> 19:00) per player, blackout darkness,
-- dark rooms, storm (rain + lightning) and the full-moon tint. Also drives clock hands, swings, mobiles etc.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local State = require(script.Parent.Parent.State)

local player = Players.LocalPlayer
local LightingController = {}
local Controllers
local rainPart: Part? = nil

local LOBBY = {
	ClockTime = 18.6,
	Brightness = 1.6,
	Ambient = Color3.fromRGB(95, 80, 120),
	OutdoorAmbient = Color3.fromRGB(130, 105, 150),
	FogColor = Color3.fromRGB(150, 120, 170),
}

local function daycare(): Model?
	local shift = State.Shift
	local dc = workspace:FindFirstChild("Daycares")
	return shift and dc and dc:FindFirstChild("Daycare_" .. tostring(shift.Slot)) :: Model?
end

local function roomOf(m: Model, pos: Vector3): string?
	local vols = m:FindFirstChild("RoomVolumes")
	if not vols then
		return nil
	end
	for _, v in vols:GetChildren() do
		if v:IsA("BasePart") then
			local rel = v.CFrame:PointToObjectSpace(pos)
			local h = v.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z then
				return v:GetAttribute("RoomName")
			end
		end
	end
	return nil
end

local function ensureRain(on: boolean)
	if on and not rainPart then
		local p = Instance.new("Part")
		p.Name = "LocalRain"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Transparency = 1
		p.Size = Vector3.new(120, 1, 120)
		p.Parent = workspace
		local e = Instance.new("ParticleEmitter")
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Color3.fromRGB(180, 200, 255))
		e.Size = NumberSequence.new(0.15)
		e.Transparency = NumberSequence.new(0.3)
		e.Rate = if Controllers.SettingsController:Quality() == "Low" then 150 else 500
		e.Lifetime = NumberRange.new(1, 1.4)
		e.Speed = NumberRange.new(60, 70)
		e.EmissionDirection = Enum.NormalId.Bottom
		e.LightEmission = 0.3
		e.Parent = p
		rainPart = p
	elseif not on and rainPart then
		rainPart:Destroy()
		rainPart = nil
	end
end

local lightningAt = 0
local function lightningFlash()
	local cc = Lighting:FindFirstChild("ColorCorrection") :: ColorCorrectionEffect?
	if cc then
		cc.Brightness = 0.5
		TweenService:Create(cc, TweenInfo.new(0.4), { Brightness = 0 }):Play()
	end
	if Controllers.SoundController then
		Controllers.SoundController:Play("Env_Thunder")
	end
end

function LightingController:Init(c)
	Controllers = c
end

function LightingController:Start()
	local dark = Lighting:WaitForChild("DarkCorrection", 10) :: ColorCorrectionEffect?
	local cc = Lighting:FindFirstChild("ColorCorrection") :: ColorCorrectionEffect?
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	local darkTarget = 0

	RunService.RenderStepped:Connect(function(dt)
		local shift = State.Shift
		local m = daycare()
		local char = player.Character
		local r = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local storm, fullMoon, powerOn = false, false, true
		if shift and m then
			storm = m:GetAttribute("Storm") == true
			fullMoon = m:GetAttribute("FullMoon") == true
			powerOn = m:GetAttribute("PowerOn") ~= false
			local clock = shift.Clock or 7
			if not shift.ClockFrozen and shift.Phase == "Playing" then
				-- extrapolate between 1 s state updates for a smooth sun
				shift.Clock = clock + dt * 12 / (shift.Duration or 480)
			end
			Lighting.ClockTime = Lighting.ClockTime + ((shift.Clock or 7) - Lighting.ClockTime) * math.min(1, dt * 2)
			local evening = math.clamp((Lighting.ClockTime - 16) / 3, 0, 1)
			Lighting.Brightness = (if storm then 1.2 else 2.4) - evening * 0.8
			Lighting.OutdoorAmbient = Color3.fromRGB(150, 145, 160):Lerp(Color3.fromRGB(170, 120, 110), evening)
			Lighting.Ambient = Color3.fromRGB(110, 105, 120)
			if atm then
				atm.Density = if storm then 0.5 else 0.25 + evening * 0.1
				atm.Color = Color3.fromRGB(220, 230, 245):Lerp(Color3.fromRGB(255, 180, 140), evening)
			end
			if cc then
				cc.TintColor = if fullMoon then Color3.fromRGB(210, 190, 255) else Color3.fromRGB(255, 245, 240)
			end
			-- darkness: blackout indoors, dark rooms
			local room = r and roomOf(m, r.Position)
			local indoor = room ~= nil and room ~= "Yard" and room ~= "Outside" and room ~= "Front"
			darkTarget = 0
			if not powerOn and indoor then
				darkTarget = -0.32
			elseif room == "Basement" then
				darkTarget = -0.15
			elseif room == "Bedroom" and m:GetAttribute("CurtainsClosed") then
				darkTarget = -0.2
			end
			if storm then
				ensureRain(true)
				if rainPart and r then
					rainPart.CFrame = CFrame.new(r.Position + Vector3.new(0, 40, 0))
				end
				if os.clock() > lightningAt then
					lightningAt = os.clock() + math.random(6, 14)
					lightningFlash()
				end
			else
				ensureRain(false)
			end
		else
			ensureRain(false)
			Lighting.ClockTime = LOBBY.ClockTime
			Lighting.Brightness = LOBBY.Brightness
			Lighting.Ambient = LOBBY.Ambient
			Lighting.OutdoorAmbient = LOBBY.OutdoorAmbient
			if atm then
				atm.Density = 0.35
				atm.Color = Color3.fromRGB(230, 190, 210)
			end
			if cc then
				cc.TintColor = Color3.fromRGB(255, 240, 245)
			end
			darkTarget = 0
		end
		if dark then
			dark.Brightness = dark.Brightness + (darkTarget - dark.Brightness) * math.min(1, dt * 4)
		end
	end)

	-- Ambient animations (cheap, local): mobiles, swings, clocks, drifting balloon, bobbing arrows, eyes, flicker.
	local t0 = os.clock()
	RunService.Heartbeat:Connect(function()
		local t = os.clock() - t0
		for _, m in CollectionService:GetTagged("Spinner") do
			if m:IsA("Model") and m.PrimaryPart then
				local base = m:GetAttribute("BaseCF")
				if not base then
					base = m:GetPivot()
					m:SetAttribute("BaseCF", base)
				end
				m:PivotTo(base * CFrame.Angles(0, t * (m:GetAttribute("Speed") or 0.5), 0))
			end
		end
		for _, seat in CollectionService:GetTagged("Swing") do
			local pivot = seat:GetAttribute("PivotCF")
			if seat:IsA("Model") and typeof(pivot) == "CFrame" then
				local base = seat:GetAttribute("BaseOffset")
				if not base then
					base = pivot:ToObjectSpace(seat:GetPivot())
					seat:SetAttribute("BaseOffset", base)
				end
				local angle = math.sin(t * 1.6 + (seat:GetAttribute("Phase") or 0)) * 0.35
				seat:PivotTo(pivot * CFrame.Angles(angle, 0, 0) * base)
			end
		end
		local clock = if State.Shift then (State.Shift.Clock or 7) else 18.5
		for _, hand in CollectionService:GetTagged("ClockHandHour") do
			local pivot = hand:GetAttribute("PivotCF")
			if typeof(pivot) == "CFrame" and hand:IsA("BasePart") then
				local a = (clock % 12) / 12 * math.pi * 2
				hand.CFrame = pivot * CFrame.Angles(0, 0, -a) * CFrame.new(0, (hand:GetAttribute("Length") or 1) / 2, 0)
			end
		end
		for _, hand in CollectionService:GetTagged("ClockHandMinute") do
			local pivot = hand:GetAttribute("PivotCF")
			if typeof(pivot) == "CFrame" and hand:IsA("BasePart") then
				local a = (clock % 1) * math.pi * 2
				hand.CFrame = pivot * CFrame.Angles(0, 0, -a) * CFrame.new(0, (hand:GetAttribute("Length") or 1) / 2, 0)
			end
		end
		for _, m in CollectionService:GetTagged("Drifter") do
			local c = m:GetAttribute("Center")
			if m:IsA("Model") and typeof(c) == "Vector3" then
				m:PivotTo(CFrame.new(c + Vector3.new(math.sin(t * 0.05) * 30, math.sin(t * 0.3) * 2, math.cos(t * 0.05) * 20)))
			end
		end
		for _, p in CollectionService:GetTagged("Bobber") do
			if p:IsA("BasePart") then
				local base = p:GetAttribute("BaseCF")
				if not base then
					base = p.CFrame
					p:SetAttribute("BaseCF", base)
				end
				p.CFrame = base + Vector3.new(0, math.sin(t * 3) * 0.6, 0)
			end
		end
		local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		for _, eye in CollectionService:GetTagged("LookingEye") do
			local center = eye:GetAttribute("Center")
			if eye:IsA("BasePart") and typeof(center) == "Vector3" and r then
				local d = r.Position - center
				local off = if d.Magnitude > 0.1 then d.Unit * 0.12 else Vector3.zero
				eye.Position = center + Vector3.new(off.X, math.clamp(off.Y, -0.08, 0.08), off.Z)
			end
		end
		for _, lamp in CollectionService:GetTagged("Flicker") do
			local light = lamp:FindFirstChildWhichIsA("PointLight", true)
			if light then
				local on = light:GetAttribute("ServerEnabled")
				if on == nil then
					light:SetAttribute("ServerEnabled", true)
				end
				light.Brightness = if math.noise(t * 3, lamp:GetPivot().Position.X) > 0.35 then 0.15 else 1.1
			end
		end
	end)
end

return LightingController
