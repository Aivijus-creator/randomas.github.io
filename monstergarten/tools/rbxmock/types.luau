-- Roblox datatype mocks: Vector3, Vector2, CFrame, Color3, UDim, UDim2, sequences, Enum, Random...
local M = {}
local sqrt, abs, cos, sin = math.sqrt, math.abs, math.cos, math.sin

local V3 = {}
V3.__type = "Vector3"
local function v3(x, y, z) return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3) end
V3.__index = function(v, k)
	if k == "Magnitude" then return sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	if k == "Unit" then local m = sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z); if m == 0 then return v3(0, 0, 0) end return v3(v.X / m, v.Y / m, v.Z / m) end
	return V3[k]
end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return v3(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(v) return string.format("%.3f, %.3f, %.3f", v.X, v.Y, v.Z) end
function V3.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3.Cross(a, b) return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X) end
function V3.Lerp(a, b, t) return a + (b - a) * t end
function V3.Abs(a) return v3(abs(a.X), abs(a.Y), abs(a.Z)) end
function V3.Min(a, b) return v3(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z)) end
function V3.Max(a, b) return v3(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z)) end
function V3.FuzzyEq(a, b, e) return (a - b).Magnitude <= (e or 1e-5) end
M.Vector3 = { new = v3, zero = v3(0, 0, 0), one = v3(1, 1, 1), xAxis = v3(1, 0, 0), yAxis = v3(0, 1, 0), zAxis = v3(0, 0, 1) }

local V2 = { __type = "Vector2" }
local function v2(x, y) return setmetatable({ X = x or 0, Y = y or 0 }, V2) end
V2.__index = function(v, k)
	if k == "Magnitude" then return sqrt(v.X * v.X + v.Y * v.Y) end
	if k == "Unit" then local m = sqrt(v.X * v.X + v.Y * v.Y); return v2(v.X / m, v.Y / m) end
	return V2[k]
