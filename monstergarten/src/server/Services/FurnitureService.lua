-- FurnitureService: furniture HP + repairs, electricity (blackouts / panel), curtains and the yard gate.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local ServerUtil = require(script.Parent.Parent.ServerUtil)
local Interact = require(script.Parent.Parent.Interact)

local FurnitureService = {}
local S

local function setTint(model: Model, ratio: number)
	-- Darken furniture as it breaks; remember original colours once.
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local orig = p:GetAttribute("OrigColor")
			if not orig then
				p:SetAttribute("OrigColor", p.Color)
				orig = p.Color
			end
			p.Color = (orig :: Color3):Lerp(Color3.fromRGB(45, 35, 30), (1 - ratio) * 0.6)
		end
	end
end

function FurnitureService:Damage(session, model: Model, amount: number)
	local f = session.Furniture[model]
	if not f or amount <= 0 then
		return
	end
	local before = f.HP
	f.HP = math.max(0, f.HP - amount)
	model:SetAttribute("HP", math.floor(f.HP))
	local ratio = f.HP / f.MaxHP
	if math.floor(before / f.MaxHP * 10) ~= math.floor(ratio * 10) then
		setTint(model, ratio)
	end
	if f.Prompt then
		f.Prompt.Enabled = f.HP < f.MaxHP * 0.95
	end
end

function FurnitureService:Repair(session, model: Model, player: Player?)
	local f = session.Furniture[model]
	if not f then
		return
	end
	f.HP = f.MaxHP
	model:SetAttribute("HP", f.MaxHP)
	setTint(model, 1)
	if f.Prompt then
		f.Prompt.Enabled = false
	end
	if player then
		session:AddAction(player)
		S.QuestService:Track(player, "Repaired", 1)
	end
	session:Effect("Sparkle", { Position = model:GetPivot().Position + Vector3.new(0, 2, 0) })
end

function FurnitureService:BuildingHealth(session): number
	local sum, n = 0, 0
	for _, f in session.Furniture do
		sum += f.HP / f.MaxHP
		n += 1
	end
	return if n > 0 then math.floor(sum / n * 100) else 100
end

function FurnitureService:Nearest(session, pos: Vector3, radius: number, filter: ((Model) -> boolean)?): Model?
	local best, bestD = nil, radius
	for model in session.Furniture do
		if model.Parent and (not filter or filter(model)) then
			local p = model:GetPivot().Position
			local d = (Vector3.new(p.X, pos.Y, p.Z) - pos).Magnitude
			if d < bestD then
				best, bestD = model, d
			end
		end
	end
	return best
end

-- Electricity -------------------------------------------------------------------------

function FurnitureService:SetPower(session, on: boolean)
	if session.PowerOn == on then
		return
	end
	session.PowerOn = on
	session.Model:SetAttribute("PowerOn", on)
	for _, light in CollectionService:GetTagged("RoomLight") do
		if light:IsDescendantOf(session.Model) and light:IsA("Light") then
			light.Enabled = on
		end
	end
	for _, bulb in session:Tagged("LampBulb") do
		(bulb :: BasePart).Material = if on then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
	for _, panel in session:Tagged("ElectricPanel") do
		local led = panel:FindFirstChild("Led", true) :: BasePart?
		if led then
			led.Color = if on then Color3.fromRGB(110, 220, 120) else Color3.fromRGB(235, 70, 70)
		end
		local lever = panel:FindFirstChild("Lever", true) :: BasePart?
		if lever then
			local base = lever:GetAttribute("BaseCF") or lever.CFrame
			lever:SetAttribute("BaseCF", base)
			lever.CFrame = if on then base else base * CFrame.Angles(math.rad(60), 0, 0)
		end
		local pp = panel:FindFirstChild("Prompt_RestorePower", true) :: ProximityPrompt?
		if pp then
			pp.Enabled = not on
		end
	end
	session:Sound(if on then "Env_PowerOn" else "Env_PowerOff")
	session:Effect("Power", { On = on })
	if not on then
		session:Notify("Toast_PowerOut", "bad")
		S.ChaosService:OnPowerChanged(session, false)
	else
		S.ChaosService:OnPowerChanged(session, true)
	end
	S.EventService:OnPower(session, on)
end

-- Curtains -------------------------------------------------------------------------------

