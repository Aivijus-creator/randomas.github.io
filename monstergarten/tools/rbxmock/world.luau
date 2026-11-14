-- Builds the DataModel (services), loads the Rojo project tree, provides globals + require.
local R = RUNTIME
local T = R.T
local V3, CF = T.Vector3, T.CFrame
local new = R.newInstance

local game = new("DataModel")
game.__props.Name = "Game"
R.game = game
local services = {}
R.services = services
local function svc(name, cls)
	local s = new(cls or name)
	s.__props.Name = name
	s.Parent = game
	services[name] = s
	return s
end
local workspace = svc("Workspace")
local CurrentCamera = new("Camera")
CurrentCamera.__props.ViewportSize = T.Vector2.new(1280, 720)
CurrentCamera.__props.CFrame = CF.new()
workspace.__props.CurrentCamera = CurrentCamera
for _, n in { "Players", "Lighting", "ReplicatedStorage", "ServerStorage", "ServerScriptService", "StarterPlayer", "StarterGui", "SoundService", "RunService",
	"CollectionService", "PathfindingService", "TweenService", "ProximityPromptService", "MarketplaceService", "TextService", "DataStoreService", "Debris",
	"UserInputService", "HttpService", "ContentProvider", "TeleportService", "ReplicatedFirst", "Chat", "Teams" } do
	svc(n)
end

-- game methods
game.__methods = {
	GetService = function(_, n) return services[n] or error("no service " .. n) end,
	BindToClose = function(_, fn) R.closeHandlers = R.closeHandlers or {} table.insert(R.closeHandlers, fn) end,
}
game.__props.JobId = ""
game.__props.PlaceId = 0
game.__props.CreatorId = 0
game.__props.CreatorType = T.Enum.CreatorType.User

-- RunService
services.RunService.__methods = {
	IsStudio = function() return true end,
	IsServer = function() return true end,
	IsClient = function() return true end,
	IsRunning = function() return true end,
	BindToRenderStep = function() end,
	UnbindFromRenderStep = function() end,
}

-- CollectionService
local tags = {} -- tag -> set
local instTags = setmetatable({}, { __mode = "k" })
local tagAdded, tagRemoved = {}, {}
function R.addTag(inst, t)
	tags[t] = tags[t] or {}
	if tags[t][inst] then return end
	tags[t][inst] = true
	instTags[inst] = instTags[inst] or {}
	instTags[inst][t] = true
	if tagAdded[t] and R.rootOf(inst) == game then tagAdded[t]:Fire(inst) end
end
function R.tagsOf(inst) local out = {} for t in instTags[inst] or {} do table.insert(out, t) end return out end
R.onAddedToGame = function(inst)
	for t in instTags[inst] or {} do if tagAdded[t] then tagAdded[t]:Fire(inst) end end
end
services.CollectionService.__methods = {
	AddTag = function(_, inst, t) R.addTag(inst, t) end,
	RemoveTag = function(_, inst, t) if tags[t] then tags[t][inst] = nil end if instTags[inst] then instTags[inst][t] = nil end if tagRemoved[t] then tagRemoved[t]:Fire(inst) end end,
	HasTag = function(_, inst, t) return tags[t] ~= nil and tags[t][inst] == true end,
	GetTags = function(_, inst) return R.tagsOf(inst) end,
	GetTagged = function(_, t)
		local out = {}
		for inst in tags[t] or {} do if not rawget(inst, "__destroyed") and R.rootOf(inst) == game then table.insert(out, inst) end end
		return out
	end,
	GetInstanceAddedSignal = function(_, t) tagAdded[t] = tagAdded[t] or R.newSignal() return tagAdded[t] end,
	GetInstanceRemovedSignal = function(_, t) tagRemoved[t] = tagRemoved[t] or R.newSignal() return tagRemoved[t] end,
}
-- Instance methods AddTag/HasTag
local Inst = getmetatable(new("Folder")).__index
R.IMT.__index = (function(old)
	return function(o, k)
		local mm = rawget(o, "__methods")
		if mm and mm[k] then return mm[k] end
		if k == "AddTag" then return function(self, t) R.addTag(self, t) end end
		if k == "HasTag" then return function(self, t) return tags[t] ~= nil and tags[t][self] == true end end
		if k == "RemoveTag" then return function(self, t) services.CollectionService.__methods.RemoveTag(nil, self, t) end end
		if k == "GetTags" then return function(self) return R.tagsOf(self) end end
		return old(o, k)
	end
end)(R.IMT.__index)

