--!strict
export type DifficultyDef = {
	Id: string,
	UnlockLevel: number,
	BabyBonus: number,
	MinBabies: number,
	MaxBabies: number,
	NeedDecay: number,
	ChaosStrength: number,
	Events: number,
	Coins: number,
	Color: Color3,
}

local Difficulty: { [string]: DifficultyDef } = {
	Easy = { Id = "Easy", UnlockLevel = 1, BabyBonus = 2, MinBabies = 3, MaxBabies = 6, NeedDecay = 0.75, ChaosStrength = 0.75, Events = 1, Coins = 1.0, Color = Color3.fromRGB(168, 230, 207) },
	Normal = { Id = "Normal", UnlockLevel = 3, BabyBonus = 3, MinBabies = 4, MaxBabies = 8, NeedDecay = 1.0, ChaosStrength = 1.0, Events = 2, Coins = 1.5, Color = Color3.fromRGB(255, 211, 182) },
	Nightmare = { Id = "Nightmare", UnlockLevel = 9, BabyBonus = 4, MinBabies = 5, MaxBabies = 10, NeedDecay = 1.35, ChaosStrength = 1.5, Events = 3, Coins = 2.5, Color = Color3.fromRGB(195, 120, 200) },
}

return {
	Defs = Difficulty,
	Order = { "Easy", "Normal", "Nightmare" },
	MaxSameSpecies = 2,
}
