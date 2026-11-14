-- Minimal Roblox engine mock: Instances, signals, services, task scheduler, require. Loaded via __compile.
local DIR = MOCK_DIR
local function load(path)
	local fn, err = __compile(__readfile(path), path)
	if not fn then error(err) end
	return fn()
end
local T = load(DIR .. "/types.luau")
local R = { Errors = {}, Warnings = {}, Log = {}, unknown = {}, lenient = true }
local V3, CF = T.Vector3, T.CFrame

-- scheduler -----------------------------------------------------------------------
local now = 0
local queue = {}
local dead = setmetatable({}, { __mode = "k" })
local function report(co, err)
	local msg = tostring(err) .. "\n" .. debug.traceback(co)
	table.insert(R.Errors, msg)
	print("ERROR: " .. msg)
end
local function resume(co, ...)
	if dead[co] or coroutine.status(co) == "dead" then return end
	local ok, err = coroutine.resume(co, ...)
	if not ok then report(co, err) end
end
local task = {}
function task.spawn(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	resume(co, ...)
	return co
end
function task.defer(f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	table.insert(queue, { t = now, co = co, args = { ... } })
	return co
end
function task.delay(d, f, ...)
	local co = type(f) == "thread" and f or coroutine.create(f)
	table.insert(queue, { t = now + (d or 0), co = co, args = { ... } })
	return co
end
function task.wait(d)
	local co = coroutine.running()
	local start = now
	table.insert(queue, { t = now + (d or 0.03), co = co, args = {} })
	coroutine.yield()
	return now - start
end
function task.cancel(co) dead[co] = true end
function task.desynchronize() end
function task.synchronize() end
R.task = task
local function runDue()
	local guard = 0
	while true do
		guard += 1
		if guard > 100000 then error("scheduler runaway") end
		local idx, best = nil, math.huge
		for i, e in queue do
			if e.t <= now and e.t < best then idx, best = i, e.t end
		end
		if not idx then break end
		local e = table.remove(queue, idx)
		resume(e.co, table.unpack(e.args))
	end
end

-- signals ---------------------------------------------------------------------------
local Signal = {}
Signal.__index = Signal
local function newSignal() return setmetatable({ handlers = {} }, Signal) end
function Signal:Connect(fn)
	local key = {}
	self.handlers[key] = fn
	local hs = self.handlers
	local c = { Connected = true }
	function c:Disconnect() self.Connected = false hs[key] = nil end
	return setmetatable(c, { __type = "RBXScriptConnection" })
end
function Signal:Once(fn) local c c = self:Connect(function(...) c:Disconnect() fn(...) end) return c end
function Signal:Fire(...)
	local list = {}
	for _, fn in self.handlers do table.insert(list, fn) end
	for _, fn in list do task.spawn(fn, ...) end
end
function Signal:Wait()
	local co = coroutine.running()
	self:Once(function(...) resume(co, ...) end)
	return coroutine.yield()
end
R.newSignal = newSignal

-- instances ---------------------------------------------------------------------------
local Inst = {}
local IMT = { __type = "Instance" }
local SUPER = {
	Part = "BasePart", WedgePart = "BasePart", CornerWedgePart = "BasePart", MeshPart = "BasePart", SpawnLocation = "Part", TrussPart = "BasePart",
	BasePart = "PVInstance", Model = "PVInstance", PVInstance = "Instance", Workspace = "Model",
	Script = "BaseScript", LocalScript = "BaseScript", BaseScript = "LuaSourceContainer", ModuleScript = "LuaSourceContainer",
	Weld = "JointInstance", Motor6D = "JointInstance", WeldConstraint = "Instance",
	PointLight = "Light", SpotLight = "Light", SurfaceLight = "Light",
	TextLabel = "GuiObject", TextButton = "GuiButton", ImageButton = "GuiButton", GuiButton = "GuiObject", ImageLabel = "GuiObject", Frame = "GuiObject", TextBox = "GuiObject", ScrollingFrame = "GuiObject", ViewportFrame = "GuiObject", GuiObject = "GuiBase2d",
	ScreenGui = "LayerCollector", SurfaceGui = "LayerCollector", BillboardGui = "LayerCollector", LayerCollector = "GuiBase2d",
	RemoteEvent = "Instance", Folder = "Instance", Humanoid = "Instance", Animator = "Instance",
	Atmosphere = "Instance", BloomEffect = "PostEffect", ColorCorrectionEffect = "PostEffect", SunRaysEffect = "PostEffect", DepthOfFieldEffect = "PostEffect",
}
local DEFAULTS = {
	BasePart = { Size = V3.new(4, 1, 2), Transparency = 0, Anchored = false, CanCollide = true, CanQuery = true, CanTouch = true, CastShadow = true, Massless = false, Color = T.Color3.fromRGB(163, 162, 165), Reflectance = 0, LocalTransparencyModifier = 0 },
	Model = { PrimaryPart = nil },
	ProximityPrompt = { Enabled = true, MaxActivationDistance = 10, HoldDuration = 0, ActionText = "", ObjectText = "" },
	Light = { Enabled = true, Brightness = 1, Range = 8 },
	Humanoid = { WalkSpeed = 16, Health = 100 },
}
local EVENTS = {
	Touched = 1, TouchEnded = 1, Changed = 1, ChildAdded = 1, ChildRemoved = 1, DescendantAdded = 1, DescendantRemoving = 1, AncestryChanged = 1, Destroying = 1,
	Triggered = 1, TriggerEnded = 1, PromptButtonHoldBegan = 1, PromptButtonHoldEnded = 1, OnServerEvent = 1, OnClientEvent = 1, PlayerAdded = 1, PlayerRemoving = 1,
	CharacterAdded = 1, CharacterAppearanceLoaded = 1, CharacterRemoving = 1, Heartbeat = 1, RenderStepped = 1, Stepped = 1, PromptTriggered = 1, PromptShown = 1, PromptHidden = 1,
	PromptGamePassPurchaseFinished = 1, Died = 1, Activated = 1, MouseEnter = 1, MouseLeave = 1, InputBegan = 1, InputEnded = 1, Completed = 1,
}
local function isA(class, target)
	local c = class
	while c do
		if c == target then return true end
		c = SUPER[c] or (c ~= "Instance" and "Instance" or nil)
	end
	return false
end
local function defaultsFor(class, props)
	local c = class
	while c do
		local d = DEFAULTS[c]
		if d then for k, v in d do if props[k] == nil then props[k] = v end end end
		c = SUPER[c]
	end
end
local function newInstance(class)
	local o = { __class = class, __props = { Name = class }, __children = {}, __attrs = {}, __signals = {}, __attrSignals = {}, __propSignals = {} }
	defaultsFor(class, o.__props)
	if isA(class, "BasePart") then o.__props.CFrame = CF.new() end
	return setmetatable(o, IMT)
end
R.isA = isA
local function signalOf(o, name)
	local s = o.__signals[name]
	if not s then s = newSignal() o.__signals[name] = s end
	return s
end
local function rootOf(o) while rawget(o, "__parent") do o = rawget(o, "__parent") end return o end
IMT.__index = function(o, k)
	local m = Inst[k]
	if m then return m end
	if k == "ClassName" then return o.__class end
	if k == "Parent" then return rawget(o, "__parent") end
	local p = o.__props
	local v = p[k]
	if v ~= nil then return v end
	if k == "Position" and p.CFrame then return p.CFrame.Position end
	if k == "Orientation" and p.CFrame then return V3.new(0, 0, 0) end
	if EVENTS[k] then return signalOf(o, k) end
	for _, c in o.__children do if c.__props.Name == k then return c end end
	local mm = rawget(o, "__methods") if mm and mm[k] then return mm[k] end
	if DEFAULT_NIL_OK[k] then return nil end
	if R.lenient and type(k) == "string" and k:match("^%u") then
		R.unknown[o.__class .. "." .. k] = (R.unknown[o.__class .. "." .. k] or 0) + 1
		if k:match("Velocity$") then return R.T.Vector3.new() end
		return nil
	end
	error(tostring(k) .. " is not a valid member of " .. o.__class .. ' "' .. tostring(p.Name) .. '"', 2)
end
DEFAULT_NIL_OK = { PrimaryPart = 1, Character = 1, Adornee = 1, CurrentCamera = 1, SoundId = 1, Part0 = 1, Part1 = 1, Attachment0 = 1, Attachment1 = 1, ProcessReceipt = 1, CameraSubject = 1, Image = 1, Texture = 1, Shape = 1, Material = 1, Face = 1, OnServerInvoke = 1, OnClientInvoke = 1 }
local function setParent(o, parent)
	local old = rawget(o, "__parent")
	if old == parent then return end
	if old then
		for i, c in old.__children do if c == o then table.remove(old.__children, i) break end end
	end
	rawset(o, "__parent", parent)
	if parent then
		table.insert(parent.__children, o)
		signalOf(parent, "ChildAdded"):Fire(o)
		local a = parent
		local descs = { o }
		for _, d in o:GetDescendants() do table.insert(descs, d) end
		while a do
			for _, d in descs do signalOf(a, "DescendantAdded"):Fire(d) end
			a = rawget(a, "__parent")
		end
		if R.onAddedToGame and rootOf(o) == R.game then
			for _, d in descs do R.onAddedToGame(d) end
		end
	end
	signalOf(o, "AncestryChanged"):Fire(o, parent)
end
IMT.__newindex = function(o, k, v)
	if type(k) == "string" and k:sub(1, 2) == "__" then rawset(o, k, v) return end
	if k == "Parent" then setParent(o, v) return end
	local p = o.__props
	if k == "Position" and p.CFrame then
		local c = p.CFrame
		p.CFrame = CF.new(v.X, v.Y, v.Z) * c.Rotation
	elseif k == "Shape" and v and v.Name == "Ball" and p.Size then
		p.Shape = v
		local s = math.min(p.Size.X, p.Size.Y, p.Size.Z)
		p.Size = V3.new(s, s, s)
	elseif k == "Size" and p.Shape and p.Shape.Name == "Ball" then
		local s = math.min(v.X, v.Y, v.Z)
		p.Size = V3.new(s, s, s)
	else
		p[k] = v
	end
	local s = o.__propSignals[k]
	if s then s:Fire() end
	if o.__signals.Changed then o.__signals.Changed:Fire(k) end
end
IMT.__tostring = function(o) return o.__props.Name end

function Inst:GetChildren() return table.clone(self.__children) end
function Inst:GetDescendants()
	local out = {}
	local function rec(x) for _, c in x.__children do table.insert(out, c) rec(c) end end
	rec(self)
	return out
end
function Inst:FindFirstChild(name, recursive)
	for _, c in self.__children do if c.__props.Name == name then return c end end
	if recursive then for _, d in self:GetDescendants() do if d.__props.Name == name then return d end end end
	return nil
end
function Inst:WaitForChild(name, timeout)
	local c = self:FindFirstChild(name)
	if c then return c end
	local t0 = now
	while now - t0 < (timeout or 5) do
		task.wait(0.05)
		c = self:FindFirstChild(name)
		if c then return c end
	end
	table.insert(R.Warnings, "Infinite yield possible on WaitForChild " .. tostring(name))
	return nil
end
function Inst:FindFirstChildOfClass(cls) for _, c in self.__children do if c.__class == cls then return c end end return nil end
function Inst:FindFirstChildWhichIsA(cls, rec)
	for _, c in (rec and self:GetDescendants() or self.__children) do if isA(c.__class, cls) then return c end end
	return nil
end
function Inst:FindFirstAncestor(name) local a = rawget(self, "__parent") while a do if a.__props.Name == name then return a end a = rawget(a, "__parent") end return nil end
function Inst:FindFirstAncestorWhichIsA(cls) local a = rawget(self, "__parent") while a do if isA(a.__class, cls) then return a end a = rawget(a, "__parent") end return nil end
function Inst:FindFirstAncestorOfClass(cls) local a = rawget(self, "__parent") while a do if a.__class == cls then return a end a = rawget(a, "__parent") end return nil end
function Inst:IsA(cls) return isA(self.__class, cls) end
function Inst:IsDescendantOf(x) local a = rawget(self, "__parent") while a do if a == x then return true end a = rawget(a, "__parent") end return false end
function Inst:IsAncestorOf(x) return x:IsDescendantOf(self) end
function Inst:Destroy()
	if rawget(self, "__destroyed") then return end
	signalOf(self, "Destroying"):Fire()
	for _, c in table.clone(self.__children) do c:Destroy() end
	setParent(self, nil)
	rawset(self, "__destroyed", true)
	if R.onDestroy then R.onDestroy(self) end
end
function Inst:ClearAllChildren() for _, c in table.clone(self.__children) do c:Destroy() end end
function Inst:SetAttribute(k, v)
	self.__attrs[k] = v
	local s = self.__attrSignals[k]
	if s then s:Fire() end
end
function Inst:GetAttribute(k) return self.__attrs[k] end
function Inst:GetAttributes() return table.clone(self.__attrs) end
function Inst:GetAttributeChangedSignal(k) local s = self.__attrSignals[k] if not s then s = newSignal() self.__attrSignals[k] = s end return s end
function Inst:GetPropertyChangedSignal(k) local s = self.__propSignals[k] if not s then s = newSignal() self.__propSignals[k] = s end return s end
function Inst:GetFullName() local n = self.__props.Name local a = rawget(self, "__parent") while a and a ~= R.game do n = a.__props.Name .. "." .. n a = rawget(a, "__parent") end return n end
function Inst:Clone()
	local map = {}
	local function copy(x)
		local c = newInstance(x.__class)
		map[x] = c
		for k, v in x.__props do c.__props[k] = v end
		for k, v in x.__attrs do c.__attrs[k] = v end
		rawset(c, "__source", rawget(x, "__source"))
		rawset(c, "__methods", rawget(x, "__methods"))
		if R.tagsOf then for _, t in R.tagsOf(x) do R.addTag(c, t) end end
		for _, ch in x.__children do local cc = copy(ch) rawset(cc, "__parent", c) table.insert(c.__children, cc) end
		return c
	end
	local root = copy(self)
	for _, c in map do
		for k, v in c.__props do
			if type(v) == "table" and getmetatable(v) == IMT and map[v] then c.__props[k] = map[v] end
		end
	end
	return root
end
local function partsOf(o)
	local out = {}
	if isA(o.__class, "BasePart") then table.insert(out, o) end
	for _, d in o:GetDescendants() do if isA(d.__class, "BasePart") then table.insert(out, d) end end
	return out
end
function Inst:GetPivot()
	if isA(self.__class, "BasePart") then return self.__props.CFrame end
	local pp = self.__props.PrimaryPart
	if pp then return pp.__props.CFrame end
	local cf, _ = self:GetBoundingBox()
	return cf
end
function Inst:PivotTo(target)
	local delta = target * self:GetPivot():Inverse()
	for _, p in partsOf(self) do p.__props.CFrame = delta * p.__props.CFrame end
end
function Inst:GetBoundingBox()
	local mn, mx = V3.new(math.huge, math.huge, math.huge), V3.new(-math.huge, -math.huge, -math.huge)
	for _, p in partsOf(self) do
		local c, s = p.__props.CFrame, p.__props.Size / 2
		for _, sx in { -1, 1 } do for _, sy in { -1, 1 } do for _, sz in { -1, 1 } do
			local w = c * V3.new(s.X * sx, s.Y * sy, s.Z * sz)
			mn, mx = mn:Min(w), mx:Max(w)
		end end end
	end
	if mn.X == math.huge then return CF.new(), V3.new() end
	return CF.new((mn + mx) / 2), mx - mn
end
function Inst:GetExtentsSize() local _, s = self:GetBoundingBox() return s end
function Inst:ScaleTo(s)
	local cur = self.__attrs.__scale or 1
	local f = s / cur
	local pivot = self:GetPivot()
	for _, p in partsOf(self) do
		local rel = pivot:ToObjectSpace(p.__props.CFrame)
		p.__props.CFrame = pivot * (CF.new(rel.Position * f) * rel.Rotation)
		p.__props.Size = p.__props.Size * f
	end
	self.__attrs.__scale = s
end
function Inst:GetScale() return self.__attrs.__scale or 1 end
function Inst:AddPersistentPlayer() end
function Inst:RemovePersistentPlayer() end
function Inst:SetNetworkOwner() end
function Inst:GetMass() return 1 end
function Inst:FireClient(player, ...)
	table.insert(R.Log, { remote = self.__props.Name, player = player, args = { ... } })
	if R.clientPlayer == player then signalOf(self, "OnClientEvent"):Fire(...) end
end
function Inst:FireServer(...) signalOf(self, "OnServerEvent"):Fire(R.clientPlayer, ...) end
function Inst:InvokeServer(...)
	local f = self.__props.OnServerInvoke
	if f then return f(R.clientPlayer, ...) end
end
function Inst:WorldToViewportPoint(v) return R.T.Vector3.new(640, 360, 10), true end
function Inst:WorldToScreenPoint(v) return R.T.Vector3.new(640, 360, 10), true end
function Inst:FireAllClients(...) table.insert(R.Log, { remote = self.__props.Name, args = { ... } }) end
function Inst:Emit() end
function Inst:Play() end
function Inst:Stop() end
function Inst:InputHoldBegin() end
function Inst:InputHoldEnd() end
function Inst:LoadAnimation() return { Play = function() end, Stop = function() end, IsPlaying = false } end

R.Instance = { new = function(cls, parent) local o = newInstance(cls) if parent then o.Parent = parent end return o end }
R.IMT = IMT
R.newInstance = newInstance
R.signalOf = signalOf
R.rootOf = rootOf
R.partsOf = partsOf
R.T = T
function R.now() return now end
function R.step(dt)
	now += dt
	local hb = R.services and R.services.RunService
	if hb then
		signalOf(hb, "Heartbeat"):Fire(dt)
		signalOf(hb, "Stepped"):Fire(now, dt)
	end
	runDue()
end
R.runDue = runDue
return R
