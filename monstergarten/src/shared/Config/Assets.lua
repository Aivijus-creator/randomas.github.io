--!strict
-- All uploaded asset ids. 0 = missing -> the sound/animation is silently skipped
-- and a procedural fallback is used. See ASSETS_TODO.md for what each one should be.

local Sounds: { [string]: number } = {
	-- UI
	UI_Click = 0, UI_Purchase = 0, UI_Coins = 0, UI_Star = 0, UI_LevelUp = 0, UI_Notify = 0, UI_Error = 0,
	-- Tools
	Tool_Extinguisher = 0, Tool_Mop = 0, Tool_Hammer = 0, Tool_Shears = 0, Tool_Water = 0, Tool_FlashlightClick = 0, Tool_Net = 0,
	Pickup = 0, Drop = 0,
	-- Kitchen
	Kitchen_OvenHum = 0, Kitchen_Ding = 0, Kitchen_PotBubble = 0, Kitchen_Blender = 0, Kitchen_Freezer = 0, Kitchen_Overheat = 0,
	-- Environment
	Env_Rain = 0, Env_Thunder = 0, Env_PowerOff = 0, Env_PowerOn = 0, Env_Birds = 0, Env_Crickets = 0,
	Env_Fire = 0, Env_Fizz = 0, Env_Bell = 0, Env_Stomp = 0, Env_Wail = 0, Env_Spark = 0, Env_Freeze = 0, Env_Splat = 0,
	Env_DoorOpen = 0, Env_Egg = 0,
	-- Shift
	Shift_ParentsComing = 0, Shift_Banner = 0, Shift_Complaint = 0,
}

-- Per-baby sounds: Baby_<Id>_Happy / _Cry / _Chaos (filled programmatically below)
local babyIds = { "Dragling", "Slimy", "Ghostie", "Vampy", "Octo", "Golem", "Sparky", "Sprout", "Yeti", "Mummy" }
for _, id in babyIds do
	Sounds["Baby_" .. id .. "_Happy"] = Sounds["Baby_" .. id .. "_Happy"] or 0
	Sounds["Baby_" .. id .. "_Cry"] = Sounds["Baby_" .. id .. "_Cry"] or 0
	Sounds["Baby_" .. id .. "_Chaos"] = Sounds["Baby_" .. id .. "_Chaos"] or 0
end

local Music: { [string]: number } = {
	Lobby = 0,
	ShiftCalm = 0,
	ShiftIntense = 0,
	Results = 0,
	FullMoon = 0,
	Tutorial = 0,
}

-- Optional extra tracks for the Music Box game pass (name -> id).
local MusicBox: { { Name: string, Id: number } } = {
	{ Name = "Lullaby Lane", Id = 0 },
	{ Name = "Spooky Sandbox", Id = 0 },
	{ Name = "Pumpkin Polka", Id = 0 },
}

-- Animations used when a model has a Humanoid/AnimationController.
-- Per-species override: Animations.Babies.<Id>.<Name>; fallback: Animations.BabyDefault.<Name>.
-- A model's own "Animations" folder (Animation objects) wins over both.
local AnimationNames = { "Idle", "Walk", "Cry", "Tantrum", "Eat", "Sleep", "Happy", "Carried", "Chaos" }
local BabyDefault: { [string]: number } = {}
for _, n in AnimationNames do
	BabyDefault[n] = 0
end

local Animations = {
	BabyDefault = BabyDefault,
	Babies = {} :: { [string]: { [string]: number } },
	Player = {
		Carry = 0,
		Spray = 0,
		Mop = 0,
		Hammer = 0,
	},
}

-- Optional images (0 = use emoji / text instead).
local Images: { [string]: number } = {
	Logo = 0,
	CoinIcon = 0,
	StarIcon = 0,
}

-- Sound tuning: default volume and 3D roll-off distance.
local SoundProps: { [string]: { Volume: number?, MaxDistance: number?, Looped: boolean? } } = {
	Env_Rain = { Volume = 0.4, Looped = true },
	Env_Fire = { Volume = 0.5, MaxDistance = 40, Looped = true },
	Kitchen_OvenHum = { Volume = 0.3, MaxDistance = 30, Looped = true },
	Kitchen_PotBubble = { Volume = 0.3, MaxDistance = 30, Looped = true },
	Env_Wail = { Volume = 0.8, MaxDistance = 80 },
	Env_Stomp = { Volume = 0.7, MaxDistance = 60 },
}

return {
	Sounds = Sounds,
	Music = Music,
	MusicBox = MusicBox,
	Animations = Animations,
	AnimationNames = AnimationNames,
	Images = Images,
	SoundProps = SoundProps,
}
