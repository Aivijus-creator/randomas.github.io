# Assets to upload

Upload each file on the Creator Dashboard (Creations → Development Items → Audio / Animations / Images),
copy its **asset id** and paste it into `src/shared/Config/Assets.lua`. Anything left at `0` is skipped
silently (procedural fallbacks are used), so you can add them one by one.

Suggested format: short `.ogg`/`.mp3`, sound effects < 2 s unless noted, loops marked 🔁 must loop cleanly.

## Music (`Assets.Music`)
| Key | Description |
|---|---|
| `Lobby` 🔁 | cosy, slightly spooky evening tune (music box, celesta, soft pizzicato) |
| `ShiftCalm` 🔁 | playful daytime daycare theme, medium tempo |
| `ShiftIntense` 🔁 | same theme, faster and busier – plays when 3+ babies are in a tantrum (crossfade) |
| `Results` | short fanfare for the rating screen (5–8 s) |
| `FullMoon` 🔁 | eerie but cute variation for the Full Moon event |
| `Tutorial` 🔁 | gentle, simple version of the calm theme |
| `MusicBox` list | optional extra lobby tracks for the Music Box game pass |

## UI (`Assets.Sounds`)
`UI_Click` soft pop · `UI_Purchase` cash-register sparkle · `UI_Coins` coin jingle · `UI_Star` star "ding" with
chime (played per star) · `UI_LevelUp` short level-up jingle · `UI_Notify` gentle notification bubble ·
`UI_Error` soft "bonk"

## Tools
`Tool_Extinguisher` foam spray (short, repeatable) · `Tool_Mop` wet scrub · `Tool_Hammer` hammer knock ·
`Tool_Shears` snip · `Tool_Water` watering splash · `Tool_FlashlightClick` click · `Tool_Net` whoosh ·
`Pickup` light pick-up pop · `Drop` soft thud

## Kitchen
`Kitchen_OvenHum` 🔁 oven hum · `Kitchen_Ding` oven bell · `Kitchen_PotBubble` 🔁 bubbling pot ·
`Kitchen_Blender` blender whirr · `Kitchen_Freezer` freezer hiss · `Kitchen_Overheat` alarm beeps

## Environment
`Env_Rain` 🔁 rain · `Env_Thunder` thunder clap · `Env_PowerOff` power-down "vwoom" · `Env_PowerOn` power-up hum ·
`Env_Birds` 🔁 daytime birds · `Env_Crickets` 🔁 lobby crickets · `Env_Fire` 🔁 crackling fire ·
`Env_Fizz` fire extinguished hiss · `Env_Bell` parents' doorbell · `Env_Stomp` heavy stomp + rumble ·
`Env_Wail` baby-monster wail (loud) · `Env_Spark` electric crackle · `Env_Freeze` ice crackle ·
`Env_Splat` ink splat · `Env_DoorOpen` creaky gate · `Env_Egg` mysterious egg wobble

## Shift
`Shift_ParentsComing` car horn / jingle for the 7:30 warning · `Shift_Banner` event banner swoosh ·
`Shift_Complaint` comedic "harrumph" when parents are unhappy

## Babies (3 per baby: `Baby_<Id>_Happy`, `Baby_<Id>_Cry`, `Baby_<Id>_Chaos`)
| Baby | Happy | Cry | Chaos |
|---|---|---|---|
| Dragling | little purr-roar | whiny squeak | sneeze + whoosh of fire |
| Slimy | squishy giggle | blubbering | slurp / munch |
| Ghostie | airy "ooo" giggle | ghostly sob | spooky "boo!" |
| Vampy | tiny "bleh" laugh | sniffle | ear-splitting wail |
| Octo | bubbly giggle | gurgle cry | ink squirt |
| Golem (Pebble) | rock clack laugh | grinding grumble | stomp |
| Sparky | buzzy giggle | static crackle cry | zap |
| Sprout | leafy rustle giggle | wilting whimper | creaking roots |
| Yeti (Yetiny) | fluffy chuckle | brr-whine | icy blast |
| Mummy (Mumbles) | muffled giggle | muffled cry | unravelling cloth |

## Animations (`Assets.Animations`)
Only needed if your baby models use a `Humanoid`/`AnimationController`. Either put `Animation` objects in a
model's `Animations` folder, or set ids here:

* `BabyDefault.<Name>` – used for every species without its own id
* `Babies.<Id>.<Name>` – per-species override (create the table, e.g. `Babies.Dragling = { Idle = 123 }`)

Names: `Idle` (breathing sway, loop) · `Walk` (bouncy hop, loop) · `Cry` (shaking sob, loop) · `Tantrum`
(stomping fit, loop) · `Eat` (chewing, ~1.5 s) · `Sleep` (curled up breathing, loop) · `Happy` (jump + spin,
~1.5 s) · `Carried` (dangling legs, loop) · `Chaos` (species special: sneeze, wail, stomp...).

Player (optional, procedural fallback exists): `Player.Carry`, `Player.Spray`, `Player.Mop`, `Player.Hammer`.

## Images (`Assets.Images`, optional)
`Logo` (loading screen; text logo is used until set) · `CoinIcon` · `StarIcon`.
Baby icons: put an ImageLabel/Decal named after the baby in `ReplicatedStorage/Assets/Icons`.

## Also needed for publishing (not in code)
Game icon (512×512), thumbnails (1920×1080), Game Passes and Developer Products listed in README section 6.