function FurnitureService:SetCurtains(session, closed: boolean)
	session.CurtainsClosed = closed
	for _, c in session:Tagged("Curtain") do
		local part = c :: BasePart
		local cf = part:GetAttribute(if closed then "ClosedCF" else "OpenCF")
		local size = part:GetAttribute(if closed then "ClosedSize" else "OpenSize")
		if typeof(cf) == "CFrame" and typeof(size) == "Vector3" then
			TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { CFrame = cf, Size = size }):Play()
		end
	end
	for _, z in session:Tagged("DarkZone") do
		if z:GetAttribute("Room") then
			z:SetAttribute("Active", closed)
		end
	end
	session.Model:SetAttribute("CurtainsClosed", closed)
end

-- Gate --------------------------------------------------------------------------------------

function FurnitureService:SetGate(session, open: boolean)
	local g = session.Gate
	if not g or g.Open == open then
		return
	end
	g.Open = open
	g.Model:SetAttribute("Open", open)
	local doors = g.Model:FindFirstChild("Doors")
	if doors then
		for _, d in doors:GetChildren() do
			local cf = d:GetAttribute(if open then "OpenCF" else "ClosedCF")
			if typeof(cf) == "CFrame" then
				TweenService:Create(d, TweenInfo.new(0.8, Enum.EasingStyle.Back), { CFrame = cf }):Play()
				d.CanCollide = not open
			end
		end
	end
	if g.Prompt then
		g.Prompt.ActionText = if open then "Close gate" else "Open gate"
	end
	session:Sound("Env_DoorOpen", g.Inside)
end

-- Session --------------------------------------------------------------------------------------

function FurnitureService:SetupSession(session)
	session.Furniture = {}
	for _, m in session:Tagged("Furniture") do
		if m:IsA("Model") then
			local max = m:GetAttribute("MaxHP") or 100
			local f = { HP = max, MaxHP = max }
			local root = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
			if root then
				f.Prompt = ServerUtil.prompt(root, "Repair", { Text = "Repair", Object = m.Name, Need = "Tool:Hammer", Hold = S.ToolService:ToolStat(session, "Hammer", "Time") or 3, Distance = 8 })
				f.Prompt.Enabled = false
			end
			session.Furniture[m] = f
		end
	end
	for _, panel in session:Tagged("ElectricPanel") do
		local root = (panel :: Model).PrimaryPart
		if root then
			local pp = ServerUtil.prompt(root, "RestorePower", { Text = "Restore power", Object = "Panel", Need = "Any", Hold = 3, Distance = 8 })
			pp.Enabled = false
		end
	end
	for _, sw in session:Tagged("CurtainSwitch") do
		local root = (sw :: Model).PrimaryPart
		if root then
			ServerUtil.prompt(root, "Curtains", { Text = "Curtains", Object = "Switch", Need = "Any", Distance = 7 })
		end
	end
	local gateModel = session:Tagged("Gate")[1]
	if gateModel then
		local outside = gateModel:FindFirstChild("Outside") :: BasePart?
		local root = (gateModel :: Model).PrimaryPart :: BasePart
		session.Gate = {
			Model = gateModel,
			Open = false,
			Outside = if outside then outside.Position - Vector3.new(0, 1.8, 0) else root.Position,
			Inside = (root.CFrame * CFrame.new(0, -3, 6)).Position,
		}
		session.Gate.Prompt = ServerUtil.prompt(root, "Gate", { Text = "Open gate", Object = "Gate", Need = "Any", Distance = 9 })
	end
	session.Model:SetAttribute("PowerOn", true)
	session.Model:SetAttribute("CurtainsClosed", false)
end

function FurnitureService:Init(services)
	S = services
	Interact.on("Repair", function(player, prompt, session)
		if not session then
			return
		end
		local held = S.ToolService:GetHeld(player)
		if not held or held.Id ~= "Hammer" then
			return
		end
		for model in session.Furniture do
			if prompt:IsDescendantOf(model) then
				session:Sound("Tool_Hammer", model:GetPivot().Position)
				self:Repair(session, model, player)
				return
			end
		end
	end)
	Interact.on("RestorePower", function(player, _, session)
		if session and not session.PowerOn then
			self:SetPower(session, true)
			session:AddAction(player, 2)
		end
	end)
	Interact.on("Curtains", function(player, _, session)
		if session then
			self:SetCurtains(session, not session.CurtainsClosed)
			session:AddAction(player)
		end
	end)
	Interact.on("Gate", function(player, _, session)
		if session and session.Gate then
			self:SetGate(session, not session.Gate.Open)
		end
	end)
end

return FurnitureService
