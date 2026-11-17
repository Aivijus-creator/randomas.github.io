--[[
	Settings – visi bendri žaidimo skaičiai ir nustatymai.
	Kode „magiškų“ skaičių nėra: jei nori ką nors pakeisti, keisk čia.
]]

local C = Color3.fromRGB

local Settings = {}

----------------------------------------------------------------------
-- Gamyba
----------------------------------------------------------------------
Settings.ConveyorSpeed = 8          -- studai per sekundę
Settings.ItemLifetime = 30          -- s; po to žaliava sunaikinama
Settings.MaxItemsPerPlot = 50       -- daugiau judančių objektų sklype nebus
Settings.MinItemsPerLine = 8        -- kiekviena linija visada gauna bent tiek vietų (kitos negali jų „užimti“)
-- Ekonomikos daugiklis: visos pardavimo kainos × šis skaičius (1 = originalios lentelių kainos)
Settings.IncomeMultiplier = 3
Settings.MinDropInterval = 0.5      -- s; jei greičiau, didinama vieno objekto vertė
Settings.ItemTickRate = 0.1         -- s; kaip dažnai serveris tikrina žaliavas
Settings.IncomeUpdateRate = 1       -- s; kaip dažnai perskaičiuojamos pajamos/s
Settings.FallKillDepth = -8         -- studai žemiau sklypo grindų – objektas sunaikinamas
Settings.ItemLaneTolerance = 3.5    -- kiek studų nuo konvejerio centro dar skaitosi „ant konvejerio“

----------------------------------------------------------------------
-- Saugumas
----------------------------------------------------------------------
Settings.PurchaseDebounce = 0.5     -- s vienam žaidėjui
Settings.ButtonCheckRate = 0.15     -- s; kaip dažnai serveris tikrina, ar žaidėjas stovi ant mygtuko
Settings.ButtonHeight = 7           -- studai virš mygtuko, kurie dar skaitosi „ant mygtuko“
Settings.RemoteRateLimit = 5        -- užklausų per sekundę vienam žaidėjui

----------------------------------------------------------------------
-- Duomenys
----------------------------------------------------------------------
Settings.DataStoreName = "CepelinuGamykla_PlayerData_v1"
Settings.DataVersion = 2
Settings.AutosaveInterval = 60      -- s
Settings.SessionLockStale = 180     -- s; po tiek laiko svetimas užraktas laikomas pasenusiu
Settings.SaveRetries = 3
Settings.LoadRetries = 5
Settings.RetryDelay = 2             -- s
Settings.StartingMoney = 0

----------------------------------------------------------------------
-- Žemėlapis ir sklypai
----------------------------------------------------------------------
Settings.PlotCount = 6

Settings.Map = {
	GroundSize = 1000,
	ForestTrees = 900,              -- medžiai tankiame miške pakraščiuose (mažink, jei telefonuose lėta)
	MidTrees = 250,                 -- medžiai tarp sklypų ir prie kelių
	GrassColor = C(98, 140, 62),
	-- Pakraščiai: kalvų žiedas su mišku ir akmenimis, laukai, upelis
	Edges = {
		HillInnerR = 455,           -- pirmos kalvų eilės atstumas nuo centro
		HillOuterR = 520,           -- antros (aukštesnės) eilės atstumas
		RockyAbove = 42,            -- aukščiau – uolėtos viršūnės
		HillTrees = 420,            -- medžių ant kalvų (mažink, jei telefonuose lėta)
		HillRocks = 140,
		HillWindmills = 4,
		Fields = 6,                 -- javų / linų / rapsų laukai
		FieldMinR = 265, FieldMaxR = 410,
		GroundPatches = 160,        -- žolės / žemės lopai įvairovei
	},
	LobbyRadius = 48,
	PlotRingRadius = 175,           -- sklypo centro atstumas nuo lobby centro
	PathWidth = 12,
}

