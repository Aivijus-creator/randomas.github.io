-- Tiny assert-based test runner. Runs every *.spec module in this folder.
-- Enable in Studio with Config/GameSettings.RunTestsOnStart = true or Workspace attribute RunTests = true.
local TestRunner = {}

local function makeT(results, specName)
	local t = {}
	function t.ok(cond, msg)
		if not cond then
			error((msg or "assertion failed"), 2)
		end
	end
	function t.eq(a, b, msg)
		if a ~= b then
			error(string.format("%s: expected %s, got %s", msg or "eq", tostring(b), tostring(a)), 2)
		end
	end
	function t.near(a, b, eps, msg)
		if math.abs(a - b) > (eps or 1e-6) then
			error(string.format("%s: expected ~%s, got %s", msg or "near", tostring(b), tostring(a)), 2)
		end
	end
	function t.case(name, fn)
		local ok, err = pcall(fn)
		table.insert(results, { spec = specName, name = name, ok = ok, err = err })
	end
	return t
end

function TestRunner.run(folder)
	local results = {}
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") and child.Name:match("%.spec$") then
			local ok, spec = pcall(require, child)
			if ok and type(spec) == "function" then
				spec(makeT(results, child.Name))
			else
				table.insert(results, { spec = child.Name, name = "load", ok = false, err = spec })
			end
		end
	end
	local passed, failed = 0, 0
	for _, r in results do
		if r.ok then
			passed += 1
		else
			failed += 1
			warn(string.format("[TEST FAIL] %s / %s: %s", r.spec, r.name, tostring(r.err)))
		end
	end
	print(string.format("[Tests] %d passed, %d failed", passed, failed))
	return passed, failed
end

return TestRunner
