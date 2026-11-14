--!strict
local TableUtil = {}

function TableUtil.deepCopy<T>(t: T): T
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in t :: any do
		out[TableUtil.deepCopy(k)] = TableUtil.deepCopy(v)
	end
	return (out :: any) :: T
end

-- Fill missing keys in `target` from `template` (recursive). Existing values are kept.
function TableUtil.reconcile(target: { [any]: any }, template: { [any]: any })
	for k, v in template do
		if target[k] == nil then
			target[k] = TableUtil.deepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" and next(v) ~= nil and #v == 0 then
			TableUtil.reconcile(target[k], v)
		end
	end
	return target
end

function TableUtil.keys<K>(t: { [K]: any }): { K }
	local out = {}
	for k in t do
		table.insert(out, k)
	end
	return out
end

function TableUtil.count(t: { [any]: any }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

function TableUtil.shuffle<T>(t: { T }, rng: Random?): { T }
	for i = #t, 2, -1 do
		local j = rng and rng:NextInteger(1, i) or math.random(1, i)
		t[i], t[j] = t[j], t[i]
	end
	return t
end

function TableUtil.find<T>(t: { T }, pred: (T) -> boolean): (T?, number?)
	for i, v in t do
		if pred(v) then
			return v, i
		end
	end
	return nil, nil
end

function TableUtil.map<T, U>(t: { T }, fn: (T) -> U): { U }
	local out = {}
	for i, v in t do
		out[i] = fn(v)
	end
	return out
end

return TableUtil
