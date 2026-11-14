--!strict
-- Random shift events (GDD section 9).

export type EventDef = {
	Id: string,
	Emoji: string,
	Duration: number,
	Reward: number,
	MinClock: number?, -- earliest in-game hour
	Weight: number,
}

local Events: { [string]: EventDef } = {
	Storm = { Id = "Storm", Emoji = "🌩️", Duration = 45, Reward = 50, Weight = 1 },
	Birthday = { Id = "Birthday", Emoji = "🎂", Duration = 90, Reward = 100, Weight = 1 },
	Inspector = { Id = "Inspector", Emoji = "🕵️", Duration = 60, Reward = 150, Weight = 1 },
	MysteryEgg = { Id = "MysteryEgg", Emoji = "🥚", Duration = 60, Reward = 0, Weight = 0.8 },
	FullMoon = { Id = "FullMoon", Emoji = "🌕", Duration = 40, Reward = 75, MinClock = 16, Weight = 0.8 },
	MessRain = { Id = "MessRain", Emoji = "🧹", Duration = 40, Reward = 5, Weight = 1 },
	Escape = { Id = "Escape", Emoji = "🎈", Duration = 30, Reward = 80, Weight = 1 },
}

local Order = { "Storm", "Birthday", "Inspector", "MysteryEgg", "FullMoon", "MessRain", "Escape" }

return {
	Defs = Events,
	Order = Order,
	MinGap = 90,
	-- Approximate anchor times (seconds into the shift); each is jittered.
	Anchors = { 90, 210, 330 },
	Jitter = 25,
	MaxBonusScore = 10,
}