-- Sklypo vidinis išdėstymas (lokalios koordinatės, studais).
-- Sklypo centras = (0,0,0) grindų paviršiuje, vartai -Z kryptimi (į lobby).
Settings.Layout = {
	PlotSize = 120,
	ZoneTopY = 0.2,                 -- zonų pagrindo viršus
	LaneSpacing = 20,               -- atstumas tarp linijų
	FirstLaneX = 40,                -- 1-osios linijos X (kitos: -20, -20 ...)
	ZoneMinZ = -40,
	ZoneMaxZ = 56,
	ConveyorStartZ = 50,
	ConveyorEndZ = -23,
	ConveyorWidth = 4,
	ConveyorHeight = 1.2,
	DropperZ = { 46, 40, 34 },
	DropSpawnHeight = 4.4,          -- žemiau latako apačios (5,4), kad bulvė neužkliūtų
	UpgraderZ = { 26, 18, 10, 2, -6, -14 },
	SellTriggerZ = -22.5,           -- čia žaliava parduodama
	SellZ = -25.5,                  -- pardavimo langelio centras
	UnlockButtonZ = -34,
	BaseButtonZ = 10,
	ButtonSideOffset = 6.9,         -- pirkimo mygtukas šalia mašinos (toliau nuo stulpų)
	ButtonRadius = 2.6,
	GrannyX = -5.3,                 -- močiutės stalas
	GrannyStandOffset = 3.0,        -- močiutė stovi tiek studų toliau nuo stalo (už jo)
	GrannyZ = -18,
	GrannyButtonZ = -31,
	GrannyButtonX = -7,             -- močiutės mygtukas (atokiau nuo pardavimo langelio ir statulos)
	StatueZ = -34,
	ShelfZ = -54,
	ShelfX = 32,
	ShelfButtonsX = { 24, 36, 16 }, -- greitesni dropper'iai, puošmenos, vartai
	ShelfButtonsZ = -48,
	GateZ = -60,
	GateWidth = 14,
	ClaimPadZ = -67,
	SpawnZ = -46,
	FlagX = -10,                    -- vėliava ant vartų bokšto
}

----------------------------------------------------------------------
-- Bendri patobulinimai (lentyna prie vartų)
----------------------------------------------------------------------
Settings.GlobalUpgrades = {
	UnlockLine = "Kibinai",         -- lentyna atsiranda atrakinus šią liniją
	DropperSpeedReduction = 0.15,   -- kiekvienas lygis: intervalas dar -15 %
	DropperSpeed = {                -- lygiai iš eilės (1 lentynos vieta)
		{ Id = "DropperSpeed1", Price = 50000 },
		{ Id = "DropperSpeed2", Price = 5000000 },
		{ Id = "DropperSpeed3", Price = 300000000 },
		{ Id = "DropperSpeed4", Price = 10000000000 },
		{ Id = "DropperSpeed5", Price = 100000000000 },
	},
	-- Vartų patobulinimai iš eilės (3 lentynos vieta): rąstai → dailidės vartai → plytų vartai
	Gate = {
		{ Id = "Gate1", Price = 75000, Bonus = 0.03 },
		{ Id = "Gate2", Price = 25000000, Bonus = 0.05 },
	},
	-- Sklypo puošmenos iš eilės (2 lentynos vieta): kiekviena prideda pajamų ir atsiranda sklype.
	-- Pos – vieta sklype (X, Z), sklypo koordinatėmis; vėliava kabo ant vartų bokšto.
	Decor = {
		{ Id = "Flag", Price = 1000000, Bonus = 0.05 },                                   -- Lietuviška vėliava
		{ Id = "StorkNest", Price = 20000000, Bonus = 0.05, Pos = { -50, -52 } },        -- Gandralizdis
		{ Id = "RueGarden", Price = 300000000, Bonus = 0.05, Pos = { -36, -51 } },       -- Rūtų darželis
		{ Id = "Well", Price = 3000000000, Bonus = 0.10, Pos = { -22, -52 } },           -- Šulinys su svirtimi
		{ Id = "AmberLanterns", Price = 25000000000, Bonus = 0.10, Pos = { 0, -52 } },   -- Gintariniai žibintai prie vartų
		{ Id = "VytisStatue", Price = 200000000000, Bonus = 0.15, Pos = { 50, -51 } },   -- Auksinis Vytis
	},
}

