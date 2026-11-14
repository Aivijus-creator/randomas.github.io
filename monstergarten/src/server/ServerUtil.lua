-- Server helpers: messaging, effects broadcast, rate limiting, range checks, part factory helpers.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local GameSettings = require(Shared.Config.GameSettings)

local ServerUtil = {}

local buckets: { [Player]: { [string]: { tokens: number, last: number } } } = {}
Players.PlayerRemoving:Connect(function(p)
	buckets[p] = nil
end)

-- Token bucket rate limiter. Returns true if the action is allowed.
function ServerUtil.rateLimit(player: Player, key: string, perSecond: number?): boolean
	local rate = perSecond or GameSettings.RateLimitPerSecond
	local pb = buckets[player]
	if not pb then
		pb = {}
		buckets[player] = pb
	end
	local b = pb[key]
	local now = os.clock()
	if not b then
		b = { tokens = rate, last = now }
		pb[key] = b
	end
	b.tokens = math.min(rate, b.tokens + (now - b.last) * rate)
	b.last = now
	if b.tokens >= 1 then
		b.tokens -= 1
		return true
	end
	return false
end

function ServerUtil.root(player: Player): BasePart?
	local char = player.Character
	if not char then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function ServerUtil.humanoid(player: Player): Humanoid?
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function ServerUtil.inRange(player: Player, pos: Vector3, range: number?): boolean
	local r = ServerUtil.root(player)
	if not r then
		return false
	end
	return (r.Position - pos).Magnitude <= (range or GameSettings.InteractRange)
end

function ServerUtil.notify(player: Player, msg: any, kind: string?)
	Remotes.event("Notify"):FireClient(player, msg, kind or "info")
end

function ServerUtil.notifyAll(players: { Player }, msg: any, kind: string?)
	for _, p in players do
		Remotes.event("Notify"):FireClient(p, msg, kind or "info")
	end
end

function ServerUtil.effect(players: { Player }, name: string, payload: any)
	local ev = Remotes.event("Effect")
	for _, p in players do
		if p.Parent then
			ev:FireClient(p, name, payload)
		end
	end
end

function ServerUtil.sound(players: { Player }, name: string, pos: Vector3?)
	local ev = Remotes.event("Sound")
	for _, p in players do
		if p.Parent then
			ev:FireClient(p, name, pos)
		end
	end
end

function ServerUtil.shake(players: { Player }, intensity: number, pos: Vector3?, radius: number?)
	local ev = Remotes.event("CameraShake")
	for _, p in players do
		if p.Parent then
			ev:FireClient(p, intensity, pos, radius)
		end
	end
end

-- Teleport a character to a CFrame safely.
function ServerUtil.teleport(player: Player, cf: CFrame)
	local char = player.Character
	if char then
		char:PivotTo(cf + Vector3.new(0, 3, 0))
	end
end

-- Generic ProximityPrompt factory. Prompts use the custom style rendered by the client.
function ServerUtil.prompt(parent: Instance, action: string, opts: { [string]: any }?): ProximityPrompt
	local o = opts or {}
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "Prompt_" .. action
	pp.ActionText = o.Text or action
	pp.ObjectText = o.Object or ""
	pp.KeyboardKeyCode = o.Key or Enum.KeyCode.E
	pp.GamepadKeyCode = o.Pad or Enum.KeyCode.ButtonX
	pp.HoldDuration = o.Hold or 0
	pp.MaxActivationDistance = o.Distance or 7
	pp.RequiresLineOfSight = false
	pp.Style = Enum.ProximityPromptStyle.Custom
	pp.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	pp:SetAttribute("Action", action)
	game:GetService("CollectionService"):AddTag(pp, "MGPrompt")
	if o.Need then
		pp:SetAttribute("NeedHeld", o.Need) -- client filter hint, e.g. "Empty", "Tool:Extinguisher", "Kind:Dish"
	end
	pp.Parent = parent
	return pp
end

-- Part helper used by gameplay services (not the map builder).
function ServerUtil.part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = true
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

-- Raycast down to find floor Y below a point (ignoring characters/babies/effects).
local floorParams = RaycastParams.new()
floorParams.FilterType = Enum.RaycastFilterType.Include
function ServerUtil.floorY(origin: Vector3, includeRoot: Instance): number?
	floorParams.FilterDescendantsInstances = { includeRoot }
	local result = workspace:Raycast(origin + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), floorParams)
	if result then
		return result.Position.Y
	end
	return nil
end

return ServerUtil
