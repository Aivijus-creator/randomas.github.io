--!strict
-- Tool definitions. Levels[n] are per-upgrade-level stats (index 1 = base, 2..4 = upgrades 1..3).

export type ToolDef = {
	Id: string,
	Emoji: string,
	UnlockLevel: number,
	Racks: { string }, -- rooms where a rack holds it
	Use: string, -- "Cone" | "Toggle" | "Net" | "Prompt" | "Place"
	Range: number?,
	Angle: number?,
	Power: number?,
	Color: Color3,
	UpgradeCost: { number },
	Levels: { { [string]: number } }?,
}

local Tools: { [string]: ToolDef } = {
	Extinguisher = {
		Id = "Extinguisher", Emoji = "🧯", UnlockLevel = 1, Racks = { "Hall", "Kitchen" }, Use = "Cone",
		Range = 10, Angle = 25, Power = 1.0, Color = Color3.fromRGB(230, 60, 60),
		UpgradeCost = { 300, 800, 2000 },
		Levels = { { Range = 10, Power = 1.0 }, { Range = 12, Power = 1.3 }, { Range = 14, Power = 1.6 }, { Range = 16, Power = 2.0 } },
	},
	Mop = {
		Id = "Mop", Emoji = "🧹", UnlockLevel = 1, Racks = { "Hall", "Bathroom" }, Use = "Cone",
		Range = 6, Angle = 40, Power = 1.0, Color = Color3.fromRGB(110, 170, 255),
		UpgradeCost = { 250, 700, 1800 },
		Levels = { { Range = 6, Power = 1.0 }, { Range = 7, Power = 1.3 }, { Range = 8, Power = 1.6 }, { Range = 10, Power = 2.0 } },
	},
	Flashlight = {
		Id = "Flashlight", Emoji = "🔦", UnlockLevel = 1, Racks = { "Hall", "Basement" }, Use = "Toggle",
		Range = 30, Angle = 22, Power = 1, Color = Color3.fromRGB(255, 220, 90),
		UpgradeCost = { 200, 600, 1500 },
		Levels = { { Range = 30, Angle = 22 }, { Range = 34, Angle = 27 }, { Range = 38, Angle = 32 }, { Range = 44, Angle = 38 } },
	},
	ToyBag = {
		Id = "ToyBag", Emoji = "🧸", UnlockLevel = 1, Racks = { "Playroom" }, Use = "Prompt",
		Color = Color3.fromRGB(255, 170, 200), UpgradeCost = {},
	},
	Lullaby = {
		Id = "Lullaby", Emoji = "🎵", UnlockLevel = 2, Racks = { "Bedroom" }, Use = "Place",
		Range = 16, Color = Color3.fromRGB(190, 160, 255), UpgradeCost = { 400, 900, 2000 },
		Levels = { { Range = 16 }, { Range = 20, NoPower = 1 }, { Range = 24, NoPower = 1 }, { Range = 30, NoPower = 1 } },
	},
	Net = {
		Id = "Net", Emoji = "🥅", UnlockLevel = 3, Racks = { "Yard", "Hall" }, Use = "Net",
		Range = 12, Angle = 30, Color = Color3.fromRGB(120, 200, 140), UpgradeCost = { 300, 800, 1800 },
		Levels = { { Range = 12 }, { Range = 15 }, { Range = 18 }, { Range = 22 } },
	},
	Hammer = {
		Id = "Hammer", Emoji = "🔨", UnlockLevel = 2, Racks = { "Basement", "Hall" }, Use = "Prompt",
		Color = Color3.fromRGB(160, 110, 70), UpgradeCost = { 300, 700, 1500 },
		Levels = { { Time = 3 }, { Time = 2.4 }, { Time = 1.8 }, { Time = 1.2 } },
	},
	Shears = {
		Id = "Shears", Emoji = "✂️", UnlockLevel = 10, Racks = { "Yard" }, Use = "Prompt",
		Color = Color3.fromRGB(120, 120, 130), UpgradeCost = { 400, 900, 2000 },
		Levels = { { Time = 1.5 }, { Time = 1.1 }, { Time = 0.8 }, { Time = 0.5 } },
	},
	WateringCan = {
		Id = "WateringCan", Emoji = "💧", UnlockLevel = 10, Racks = { "Yard" }, Use = "Cone",
		Range = 7, Angle = 25, Power = 0.5, Color = Color3.fromRGB(90, 190, 230), UpgradeCost = { 400, 900, 2000 },
		Levels = { { Range = 7, Power = 0.5 }, { Range = 8, Power = 0.7 }, { Range = 9, Power = 0.9 }, { Range = 10, Power = 1.1 } },
	},
	Sponge = {
		Id = "Sponge", Emoji = "🧽", UnlockLevel = 1, Racks = { "Bathroom" }, Use = "Prompt",
		Color = Color3.fromRGB(255, 230, 100), UpgradeCost = {},
	},
	BandageRoll = {
		Id = "BandageRoll", Emoji = "🧻", UnlockLevel = 14, Racks = { "Bathroom" }, Use = "Prompt",
		Color = Color3.fromRGB(245, 240, 225), UpgradeCost = {},
	},
	TrashBag = {
		Id = "TrashBag", Emoji = "🗑️", UnlockLevel = 6, Racks = { "Hall" }, Use = "Prompt",
		Color = Color3.fromRGB(70, 70, 80), UpgradeCost = { 300, 700 },
		Levels = { { Capacity = 5 }, { Capacity = 8 }, { Capacity = 12 } },
	},
}

local Order = { "Extinguisher", "Mop", "Flashlight", "ToyBag", "Sponge", "Lullaby", "Hammer", "Net", "TrashBag", "Shears", "WateringCan", "BandageRoll" }

return {
	Defs = Tools,
	Order = Order,
	ReturnAfter = 30, -- seconds on the ground before returning to rack
}
