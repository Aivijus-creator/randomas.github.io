--!strict
-- Pure math helpers (no Roblox dependencies except optional Vector3 use by callers).
local MathUtil = {}

function MathUtil.clamp(x: number, a: number, b: number): number
	if x < a then
		return a
	elseif x > b then
		return b
	end
	return x
end

function MathUtil.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function MathUtil.round(x: number, step: number?): number
	local s = step or 1
	return math.floor(x / s + 0.5) * s
end

-- Is `point` within a cone starting at `origin` facing `dir` (unit), with half-angle in degrees and range?
function MathUtil.inCone(origin: Vector3, dir: Vector3, point: Vector3, range: number, halfAngleDeg: number): boolean
	local offset = point - origin
	local dist = offset.Magnitude
	if dist > range then
		return false
	end
	if dist < 0.5 then
		return true
	end
	local cos = offset.Unit:Dot(dir)
	return cos >= math.cos(math.rad(halfAngleDeg))
end

function MathUtil.flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

function MathUtil.formatClock(hours: number): string
	local h = math.floor(hours)
	local m = math.floor((hours - h) * 60)
	return string.format("%02d:%02d", h, m)
end

function MathUtil.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if formatted:sub(1, 1) == "," then
		formatted = formatted:sub(2)
	end
	return formatted
end

function MathUtil.weightedPick<T>(items: { T }, weightOf: (T) -> number, rng: Random?): T?
	local total = 0
	for _, it in items do
		total += weightOf(it)
	end
	if total <= 0 then
		return nil
	end
	local r = (rng and rng:NextNumber() or math.random()) * total
	for _, it in items do
		r -= weightOf(it)
		if r <= 0 then
			return it
		end
	end
	return items[#items]
end

return MathUtil