-- Workspace raycast (good enough for floors: vertical rays against Include lists)
workspace.__methods = {
	Raycast = function(_, origin, dir, params)
		local list = params and params.FilterDescendantsInstances or {}
		if math.abs(dir.X) > 0.01 or math.abs(dir.Z) > 0.01 or dir.Y >= 0 then return nil end
		local best = nil
		local function test(p)
			local c, s = p.__props.CFrame, p.__props.Size
			local rel = c:PointToObjectSpace(origin)
			if math.abs(rel.X) <= s.X / 2 and math.abs(rel.Z) <= s.Z / 2 then
				local top = (c * V3.new(0, s.Y / 2, 0)).Y
				if top <= origin.Y and top >= origin.Y + dir.Y and (not best or top > best) then best = top end
			end
		end
		for _, root in list do
			for _, p in R.partsOf(root) do if p.__props.CanCollide or p.__props.CanQuery then test(p) end end
		end
		if best then return { Position = V3.new(origin.X, best, origin.Z), Normal = V3.new(0, 1, 0) } end
		return nil
	end,
	GetPartBoundsInRadius = function() return {} end,
	GetServerTimeNow = function() return R.now() end,
}
-- Pathfinding: straight line in 3-stud steps
services.PathfindingService.__methods = {
	CreatePath = function()
		local path = { Status = T.Enum.PathStatus.Success, pts = {} }
		function path:ComputeAsync(a, b)
			R.task.wait(0.02)
			self.pts = {}
			local n = math.max(1, math.floor((b - a).Magnitude / 3))
			for i = 0, n do table.insert(self.pts, { Position = a:Lerp(b, i / n) }) end
		end
		function path:GetWaypoints() return self.pts end
		return path
	end,
}
services.TweenService.__methods = {
	Create = function(_, inst, info, props)
		local t = { Completed = R.newSignal() }
		function t:Play() for k, v in props do inst[k] = v end t.Completed:Fire(T.Enum.PlaybackState.Completed) end
		function t:Cancel() end
		function t:Pause() end
		return t
	end,
}
services.DataStoreService.__methods = {
	GetDataStore = function() error("Studio access to API services is not enabled (mock)") end,
	GetOrderedDataStore = function() error("Studio access to API services is not enabled (mock)") end,
}
services.MarketplaceService.__methods = {
	UserOwnsGamePassAsync = function() return false end,
	PromptGamePassPurchase = function() end,
	PromptProductPurchase = function() end,
	GetProductInfo = function() return { PriceInRobux = 99 } end,
}
services.TextService.__methods = {
	FilterStringAsync = function(_, text) return { GetNonChatStringForBroadcastAsync = function() return text end } end,
}
services.Debris.__methods = { AddItem = function(_, inst, t) R.task.delay(t or 10, function() inst:Destroy() end) end }
services.UserInputService.__props.TouchEnabled = false
services.UserInputService.__props.KeyboardEnabled = true
services.UserInputService.__props.GamepadEnabled = false
services.UserInputService.__methods = { GetFocusedTextBox = function() return nil end, GetLastInputType = function() return T.Enum.UserInputType.Keyboard end }
services.ContentProvider.__methods = { PreloadAsync = function() end }
services.HttpService.__methods = { GenerateGUID = function() return "guid" end }

-- Players
local Players = services.Players
local playerCount = 0
Players.__methods = {
	GetPlayers = function() local out = {} for _, c in Players.__children do if c.__class == "Player" then table.insert(out, c) end end return out end,
	GetPlayerFromCharacter = function(_, char) for _, c in Players.__children do if c.__props.Character == char then return c end end return nil end,
	GetPlayerByUserId = function(_, id) for _, c in Players.__children do if c.__props.UserId == id then return c end end return nil end,
	GetNameFromUserIdAsync = function(_, id) return "User" .. id end,
	GetUserThumbnailAsync = function() return "", true end,
}
function R.makeCharacter(player, pos)
	local char = new("Model")
	char.__props.Name = player.__props.Name
	local hrp = new("Part")
	hrp.__props.Name = "HumanoidRootPart"
	hrp.__props.Size = V3.new(2, 2, 1)
	hrp.__props.CFrame = CF.new(pos)
	hrp.Parent = char
	char.__props.PrimaryPart = hrp
	for _, n in { "Head", "UpperTorso", "LowerTorso", "RightUpperArm", "LeftUpperArm" } do
		local p = new("Part")
		p.__props.Name = n
		p.__props.Size = V3.new(1, 1, 1)
		p.__props.CFrame = CF.new(pos + V3.new(0, 1.5, 0))
		p.Parent = char
	end
	for _, n in { "RightShoulder", "LeftShoulder" } do
		local m = new("Motor6D")
		m.__props.Name = n
		m.__props.C0 = CF.new()
		m.Parent = char:FindFirstChild(n:find("Right") and "RightUpperArm" or "LeftUpperArm")
	end
	local hum = new("Humanoid")
	hum.Parent = char
	char.Parent = workspace
	player.__props.Character = char
	R.signalOf(player, "CharacterAdded"):Fire(char)
	return char
