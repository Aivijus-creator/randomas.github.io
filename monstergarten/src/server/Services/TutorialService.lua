-- TutorialService: scripted solo shift with one Dragling and no time limit (GDD 20).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local ServerUtil = require(script.Parent.Parent.ServerUtil)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local TutorialService = {}
local S

-- Step definitions: Key (string id), Target (tag the client points an arrow at), Wait (event that advances).
local STEPS = {
	{ Key = "Tut_Move", Target = "ToolRack", Wait = "PickUp" },
	{ Key = "Tut_Bubble", Target = "Baby", Wait = "Timer", Time = 7 },
	{ Key = "Tut_Cook", Target = "Appliance", Wait = "Fed" },
	{ Key = "Tut_Sleep", Target = "Bed", Wait = "PutToBed" },
	{ Key = "Tut_Fire", Target = "Fire", Wait = "FireOut" },
	{ Key = "Tut_Tantrum", Target = "Baby", Wait = "Next" },
	{ Key = "Tut_Parents", Target = "ParentDropoff", Wait = "Timer", Time = 6 },
}

local function send(session)
	local step = STEPS[session.TutStep]
	local ev = Remotes.event("TutorialStep")
	for _, p in session.Players do
		ev:FireClient(p, session.TutStep, step and { Key = step.Key, Target = step.Target, Total = #STEPS, Wait = step.Wait } or nil)
	end
end

local function baby(session)
	return session.BabyList[1]
end

local function enterStep(session, index: number)
	session.TutStep = index
	session.TutTimer = 0
	local step = STEPS[index]
	if not step then
		-- done: parents return, stars, reward
		session.ClockFrozen = false
		session.Time = session.Duration
		return
	end
	local b = baby(session)
	if step.Key == "Tut_Bubble" and b then
		BabyBase.set(b, "Hunger", 28)
	elseif step.Key == "Tut_Sleep" and b then
		BabyBase.set(b, "Hunger", 90)
		BabyBase.set(b, "Sleep", 22)
	elseif step.Key == "Tut_Fire" then
		local kitchen = session.Model:FindFirstChild("Room_Playroom", true) :: BasePart?
		local pos = if kitchen then kitchen.Position + Vector3.new(6, -6, 8) else session:Origin()
		S.HazardService:SpawnFire(session, pos, nil)
	elseif step.Key == "Tut_Tantrum" and b then
		BabyBase.set(b, "Warmth", 0)
	end
	send(session)
end

function TutorialService:Begin(session)
	session.TutStep = 0
	enterStep(session, 1)
end

function TutorialService:OnEvent(session, event: string, _player: Player?)
	if not session or not session.Tutorial or not session.TutStep then
		return
	end
	local step = STEPS[session.TutStep]
	if step and step.Wait == event then
		enterStep(session, session.TutStep + 1)
	end
end

function TutorialService:Tick(session, dt)
	if not session.Tutorial or not session.TutStep then
		return
	end
	local step = STEPS[session.TutStep]
	if not step then
		return
	end
	session.TutTimer += dt
	if step.Wait == "Timer" and session.TutTimer >= (step.Time or 5) then
		enterStep(session, session.TutStep + 1)
		return
	end
	-- keep the baby from melting down outside of the scripted moments
	local b = baby(session)
	if b then
		for n, v in b.Needs do
			local scripted = (step.Key == "Tut_Bubble" or step.Key == "Tut_Cook") and n == "Hunger"
				or step.Key == "Tut_Sleep" and n == "Sleep"
				or step.Key == "Tut_Tantrum" and n == "Warmth"
			if not scripted and v < 45 then
				BabyBase.set(b, n, 45)
			end
			if scripted and step.Key ~= "Tut_Tantrum" and v < 12 then
				BabyBase.set(b, n, 12)
			end
		end
		-- the tantrum step: once warm again the player may continue
		if step.Key == "Tut_Tantrum" and session.TutTimer > 25 then
			enterStep(session, session.TutStep + 1)
		end
	end
end

function TutorialService:Init(services)
	S = services
end

function TutorialService:Start()
	Remotes.event("TutorialAction").OnServerEvent:Connect(function(player, action)
		if not ServerUtil.rateLimit(player, "Tutorial", 2) then
			return
		end
		local session = S.ShiftService:SessionOf(player)
		if action == "Next" and session and session.Tutorial then
			TutorialService:OnEvent(session, "Next", player)
		elseif action == "Skip" then
			S.DataService:Update(player, function(d)
				d.TutorialDone = true
			end)
			if session and session.Tutorial then
				S.ShiftService:Teardown(session, true)
			end
		elseif action == "Replay" and not session then
			S.QueueService:Leave(player)
			if not S.ShiftService:StartShift({ player }, { Tutorial = true, Difficulty = "Easy" }) then
				ServerUtil.notify(player, "Queue_NoSlot", "error")
			end
		end
	end)
end

return TutorialService