----------------------------------------------------------------------
-- Močiutės
----------------------------------------------------------------------
Settings.Grannies = {
	Levels = {
		{ IntervalReduction = 0.10, PriceFactor = 5, ValueBonus = 0, Scarf = C(170, 40, 40), Apron = C(235, 235, 225) },
		{ IntervalReduction = 0.20, PriceFactor = 15, ValueBonus = 0, Scarf = C(40, 80, 170), Apron = C(250, 220, 120) },
		{ IntervalReduction = 0.30, PriceFactor = 50, ValueBonus = 0.10, Scarf = C(120, 30, 120), Apron = C(255, 200, 40), Golden = true },
	},
	PhraseMin = 20,                 -- s
	PhraseMax = 40,                 -- s
	PhraseShowTime = 5,             -- s
	SkinColor = C(234, 192, 160),
	DressColor = C(90, 60, 110),
}

----------------------------------------------------------------------
-- Rebirth „Močiutės palaiminimas“
----------------------------------------------------------------------
Settings.Rebirth = {
	RequiredLine = "Saltibarsciai",
	FirstCost = 1000000,
	CostMultiplier = 3,
	MultiplierPerRebirth = 0.5,
	Titles = {
		{ At = 0, Key = "Title_0" },
		{ At = 1, Key = "Title_1" },
		{ At = 3, Key = "Title_3" },
		{ At = 5, Key = "Title_5" },
		{ At = 10, Key = "Title_10" },
		{ At = 25, Key = "Title_25" },
		{ At = 50, Key = "Title_50" },
	},
	Rewards = {
		{ At = 1, Type = "Skin", Skin = "Wood", Key = "Reward_1" },
		{ At = 3, Type = "StartMoney", Amount = 1000, Key = "Reward_3" },
		{ At = 5, Type = "FreeGranny", Line = "Cepelinai", Key = "Reward_5" },
		{ At = 10, Type = "Skin", Skin = "Gold", Key = "Reward_10" },
		{ At = 25, Type = "UnlockLine", Line = "Kibinai", Key = "Reward_25" },
		{ At = 50, Type = "Crown", Badge = "Vytautas", Key = "Reward_50" },
	},
}

-- Virtuvės skinai: sklypo grindų / tvorų išvaizda
Settings.Skins = {
	Default = { Floor = C(124, 156, 84), FloorMaterial = Enum.Material.Grass, Fence = C(120, 85, 50), FenceMaterial = Enum.Material.Wood },
	Wood = { Floor = C(150, 108, 66), FloorMaterial = Enum.Material.WoodPlanks, Fence = C(95, 62, 35), FenceMaterial = Enum.Material.WoodPlanks },
	Gold = { Floor = C(214, 176, 64), FloorMaterial = Enum.Material.Marble, Fence = C(255, 205, 60), FenceMaterial = Enum.Material.Metal },
}

