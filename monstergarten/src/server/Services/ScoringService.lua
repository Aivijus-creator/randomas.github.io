-- ScoringService: computes baby / building / final scores and stars at the end of a shift (GDD 10.2).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Scoring = require(Shared.Logic.Scoring)
local BabyBase = require(script.Parent.Parent.Babies.BabyBase)

local ScoringService = {}
local S

function ScoringService:Init(services)
	S = services
end

local function face(score: number): string
	if score >= 85 then
		return "😃"
	elseif score >= 50 then
		return "😐"
	end
	return "😢"
end

function ScoringService:Compute(session)
	local babyScores, babies = {}, {}
	for _, b in session.BabyList do
		local score = Scoring.babyScore({
			TantrumSeconds = b.TantrumSeconds,
			InTantrumAtEnd = b.Tantrum ~= nil,
			Escaped = b.Escaped,
			GhostHidden = b.Def.Id == "Ghostie" and b.Hidden,
			AllNeedsHappy = BabyBase.allHappy(b),
		})
		table.insert(babyScores, score)
		table.insert(babies, { Uid = b.Uid, BabyId = b.Id, Score = math.floor(score + 0.5), Face = face(score) })
	end
	local trash, spills, fire = S.HazardService:Counts(session)
	local building = Scoring.buildingScore({
		AvgFurnitureHP = S.FurnitureService:BuildingHealth(session),
		Trash = trash,
		Spills = spills,
		FireBurning = fire,
	})
	local final = Scoring.finalScore(babyScores, building, session.EventBonus)
	local stars = Scoring.stars(final)
	return {
		Stars = stars,
		FinalScore = math.floor(final + 0.5),
		BuildingScore = math.floor(building + 0.5),
		Babies = babies,
		EventCoins = session.EventCoins,
		EventBonus = session.EventBonus,
		Difficulty = session.Difficulty.Id,
		Tutorial = session.Tutorial,
	}
end

return ScoringService
