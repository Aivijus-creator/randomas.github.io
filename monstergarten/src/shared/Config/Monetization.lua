--!strict
-- Game Pass / Developer Product ids. 0 = not created yet -> hidden in UI.
-- The author creates them on the Creator Dashboard and pastes the ids here.

return {
	GamePasses = {
		VIP = 0, -- gold name, VIP apron, +1 pet slot
		HeadNanny = 0, -- choose which babies come to the shift
		MusicBox = 0, -- pick lobby music
		CoinPouch = 0, -- +50% coins from shifts
	},
	Products = {
		CoinsSmall = 0,
		CoinsMedium = 0,
		CoinsLarge = 0,
	},
	-- Premium cosmetics sold as Developer Products: CosmeticId -> product id
	PremiumCosmetics = {
		Hat_Witch = 0,
		Skin_DragonExtinguisher = 0,
		Skin_MoonFlashlight = 0,
		PetAcc_Crown = 0,
	},
	CoinPouchBonus = 0.5,
}
