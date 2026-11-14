--!strict
-- All remotes in one place. The server creates them (Remotes.setup()), clients wait for them.
-- C>S = client to server, S>C = server to client.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EVENTS = {
	-- C>S
	"DropHeld", -- ()
	"UseTool", -- (dir: Vector3, holding: boolean)
	"QueueAction", -- (action: string, arg: any)
	"CutsceneSkip", -- ()
	"ResultsChoice", -- ("Again" | "Lobby")
	"ShopBuy", -- (kind: string, id: string)
	"Equip", -- (slot: string, id: string?)
	"PetAction", -- (action: string, index: number, arg: any)
	"ClaimDaily", -- ()
	"SetSetting", -- (key: string, value: any)
	"TutorialAction", -- ("Skip" | "Next" | "Replay")
	"DebugCommand", -- (cmd: string, ...)
	"PromptPurchase", -- (kind: "Pass" | "Product" | "Cosmetic", id: string)
	"PlayEmote", -- (name)
	-- S>C
	"Notify", -- (msg: {key,...}, kind: string)
	"DataChanged", -- (data snapshot)
	"ShiftState", -- (state table)
	"Cutscene", -- (kind: string, data)
	"Banner", -- (eventId: string, phase: string, extra)
	"Effect", -- (name: string, payload)
	"Sound", -- (name: string, position: Vector3?)
	"TutorialStep", -- (index: number, data)
	"QueueUpdate", -- (state or nil)
	"CameraShake", -- (intensity: number, position: Vector3?, radius: number?)
	"Fade", -- (fadeIn: boolean, time: number)
	"Results", -- (results table)
	"DebugInfo", -- (info)
}

local FUNCTIONS = {
	"GetData", -- () -> snapshot
	"GetLeaderboard", -- (board) -> entries
}

local Remotes = {}
local folder: Folder? = nil

function Remotes.setup()
	assert(RunService:IsServer(), "Remotes.setup is server-only")
	local f = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
	if not f then
		local nf = Instance.new("Folder")
		nf.Name = "Remotes"
		nf.Parent = ReplicatedStorage
		f = nf
	end
	for _, name in EVENTS do
		if not (f :: Folder):FindFirstChild(name) then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = f
		end
	end
	for _, name in FUNCTIONS do
		if not (f :: Folder):FindFirstChild(name) then
			local r = Instance.new("RemoteFunction")
			r.Name = name
			r.Parent = f
		end
	end
	folder = f
end

local function getFolder(): Folder
	if folder then
		return folder
	end
	if RunService:IsServer() then
		Remotes.setup()
		return folder :: Folder
	end
	folder = ReplicatedStorage:WaitForChild("Remotes", 60) :: Folder
	return folder :: Folder
end

function Remotes.event(name: string): RemoteEvent
	local r = getFolder():WaitForChild(name, 30)
	assert(r and r:IsA("RemoteEvent"), "Unknown remote event " .. name)
	return r :: RemoteEvent
end

function Remotes.func(name: string): RemoteFunction
	local r = getFolder():WaitForChild(name, 30)
	assert(r and r:IsA("RemoteFunction"), "Unknown remote function " .. name)
	return r :: RemoteFunction
end

Remotes.EVENTS = EVENTS
Remotes.FUNCTIONS = FUNCTIONS

return Remotes
