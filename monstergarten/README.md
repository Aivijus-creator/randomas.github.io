# 🍼 Monstergarten

A cooperative, chaotic daycare game for Roblox: you are nannies in a monster daycare. Feed, rock, bathe and
entertain baby monsters, fight the chaos they cause, and earn stars from their giant parents.

Everything – code, map, effects, UI, sound system, data, progression and monetization – lives in this Rojo
project and is built **by code**, so the game is playable as soon as it is synced into Studio.

---

## 1. What you need

| Tool | Why | Install |
|---|---|---|
| **Roblox Studio** | runs the game | <https://create.roblox.com> |
| **Rojo 7.4+** | syncs these files into Studio | easiest: `rokit install` (uses `rokit.toml`), or `aftman install`, or download from <https://rojo.space> |
| **Rojo Studio plugin** | the Studio side of Rojo | Studio → *Plugins* → *Manage Plugins* → search “Rojo” (or `rojo plugin install`) |
| selene + StyLua (optional) | lint / format | installed by `rokit install` too |

## 2. Run the game in Studio (step by step)

1. Open a terminal in this `monstergarten/` folder.
2. Install the tools once:
   ```bash
   rokit install
   ```
3. Start the Rojo server:
   ```bash
   rojo serve
   ```
4. In Roblox Studio create a new **Baseplate** place, then delete the `Baseplate` part and the default
   `SpawnLocation` from Workspace (the game builds its own lobby and spawn).
5. Open the **Rojo** plugin tab → **Connect**. All scripts appear in ServerScriptService,
   ReplicatedStorage and StarterPlayerScripts.
6. Press **Play** (F5). The server builds the lobby, the daycare template and the lighting, and you spawn in
   the lobby. Walk onto the yellow **Tutorial** pad or a coloured shift door pad to start a shift.
7. Multiplayer test: *Test* → *Clients and Servers* → 2–4 players → *Start*.
8. Phone/tablet test: *Test* → *Device* emulator.

> Saving in Studio: if API access is off the game uses an **in-memory mock store** and prints a warning in
> Output – everything works, but progress is not kept between test sessions. Turn on
> *Game Settings → Security → Enable Studio Access to API Services* to test real saving.

Build a place file without Studio (for CI or sharing):

```bash
rojo build -o Monstergarten.rbxlx
```

## 3. Publish

1. *File → Publish to Roblox* (create a new experience).
2. *Game Settings → Security* → enable **Studio Access to API Services** (DataStores, leaderboards).
3. *Game Settings → Avatar* – R15 recommended (R6 also works).
4. Create Game Passes / Developer Products (section 6) and paste their ids into `src/shared/Config/Monetization.lua`.
5. Upload sounds / music / animations (see `ASSETS_TODO.md`) and paste ids into `src/shared/Config/Assets.lua`.
6. Re-sync with Rojo, then publish again.

## 4. Character models (babies, parents, NPCs)

**Your designed characters are already in the game.** All 22 characters from the 3D character sheet
(10 babies, 10 parents, Inspector, Shopkeeper) live in `src/shared/World/CharacterData.lua` and are built
by `CharacterBuilder` at runtime. To update them after changing the sheet:

```bash
python3 tools/import_characters.py "Monstergarten – 3D veikėjai.html"
```

Model priority: a model placed in `ReplicatedStorage/Assets/...` (below) → designed character from
`CharacterData` → automatic placeholder.


The code never needs to change when you add your own models. Put them here (in Studio, or under
`ReplicatedStorage/Assets` in `default.project.json` with `.rbxm` files):

```
ReplicatedStorage/Assets/
  Babies/   Dragling, Slimy, Ghostie, Vampy, Octo, Golem, Sparky, Sprout, Yeti, Mummy   (Models)
  Parents/  <same names>  ← optional; otherwise the baby model ×6 in a dark tint is used
  NPCs/     Inspector, Shopkeeper
  Icons/    <BabyId> (ImageLabel or Decal) ← optional
```

Each model **must** have a part named `HumanoidRootPart` (≈ 2×2×1 for babies). Optional extras:

* `Humanoid` or `AnimationController` + `Animator`, and an `Animations` folder with `Animation` objects
  named `Idle, Walk, Cry, Tantrum, Eat, Sleep, Happy, Carried, Chaos` → real animations are played;
  otherwise procedural animations are used (they animate the first joint attached to the root).
* Attachments `HeadTop` (need bubble), `Mouth`, `Hands` inside the root.
* `Faces` folder with Decals `Happy, Neutral, Sad, Angry, Sleeping` (reserved for face swapping).

Parts that you leave **anchored** are automatically welded to the root; rigged parts (Motor6D) are left alone.
Until a model exists, `ModelRegistry` builds a cute placeholder from parts.

**How to check a model:** press Play, start a shift (or the tutorial), press **F2** (debug menu, Studio only)
and click *Spawn baby → <Id>*. The baby appears in front of you using your model.

## 5. Debug menu (F2)

Available in Studio, for the place creator, and for user ids in `Config/GameSettings.lua → DebugUserIds`:
spawn any baby, set all needs, trigger any event, time ×5, add coins / stars, unlock everything, show AI
states above babies, end the shift, power cut, friendship = 5, reset your data.

Unit tests (scoring, need decay, recipes, data migration, unlocks): set `RunTestsOnStart = true` in
`Config/GameSettings.lua` or add a Workspace attribute `RunTests = true`, then press Play – results appear in Output.

## 6. Monetization ids (`src/shared/Config/Monetization.lua`)

| Key | Type | What it gives |
|---|---|---|
| `GamePasses.VIP` | Game Pass | golden name, VIP apron, +1 pet slot |
| `GamePasses.HeadNanny` | Game Pass | host chooses which babies come to the shift |
| `GamePasses.MusicBox` | Game Pass | flag for picking lobby music (`Assets.MusicBox`) |
| `GamePasses.CoinPouch` | Game Pass | +50 % coins from shifts |
| `Products.CoinsSmall/Medium/Large` | Dev Product | 500 / 1500 / 4000 coins (`Config/Shop.lua`) |
| `PremiumCosmetics.<CosmeticId>` | Dev Product | premium cosmetic |

An id of `0` hides that item in the shop. Receipts are processed safely (saved before `PurchaseGranted`,
duplicate receipts ignored).

## 7. Project layout

```
src/shared  → ReplicatedStorage.Shared   Config/*, Strings (EN/LT), Net/Remotes, Util/*, Logic/* (pure, tested), World/* (models, cosmetics)
src/server  → ServerScriptService.Server Main.server.lua, Services/*, Babies/* (base, AI, behaviors), World/MapBuilder/*, Classes/ShiftSession, Tests/*
src/client  → StarterPlayerScripts.Client Main.client.lua, State, Controllers/*, UI/*
```

* Add a baby: add an entry to `Config/Babies.lua` (+ optional `server/Babies/Behaviors/<Id>.lua`, + unlock in `Config/Progression.lua`).
* Tune balance: `Config/Needs.lua`, `Difficulty.lua`, `Recipes.lua`, `Events.lua`, `Progression.lua`, `GameSettings.lua`.
* Texts: `src/shared/Strings/en.lua` and `lt.lua` (language follows the player's LocaleId; can be changed in Settings).

## 8. Lint / format

```bash
selene src
```

```bash
stylua src
```

See `DECISIONS.md` for design decisions taken where the design document left room, and `ASSETS_TODO.md`
for every sound, music track and animation to upload.
