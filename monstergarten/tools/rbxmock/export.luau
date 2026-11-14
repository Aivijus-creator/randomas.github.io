-- Builds the editable place content with the real code and writes a JSON instance tree for placegen.
local function load(path) local fn, err = __compile(__readfile(path), path) if not fn then error(err) end return fn() end
RUNTIME = load(MOCK_DIR .. "/runtime.luau")
local R = load(MOCK_DIR .. "/world.luau")
local T = R.T
local req = R.env.require
local game = R.game
local nextId = 0
local ids = {}
local function idOf(inst) if not ids[inst] then nextId += 1 ids[inst] = nextId end return ids[inst] end
local SKIP_PROPS = { Name = true, Position = true, __scale = true }
local function enc(v)
	local t = R.env.typeof(v)
	if t == "string" then return { "s", v } end
	if t == "boolean" then return { "b", v } end
	if t == "number" then if v ~= v or v == math.huge or v == -math.huge then return nil end return { "f", v } end
	if t == "Vector3" then return { "v3", { v.X, v.Y, v.Z } } end
	if t == "Vector2" then return { "v2", { v.X, v.Y } } end
	if t == "CFrame" then return { "cf", { v:GetComponents() } } end
	if t == "Color3" then return { "c3", { v.R, v.G, v.B } } end
	if t == "EnumItem" then return { "e", { v.EnumType, v.Name } } end
	if t == "UDim2" then return { "u2", { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset } } end
	if t == "UDim" then return { "u", { v.Scale, v.Offset } } end
	if t == "NumberRange" then return { "nr", { v.Min, v.Max } } end
	if t == "NumberSequence" then local k = {} for _, p in v.Keypoints do table.insert(k, { p.Time, p.Value, p.Envelope or 0 }) end return { "ns", k } end
	if t == "ColorSequence" then local k = {} for _, p in v.Keypoints do table.insert(k, { p.Time, p.Value.R, p.Value.G, p.Value.B }) end return { "cs", k } end
	if t == "Instance" then return { "ref", idOf(v) } end
	return nil
end
local function node(inst)
	local n = { c = inst.ClassName, n = inst.Name, id = idOf(inst), p = {}, a = {}, t = R.tagsOf(inst), k = {} }
	for k, v in inst.__props do
		if not SKIP_PROPS[k] then
			local e = enc(v)
			if e then n.p[k] = e end
		end
	end
	if rawget(inst, "__source") then n.p.Source = { "s", __readfile(rawget(inst, "__source")) } end
	for k, v in inst.__attrs do
		if k:sub(1, 2) ~= "__" then
			local e = enc(v)
			if e and e[1] ~= "ref" and e[1] ~= "e" then n.a[k] = e end
		end
	end
	for _, c in inst:GetChildren() do table.insert(n.k, node(c)) end
	return n
end
-- tiny JSON encoder
local function json(v)
	local t = type(v)
	if t == "table" then
		if #v > 0 or next(v) == nil and getmetatable(v) == "array" then
			local parts = {}
			for _, x in v do table.insert(parts, json(x)) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		if next(v) == nil then return "{}" end
		local parts = {}
		for k, x in v do table.insert(parts, string.format("%q", tostring(k)) .. ":" .. json(x)) end
		return "{" .. table.concat(parts, ",") .. "}"
	elseif t == "string" then
		return '"' .. v:gsub('[%c"\\]', function(c)
			local map = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }
			return map[c] or string.format("\\u%04x", c:byte())
		end) .. '"'
	elseif t == "number" then
		if v == math.floor(v) and math.abs(v) < 1e15 then return tostring(math.floor(v)) end
		return string.format("%.6g", v)
	elseif t == "boolean" then
		return tostring(v)
	end
	return "null"
end

R.task.spawn(function()
	local MB = req(R.ServerFolder.World.MapBuilder)
	MB.setupLighting()
	local ws = game:GetService("Workspace")
	local lobby = MB.buildLobby()
	local tpl = MB.buildTemplate()
	tpl.Name = "DaycareTemplate"
	tpl:PivotTo(T.CFrame.new(-700, 0, 0))
	tpl.Parent = ws
	-- Assets: designed characters as editable models
	local RS = game:GetService("ReplicatedStorage")
	local CB = req(RS.Shared.World.CharacterBuilder)
	local CD = req(RS.Shared.World.CharacterData)
	for _, folder in { "Babies", "Parents", "NPCs" } do
		for id in CD[folder] do
			local m = CB.build(folder, id)
			m.Name = id
			m.Parent = RS.Assets[folder]
		end
	end
	local function svcNode(name, props, children)
		local s = game:GetService(name)
		local n = { c = s.ClassName == "Workspace" and "Workspace" or name, n = name, id = idOf(s), p = props or {}, a = {}, t = {}, k = {} }
		for _, c in children or s:GetChildren() do table.insert(n.k, node(c)) end
		return n
	end
	local Lighting = game:GetService("Lighting")
	local lightProps = { Technology = { "e", { "Technology", "Future" } } }
	for k, v in Lighting.__props do if not SKIP_PROPS[k] then local e = enc(v) if e then lightProps[k] = e end end end
	local tree = {
		svcNode("Workspace", { StreamingEnabled = { "b", true } }, { lobby, tpl }),
		svcNode("Lighting", lightProps),
		svcNode("ReplicatedStorage"),
		svcNode("ServerScriptService"),
		svcNode("ServerStorage"),
		svcNode("StarterPlayer", { CameraMaxZoomDistance = { "f", 40 } }),
		svcNode("SoundService", { RespectFilteringEnabled = { "b", true } }),
	}
	__writefile(OUT_JSON, json(tree))
	print("exported ids:", nextId, "errors:", #R.Errors)
end)
for _ = 1, 30 do R.step(0.1) end
