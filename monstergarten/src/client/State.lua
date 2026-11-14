-- Client-side state store: player data snapshot, shift state, held item. Signals on change.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Net.Remotes)
local Signal = require(Shared.Util.Signal)
local Strings = require(Shared.Strings)

local player = Players.LocalPlayer

local State = {
	Data = nil :: any,
	Shift = nil :: any, -- current shift state (nil in lobby)
	Controllers = {} :: { [string]: any },
	DataChanged = Signal.new(),
	ShiftChanged = Signal.new(),
	HeldChanged = Signal.new(),
	LanguageChanged = Signal.new(),
	Held = nil :: { Kind: string, Id: string }?,
}

local function parseHeld(s: string?): any
	if not s or s == "" then
		return nil
	end
	local kind, id = s:match("^(%w+):(.+)$")
	if not kind then
		return nil
	end
	return { Kind = kind, Id = id }
end

function State.applyLanguage()
	local d = State.Data
	local lang = Strings.resolve(d and d.Settings and d.Settings.Language or "auto", player.LocaleId)
	if lang ~= Strings.language() then
		Strings.setLanguage(lang)
		State.LanguageChanged:Fire(lang)
	end
end

function State.inShift(): boolean
	return State.Shift ~= nil
end

function State.start()
	Remotes.event("DataChanged").OnClientEvent:Connect(function(data)
		State.Data = data
		State.applyLanguage()
		State.DataChanged:Fire(data)
	end)
	Remotes.event("ShiftState").OnClientEvent:Connect(function(shift)
		State.Shift = shift
		State.ShiftChanged:Fire(shift)
	end)
	player:GetAttributeChangedSignal("Held"):Connect(function()
		State.Held = parseHeld(player:GetAttribute("Held"))
		State.HeldChanged:Fire(State.Held)
	end)
	State.Held = parseHeld(player:GetAttribute("Held"))
	task.spawn(function()
		local ok, data = pcall(function()
			return Remotes.func("GetData"):InvokeServer()
		end)
		if ok and data and not State.Data then
			State.Data = data
			State.applyLanguage()
			State.DataChanged:Fire(data)
		end
	end)
end

State.parseHeld = parseHeld
State.player = player

return State
