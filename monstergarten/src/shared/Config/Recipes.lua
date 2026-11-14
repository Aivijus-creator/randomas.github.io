--!strict
-- Ingredients, dishes and recipes.

local Ingredients = {
	Meat = { Emoji = "🥩", Color = Color3.fromRGB(200, 80, 80) },
	Pepper = { Emoji = "🌶️", Color = Color3.fromRGB(230, 50, 40) },
	Milk = { Emoji = "🥛", Color = Color3.fromRGB(250, 250, 250) },
	Fish = { Emoji = "🐟", Color = Color3.fromRGB(120, 170, 220) },
	Beet = { Emoji = "🫜", Color = Color3.fromRGB(150, 30, 80) },
	Berries = { Emoji = "🫐", Color = Color3.fromRGB(90, 80, 200) },
	Rocks = { Emoji = "🪨", Color = Color3.fromRGB(140, 140, 140) },
	Flour = { Emoji = "🌾", Color = Color3.fromRGB(240, 225, 180) },
	Ice = { Emoji = "🧊", Color = Color3.fromRGB(190, 235, 255) },
}

local Dishes = {
	SpicySteak = { Emoji = "🌶️", Color = Color3.fromRGB(170, 70, 40) },
	BeetJuice = { Emoji = "🥤", Color = Color3.fromRGB(160, 30, 90) },
	FishMash = { Emoji = "🐟", Color = Color3.fromRGB(230, 220, 190) },
	RockCookies = { Emoji = "🍪", Color = Color3.fromRGB(150, 130, 110) },
	BerryIceCream = { Emoji = "🍨", Color = Color3.fromRGB(190, 160, 255) },
	Porridge = { Emoji = "🥣", Color = Color3.fromRGB(245, 230, 190) },
	Cake = { Emoji = "🎂", Color = Color3.fromRGB(255, 190, 210) },
	Burnt = { Emoji = "💩", Color = Color3.fromRGB(40, 35, 30) },
}

export type Recipe = { Dish: string, Ingredients: { string }, Appliance: string, Time: number, Event: boolean? }

local Recipes: { Recipe } = {
	{ Dish = "SpicySteak", Ingredients = { "Meat", "Pepper" }, Appliance = "Oven", Time = 8 },
	{ Dish = "BeetJuice", Ingredients = { "Beet" }, Appliance = "Blender", Time = 4 },
	{ Dish = "FishMash", Ingredients = { "Fish", "Milk" }, Appliance = "Pot", Time = 7 },
	{ Dish = "RockCookies", Ingredients = { "Rocks", "Flour" }, Appliance = "Oven", Time = 9 },
	{ Dish = "BerryIceCream", Ingredients = { "Berries", "Milk" }, Appliance = "Freezer", Time = 6 },
	{ Dish = "Porridge", Ingredients = { "Flour", "Milk" }, Appliance = "Pot", Time = 6 },
	{ Dish = "Cake", Ingredients = { "Flour", "Milk", "Berries" }, Appliance = "Oven", Time = 10, Event = true },
}

local Appliances = {
	Oven = { Electric = true, CanBurn = true, Emoji = "♨️" },
	Pot = { Electric = false, CanBurn = true, Emoji = "🍲" },
	Blender = { Electric = true, CanBurn = false, Emoji = "🌀" },
	Freezer = { Electric = true, CanBurn = false, Emoji = "❄️" },
}

return {
	Ingredients = Ingredients,
	Dishes = Dishes,
	Recipes = Recipes,
	Appliances = Appliances,
	OvercookTime = 12, -- seconds after ready before burning
	BurnToFire = 8, -- seconds after burning before fire starts
	MaxSlots = 3,
}
