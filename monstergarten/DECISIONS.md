# Design decisions

Decisions taken where the GDD left room (GDD 0.1 point 6). Each can be changed in config or one module.

## Architecture
- **Own service/controller loader** (`Main.server.lua`, `Main.client.lua`): every module gets `Init(services)`
  then `Start()`. No Knit/Wally dependency, so the project works with plain Rojo and no package step.
- **Own UI builder** (`client/UI/Components.lua`) instead of React-lua/Fusion: no packages, small and readable.
  Screens are built inside their controllers.
- **Extra services** beyond the GDD list: `MapService` (wraps MapBuilder + daycare copies), `HazardService`
  (fires, puddles, trash, roots, bandage trails, cone tools), `DebugService`. Prompt routing lives in
  `server/Interact.lua`, helpers in `server/ServerUtil.lua`.
- **`ModelRegistry` and `Placeholders` are in `shared/World/`** (not server) so the client can also build
  parent silhouettes for cutscenes and wardrobe/pet previews.
- **Pure logic in `shared/Logic/`** (scoring, need math, recipe matching, progression, data schema) so it is
  unit-tested (`server/Tests`) without Roblox APIs.
- `--!strict` is used in config/util/logic modules; services/controllers are non-strict to keep them simple.

## Data
- Own DataStore wrapper with **session locking** via `UpdateAsync` (lock = JobId + timestamp, 150 s timeout,
  6 retries then steal), autosave every 60 s, save on leave and in `BindToClose`. Studio without API access
  uses an in-memory mock with a clear warning.
- Schema version 2 (`DataVersion`). v1→v2 migration normalises empty cosmetic slots to `""` and adds
  `SeenBabies` / `WeeklyBest`. Missing keys are always reconciled from the template.

## Gameplay interpretations
- **Interaction**: everything is a ProximityPrompt created by the server (validated in one place). The
  client hides prompts that do not fit what you hold by setting `MaxActivationDistance = 0` locally.
  Keys: E pick up / interact, F play with a baby (hold 3 s), Q drop, left click / R2 use tool, Shift run.
- **Holding** welds the item/baby to the HumanoidRootPart in front of the player and raises the arms by
  changing shoulder `Motor6D.C0` on the server (replicates to everyone).
- **Babies** move with an anchored root (CFrame) along PathfindingService paths; AI thinks every 0.3–0.6 s,
  movement is integrated every frame. Ghostie glides through walls while hidden.
- **Stations** (crib, bath, fireplace/heater, charging station, sun spots, greenhouse lamp, cold spots, coffin
  cribs) have a “Place” prompt. A placed baby stays until the need is full (≥ 99.5) or someone picks it up.
  Babies standing near a station also get 60 % of its rate (GDD “sitting by the fireplace”).
  A baby cannot be placed on a station for a need it does not have.
- **Feeding results**: favourite dish +60, Porridge +25 for everyone who eats, Cake +40, raw food only for
  Slimy (+20; any cooked dish counts as Slimy’s favourite), anything else −10 and an angry puff.
  Yetiny can be fed raw **Ice** for +40 Cold (gives the otherwise unused Ice ingredient a purpose).
- **Bath**: put the baby in a tub, then hold “Wash” with the sponge. **Bandages** can be changed anywhere
  with the bandage roll (taken from the bathroom rack). **Watering** Sprout is a 2 s hold prompt; the watering
  can also works as a small cone that weakens small fires.
- **Lullaby player**: drop it (Q) near the cribs; it stays where it is placed and boosts cribs within its range.
  Upgrade level 2+ makes it work during blackouts.
- **Tool upgrades** are shared by the team (max level among players in the shift), as in the GDD.
- **Electric appliances**: oven, blender, freezer, fridges, ice box, charging stations, grow lamp and heater
  stop during blackouts; the stove pot and fireplaces keep working.
- **Electric panel**: lives in the basement; until the basement is unlocked (level 5) an extra panel is placed
  in the hall so blackouts (storm) can always be fixed.
- **Slimy** grows by eating furniture (x1 → x2.5); above x2 an invisible blocker makes it block doorways.
  Feeding shrinks it back over 5 s. It eats ink puddles it touches (turns black for a while).
- **Mumbles** heads for the yard gate during a tantrum and opens it after pushing for 20 s; escaping babies
  wander on the street until someone carries (or nets) them back inside.
- **Sun spots** drift with the sun on the server (so stations and visuals agree) and only work 08:00–18:30
  and not during a storm.
- **Furniture HP**: fire 3 HP/s (1.2 with fireproof furniture), Slimy 4 HP/s, golem stomp 8 per stomp.
  Furniture darkens as it breaks; the hammer repair prompt appears below 95 % HP.
- **Events**: up to `Difficulty.Events` per shift near 1:30 / 3:30 / 5:30 (±25 s, ≥ 90 s apart). Full Moon is
  moved after 16:00 or replaced by Mess Rain. Event coins go into the coin formula; score bonus +2 per event
  (+5 inspector, +1 mess rain), capped at +10. The Mystery Egg hatches a random still-locked baby for the rest
  of the shift and marks it as “seen”.
- **Friendship**: when a shift ends with 3 stars, every baby species in that shift gets +1 friendship for each
  player; at 5 the player can adopt it (one pet per species). 1 pet follows you (2 with VIP); other pets play in
  the lobby pet pen.
- **MVP** is only awarded with 2+ players.
- **Tutorial** gives 200 coins once and marks it done; its rewards do not include stars. New players get an
  on-screen offer; it can be skipped and replayed from Settings.
- **Daily quests** are rewarded automatically when completed (no claim button needed).
- **Daily gift** uses UTC days; missing a day resets the streak.
- **Weekly leaderboard** uses a new OrderedDataStore key per week (weeks counted from Monday, UTC).

## Map
- Built from parts by `server/World/MapBuilder`. If `ServerStorage/Maps/Lobby` or
  `ServerStorage/Maps/DaycareTemplate` exists it is used instead (keep the tags/attributes listed in GDD 8.5).
- Daycare copies are placed at X = 1000 × slot and use `ModelStreamingMode = PersistentPerPlayer` with the
  shift's players added, so streaming never hides parts of your own daycare.
- Ceilings exist (they darken rooms and stop light) but the client hides them locally while you are in a shift
  for a clear top-down view.
- Daylight is per player (client) because several shifts run on the same server.

## Monetization
- No “revive shift” product (GDD 16). “x2 Coins” is the **Coin Pouch** (+50 %).
- Premium cosmetics are Developer Products (one purchase each; ownership saved in data).

## Things intentionally simplified
- The Music Box pass adds a track picker to Settings (only tracks with uploaded ids in `Assets.MusicBox` appear).
- Face decals (`Faces` folder) are part of the model contract; mood is shown by the mood ring and bubbles.

## Designed characters
- The author's 3D character sheet is imported by `tools/import_characters.py` into `shared/World/CharacterData.lua`.
  Spheres become ellipsoids (Part + SpecialMesh Sphere), boxes are blocks, cylinders keep their X axis.
  Units × `scale` = studs; `lift` raises floating characters (Ghostie). Glowing parts use Neon.
- All visible parts are welded to an invisible `Body` part that hangs from the root via `BodyJoint`, so the
  procedural animations work for the designed characters too. The shopkeeper stands behind the lobby kiosk.
