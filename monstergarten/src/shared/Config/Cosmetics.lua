--!strict
-- Cosmetics are built from parts at runtime (no uploads needed).
-- Slot: Hat | Apron | Uniform | ToolSkin | PetAccessory
-- Premium = bought with a Developer Product (id in Config/Monetization.PremiumCosmetics).

export type CosmeticDef = {
	Id: string,
	Slot: string,
	Name: { en: string, lt: string },
	Cost: number, -- 0 = not sold for coins (reward / premium / pass)
	Color: Color3,
	Style: string, -- builder style key
	Premium: boolean?,
	Tool: string?, -- for ToolSkin
	Material: Enum.Material?,
}

local C: { [string]: CosmeticDef } = {
	Hat_Bow = { Id = "Hat_Bow", Slot = "Hat", Name = { en = "Big Bow", lt = "Didelis kaspinas" }, Cost = 0, Color = Color3.fromRGB(255, 170, 165), Style = "Bow" },
	Hat_Beanie = { Id = "Hat_Beanie", Slot = "Hat", Name = { en = "Cozy Beanie", lt = "Jauki kepurytė" }, Cost = 0, Color = Color3.fromRGB(168, 230, 207), Style = "Beanie" },
	Hat_Crown = { Id = "Hat_Crown", Slot = "Hat", Name = { en = "Nanny Crown", lt = "Auklės karūna" }, Cost = 0, Color = Color3.fromRGB(255, 205, 60), Style = "Crown", Material = Enum.Material.Neon },
	Hat_Pumpkin = { Id = "Hat_Pumpkin", Slot = "Hat", Name = { en = "Pumpkin Hat", lt = "Moliūgo kepurė" }, Cost = 400, Color = Color3.fromRGB(255, 154, 60), Style = "Pumpkin" },
	Hat_Horns = { Id = "Hat_Horns", Slot = "Hat", Name = { en = "Monster Horns", lt = "Pabaisos ragai" }, Cost = 600, Color = Color3.fromRGB(195, 177, 225), Style = "Horns" },
	Hat_Chef = { Id = "Hat_Chef", Slot = "Hat", Name = { en = "Chef Hat", lt = "Virėjo kepurė" }, Cost = 800, Color = Color3.fromRGB(255, 255, 255), Style = "Chef" },
	Hat_Witch = { Id = "Hat_Witch", Slot = "Hat", Name = { en = "Witch Hat", lt = "Raganos kepurė" }, Cost = 0, Color = Color3.fromRGB(75, 63, 114), Style = "Witch", Premium = true },
	Apron_Mint = { Id = "Apron_Mint", Slot = "Apron", Name = { en = "Mint Apron", lt = "Mėtinė prijuostė" }, Cost = 200, Color = Color3.fromRGB(168, 230, 207), Style = "Apron" },
	Apron_Stars = { Id = "Apron_Stars", Slot = "Apron", Name = { en = "Starry Apron", lt = "Žvaigždėta prijuostė" }, Cost = 0, Color = Color3.fromRGB(75, 63, 114), Style = "ApronStars" },
	Apron_Peach = { Id = "Apron_Peach", Slot = "Apron", Name = { en = "Peach Apron", lt = "Persikinė prijuostė" }, Cost = 350, Color = Color3.fromRGB(255, 211, 182), Style = "Apron" },
	Apron_VIP = { Id = "Apron_VIP", Slot = "Apron", Name = { en = "VIP Apron", lt = "VIP prijuostė" }, Cost = 0, Color = Color3.fromRGB(255, 205, 60), Style = "ApronStars", Material = Enum.Material.Neon },
	Uniform_Lavender = { Id = "Uniform_Lavender", Slot = "Uniform", Name = { en = "Lavender Uniform", lt = "Levandų uniforma" }, Cost = 500, Color = Color3.fromRGB(195, 177, 225), Style = "Uniform" },
	Uniform_Night = { Id = "Uniform_Night", Slot = "Uniform", Name = { en = "Night Shift Uniform", lt = "Naktinės pamainos uniforma" }, Cost = 0, Color = Color3.fromRGB(60, 50, 95), Style = "Uniform" },
	Uniform_Pink = { Id = "Uniform_Pink", Slot = "Uniform", Name = { en = "Bubblegum Uniform", lt = "Kramtomosios gumos uniforma" }, Cost = 700, Color = Color3.fromRGB(255, 170, 165), Style = "Uniform" },
	Skin_DragonExtinguisher = { Id = "Skin_DragonExtinguisher", Slot = "ToolSkin", Tool = "Extinguisher", Name = { en = "Dragon Extinguisher", lt = "Drakono gesintuvas" }, Cost = 0, Color = Color3.fromRGB(60, 160, 90), Style = "Skin", Premium = true },
	Skin_RainbowMop = { Id = "Skin_RainbowMop", Slot = "ToolSkin", Tool = "Mop", Name = { en = "Rainbow Mop", lt = "Vaivorykštinė šluota" }, Cost = 900, Color = Color3.fromRGB(255, 120, 200), Style = "Skin", Material = Enum.Material.Neon },
	Skin_MoonFlashlight = { Id = "Skin_MoonFlashlight", Slot = "ToolSkin", Tool = "Flashlight", Name = { en = "Moon Flashlight", lt = "Mėnulio žibintuvėlis" }, Cost = 0, Color = Color3.fromRGB(200, 210, 255), Style = "Skin", Premium = true, Material = Enum.Material.Neon },
	PetAcc_Bow = { Id = "PetAcc_Bow", Slot = "PetAccessory", Name = { en = "Pet Bow", lt = "Augintinio kaspinėlis" }, Cost = 250, Color = Color3.fromRGB(255, 120, 150), Style = "Bow" },
	PetAcc_Crown = { Id = "PetAcc_Crown", Slot = "PetAccessory", Name = { en = "Pet Crown", lt = "Augintinio karūnėlė" }, Cost = 0, Color = Color3.fromRGB(255, 205, 60), Style = "Crown", Premium = true },
	GoldenSign = { Id = "GoldenSign", Slot = "Sign", Name = { en = "Golden Daycare", lt = "Auksinis darželis" }, Cost = 0, Color = Color3.fromRGB(255, 205, 60), Style = "Sign" },
}

local Order = {
	"Hat_Bow", "Hat_Beanie", "Hat_Crown", "Hat_Pumpkin", "Hat_Horns", "Hat_Chef", "Hat_Witch",
	"Apron_Mint", "Apron_Stars", "Apron_Peach", "Apron_VIP",
	"Uniform_Lavender", "Uniform_Night", "Uniform_Pink",
	"Skin_DragonExtinguisher", "Skin_RainbowMop", "Skin_MoonFlashlight",
	"PetAcc_Bow", "PetAcc_Crown",
}

return {
	Defs = C,
	Order = Order,
	Slots = { "Hat", "Apron", "Uniform", "ToolSkin", "PetAccessory" },
}