end
V2.__add = function(a, b) return v2(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return v2(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b) if type(b) == "number" then return v2(a.X * b, a.Y * b) end if type(a) == "number" then return v2(a * b.X, a * b.Y) end return v2(a.X * b.X, a.Y * b.Y) end
V2.__div = function(a, b) return v2(a.X / b, a.Y / b) end
V2.__eq = function(a, b) return a.X == b.X and a.Y == b.Y end
M.Vector2 = { new = v2, zero = v2(0, 0), one = v2(1, 1) }

-- CFrame: position p + rotation matrix rows r[1..9] (row-major); columns = Right, Up, Back
local CF = { __type = "CFrame" }
local function cf(x, y, z, m)
	m = m or { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
	return setmetatable({ x = x, y = y, z = z, m = m }, CF)
end
local function mmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			r[i * 3 + j + 1] = a[i * 3 + 1] * b[j + 1] + a[i * 3 + 2] * b[3 + j + 1] + a[i * 3 + 3] * b[6 + j + 1]
		end
	end
	return r
end
local function rotv(m, x, y, z) return m[1] * x + m[2] * y + m[3] * z, m[4] * x + m[5] * y + m[6] * z, m[7] * x + m[8] * y + m[9] * z end
local function transpose(m) return { m[1], m[4], m[7], m[2], m[5], m[8], m[3], m[6], m[9] } end
CF.__index = function(c, k)
	if k == "Position" or k == "p" then return v3(c.x, c.y, c.z) end
	if k == "X" then return c.x end
	if k == "Y" then return c.y end
	if k == "Z" then return c.z end
	local m = c.m
	if k == "LookVector" then return v3(-m[3], -m[6], -m[9]) end
	if k == "RightVector" then return v3(m[1], m[4], m[7]) end
	if k == "UpVector" then return v3(m[2], m[5], m[8]) end
	if k == "Rotation" then return cf(0, 0, 0, m) end
	return CF[k]
end
CF.__mul = function(a, b)
	if getmetatable(b) == CF then
		local x, y, z = rotv(a.m, b.x, b.y, b.z)
		return cf(a.x + x, a.y + y, a.z + z, mmul(a.m, b.m))
	end
	local x, y, z = rotv(a.m, b.X, b.Y, b.Z)
	return v3(a.x + x, a.y + y, a.z + z)
end
CF.__add = function(a, b) return cf(a.x + b.X, a.y + b.Y, a.z + b.Z, a.m) end
CF.__sub = function(a, b) return cf(a.x - b.X, a.y - b.Y, a.z - b.Z, a.m) end
CF.__eq = function(a, b) if a.x ~= b.x or a.y ~= b.y or a.z ~= b.z then return false end for i = 1, 9 do if a.m[i] ~= b.m[i] then return false end end return true end
function CF.Inverse(c)
	local t = transpose(c.m)
	local x, y, z = rotv(t, -c.x, -c.y, -c.z)
	return cf(x, y, z, t)
end
function CF.ToObjectSpace(a, b) return CF.Inverse(a) * b end
function CF.ToWorldSpace(a, b) return a * b end
function CF.PointToObjectSpace(a, v) return CF.Inverse(a) * v end
function CF.PointToWorldSpace(a, v) return a * v end
function CF.VectorToWorldSpace(a, v) local x, y, z = rotv(a.m, v.X, v.Y, v.Z) return v3(x, y, z) end
function CF.VectorToObjectSpace(a, v) local x, y, z = rotv(transpose(a.m), v.X, v.Y, v.Z) return v3(x, y, z) end
function CF.GetComponents(c) local m = c.m return c.x, c.y, c.z, m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9] end
function CF.ToEulerAnglesYXZ(c)
	local m = c.m
	local x = math.asin(math.clamp(-m[6], -1, 1))
	local y = math.atan2(m[3], m[9])
	local z = math.atan2(m[4], m[5])
	return x, y, z
end
function CF.ToEulerAnglesXYZ(c)
	local m = c.m
	local y = math.asin(math.clamp(m[3], -1, 1))
	local x = math.atan2(-m[6], m[9])
	local z = math.atan2(-m[2], m[1])
	return x, y, z
end
function CF.Lerp(a, b, t) return cf(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t, a.z + (b.z - a.z) * t, t < 0.5 and a.m or b.m) end
local function rx(a) local c, s = cos(a), sin(a) return { 1, 0, 0, 0, c, -s, 0, s, c } end
local function ry(a) local c, s = cos(a), sin(a) return { c, 0, s, 0, 1, 0, -s, 0, c } end
local function rz(a) local c, s = cos(a), sin(a) return { c, -s, 0, s, c, 0, 0, 0, 1 } end
local function angles(x, y, z) return cf(0, 0, 0, mmul(mmul(rx(x or 0), ry(y or 0)), rz(z or 0))) end
local function lookAt(at, target, up)
	up = up or v3(0, 1, 0)
	local f = (target - at)
	if f.Magnitude < 1e-9 then return cf(at.X, at.Y, at.Z) end
	f = f.Unit
	local r = f:Cross(up)
	if r.Magnitude < 1e-6 then r = v3(1, 0, 0) else r = r.Unit end
	local u = r:Cross(f)
	return cf(at.X, at.Y, at.Z, { r.X, u.X, -f.X, r.Y, u.Y, -f.Y, r.Z, u.Z, -f.Z })
end
M.CFrame = {
	new = function(a, b, c, ...)
		if a == nil then return cf(0, 0, 0) end
		if type(a) == "table" then
			if b then return lookAt(a, b) end
			return cf(a.X, a.Y, a.Z)
		end
		local rest = { ... }
		if #rest == 9 then return cf(a, b, c, rest) end
		return cf(a, b, c)
	end,
	Angles = angles,
	fromEulerAnglesXYZ = angles,
	fromEulerAnglesYXZ = function(x, y, z) return cf(0, 0, 0, mmul(mmul(ry(y), rx(x)), rz(z))) end,
	fromOrientation = function(x, y, z) return cf(0, 0, 0, mmul(mmul(ry(y), rx(x)), rz(z))) end,
	lookAt = lookAt,
	identity = cf(0, 0, 0),
	fromMatrix = function(pos, r, u, b)
		b = b or r:Cross(u)
		return cf(pos.X, pos.Y, pos.Z, { r.X, u.X, b.X, r.Y, u.Y, b.Y, r.Z, u.Z, b.Z })
	end,
}

local C3 = { __type = "Color3" }
C3.__index = C3
local function c3(r, g, b) return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3) end
function C3.Lerp(a, b, t) return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
function C3.ToHex(c) return string.format("%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
M.Color3 = {
	new = c3,
	fromRGB = function(r, g, b) return c3(r / 255, g / 255, b / 255) end,
	fromHex = function(h)
		h = h:gsub("#", "")
		return c3(tonumber(h:sub(1, 2), 16) / 255, tonumber(h:sub(3, 4), 16) / 255, tonumber(h:sub(5, 6), 16) / 255)
	end,
	fromHSV = function(h, s, v)
		local i = math.floor(h * 6) % 6
		local f = h * 6 - math.floor(h * 6)
		local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
		local t2 = ({ { v, t, p }, { q, v, p }, { p, v, t }, { p, q, v }, { t, p, v }, { v, p, q } })[i + 1]
		return c3(t2[1], t2[2], t2[3])
	end,
}

local function simple(tname, fields)
	local mt = { __type = tname }
	mt.__index = mt
	return mt, function(...)
		local o = setmetatable({}, mt)
		local args = { ... }
		for i, f in fields do
			o[f] = args[i]
		end
		return o
	end
end
local UDmt, udim = simple("UDim", { "Scale", "Offset" })
UDmt.__add = function(a, b) return udim(a.Scale + b.Scale, a.Offset + b.Offset) end
M.UDim = { new = udim }
local U2mt, udim2raw = simple("UDim2", { "X", "Y" })
local function udim2(xs, xo, ys, yo) return udim2raw(udim(xs or 0, xo or 0), udim(ys or 0, yo or 0)) end
U2mt.__add = function(a, b) return udim2raw(a.X + b.X, a.Y + b.Y) end
M.UDim2 = {
	new = function(a, b, c, d) if type(a) == "table" then return udim2raw(a, b) end return udim2(a, b, c, d) end,
	fromScale = function(x, y) return udim2(x, 0, y, 0) end,
	fromOffset = function(x, y) return udim2(0, x, 0, y) end,
}
local _, nrange = simple("NumberRange", { "Min", "Max" })
M.NumberRange = { new = function(a, b) return nrange(a, b or a) end }
local _, nsk = simple("NumberSequenceKeypoint", { "Time", "Value", "Envelope" })
M.NumberSequenceKeypoint = { new = nsk }
local _, nseq = simple("NumberSequence", { "Keypoints" })
M.NumberSequence = { new = function(a, b) if type(a) == "table" then return nseq(a) end return nseq({ nsk(0, a), nsk(1, b or a) }) end }
local _, csk = simple("ColorSequenceKeypoint", { "Time", "Value" })
M.ColorSequenceKeypoint = { new = csk }
local _, cseq = simple("ColorSequence", { "Keypoints" })
M.ColorSequence = { new = function(a, b) if getmetatable(a) == C3 then return cseq({ csk(0, a), csk(1, b or a) }) end return cseq(a) end }
local _, tweeninfo = simple("TweenInfo", { "Time", "EasingStyle", "EasingDirection", "RepeatCount", "Reverses", "DelayTime" })
M.TweenInfo = { new = tweeninfo }
local _, rect = simple("Rect", { "Min", "Max" })
M.Rect = { new = rect }
local _, physprops = simple("PhysicalProperties", { "Density", "Friction", "Elasticity" })
M.PhysicalProperties = { new = physprops }
local RPmt = { __type = "RaycastParams" }
RPmt.__index = RPmt
M.RaycastParams = { new = function() return setmetatable({ FilterDescendantsInstances = {} }, RPmt) end }
local OPmt = { __type = "OverlapParams" }
OPmt.__index = OPmt
M.OverlapParams = { new = function() return setmetatable({ FilterDescendantsInstances = {} }, OPmt) end }

-- Random
local RND = { __type = "Random" }
RND.__index = RND
local function lcg(s)
	s.state = (s.state * 1103515245 + 12345) % 2147483648
	return s.state / 2147483648
end
function RND.NextNumber(s, a, b) local r = lcg(s) if a then return a + (b - a) * r end return r end
function RND.NextInteger(s, a, b) return a + math.floor(lcg(s) * (b - a + 1)) end
M.Random = { new = function(seed) return setmetatable({ state = math.floor(seed or 1) % 2147483648 }, RND) end }

-- Enum: Enum.Material.Wood etc. Items are cached so identity comparison works.
local EnumItem = { __type = "EnumItem" }
EnumItem.__index = EnumItem
EnumItem.__tostring = function(e) return "Enum." .. e.EnumType .. "." .. e.Name end
local enumCache = {}
local KNOWN = dofile_enum_values or {}
local function enumType(name)
	if enumCache[name] then return enumCache[name] end
	local items = {}
	local et = setmetatable({}, {
		__index = function(_, k)
			if k == "GetEnumItems" then return function() local out = {} for _, v in items do table.insert(out, v) end return out end end
			if not items[k] then
				local value = (KNOWN[name] and KNOWN[name][k]) or 0
				items[k] = setmetatable({ Name = k, Value = value, EnumType = name }, EnumItem)
			end
			return items[k]
		end,
	})
	enumCache[name] = et
	return et
end
M.Enum = setmetatable({}, { __index = function(_, k) return enumType(k) end })
M.EnumItem = EnumItem

M.metas = { Vector3 = V3, Vector2 = V2, CFrame = CF, Color3 = C3, UDim = UDmt, UDim2 = U2mt, EnumItem = EnumItem, Random = RND }
return M
