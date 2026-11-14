--!strict
-- Shared type definitions.

-- What a player holds: Kind + Id (+ optional extra like baby uid or trash count).
export type Held = {
	Kind: "Tool" | "Ingredient" | "Dish" | "Baby" | "Trash",
	Id: string,
	Extra: any?,
}

export type QueueState = {
	DoorId: string,
	Host: number,
	Players: { number },
	Difficulty: string,
	Countdown: number,
	Solo: boolean,
	Tutorial: boolean,
	Waiting: boolean,
	PreferredBabies: { string }?,
}

export type ShiftResults = {
	Stars: number,
	FinalScore: number,
	BuildingScore: number,
	Babies: { { BabyId: string, Score: number, Emoji: string } },
	Coins: number,
	XP: number,
	MVP: number?,
	EventCoins: number,
	Tutorial: boolean,
}

return nil
