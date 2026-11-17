--[[
	Sounds – visų garsų ID vienoje vietoje.

	Dabar naudojami Roblox įdiegti standartiniai garsai (rbxasset://sounds/...), kad žaidimas
	iš karto skambėtų. Gražesnius garsus susirask Creator Store (Studio → Toolbox → Audio),
	nukopijuok ID ir įrašyk čia formatu "rbxassetid://123456789".
	Tuščia eilutė "" = garsas negrojamas.
]]

local Sounds = {
	-- Fonė muzika: grojama ratu, atsitiktine tvarka.
	-- Failai paruošti aplanke audio/muzika (kaimo_valsas.ogg, prie_nemuno.ogg).
	-- Įkelk juos: Creator Hub → Creations → Development Items → Audio → Upload,
	-- tada įrašyk gautus ID, pvz. "rbxassetid://123456789". Gali pridėti ir daugiau dainų.
	Music = {
		"rbxassetid://109933677310375", -- kaimo_valsas.ogg
		"rbxassetid://126820420927610", -- prie_nemuno.ogg
	},
	MusicVolume = 0.2,

	-- Močiutės balsai (lietuviškai), ta pačia tvarka kaip Texts.lt.GrannyPhrases.
	-- Failai: audio/mociute/mociute_1.ogg ... mociute_8.ogg – įkelk ir įrašyk ID.
	GrannyVoice = {
		"rbxassetid://95150237193155", -- 1 Valgyk, tu labai sulysęs!
		"rbxassetid://93437231319658", -- 2 Dar vieną cepeliną?
		"rbxassetid://127283145631944", -- 3 Mano laikais bulvės buvo didesnės!
		"rbxassetid://124872303550449", -- 4 Kepurę užsidėk, šalta!
		"rbxassetid://90377310314912", -- 5 Kas nori grietinės?
		"rbxassetid://114450530579373", -- 6 Nepamiršk paskambinti močiutei!
		"rbxassetid://137645180155067", -- 7 Kibinai patys nepasidarys!
		"rbxassetid://75652347311656", -- 8 Daugiau spirgučių dar niekam nepakenkė.
	},
	GrannyVoiceVolume = 0.9,

	-- Monetos pardavus (paieška Toolbox: "coin")
	Coin = "rbxasset://sounds/electronicpingshort.wav",
	CoinVolume = 0.2,
	-- „Pop“ nupirkus
	Pop = "rbxasset://sounds/action_jump_land.mp3",
	-- Burbuliavimas prie puodų (išjungta)
	Bubbling = "",
	-- Fanfaros rebirth metu (paieška: "fanfare")
	Fanfare = "",
	-- Event signalas (paieška: "medieval horn")
	EventHorn = "rbxasset://sounds/action_get_up.mp3",
	-- Juokingas garsas sprogus Didžiajam Cepelinui / smūgis ginklu
	Splat = "rbxasset://sounds/impact_water.mp3",
	Click = "",
	Error = "",

	SfxVolume = 0.6,
}

return Sounds
