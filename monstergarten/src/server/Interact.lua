-- Interact: one global ProximityPrompt listener that validates and routes prompt actions to services.
-- Prompts carry an "Action" attribute; services register handlers with Interact.on(action, fn).
local ProximityPromptService = game:GetService("ProximityPromptService")

local ServerUtil = require(script.Parent.ServerUtil)

local Interact = {}
local handlers: { [string]: (Player, ProximityPrompt, any) -> () } = {}
local holdHandlers: { [string]: (Player, ProximityPrompt, any) -> () } = {}
local sessionOf: ((Player) -> any)? = nil

function Interact.setSessionResolver(fn: (Player) -> any)
	sessionOf = fn
end

-- fn(player, prompt, session) — session is nil for lobby prompts.
function Interact.on(action: string, fn: (Player, ProximityPrompt, any) -> ())
	handlers[action] = fn
end

-- Called when a hold-prompt starts (e.g. to start an animation); optional.
function Interact.onHoldBegan(action: string, fn: (Player, ProximityPrompt, any) -> ())
	holdHandlers[action] = fn
end

local function validate(player: Player, prompt: ProximityPrompt): (boolean, any)
	local action = prompt:GetAttribute("Action")
	if type(action) ~= "string" then
		return false, nil
	end
	if not ServerUtil.rateLimit(player, "Interact", 10) then
		return false, nil
	end
	local parent = prompt.Parent
	local pos: Vector3? = nil
	if parent and parent:IsA("BasePart") then
		pos = parent.Position
	elseif parent and parent:IsA("Attachment") then
		pos = parent.WorldPosition
	elseif parent and parent:IsA("Model") then
		pos = parent:GetPivot().Position
	end
	if not pos or not ServerUtil.inRange(player, pos, prompt.MaxActivationDistance + 6) then
		return false, nil
	end
	local session = sessionOf and sessionOf(player)
	if session then
		if not prompt:IsDescendantOf(session.Model) then
			return false, nil
		end
		if session.Phase ~= "Playing" then
			return false, nil
		end
	elseif not prompt:IsDescendantOf(workspace) then
		return false, nil
	end
	return true, session
end

function Interact.start()
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local ok, session = validate(player, prompt)
		if not ok then
			return
		end
		local fn = handlers[prompt:GetAttribute("Action")]
		if fn then
			local success, err = pcall(fn, player, prompt, session)
			if not success then
				warn("[Interact] handler error", prompt:GetAttribute("Action"), err)
			end
		end
	end)
	ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
		local fn = holdHandlers[prompt:GetAttribute("Action")]
		if fn then
			local ok, session = validate(player, prompt)
			if ok then
				pcall(fn, player, prompt, session)
			end
		end
	end)
end

return Interact
