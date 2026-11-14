--!strict
-- Need decay math. Pure.
local Needs = require(script.Parent.Parent.Config.Needs)

local NeedMath = {}

function NeedMath.playerScale(players: number): number
	local n = math.clamp(players, 1, #Needs.PlayerScale)
	return Needs.PlayerScale[n]
end

-- Decay per second for one need of one baby.
function NeedMath.decayRate(needId: string, babyMult: number, difficultyMult: number, players: number): number
	local def = Needs.Defs[needId]
	if not def then
		return 0
	end
	return def.Base * babyMult * difficultyMult * NeedMath.playerScale(players)
end

function NeedMath.state(value: number): string
	local t = Needs.Thresholds
	if value <= 0 then
		return "Tantrum"
	elseif value < t.Crying then
		return "Crying"
	elseif value < t.Bubble then
		return "Bubble"
	elseif value > t.Happy then
		return "Happy"
	end
	return "Normal"
end

function NeedMath.mood(needs: { [string]: number }): number
	local sum, n = 0, 0
	for _, v in needs do
		sum += v
		n += 1
	end
	return if n > 0 then sum / n else 100
end

return NeedMath
