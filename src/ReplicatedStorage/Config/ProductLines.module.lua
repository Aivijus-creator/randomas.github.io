--[[
	ProductLines – visos produktų linijos, pirkiniai ir kainos.

	Pirkinio ID formatas: <Linija>_<Nr>, pvz. "Cepelinai_3" (sugeneruojamas automatiškai
	pagal eilę sąraše). Pavadinimai abiem kalbomis yra Config/Texts modulyje pagal tą patį ID.

	Pirkinių tipai:
	  Dropper    – +1 dropper'is (iki 3 linijoje); IncludesBase = true – kartu pastatomas
	               konvejeris ir pardavimo langelis (pirmas nemokamas maišas, kad būtų iš ko uždirbti)
	  Base       – konvejeris + pardavimo langelis (atskiras pirkinys, jei reikia)
	  Upgrader   – Op = "Mul" (daugiklis) arba "Add" (priedas), Amount = skaičius
	  Unlock     – atrakina liniją Unlocks
	  Decoration – dekoracija (pvz. statula), gali duoti Badge

	ValueMultiplier – visos linijos produktų vertės daugiklis (vėlesnės linijos duoda daugiau,
	kad ekonomika nesulėtėtų). Pakeisk, jei kuri linija atrodo per lėta ar per greita.

	Upgrader'io išvaizdos laukai (nebūtini):
	  ItemColor, ItemMaterial, ItemSize (Vector3), ItemMesh ("Sphere" / "Cylinder" / "Block"),
	  ItemTopping (Color3) – ant produkto atsiranda priedas (grietinė, glajus, kaspinas...)
	  ItemLook – produkto vaizdas po apdorojimo (ServerScriptService/Lib/FoodLooks); jei nurodytas,
	             jis pakeičia ItemColor/ItemSize/ItemMesh/ItemTopping

	Modeliai ieškomi ServerStorage/Templates/Machines pagal pavadinimą:
	  Dropper_<Linija>, Conveyor_<Linija>, Sell_<Linija>, <pirkinio ID> (upgrader'iai, statula),
	o žaliava – ServerStorage/Templates/Items/Item_<Linija>.
	Jei modelio nėra, sugeneruojamas paprastas placeholder'is iš Parts.
]]

local C = Color3.fromRGB
local V = Vector3.new
local M = Enum.Material

local ProductLines = {}

-- Linijų eilė (zonos sklype išdėstomos šia tvarka)
ProductLines.Order = { "Cepelinai", "Kibinai", "Saltibarsciai", "Sakotis", "AuksinisCepelinas" }

ProductLines.Lines = {
	------------------------------------------------------------------
	Cepelinai = {
		BasePrice = 200,             -- močiučių kainai
		ValueMultiplier = 1,
		UnlockedBy = nil,            -- pradinė linija
		StartDroppers = 0,           -- pirmas dropper'is perkamas (nemokamai)
		StartsWithBase = false,
		Item = { Value = 1, Interval = 2, Color = C(170, 122, 72), Material = M.Sand, Size = V(1.5, 1.15, 1.2), Mesh = "Sphere", Style = "Potato" },
		Theme = { Floor = C(176, 136, 92), FloorMaterial = M.WoodPlanks, Accent = C(110, 72, 42), Belt = C(70, 58, 46), BeltMaterial = M.Fabric, BeltTransparency = 0, Machine = C(160, 120, 80) },
		Purchases = {
			{ Type = "Dropper", Price = 0, IncludesBase = true },                             -- 1 Bulvių maišas + konvejeris + pardavimo langelis
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 50, ItemColor = C(232, 218, 170), ItemMaterial = M.Sand, ItemLook = "GratedPotato" },  -- 2 Bulvių tarka
			{ Type = "Upgrader", Op = "Add", Amount = 5, Price = 150, ItemColor = C(214, 186, 160), ItemLook = "PotatoMeat" },                 -- 3 Mėsos malūnėlis
			{ Type = "Dropper", Price = 400 },                                                -- 4 Antras bulvių maišas
			{ Type = "Upgrader", Op = "Mul", Amount = 1.5, Price = 900, ItemColor = C(220, 212, 196), ItemSize = V(1.9, 1.1, 1.1), ItemMaterial = M.SmoothPlastic, ItemLook = "CepelinasRaw" }, -- 5 Močiutės rankos (cepelino forma)
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 2000, ItemColor = C(205, 205, 198), ItemLook = "CepelinasBoiled" },                -- 6 Didysis puodas
			{ Type = "Upgrader", Op = "Add", Amount = 10, Price = 4500, ItemColor = C(225, 222, 212), ItemTopping = C(250, 250, 245), ItemLook = "CepelinasServed" }, -- 7 Spirgučių ir grietinės mašina
			{ Type = "Dropper", Price = 8000 },                                               -- 8 Trečias bulvių maišas
			{ Type = "Unlock", Unlocks = "Kibinai", Price = 20000 },                          -- 9 Atrakinti Kibinus
		},
	},
	------------------------------------------------------------------
	Kibinai = {
		BasePrice = 20000,
		ValueMultiplier = 3,
		UnlockedBy = "Cepelinai_9",
		StartDroppers = 1,           -- atrakinus iš karto: dropper'is + konvejeris + langelis
		StartsWithBase = true,
		Item = { Value = 10, Interval = 2.5, Color = C(238, 228, 205), Material = M.Sand, Size = V(1.3, 1.1, 1.3), Mesh = "Sphere", Style = "Dough" },
		Theme = { Floor = C(160, 70, 55), FloorMaterial = M.Brick, Accent = C(120, 40, 32), Belt = C(80, 60, 50), BeltMaterial = M.Fabric, BeltTransparency = 0, Machine = C(150, 60, 45) },
		Purchases = {
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 35000, ItemColor = C(240, 232, 212), ItemSize = V(1.7, 0.5, 1.7), ItemMesh = "Cylinder", ItemLook = "DoughSheet" }, -- 1 Tešlos kočėlas
			{ Type = "Upgrader", Op = "Add", Amount = 40, Price = 60000, ItemColor = C(225, 200, 170), ItemLook = "DoughFilled" },             -- 2 Avienos įdaras
			{ Type = "Upgrader", Op = "Mul", Amount = 1.5, Price = 100000, ItemColor = C(230, 200, 150), ItemSize = V(1.9, 0.8, 1.0), ItemMesh = "Sphere", ItemLook = "KibinasRaw" }, -- 3 Pusmėnulio forma
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 160000, ItemColor = C(196, 140, 70), ItemLook = "KibinasBaked" },              -- 4 Krosnis
			{ Type = "Dropper", Price = 220000 },                                             -- 5 Antras miltų maišas
			{ Type = "Upgrader", Op = "Add", Amount = 100, Price = 300000, ItemColor = C(170, 110, 50), ItemTopping = C(200, 40, 40), ItemLook = "KibinasServed" }, -- 6 Trakų pilies antspaudas
			{ Type = "Dropper", Price = 420000 },                                             -- 7 Trečias miltų maišas
			{ Type = "Unlock", Unlocks = "Saltibarsciai", Price = 600000 },                   -- 8 Atrakinti Šaltibarščius
		},
	},
	------------------------------------------------------------------
	Saltibarsciai = {
		BasePrice = 600000,
		ValueMultiplier = 10,
		UnlockedBy = "Kibinai_8",
		StartDroppers = 1,
		StartsWithBase = true,
		Item = { Value = 50, Interval = 3, Color = C(120, 22, 52), Material = M.SmoothPlastic, Size = V(1.3, 1.3, 1.3), Mesh = "Sphere", Style = "Beet" },
		Theme = { Floor = C(120, 160, 90), FloorMaterial = M.Grass, Accent = C(230, 110, 170), Belt = C(255, 105, 180), BeltMaterial = M.Glass, BeltTransparency = 0.35, Machine = C(200, 90, 140) },
		Purchases = {
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 900000, ItemColor = C(170, 30, 80), ItemSize = V(1.4, 0.8, 1.4), ItemLook = "GratedBeet" },     -- 1 Burokėlių tarka
			{ Type = "Upgrader", Op = "Add", Amount = 200, Price = 1300000, ItemColor = C(240, 110, 170), ItemLook = "SoupBowl" },          -- 2 Kefyro čiaupas
			{ Type = "Upgrader", Op = "Mul", Amount = 1.5, Price = 2000000, ItemColor = C(235, 120, 175), ItemLook = "SoupCucumber" },          -- 3 Agurkai ir krapai
			{ Type = "Upgrader", Op = "Add", Amount = 300, Price = 2800000, ItemColor = C(245, 135, 185), ItemTopping = C(255, 240, 120), ItemLook = "SoupEgg" }, -- 4 Kiaušinių pjaustyklė
			{ Type = "Dropper", Price = 3800000 },                                            -- 5 Antras burokėlių maišas
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 5000000, ItemColor = C(255, 150, 200), ItemMaterial = M.Glass, ItemLook = "SoupChilled" }, -- 6 Šaldytuvas
			{ Type = "Upgrader", Op = "Add", Amount = 500, Price = 7000000, ItemColor = C(255, 160, 205), ItemSize = V(1.8, 0.6, 1.8), ItemMesh = "Cylinder", ItemLook = "SoupWithPotatoes" }, -- 7 Karštos bulvės šalia (lėkštė)
			{ Type = "Dropper", Price = 9000000 },                                            -- 8 Trečias burokėlių maišas
			{ Type = "Unlock", Unlocks = "Sakotis", Price = 12000000 },                       -- 9 Atrakinti Šakotį
		},
	},
	------------------------------------------------------------------
	Sakotis = {
		BasePrice = 12000000,
		ValueMultiplier = 20,
		UnlockedBy = "Saltibarsciai_9",
		StartDroppers = 1,
		StartsWithBase = true,
		Item = { Value = 300, Interval = 3, Color = C(250, 225, 120), Material = M.SmoothPlastic, Size = V(1.3, 1.1, 1.3), Mesh = "Sphere", Style = "Batter" },
		Theme = { Floor = C(235, 225, 205), FloorMaterial = M.Fabric, Accent = C(200, 50, 50), Belt = C(110, 75, 45), BeltMaterial = M.Wood, BeltTransparency = 0, Machine = C(180, 130, 70) },
		Purchases = {
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 16000000, ItemColor = C(250, 235, 160), ItemLook = "BatterWhipped" },           -- 1 Kiaušinių plakiklis
			{ Type = "Upgrader", Op = "Add", Amount = 1500, Price = 22000000, ItemColor = C(235, 200, 110), ItemSize = V(1.2, 1.6, 1.2), ItemMesh = "Cylinder", ItemLook = "SakotisSpit" }, -- 2 Sukamas iešmas
			{ Type = "Upgrader", Op = "Mul", Amount = 1.5, Price = 30000000, ItemColor = C(215, 165, 70), ItemLook = "SakotisBaked" },          -- 3 Ugnies krosnis
			{ Type = "Upgrader", Op = "Add", Amount = 2000, Price = 42000000, ItemColor = C(215, 165, 70), ItemTopping = C(250, 250, 250), ItemLook = "SakotisSugar" }, -- 4 Cukraus pudra
			{ Type = "Dropper", Price = 55000000 },                                           -- 5 Antras tešlos kubilas
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 75000000, ItemColor = C(200, 150, 70), ItemSize = V(1.3, 2.0, 1.3), ItemMesh = "Block", ItemLook = "SakotisBranches" }, -- 6 Šakų formavimas
			{ Type = "Upgrader", Op = "Add", Amount = 5000, Price = 100000000, ItemColor = C(230, 180, 80), ItemTopping = C(200, 30, 40), ItemLook = "SakotisFestive" }, -- 7 Šventinis kaspinas
			{ Type = "Dropper", Price = 140000000 },                                          -- 8 Trečias tešlos kubilas
			{ Type = "Unlock", Unlocks = "AuksinisCepelinas", Price = 200000000 },            -- 9 Atrakinti Auksinį Cepeliną
		},
	},
	------------------------------------------------------------------
	AuksinisCepelinas = {
		BasePrice = 200000000,
		ValueMultiplier = 30,
		UnlockedBy = "Sakotis_9",
		StartDroppers = 1,
		StartsWithBase = true,
		Item = { Value = 5000, Interval = 4, Color = C(255, 205, 60), Material = M.Metal, Size = V(1.5, 1.15, 1.2), Mesh = "Sphere", Style = "GoldenPotato" },
		Theme = { Floor = C(225, 180, 70), FloorMaterial = M.Marble, Accent = C(255, 150, 30), Belt = C(120, 80, 30), BeltMaterial = M.Metal, BeltTransparency = 0, Machine = C(230, 185, 60) },
		Purchases = {
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 250000000, ItemColor = C(255, 220, 90), ItemLook = "GoldenGrated" },           -- 1 Auksinė tarka
			{ Type = "Upgrader", Op = "Add", Amount = 20000, Price = 350000000, ItemColor = C(255, 160, 40), ItemMaterial = M.Glass, ItemLook = "GoldenAmber" }, -- 2 Gintaro įdaras
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 500000000, ItemColor = C(255, 230, 120), ItemSize = V(1.9, 1.1, 1.1), ItemLook = "GoldenCepelinas" }, -- 3 Vytauto palaiminimas
			{ Type = "Dropper", Price = 700000000 },                                          -- 4 Antra auksinė bulvė
			{ Type = "Upgrader", Op = "Mul", Amount = 2, Price = 1000000000, ItemColor = C(255, 215, 0), ItemMaterial = M.Neon, ItemLook = "GoldenRoyal" }, -- 5 Karališkas puodas
			{ Type = "Dropper", Price = 1500000000 },                                         -- 6 Trečia auksinė bulvė
			{ Type = "Decoration", Price = 2500000000, Badge = "GoldenStatue" },              -- 7 Auksinė cepelino statula
		},
	},
}

----------------------------------------------------------------------
-- Automatinis papildymas: ID, eilės numeris, vieta (slot) linijoje
----------------------------------------------------------------------
ProductLines.ById = {}

for order, lineId in ipairs(ProductLines.Order) do
	local line = ProductLines.Lines[lineId]
	line.Id = lineId
	line.Index = order
	local dropperSlot = line.StartDroppers
	local upgraderSlot = 0
	for index, purchase in ipairs(line.Purchases) do
		purchase.Id = lineId .. "_" .. index
		purchase.Index = index
		purchase.Line = lineId
		if purchase.Type == "Dropper" then
			dropperSlot = dropperSlot + 1
			purchase.Slot = dropperSlot
		elseif purchase.Type == "Upgrader" then
			upgraderSlot = upgraderSlot + 1
			purchase.Slot = upgraderSlot
		end
		ProductLines.ById[purchase.Id] = purchase
	end
	line.UpgraderCount = upgraderSlot
	line.MaxDroppers = dropperSlot
end

return ProductLines
