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
local function pad(id)
	for _, p in CS.GetTagged(nil, "QueuePad") do if p:GetAttribute("DoorId") == id then return p end end
end
local MODE = SMOKE_MODE or "Solo"
print("pads:", #CS.GetTagged(nil, "QueuePad"), "doors:", #CS.GetTagged(nil, "QueueDoor"), "fires", #CS.GetTagged(nil, "LobbySign"))
local solo = pad(MODE)
p1.Character.HumanoidRootPart.CFrame = solo.CFrame + R.T.Vector3.new(0, 3, 0)
R.signalOf(solo, "Touched"):Fire(p1.Character.HumanoidRootPart)
local function sessionInfo()
	local dc = R.game:GetService("Workspace"):FindFirstChild("Daycares")
	local m = dc and dc:GetChildren()[1]
	if not m then return "no daycare" end
	local babies = 0
	for _, b in CS.GetTagged(nil, "Baby") do if b:IsDescendantOf(m) then babies += 1 end end
	local state
	for i = #R.Log, 1, -1 do local e = R.Log[i] if e.remote == "ShiftState" then state = e.args[1] break end end
	return ("daycare=%s babies=%d phase=%s time=%s clock=%s"):format(m.Name, babies, state and state.Phase or "?", state and string.format("%.1f", state.Time) or "?", state and string.format("%.2f", state.Clock) or "?")
end

for _ = 1, 250 do R.step(0.1) end
local dbg = R.game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):FindFirstChild("DebugCommand")
R.signalOf(dbg, "OnServerEvent"):Fire(p1, "TimeScale", 10)
R.signalOf(dbg, "OnServerEvent"):Fire(p1, "TriggerEvent", "Storm")
local gotResults = false
for i = 1, 900 do
	R.step(0.1)
	for _, e in R.Log do if e.remote == "Results" then gotResults = true end end
	if gotResults then print("results after", i / 10, "s") break end
end
local res
for _, e in R.Log do if e.remote == "Results" then res = e.args[1] end end
if res then print("stars", res.Stars, "score", res.FinalScore, "coins", res.Personal and res.Personal.Coins, "babies", #res.Babies) end
local choice = R.game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ResultsChoice")
R.signalOf(choice, "OnServerEvent"):Fire(p1, "Lobby")
for _ = 1, 30 do R.step(0.1) end
print("back in lobby at", tostring(p1.Character.HumanoidRootPart.Position), "daycares:", #R.game:GetService("Workspace").Daycares:GetChildren())
local d
for _, e in R.Log do if e.remote == "DataChanged" then d = e.args[1] end end
print("data coins", d and d.Coins, "stars", d and d.TotalStars, "xp", d and d.NannyXP, "shifts", d and d.Stats.ShiftsPlayed)
print("errors:", #R.Errors)
for _, e in R.Errors do print("ERR:", e:sub(1, 400)) end
for _, w in R.Warnings do if not w:find("DataStores") then print("W:", w:sub(1, 200)) end end
