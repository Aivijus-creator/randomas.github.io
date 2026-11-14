--!strict
-- Daycare upgrades (coins). Tool upgrades are priced in Config/Tools (UpgradeCost).

export type DaycareUpgrade = { Id: string, Emoji: string, Cost: number, UnlockLevel: number }

local DaycareUpgrades: { [string]: DaycareUpgrade } = {
	DoublePot = { Id = "DoublePot", Emoji = "🍲", Cost = 600, UnlockLevel = 2 },
	ExtraRacks = { Id = "ExtraRacks", Emoji = "🧰", Cost = 800, UnlockLevel = 3 },
	SecondFireplace = { Id = "SecondFireplace", Emoji = "🔥", Cost = 1000, UnlockLevel = 4 },
	AutoShutoff = { Id = "AutoShutoff", Emoji = "⏲️", Cost = 1500, UnlockLevel = 5 },
	MegaBlender = { Id = "MegaBlender", Emoji = "🌀", Cost = 900, UnlockLevel = 5 },
	SecondOven = { Id = "SecondOven", Emoji = "♨️", Cost = 2000, UnlockLevel = 7 },
	AutoFeeder = { Id = "AutoFeeder", Emoji = "🤖", Cost = 3000, UnlockLevel = 11 },
	FireproofFurniture = { Id = "FireproofFurniture", Emoji = "🧱", Cost = 4000, UnlockLevel = 13 },
}

local DaycareOrder = { "DoublePot", "ExtraRacks", "SecondFireplace", "AutoShutoff", "MegaBlender", "SecondOven", "AutoFeeder", "FireproofFurniture" }

-- Coin packs (Developer Products, ids in Config/Monetization).
local CoinPacks = {
	{ Id = "CoinsSmall", Coins = 500 },
	{ Id = "CoinsMedium", Coins = 1500 },
	{ Id = "CoinsLarge", Coins = 4000 },
}

return {
	DaycareUpgrades = DaycareUpgrades,
	DaycareOrder = DaycareOrder,
	CoinPacks = CoinPacks,
}