----------------------------------------------------------------------
-- Eventai
----------------------------------------------------------------------
Settings.Events = {
	FirstEventDelay = { 120, 240 }, -- s po serverio starto pirmas atsitiktinis eventas
	PotatoRain = {
		MinGap = 600, MaxGap = 900, -- kas 10–15 min.
		Duration = 30,
		DropSpeedMultiplier = 2,    -- dropper'iai meta dvigubai dažniau
	},
	BigCepelinas = {
		MinGap = 1200, MaxGap = 1800, -- kas 20–30 min.
		Duration = 60,
		WinnerSeconds = 300,        -- pirmas paspaudęs gauna 300 s savo pajamų
		OthersSeconds = 30,         -- visi kiti – 30 s
		MinReward = 100,            -- jei pajamų dar nėra
		DropHeight = 140,
		FallTime = 4,
	},
	-- Laumės dovana: laumė pasirodo miške, pirmas radęs gauna norą
	Fairy = {
		MinGap = 1200, MaxGap = 1800,   -- kas 20–30 min.
		Duration = 90,
		WishMoney = { Multiplier = 2, Duration = 300 },   -- ×2 pinigai visam serveriui 5 min.
		WishSpeed = { Multiplier = 2, Duration = 120 },   -- ×2 dropper'iai visam serveriui 2 min.
		WishGoldSeconds = 600,          -- radusiajam – 10 min. pajamų
		OthersSeconds = 60,             -- kitiems – 1 min.
		MinReward = 300,
		BigHeadsDuration = 30,          -- juokingas „prakeiksmas“: didelės galvos
		BigHeadsScale = 2.2,
	},
	-- Žiemos pūga / Kūčios: lėtesni konvejeriai, bet ×3 pinigai, Kūčiukų dovana turguje
	Winter = {
		MinGap = 1500, MaxGap = 2100,   -- kas 25–35 min.
		DecemberMinGap = 480, DecemberMaxGap = 720, -- gruodį – kas 8–12 min.
		Duration = 45,
		MoneyMultiplier = 3,
		ConveyorFactor = 0.5,
		GiftSeconds = 120,
		GiftMin = 200,
		Lighting = { ClockTime = 13, Brightness = 2.2, Ambient = C(150, 165, 185), OutdoorAmbient = C(190, 205, 225), FogColor = C(225, 235, 245), FogEnd = 450 },
		SnowColor = C(235, 240, 248),
	},
	-- Močiučių varžybos: kas per 3 min. parduos daugiausiai
	Contest = {
		MinGap = 900, MaxGap = 1500,    -- kas 15–25 min.
		Duration = 180,
		UpdateInterval = 2,
		PrizeSeconds = { 600, 300, 150 },
		PrizeMin = { 1500, 800, 400 },
		HatDuration = 600,              -- „Šefo“ kepurė nugalėtojui 10 min.
	},
	-- Dangaus močiutė: milžiniška močiutė toli danguje kočėlu kviečia auksinius cepelinus
	SkyGranny = {
		MinGap = 1500, MaxGap = 2400,   -- kas 25–40 min.
		Duration = 40,
		FirstStrike = 4,                -- s iki pirmo smūgio
		StrikeEvery = { 10, 14 },       -- kas kiek s kočėlu trenkia į dangų
		PerStrike = { 2, 3 },           -- kiek auksinių cepelinų nukrenta po smūgio
		RewardSeconds = 240,            -- radusiam – 4 min. pajamų
		MinReward = 3000,
		NearPlayerChance = 0.6,         -- dažniau krenta netoli žaidėjų
		NearMin = 12, NearMax = 35,
		MaxRadius = 240,
		DropHeight = 160, FallTime = 3.5,
		Grace = 20,                     -- nepaimti cepelinai dar 20 s po evento
		Scale = 45, Distance = 680, Angle = 40, BaseY = 30,
		Lighting = { ClockTime = 17.4, Brightness = 1.6, Ambient = C(150, 110, 160), OutdoorAmbient = C(200, 150, 190), FogColor = C(255, 200, 150), FogEnd = 3000 },
		Atmosphere = { Density = 0.12, Color = C(255, 210, 170), Decay = C(200, 120, 160) },
	},
	Jonines = {
		StartHourLT = 19,           -- 19:00 Lietuvos laiku
		Duration = 300,             -- 5 min. (vieną kartą per dieną)
		Days = { { Month = 6, Day = 23 }, { Month = 6, Day = 24 } },
		Weekends = true,
		MoneyMultiplier = 2,
		CheckInterval = 15,
		Lighting = { ClockTime = 19.6, Brightness = 1.2, Ambient = C(120, 80, 70), OutdoorAmbient = C(170, 110, 90), FogColor = C(240, 140, 90), FogEnd = 900 },
	},
}

----------------------------------------------------------------------
-- Bėgimas (laikyk Shift; telefone – 🏃 mygtukas, pultelyje – kairės lazdelės paspaudimas)
----------------------------------------------------------------------
Settings.Sprint = {
	WalkSpeed = 16,
	SprintSpeed = 26,
	FieldOfView = 70,
	SprintFieldOfView = 78,         -- kamera šiek tiek „atitolsta“ bėgant
}

----------------------------------------------------------------------
-- Savininko ženklas kuprinėje (užrašas virš galvos)
----------------------------------------------------------------------
Settings.Sign = {
	Text = "NEBAZARINK!",
}

----------------------------------------------------------------------
-- Kalėjimas miške (/jail, /unjail – tik savininkas)
----------------------------------------------------------------------
Settings.Jail = {
	Angle = 205, Radius = 330,      -- miško aikštelė (kelios kameros greta)
	Grannies = 4,
	CircleRadius = 5.5,             -- močiučių rato spindulys
	CircleSpeed = 0.8,              -- rad/s
	BonkEvery = 1.4,                -- s tarp smūgių
}

----------------------------------------------------------------------
-- Radijas „Magė“ turgaus aikštėje (muzika pagal kodą – groja visiems serveryje)
----------------------------------------------------------------------
Settings.Radio = {
	Name = "Magė",
	Price = 20000000000,            -- 20B Lt – kiti žaidėjai gali nusipirkti (savininkui nemokamai)
	Volume = 0.4,                   -- pradinis garsumas (0.1–1)
	MaxRecent = 8,                  -- kiek neseniai grotų dainų prisiminti
	Angle = 300, Radius = 19,       -- vieta turgaus aikštėje
}

