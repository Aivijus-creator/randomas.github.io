--!strict
-- Daily quest pool. Stat = counter key incremented by QuestService.track(player, stat, amount).
export type QuestDef = { Id: string, Stat: string, Goal: number, Reward: number, Arg: string? }

local Quests: { QuestDef } = {
	{ Id = "PutOutFires", Stat = "FirePutOut", Goal = 10, Reward = 150 },
	{ Id = "FeedBabies", Stat = "Fed", Goal = 15, Reward = 120 },
	{ Id = "FindGhostie", Stat = "GhostFound", Goal = 5, Reward = 180 },
	{ Id = "ThreeStarDragling", Stat = "ThreeStarBaby", Arg = "Dragling", Goal = 3, Reward = 200 },
	{ Id = "CookDishes", Stat = "Cooked", Goal = 12, Reward = 120 },
	{ Id = "CleanMess", Stat = "Cleaned", Goal = 20, Reward = 130 },
	{ Id = "PlayShifts", Stat = "ShiftPlayed", Goal = 3, Reward = 150 },
	{ Id = "Bedtime", Stat = "PutToBed", Goal = 8, Reward = 110 },
	{ Id = "RepairFurniture", Stat = "Repaired", Goal = 5, Reward = 140 },
	{ Id = "EarnStars", Stat = "Stars", Goal = 6, Reward = 200 },
}

return { Pool = Quests, PerDay = 3 }
