# Cepelinų Gamykla – Roblox tycoon

Visas žaidimas (1–4 etapai) yra viename faile **`CepelinuGamykla.rbxlx`**. Rojo nereikia.

## Naujausi pakeitimai (2026 lapkritis)
- **Radijas „Magė“** turguje: savininkas (ir nusipirkęs už 20B Lt) įveda muzikos kodą – groja visiems serveryje. Kuprinėje Magė nešiojama ant peties.
- **Eventas „Dangaus močiutė“** (40 s): milžiniška močiutė toli danguje kočėlu trenkia į dangų, krenta auksiniai cepelinai (po 4 min. pajamų).
- **Titulo atributika:** prijuostė, šaukštas, šefo kepurė, šalikas, apsiaustas, medalionas ir kardas pagal rebirth titulą.
- **#1 titulai** virš vardo ir pokalbyje: „👑 #1 Turtingiausias“ ir „🔁 #1 Rebirth karalius“.
- **Lentyna:** gandralizdis, rūtų darželis, šulinys, gintariniai žibintai, auksinis Vytis; vartai: rąstai → dailidės → plytų.
- **Konvejerių pradžios pagal temą** (troba, Trakų pilis, veranda, kepykla, auksinė salė) ir **tikroviški patiekalai** kiekviename apdorojimo etape.
- **Žemėlapio pakraščiai:** kalvos su mišku ir akmenimis, upelis su tilteliu, javų / linų / rapsų laukai, malūnai.
- **Močiučių varžybos** – reikia paspausti „Dalyvauti“; **bėgimas su Shift**; muzika groja be pertraukų; Joninės – 5 min., kartą per dieną.

### Savininko komandos (pokalbyje)
`/givemoney Vardas 5000` · `/takemoney Vardas 5000` · `/addmoney 1000000` · `/setrebirths 5` ·
`/event lietus|cepelinas|jonines|laume|ziema|varzybos|mociute|stop` · `/quiz` ·
`/mage <kodas>` · `/mage stop` · `/jail Vardas` · `/unjail Vardas` · `/givepass ...` · `/product ...` · `/resetdata`

## Ankstesni pakeitimai
- **Sutvarkyta: linijos nustodavo gaminti.** Sklype buvo leidžiama tik 40 judančių produktų, todėl nupirkus daug linijų ir močiučių paskutinės linijos (pvz., Auksinis Cepelinas) nebegaudavo vietos. Dabar kiekviena linija turi savo vietų dalį, o jei vietų trūksta, produkto vertė padidinama, kad pajamos nedingtų.
- **Ekonomika ×3:** visos pardavimo kainos padaugintos iš 3 (`Settings.IncomeMultiplier`), pvz., cepelinas dabar 93 Lt. Visa Cepelinų linija nuperkama per ~8 min (anksčiau ~25 min).
- **Ginklai už litus:** lobby kalvėje galima nusipirkti medinį šaukštą (1 500 Lt), kočėlą (30 000 Lt) ir ketaus keptuvę (600 000 Lt). Jais galima nustumti kitus žaidėjus už lobby ribų (lobby – saugi zona). Žaidėjai nežeidžiami. Nupirkti ginklai lieka ir po rebirth.
- **Kitų sklypų užrašai paslėpti:** matai tik savo sklypo užrašus ir mygtukus. Kai jau turi sklypą, kitų sklypų Claim mygtukai dingsta.
- **Šviečiantys apskritimai po pirkimo mygtukais:** žali – gali nupirkti, raudoni – trūksta litų.
- **Virš močiutės rodoma, ką ji duoda,** pvz., „⚡ Greitis +20 %“.
- Vėliavos pavadinimas pataisytas: „ant vartų“, ne „ant stogo“.
- **Lobby sutvarkytas:** išmėtyti daiktai pašalinti, VIP baseinas mažesnis ir prie krašto, kalvė su ginklais tarp kelių.
- **Persidengimai sutvarkyti** (šaltibarščių „krantai“ ėjo per mašinas, močiutės mygtukas lindo po langeliu). Mažiau gamtos objektų ir šešėlių, todėl mažiau lagina.
- **Konvejerių (burbuliavimo) garsas išjungtas.**
- **Fonė muzika ir lietuviškas močiutės balsas** – žr. skyrių „Muzika ir močiutės balsai“.

