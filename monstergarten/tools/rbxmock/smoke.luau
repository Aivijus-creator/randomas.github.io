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
for sec = 1, 40 do
	for _ = 1, 10 do R.step(0.1) end
	if sec % 5 == 0 then print("t+" .. sec, sessionInfo(), "player at", tostring(p1.Character.HumanoidRootPart.Position)) end
end
print("errors:", #R.Errors, "warnings:", #R.Warnings)
for _, w in R.Warnings do print("  W:", w) end
local counts = {}
for _, e in R.Log do counts[e.remote] = (counts[e.remote] or 0) + 1 end
for k, v in counts do print("remote", k, v) end
for _, e in R.Log do if e.remote == "Notify" then print("notify", type(e.args[1]) == "table" and e.args[1][1] or e.args[1]) end end
for _, e in R.Log do if e.remote == "QueueUpdate" and e.args[1] then print("queue", e.args[1].DoorId, e.args[1].Countdown, e.args[1].Waiting) break end end
print("client errors:", #R.Errors)
local pg = p1:FindFirstChild("PlayerGui")
local names = {}
for _, g in pg:GetChildren() do table.insert(names, g.Name) end
print("guis:", table.concat(names, ","))
local keys = {}
for k, v in R.unknown do table.insert(keys, k .. "=" .. v) end
table.sort(keys)
print("unknown members:", table.concat(keys, "  "))

local hud = pg:FindFirstChild("HUD")
local shiftFrame = hud and hud:FindFirstChild("Shift")
print("HUD shift visible:", shiftFrame and shiftFrame.Visible)
local function texts(inst, out)
	for _, d in inst:GetDescendants() do if d.ClassName == "TextLabel" and type(d.__props.Text) == "string" and d.__props.Text ~= "" then table.insert(out, d.__props.Text) end end
	return out
end
local t = texts(shiftFrame, {})
print("shift HUD texts:", table.concat(t, " | "):sub(1, 400))
for _, b in R.services.CollectionService.__methods.GetTagged(nil, "Baby") do
	local hidden = 0
	local parts = 0
	for _, d in b:GetDescendants() do if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then parts += 1 if (d.__props.LocalTransparencyModifier or 0) > 0.5 or (d.__props.Transparency or 0) > 0.9 then hidden += 1 end end end
	print("baby", b:GetAttribute("BabyId"), "at", tostring(b.PrimaryPart.Position), "parts", parts, "hidden", hidden, "anim", b:GetAttribute("Anim"))
end
