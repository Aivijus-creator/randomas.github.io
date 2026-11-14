--!strict
-- Player data template + migrations. Pure (no Roblox services) so it can be unit tested.
local TableUtil = require(script.Parent.Parent.Util.TableUtil)

local CURRENT_VERSION = 2

local function template()
	return {
		DataVersion = CURRENT_VERSION,
		Coins = 0,
		TotalStars = 0,
		NannyXP = 0,
		NannyLevel = 1,
		TutorialDone = false,
		ToolUpgrades = {
			Extinguisher = 0, Mop = 0, Flashlight = 0, Lullaby = 0, Net = 0,
			Hammer = 0, Shears = 0, WateringCan = 0, TrashBag = 0,
		},
		DaycareUpgrades = {
			DoublePot = false, ExtraRacks = false, SecondFireplace = false, AutoShutoff = false,
			MegaBlender = false, SecondOven = false, AutoFeeder = false, FireproofFurniture = false,
		},
		Cosmetics = {
			Owned = {} :: { [string]: boolean },
			Equipped = { Hat = "", Apron = "", Uniform = "", PetAccessory = "", ToolSkins = {} :: { [string]: string } },
		},
		BabyFriendship = {} :: { [string]: number },
		SeenBabies = {} :: { [string]: boolean },
		Pets = {} :: { { BabyId: string, Name: string } },
		EquippedPets = {} :: { number },
		DailyReward = { LastClaim = 0, Streak = 0 },
		DailyQuests = { Date = "", Quests = {} :: { any } },
		Stats = {
			ShiftsPlayed = 0, FiresPutOut = 0, BabiesFed = 0, BestScore = 0, ThreeStarShifts = 0,
			GhostsFound = 0, DishesCooked = 0,
		},
		Settings = { MusicVolume = 0.5, SfxVolume = 0.8, Language = "auto", CameraShake = true, Quality = "High" },
		ProcessedReceipts = {} :: { [string]: number },
		WeeklyBest = { Week = "", Score = 0 },
	}
end

-- Ordered migration steps: [fromVersion] = function(data)
local migrations: { [number]: (any) -> () } = {
	[1] = function(data)
		-- v1 -> v2: Equipped slots stored nil as missing; normalize to "" and add SeenBabies/WeeklyBest.
		local eq = data.Cosmetics and data.Cosmetics.Equipped
		if eq then
			for _, slot in { "Hat", "Apron", "Uniform", "PetAccessory" } do
				if eq[slot] == nil then
					eq[slot] = ""
				end
			end
		end
		data.SeenBabies = data.SeenBabies or {}
	end,
}

local DataSchema = {}
DataSchema.Version = CURRENT_VERSION
DataSchema.template = template

function DataSchema.migrate(data: any): any
	if type(data) ~= "table" then
		return template()
	end
	local v = tonumber(data.DataVersion) or 1
	while v < CURRENT_VERSION do
		local step = migrations[v]
		if step then
			step(data)
		end
		v += 1
	end
	data.DataVersion = CURRENT_VERSION
	TableUtil.reconcile(data, template())
	return data
end

return DataSchema