- **Pirkimo mygtukai ir Claim veikia patikimai:** serveris kas 0,15 s tikrina, ar stovi ant mygtuko (nebepriklauso nuo fizikos `Touched`). Prie kiekvieno mygtuko taip pat yra **E – Pirkti**. Jei stovi ant mygtuko ir pritrūksta litų, jis nuperkamas, kai tik litų atsiranda. Kitas mygtukas toje pačioje vietoje savaime nenuperkamas.
- **Išjungta Terrain žolės dekoracija.** Jos stiebeliai prasikišdavo pro sklypų grindis ir uždengdavo pirkimo mygtukus.
- **Konvejeriai:** judančios skersinės juostelės, metaliniai šonai su varžtais, velenai galuose. Iškritus žaliavai pasirodo dulkės, pravažiavus upgrader'į – kibirkštys, pardavus – auksinės monetos. Įperkami mygtukai pulsuoja.
- Bulvė krenta žemiau dropper'io latako, todėl nebeužkliūva. Upgrader'iai suveikia net serveriui strigus: tikrinama, ar produktas kirto liniją.
- **Claim sutvarkytas:** sklypą galima pasiimti užlipus ant žalio mygtuko, įėjus į zoną virš jo arba paspaudus **E** (telefone – bakstelėjus). Jei jau turi sklypą, žaidimas tai praneša ir nukelia tave į jį. Jei paspaudei, kol duomenys dar kraunasi, sklypas priskiriamas, kai tik jie įsikelia.
- Lobby medinis spawn kubas pašalintas (spawn vieta dabar nematoma).
- Šriftai pakeisti į **Fondamento** (antraštės) ir **Merriweather** (tekstas). Jie turi lietuviškas raides ą č ę ė į š ų ū ž.
- Miškas generuojamas fone, todėl sklypai atsiranda iš karto paleidus žaidimą.
- **Pirmas nemokamas „Bulvių maišas“ iš karto pastato ir konvejerį su pardavimo langeliu.** Anksčiau konvejeris kainavo 10 Lt, bet be jo nebuvo kaip uždirbti, todėl žaidimas užstrigdavo. Cepelinų linijoje dabar 9 pirkiniai (`Cepelinai_1` … `Cepelinai_9`).
- Didelis **LT | EN** mygtukas viršuje, šalia litų juostos: vienas paspaudimas pakeičia visų tekstų kalbą.
- Gražesnės žaliavos: gumbuotos bulvės su akutėmis, burokėliai su lapais, tešla su miltais. Upgrader'iai uždeda priedų: grietinę, antspaudą, glajų, kaspiną.
- Daug daugiau gamtos ir detalių: Terrain žolė, ~850 objektų (eglės, beržai, ąžuolai, krūmai, akmenys, gėlės, grybai), tvenkinys su lieptu, 2 vėjo malūnai besisukančiais sparnais, šieno kupetos, vežimai, fakelai ir tvorelės palei kelius. Lobby papuoštas vėliavomis, suolais, šuliniu ir prekystaliais, sklypai – fakelais, daržu ir beržiukais. Pridėti apšvietimo efektai (atmosfera, bloom, spalvų korekcija, debesys).
- Visas žaidimas patikrintas automatiniu scenarijumi (44 patikrinimai): Claim, visos linijos, kainos, močiutės, rebirth, išsaugojimas ir grįžimas, Robux kvitai, eventai, kasdienis prizas.

## Kaip atidaryti

1. Atsisiųsk `CepelinuGamykla.rbxlx` į savo kompiuterį.
2. Atidaryk failą dukart spustelėjęs. Kitas būdas: Roblox Studio → **File → Open from File…**
3. Spausk **Play** (F5).

Žemėlapis (lobby, 6 sklypai, dekoracijos) ir modeliai sukuriami automatiškai, kai paleidi žaidimą.
Redagavimo režime Workspace yra tuščias, ir taip turi būti.