end
function R.addPlayer(name, userId)
	playerCount += 1
	local p = new("Player")
	p.__props.Name = name
	p.__props.DisplayName = name
	p.__props.UserId = userId or playerCount
	p.__props.LocaleId = "lt-lt"
	p.__methods = {
		Kick = function(self, msg) print("KICK", msg) end,
		RequestStreamAroundAsync = function() end,
		LoadCharacter = function(self) R.makeCharacter(self, V3.new(0, 5, 18)) end,
		GetMouse = function() return {} end,
	}
	local pg = new("PlayerGui")
	pg.__props.Name = "PlayerGui"
	pg.Parent = p
	p.Parent = Players
	R.signalOf(Players, "PlayerAdded"):Fire(p)
	R.makeCharacter(p, V3.new(0, 5, 18))
	return p
end

-- project tree from the Rojo layout ------------------------------------------------------
local ROOT = PROJECT_ROOT
local function scriptInst(cls, name, path)
	local s = new(cls)
	s.__props.Name = name
	s.__source = path
	return s
end
local function buildDir(path, parent)
	for _, f in __listdir(path) do
		local p = path .. "/" .. f
		if __isdir(p) then
			if __isfile(p .. "/init.lua") then
				local m = scriptInst("ModuleScript", f, p .. "/init.lua")
				m.Parent = parent
				buildDir(p, m)
			else
				local fo = new("Folder")
				fo.__props.Name = f
				fo.Parent = parent
				buildDir(p, fo)
			end
		elseif f:match("%.server%.lua$") then
			scriptInst("Script", f:gsub("%.server%.lua$", ""), p).Parent = parent
		elseif f:match("%.client%.lua$") then
			scriptInst("LocalScript", f:gsub("%.client%.lua$", ""), p).Parent = parent
		elseif f:match("%.lua$") and f ~= "init.lua" then
			scriptInst("ModuleScript", f:gsub("%.lua$", ""), p).Parent = parent
		end
	end
end
local function folder(name, parent) local f = new("Folder") f.__props.Name = name f.Parent = parent return f end
local shared = folder("Shared", services.ReplicatedStorage)
buildDir(ROOT .. "/src/shared", shared)
local assets = folder("Assets", services.ReplicatedStorage)
for _, n in { "Babies", "Parents", "NPCs", "Icons" } do folder(n, assets) end
local server = folder("Server", services.ServerScriptService)
buildDir(ROOT .. "/src/server", server)
folder("Maps", services.ServerStorage)
local sps = new("StarterPlayerScripts")
sps.__props.Name = "StarterPlayerScripts"
sps.Parent = services.StarterPlayer
local client = folder("Client", sps)
buildDir(ROOT .. "/src/client", client)
R.ServerFolder = server
R.ClientFolder = client

-- globals + require ----------------------------------------------------------------------
local cache = {}
local env = {}
local function typeof(v)
	if type(v) == "table" then
		local mt = getmetatable(v)
		if mt and mt.__type then return mt.__type end
	end
	return type(v)
end
function env.require(inst)
	if type(inst) ~= "table" or not rawget(inst, "__source") then error("require: not a ModuleScript: " .. tostring(inst), 2) end
	if cache[inst] ~= nil then return cache[inst] end
	local fn, err = __compile(__readfile(inst.__source), inst.__source)
	if not fn then error(err) end
	setfenv(fn, setmetatable({ script = inst }, { __index = env }))
	local res = fn()
	cache[inst] = res
	return res
end
function R.runScript(inst)
	local fn, err = __compile(__readfile(inst.__source), inst.__source)
	if not fn then error(err) end
	setfenv(fn, setmetatable({ script = inst }, { __index = env }))
	return R.task.spawn(fn)
end
local origOs = os
env.os = setmetatable({ clock = function() return R.now() end, time = function() return 1763100000 + math.floor(R.now()) end, date = origOs.date }, { __index = origOs })
env.tick = function() return R.now() end
env.time = function() return R.now() end
env.typeof = typeof
env.game = game
env.workspace = workspace
env.Workspace = workspace
env.Instance = R.Instance
env.task = R.task
env.wait = R.task.wait
env.delay = R.task.delay
env.spawn = R.task.spawn
env.warn = function(...) local s = table.concat(table.pack(...), " ", 1, select("#", ...)):gsub("table: %w+", "tbl") table.insert(R.Warnings, s) print("WARN:", ...) end
for k, v in T do if k ~= "metas" then env[k] = v end end
setmetatable(env, { __index = _G })
R.env = env
R.cache = cache
return R
