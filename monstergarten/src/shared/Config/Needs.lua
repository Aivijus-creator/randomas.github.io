--!strict
-- Need definitions. Base decay is per second at multiplier 1.

export type NeedDef = {
	Id: string,
	Base: number,
	Emoji: string,
	Color: Color3,
	Station: string?, -- CollectionService tag of the station that refills it (passive)
	Rate: number?, -- refill per second at station
}

local Needs: { [string]: NeedDef } = {
	Hunger = { Id = "Hunger", Base = 0.70, Emoji = "🍖", Color = Color3.fromRGB(255, 170, 90) },
	Sleep = { Id = "Sleep", Base = 0.50, Emoji = "💤", Color = Color3.fromRGB(140, 150, 255), Station = "Bed", Rate = 8 },
	Fun = { Id = "Fun", Base = 0.80, Emoji = "🧸", Color = Color3.fromRGB(255, 120, 170) },
	Clean = { Id = "Clean", Base = 0.45, Emoji = "🫧", Color = Color3.fromRGB(120, 210, 255) },
	Warmth = { Id = "Warmth", Base = 0.60, Emoji = "🔥", Color = Color3.fromRGB(255, 110, 60), Station = "Fireplace", Rate = 10 },
	Darkness = { Id = "Darkness", Base = 0.60, Emoji = "🌙", Color = Color3.fromRGB(110, 90, 160), Station = "DarkZone", Rate = 10 },
	Charge = { Id = "Charge", Base = 0.60, Emoji = "🔋", Color = Color3.fromRGB(255, 225, 80), Station = "ChargingStation", Rate = 12 },
	Sun = { Id = "Sun", Base = 0.60, Emoji = "☀️", Color = Color3.fromRGB(255, 220, 120), Station = "SunSpot", Rate = 10 },
	Water = { Id = "Water", Base = 0.60, Emoji = "💧", Color = Color3.fromRGB(90, 170, 255) },
	Cold = { Id = "Cold", Base = 0.60, Emoji = "🧊", Color = Color3.fromRGB(170, 230, 255), Station = "ColdSpot", Rate = 10 },
	Bandages = { Id = "Bandages", Base = 0.60, Emoji = "🩹", Color = Color3.fromRGB(240, 225, 190) },
}

local Order = { "Hunger", "Sleep", "Fun", "Clean", "Warmth", "Darkness", "Charge", "Sun", "Water", "Cold", "Bandages" }

-- Thresholds (see GDD section 4).
local Thresholds = {
	Happy = 70,
	Bubble = 35,
	Crying = 15,
	TantrumEnd = 50,
}

-- Player scaling of decay by number of nannies in the shift.
local PlayerScale = { 0.80, 0.90, 1.0, 1.05, 1.10, 1.15 }

-- Amounts restored by actions.
local Restore = {
	FeedFavorite = 60,
	FeedSuitable = 25,
	FeedCake = 40,
	FeedRaw = 20,
	FeedWrong = -10,
	ToyFun = 45,
	PlayFun = 30,
	Wash = 80,
	Water = 60,
	Bandage = 80,
	SleepLullaby = 14,
	IceFeedCold = 40,
}

return {
	Defs = Needs,
	Order = Order,
	Thresholds = Thresholds,
	PlayerScale = PlayerScale,
	Restore = Restore,
	AsleepOtherDecay = 0.5,
}
