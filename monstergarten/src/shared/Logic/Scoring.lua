--!strict
-- Shift scoring formulas (GDD 10.2 / 10.3). Pure.
local MathUtil = require(script.Parent.Parent.Util.Math)

export type BabyResult = {
	TantrumSeconds: number,
	InTantrumAtEnd: boolean,
	Escaped: boolean,
	GhostHidden: boolean,
	AllNeedsHappy: boolean,
}

export type BuildingResult = {
	AvgFurnitureHP: number, -- 0..100
	Trash: number,
	Spills: number,
	FireBurning: boolean,
}

local Scoring = {}

function Scoring.babyScore(b: BabyResult): number
	local s = 100 - 0.5 * b.TantrumSeconds
	if b.InTantrumAtEnd then
		s -= 10
	end
	if b.Escaped then
		s -= 30
	end
	if b.GhostHidden then
		s -= 15
	end
	if b.AllNeedsHappy then
		s += 5
	end
	return MathUtil.clamp(s, 0, 100)
end

function Scoring.buildingScore(b: BuildingResult): number
	local s = b.AvgFurnitureHP - 1 * b.Trash - 2 * b.Spills
	if b.FireBurning then
		s -= 10
	end
	return MathUtil.clamp(s, 0, 100)
end

function Scoring.finalScore(babyScores: { number }, building: number, eventBonus: number): number
	local sum = 0
	for _, s in babyScores do
		sum += s
	end
	local avg = if #babyScores > 0 then sum / #babyScores else 100
	return MathUtil.clamp(0.7 * avg + 0.3 * building + math.min(eventBonus, 10), 0, 110)
end

function Scoring.stars(final: number): number
	if final >= 85 then
		return 3
	elseif final >= 60 then
		return 2
	elseif final >= 35 then
		return 1
	end
	return 0
end

function Scoring.coins(final: number, stars: number, eventCoins: number, difficultyMult: number): number
	return math.floor((50 + 2 * final + 25 * stars + eventCoins) * difficultyMult + 0.5)
end

function Scoring.xp(actions: number, base: number, max: number): number
	return math.min(base + actions, max)
end

return Scoring