### Kad veiktų išsaugojimas (DataStore)
1. **File → Publish to Roblox** (sukurk naują žaidimą).
2. **Home → Game Settings → Security → Enable Studio Access to API Services** → Save.

Kol place nepublikuotas, žaidimas veikia, bet progresas neišsaugomas. Output lange tada matysi geltoną įspėjimą `[DataService] DataStore nepasiekiamas…`. Tai ne klaida.

## Kur kas yra

| Vieta | Kas |
| --- | --- |
| `ReplicatedStorage/Config/ProductLines` | Visos 5 linijos, pirkiniai, kainos, efektai |
| `ReplicatedStorage/Config/Settings` | Visi kiti skaičiai: konvejerio greitis, rebirth, močiutės, eventai, išdėstymas, badge ID |
| `ReplicatedStorage/Config/Texts` | Visi tekstai EN ir LT |
| `ReplicatedStorage/Config/Sounds` | Garsų ID |
| `ReplicatedStorage/Config/Monetization` | Gamepass'ų, produktų ir grupės ID |
| `ReplicatedStorage/Shared/Calc` | Visos ekonomikos formulės vienoje vietoje |
| `ServerScriptService/Services/*` | Serverio sistemos (Data, Plot, Tycoon, Granny, Rebirth, Event, Monetization, Bonus, Leaderboard, Admin, Map, Templates) |
| `StarterPlayerScripts/UIController` | Visas UI |
| `StarterPlayerScripts/EffectsController` | Efektai, garsai, animacijos |
| `ServerStorage/Templates` | Modelių šablonai (žr. žemiau) |

## Testavimas Studio

- **Test → Clients and Servers → 2–3 Players → Start**: keli žaidėjai vienu metu.
- Telefono vaizdas: **Test → Device** → pasirink iPhone / Android.
- **Admin komandos** (veikia TIK Studio, rašyk į pokalbį):
  - `/addmoney 1000000`
  - `/setrebirths 25`
  - `/event lietus` · `/event cepelinas` · `/event jonines` · `/event stop`
  - `/givepass DoubleMoney` (taip pat `FastDroppers`, `GrannyHelp`, `VIP`, `OfflineIncome`)
  - `/product SmallBag` (taip pat `BigBag`, `PotatoRain`, `Boost3`)
  - `/resetdata`

## Kaip pakeisti kainas
Atidaryk `Config/ProductLines` ir pakeisk `Price` arba `Amount`. Kode kitur jokių skaičių nėra.

## Kaip pridėti naują produktų liniją
1. `ProductLines.Order` sąraše pridėk ID, o `ProductLines.Lines` lentelėje aprašyk liniją (galima nukopijuoti esamą). `UnlockedBy` nurodo, kuris pirkinys ją atrakina.
2. Ankstesnės linijos gale pridėk `{ Type = "Unlock", Unlocks = "NaujaLinija", Price = ... }`.
3. `Config/Texts` lentelėje pridėk pavadinimus (`Line_NaujaLinija`, `NaujaLinija_1`, …) abiem kalbomis.
4. Sklype telpa 5 linijos. Šeštai padidink `Settings.Layout.PlotSize` arba sumažink `LaneSpacing`.
5. Norėdamas temos dekoracijų, pridėk funkciją `ServerScriptService/Lib/ZoneThemes`.

## Gražesni modeliai
Kodas modelius randa **pagal pavadinimą** `ServerStorage/Templates`. Įdėk savo modelį tuo pačiu vardu, ir jis bus naudojamas vietoje placeholder'io:
- `Machines/Dropper_<Linija>` (turi turėti dalį `DropPoint`)
- `Machines/Conveyor_<Linija>` (dalis `Belt`)
- `Machines/Sell_<Linija>`
- `Machines/<pirkinio ID>`, pvz. `Cepelinai_3`
- `Machines/Granny`, `GrannyTable`, `Shelf`, `Flag`
- `Items/Item_<Linija>`

Modelio pivot turi būti apačios centre, o konvejerio kryptis -Z.

