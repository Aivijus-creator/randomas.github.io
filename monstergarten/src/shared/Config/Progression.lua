--!strict
-- Daycare levels (by total stars) and nanny levels (by XP).

export type DaycareLevel = { Level: number, Stars: number, Unlocks: { string } }

-- Unlock ids: "Baby:<Id>", "Tool:<Id>", "Difficulty:<Id>", "Room:<Id>", "Shop:<UpgradeId>", "Cosmetic:<Id>"
local DaycareLevels: { DaycareLevel } = {
	{ Level = 1, Stars = 0, Unlocks = { "Baby:Dragling", "Baby:Slimy", "Baby:Ghostie", "Difficulty:Easy" } },
	{ Level = 2, Stars = 5, Unlocks = { "Tool:Hammer", "Tool:Lullaby" } },
	{ Level = 3, Stars = 12, Unlocks = { "Baby:Vampy", "Tool:Net", "Difficulty:Normal" } },
	{ Level = 4, Stars = 20, Unlocks = { "Baby:Octo" } },
	{ Level = 5, Stars = 30, Unlocks = { "Room:Basement" } },
	{ Level = 6, Stars = 42, Unlocks = { "Baby:Golem", "Tool:TrashBag" } },
	{ Level = 7, Stars = 56, Unlocks = { "Shop:SecondOven" } },
	{ Level = 8, Stars = 72, Unlocks = { "Baby:Sparky" } },
	{ Level = 9, Stars = 90, Unlocks = { "Difficulty:Nightmare" } },
	{ Level = 10, Stars = 110, Unlocks = { "Baby:Sprout", "Room:Greenhouse", "Tool:Shears", "Tool:WateringCan" } },
	{ Level = 11, Stars = 135, Unlocks = { "Shop:AutoFeeder" } },
	{ Level = 12, Stars = 160, Unlocks = { "Baby:Yeti", "Room:IceMat" } },
	{ Level = 13, Stars = 190, Unlocks = { "Shop:FireproofFurniture" } },
	{ Level = 14, Stars = 225, Unlocks = { "Baby:Mummy", "Tool:BandageRoll" } },
	{ Level = 15, Stars = 265, Unlocks = { "Cosmetic:GoldenSign" } },
}

local NannyTitles = {
	{ Level = 1, Key = "Title_Rookie" },
	{ Level = 5, Key = "Title_Helper" },
	{ Level = 10, Key = "Title_Whisperer" },
	{ Level = 15, Key = "Title_Tamer" },
	{ Level = 20, Key = "Title_ChaosLord" },
	{ Level = 30, Key = "Title_Legend" },
}

-- Rewards granted on reaching a nanny level (coins unless a cosmetic is listed).
local NannyLevelRewards: { [number]: { Coins: number?, Cosmetic: string? } } = {
	[2] = { Coins = 100 },
	[3] = { Cosmetic = "Hat_Bow" },
	[4] = { Coins = 150 },
	[5] = { Cosmetic = "Apron_Stars" },
	[6] = { Coins = 200 },
	[7] = { Cosmetic = "Hat_Beanie" },
	[8] = { Coins = 250 },
	[10] = { Cosmetic = "Uniform_Night" },
	[12] = { Coins = 400 },
	[15] = { Cosmetic = "Hat_Crown" },
}

return {
	DaycareLevels = DaycareLevels,
	NannyTitles = NannyTitles,
	NannyLevelRewards = NannyLevelRewards,
	XPBase = 100,
	XPExponent = 1.3,
	ShiftXPBase = 20,
	ShiftXPMax = 150,
	FriendshipToAdopt = 5,
	DailyRewards = { 50, 75, 100, 150, 200, 300, 500 },
	TutorialReward = 200,
	MVPBonus = 0.2,
}
