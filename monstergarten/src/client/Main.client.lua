-- Monstergarten client entry point. Loads controllers (Init on all, then Start on all).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:WaitForChild("Shared")
ReplicatedStorage:WaitForChild("Remotes")

local State = require(script.Parent.State)
local Folder = script.Parent:WaitForChild("Controllers")

local ORDER = {
	"SettingsController", "SoundController", "InputController", "MobileController", "CameraController",
	"LightingController", "EffectsController", "AnimationController", "BubbleController",
	"InteractionController", "HUDController", "CutsceneController", "QueueController", "ResultsController",
	"ShopController", "WardrobeController", "PetController", "TutorialController", "DebugController",
	"LoadingController",
}

local Controllers = {}
State.Controllers = Controllers

for _, name in ORDER do
	local mod = Folder:FindFirstChild(name)
	if mod then
		local ok, c = pcall(require, mod)
		if ok then
			Controllers[name] = c
		else
			warn("[Client] failed to load", name, c)
		end
	end
end

for _, name in ORDER do
	local c = Controllers[name]
	if c and c.Init then
		local ok, err = pcall(c.Init, c, Controllers)
		if not ok then
			warn("[Client] Init failed", name, err)
		end
	end
end

for _, name in ORDER do
	local c = Controllers[name]
	if c and c.Start then
		task.spawn(function()
			local ok, err = pcall(c.Start, c)
			if not ok then
				warn("[Client] Start failed", name, err)
			end
		end)
	end
end

State.start()