## Muzika ir močiutės balsai (reikia įkelti pačiam)
Faile `CepelinuGamykla_garsai.zip` yra:
- `audio/muzika/kaimo_valsas.ogg`, `audio/muzika/prie_nemuno.ogg` – originalios liaudiško stiliaus melodijos (kanklių skambesys), sukurtos specialiai šiam žaidimui;
- `audio/mociute/mociute_1.ogg` … `mociute_8.ogg` – močiutės frazės lietuviškai (ta pačia tvarka kaip `Texts.lt.GrannyPhrases`).

Roblox garsų tiesiai į place failą įdėti neleidžia, todėl:
1. Atidaryk **Creator Hub → Creations → Development Items → Audio → Upload Asset** ir įkelk kiekvieną `.ogg` failą.
2. Nukopijuok kiekvieno garso ID (skaičių).
3. Studio atidaryk `ReplicatedStorage → Config → Sounds` ir įrašyk ID, pvz., `"rbxassetid://123456789"`:
   - `Music = { "rbxassetid://...", "rbxassetid://..." }` – dainos (galima pridėti ir daugiau, pvz., iš Toolbox);
   - `GrannyVoice = { ... }` – 8 močiutės frazės iš eilės.

Kol ID neįrašyti, muzika negroja, o močiutės tik rodo užrašą.

## Garsai, kuriuos reikia susirasti
`Config/Sounds` faile dabar įrašyti Roblox standartiniai garsai. Studio → Toolbox → Audio susirask ir įrašyk šiuos:
- **Music** – rami liaudiška / viduramžių muzika (paieška: „medieval folk“, „tavern“)
- **Coin** – monetos („coin“)
- **Giggle** – močiutės kikenimas („old lady laugh“)
- **Fanfare** – fanfaros („fanfare“)
- **EventHorn** – ragas („medieval horn“)
- **Splat** – juokingas „pliumpt“ („splat“)
- **Click**, **Error** – nebūtini

## Prieš publikuojant (Creator Hub)
1. **Game Settings → Security**: įjunk API Services (DataStore).
2. **Places → Server Size**: nustatyk **6** žaidėjus.
3. **Genre**: Tycoon. Užpildyk **Maturity Questionnaire**.
4. **Monetization → Passes**: sukurk 5 gamepass'us (×2 pinigai 249, Greiti dropper'iai 149, Močiutės pagalba 199, VIP 299, Offline pajamos 199). Jų ID įrašyk į `Config/Monetization`.
5. **Monetization → Developer Products**: sukurk 4 produktus (Mažas maišas 25, Didelis maišas 99, Bulvių lietus 49, ×3 boost'as 39). ID įrašyk į `Config/Monetization`.
6. **Badges**: sukurk 2 badge'us (Auksinė cepelino statula, Vytautas Didysis). ID įrašyk į `Settings.Badges`.
7. Roblox grupės ID įrašyk į `Monetization.GroupId` (+10 % pajamų nariams).
8. Ikona: didelis auksinis cepelinas su grietine ant medinio stalo, fone Gedimino bokštas, užrašas „Cepelinų Gamykla“.
   Miniatiūros: (1) pilna gamykla su 5 linijomis iš viršaus; (2) močiutė su kalbos burbulu „Valgyk, tu labai sulysęs!“; (3) Didysis Cepelinas krenta į turgų; (4) Joninių laužai vakare.

### Pasiūlyti aprašymai
**EN – Cepelinai Factory Tycoon**
> Build your own Lithuanian food factory! Start with a single potato sack and grow it into a golden empire of cepelinai, kibinai, cold beet soup and šakotis. Hire grannies, survive the Potato Rain, catch the Big Cepelinas, and rebirth for Granny's Blessing. Can you build the Golden Cepelinas Statue?

**LT – Cepelinų Gamykla**
> Pasistatyk savo lietuviškų patiekalų gamyklą! Pradėk nuo vieno bulvių maišo ir užaugink auksinę cepelinų, kibinų, šaltibarščių ir šakočių imperiją. Samdyk močiutes, gaudyk Didįjį Cepeliną per Bulvių lietų ir gauk Močiutės palaiminimą. Ar pastatysi Auksinę cepelino statulą?

## Kodo perrinkimas (nebūtina)
Kodas laikomas `src/` aplanke. Pakeitęs failus, `.rbxlx` sugeneruok iš naujo:

```bash
python3 tools/build.py
```