----------------------------------------------------------------------
-- Viktorina apie Lietuvą (atsitiktinai iššoka visiems; klausimai – Lib/QuizQuestions)
----------------------------------------------------------------------
Settings.Quiz = {
	FirstDelay = { 60, 120 },
	MinGap = 360, MaxGap = 600,     -- kas 6–10 min.
	Duration = 20,                  -- s atsakyti
	RewardSeconds = 120,            -- teisingai – 2 min. pajamų
	MinReward = 300,
}

----------------------------------------------------------------------
-- Lyderių lentos
----------------------------------------------------------------------
Settings.Leaderboard = {
	RefreshInterval = 180,          -- s (2–5 min.)
	FirstRefresh = 10,
	Top = 10,
	TotalStore = "LB_TotalEarned_v1",
	RebirthStore = "LB_Rebirths_v1",
}

----------------------------------------------------------------------
-- Nemokami bonusai
----------------------------------------------------------------------
Settings.Daily = {
	Cooldown = 86400,               -- 24 val.
	StreakResetAfter = 172800,      -- praleidus dieną (48 val.) serija nusinuliuoja
	IncomeSeconds = 300,            -- 5 min. pajamų
	MinReward = 100,
	StreakMultipliers = { 1, 1.33, 1.67, 2, 2.33, 2.67, 3 },
}

Settings.Offline = {
	Share = 0.5,                    -- 50 % pajamų
	MaxSeconds = 8 * 3600,          -- iki 8 val.
	MinSeconds = 60,
}

----------------------------------------------------------------------
-- Administratoriai tikrame žaidime (be savininko, kuris visada admin).
-- Įrašyk draugo UserId (skaičius iš jo profilio nuorodos), pvz. { 12345678 }
----------------------------------------------------------------------
Settings.AdminUserIds = {}

----------------------------------------------------------------------
-- Badge'ai (ID įrašyk sukūręs Creator Hub; 0 = išjungta)
----------------------------------------------------------------------
Settings.Badges = {
	GoldenStatue = 1342747822340639, -- Auksinė cepelino statula
	Vytautas = 214862391941989,     -- 50 rebirth
}

----------------------------------------------------------------------
-- Ginklai (perkami už litus lobby kalvėje). Nustumia kitus žaidėjus, bet nežeidžia.
----------------------------------------------------------------------
Settings.Weapons = {
	SafeZoneRadius = 50,            -- lobby (turgus) – saugi zona, ten nustumti negalima
	CheckRate = 0.15,
	-- Kind: "Melee" – smūgis priekyje (Arc: 0,2 siauras … -0,3 platus mostas),
	--       "Projectile" – skrendantis cepelinas, "Area" – banga aplink žaidėją
	Items = {
		{ Id = "Spoon", Price = 1500, Kind = "Melee", Force = 40, Cooldown = 1.0, Range = 7, Arc = 0.2 },
		{ Id = "RollingPin", Price = 30000, Kind = "Melee", Force = 65, Cooldown = 1.2, Range = 8, Arc = 0.2 },
		{ Id = "Broom", Price = 250000, Kind = "Melee", Force = 70, Cooldown = 1.4, Range = 10, Arc = -0.3 },
		{ Id = "Pan", Price = 600000, Kind = "Melee", Force = 95, Cooldown = 1.5, Range = 9, Arc = 0.2 },
		{ Id = "CepelinasCannon", Price = 5000000, Kind = "Projectile", Force = 90, Cooldown = 1.6, Range = 60, Speed = 70, HitRadius = 3.5 },
		{ Id = "SakotisClub", Price = 50000000, Kind = "Melee", Force = 170, Cooldown = 2.0, Range = 9, Arc = 0.1 },
		{ Id = "AmberStaff", Price = 500000000, Kind = "Area", Force = 120, Cooldown = 4.0, Range = 16 },
	},
}

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------
Settings.UI = {
	NotificationTime = 4,
	MaxNotifications = 5,
	AnnouncementTime = 4,
	FloatingTextTime = 1.2,
	MaxCoinSoundsPerSecond = 2,
}

return Settings
