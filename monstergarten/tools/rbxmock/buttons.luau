local function load(path) local fn, err = __compile(__readfile(path), path) if not fn then error(err) end return fn() end
RUNTIME = load(MOCK_DIR .. "/runtime.luau")
local R = load(MOCK_DIR .. "/world.luau")
local main = R.ServerFolder:FindFirstChild("Main")
R.runScript(main)
for _ = 1, 30 do R.step(1 / 30) end
print("errors after boot:", #R.Errors)
local CS = R.services.CollectionService.__methods
local p1 = R.addPlayer("Tester", 101)
R.services.Players.__props.LocalPlayer = p1
R.clientPlayer = p1
R.runScript(R.ClientFolder:FindFirstChild("Main"))
for _ = 1, 60 do R.step(1 / 30) end
print("lobby exists:", R.game:GetService("Workspace"):FindFirstChild("Lobby") ~= nil)

local pg = p1:FindFirstChild("PlayerGui")
local function pressAll(label)
	local before = #R.Errors
	local n = 0
	for _, d in pg:GetDescendants() do
		if (d.ClassName == "TextButton" or d.ClassName == "ImageButton") and d.Name ~= "Again" then
			n += 1
			R.signalOf(d, "Activated"):Fire()
			R.step(0.05)
		end
	end
	for _ = 1, 20 do R.step(0.1) end
	print(label, "buttons pressed:", n, "new errors:", #R.Errors - before)
end
-- give coins so shop buttons exercise buying
pressAll("lobby #1")
pressAll("lobby #2")
local function pad(id) for _, p in R.services.CollectionService.__methods.GetTagged(nil, "QueuePad") do if p:GetAttribute("DoorId") == id then return p end end end
local door = pad("Shift1")
p1.Character.HumanoidRootPart.CFrame = door.CFrame + R.T.Vector3.new(0, 3, 0)
R.signalOf(door, "Touched"):Fire(p1.Character.HumanoidRootPart)
for _ = 1, 10 do R.step(0.1) end
pressAll("queue")
for _ = 1, 300 do R.step(0.1) end
pressAll("shift")
for _, e in R.Errors do print("ERR:", e:sub(1, 300)) end
