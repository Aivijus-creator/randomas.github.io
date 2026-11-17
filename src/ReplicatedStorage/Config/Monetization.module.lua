--[[
	Monetization – gamepass'ai, developer products ir grupės bonusas.

	KUR ĮRAŠYTI ID:
	  1. Creator Hub → tavo žaidimas → Monetization → Passes → Create a Pass.
	     Sukūręs nukopijuok Pass ID ir įrašyk į atitinkamą Id lauką žemiau.
	  2. Creator Hub → Monetization → Developer Products → Create a Developer Product.
	     Product ID įrašyk į Products lentelę.
	  3. Grupės ID (skaičius iš grupės nuorodos) įrašyk į GroupId.
	Kol Id = 0, pirkinys parduotuvėje rodomas, bet pirkti negalima (žaidimas praneša,
	kad pirkinys nesukonfigūruotas). Studio testams naudok admin komandą /givepass.
]]

local Monetization = {}

-- Vienkartiniai, nuolatiniai gamepass'ai
Monetization.GamePasses = {
	DoubleMoney = { Id = 2089545485, Price = 249, Icon = "💰", Multiplier = 2 },
	FastDroppers = { Id = 2088213496, Price = 149, Icon = "⚡", IntervalReduction = 0.25 },
	GrannyHelp = { Id = 2089425499, Price = 199, Icon = "👵" },
	VIP = { Id = 2089545487, Price = 299, Icon = "👑", IncomeBonus = 0.10 },
	OfflineIncome = { Id = 2087829547, Price = 199, Icon = "🌙" },
}
Monetization.PassOrder = { "DoubleMoney", "FastDroppers", "GrannyHelp", "VIP", "OfflineIncome" }

-- Developer products (perkami kiek nori kartų)
Monetization.Products = {
	SmallBag = { Id = 3731452390, Price = 25, Icon = "👛", IncomeSeconds = 600, MinReward = 500 },      -- 10 min. pajamų
	BigBag = { Id = 3731452493, Price = 99, Icon = "💼", IncomeSeconds = 3600, MinReward = 3000 },      -- 1 val. pajamų
	PotatoRain = { Id = 3731452620, Price = 49, Icon = "🥔" },                                          -- Bulvių lietus visam serveriui
	Boost3 = { Id = 3731452746, Price = 39, Icon = "🚀", Multiplier = 3, Duration = 900 },              -- ×3 pinigai 15 min.
}
Monetization.ProductOrder = { "SmallBag", "BigBag", "PotatoRain", "Boost3" }

-- Roblox grupė (0 = išjungta)
Monetization.GroupId = 0
Monetization.GroupBonus = 0.10

-- Kiek paskutinių apdorotų PurchaseId laikyti žaidėjo duomenyse
Monetization.ReceiptHistory = 50

return Monetization
