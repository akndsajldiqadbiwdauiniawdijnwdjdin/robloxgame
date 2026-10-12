# Illegal Racing (Roblox)

Arcade kart racing where cheating is the point. Every car has its own signature ability,
item boxes only give items from **your loadout**, and you collect new items through Item
Rolls, the Daily Shop and daily rewards. UI is in an "Illegal Soccer" style (cream cards,
mint buttons, key hints).

Everything is built from code (tracks, cars, lobby, UI), so it runs in an empty place.

## Controls

| Key | Action |
| --- | --- |
| WASD / arrows / gamepad / mobile stick | Drive |
| Space or Shift (hold while turning) | Drift → Mini-Turbo (press the other way to straighten out; that part doesn't charge) |
| **Q** (or 1) | Car ability |
| **E** (or 2) | Use item |
| R | Respawn at last checkpoint |
| B (lobby) | Emote wheel |

## What's in the box

| File | Does |
| --- | --- |
| `src/shared/Config.luau` | **All tuning**: race rules, rewards, drift, items, abilities, XP, spin, store, passes, audio |
| `src/shared/Cars.luau` | 10 cars + 4 motorcycles: price, 6 stats, signature ability, brick design |
| `src/shared/Items.luau` | 14 items with rarities (Common/Rare/Epic/Mythic), starter items, loadout size |
| `src/shared/Progression.luau` | Levels, 7-day daily reward, item rolls + pity, rotating daily shop |
| `src/shared/Emotes.luau` | Lobby emotes |
| `src/shared/Icons.luau` + `IconData.luau` | Picture icons for all 14 abilities and 14 items (packed 128x128 art, drawn with EditableImage; falls back to emoji) |
| `src/shared/UI.luau` | Shared UI kit (cards, buttons, tabs, key hints, ribbons) |
| `src/shared/Sounds.luau` | Sound effects (built-in Roblox sounds) |
| `src/server/Tracks/*.luau` | One file per track |
| `src/server/TrackBuilder.luau` | Builds tracks: road, borders, barriers, tunnels, grandstands, scenery |
| `src/server/RaceManager.luau` | Voting, race loop, checkpoints + rescue, awards, XP |
| `src/server/PowerUps.luau` | Item boxes (from your loadout) and all 14 item effects |
| `src/server/Abilities.luau` | The 14 vehicle abilities |
| `src/server/Shop.luau` | Cars, upgrades, daily shop, item rolls, loadout, daily reward |
| `src/server/Spin.luau` / `Monetization.luau` | Daily spin; Robux products + passes |
| `src/server/Lobby.luau` | Round pit-garage lobby: logo floor, pit bays, every vehicle on a pedestal, garage counter, spin wheel, trophy case |
| `src/client/Hud.client.luau` | Race HUD, results + awards, rescue fade |
| `src/client/Intermission.client.luau` | Between races: cup standings, vote board with everyone's picks, track roulette |
| `src/client/Menu.client.luau` | Shop (Daily Shop / Item Rolls / Loadout / Passes), Daily Reward, emotes |
| `src/client/Garage.client.luau` | Cars, stats, upgrades |
| `src/client/Drive.client.luau` | Driving physics, drifting (inside/outside), effects |
| `src/client/BikeLean.client.luau` | Motorcycles lean into turns and lift for wheelies |
| `src/client/Music.client.luau` | Music, engine loop, event sounds |

### Car abilities (Q)

| Car | Ability |
| --- | --- |
| Rusty Beater | Duct Tape: removes stolen-speed penalties + boost |
| Go-Kart | Turbo Hop: hop + instant mini-turbo |
| Street Tuner | Drift King: drifts charge 3x faster for 6s |
| Dune Buggy | Dune Jump: huge forward leap |
| Muscle Car | Battering Ram: charge and send cars flying |
| Ice Cream Truck | Brain Freeze Jingle: slows everyone nearby |
| Stolen Cop Car | Pull Over!: slows racers ahead |
| Monster Truck | Monster Stomp: shockwave |
| Supercar | Afterburner: massive boost |
| Hypercar | Blink Drive: teleport forward along the track |
| 🏍️ Pizza Scooter | Pizza Toss: slows the racer right ahead |
| 🏍️ Dirt Bike | Wheelie: +30% speed for 3s |
| 🏍️ Outlaw Chopper | Chain Whip: knocks aside everyone next to you |
| 🏍️ Street Rocket | Lane Split: boost that also blocks the next hit |

### Motorcycles: inside vs outside drift

- **Inside drift** (default on the Scooter and Street Rocket): the bike carves a tight
  line into the corner instead of swinging its back out. Good for hairpins.
- **Outside drift** (default on the Dirt Bike and Chopper, and how every car drifts):
  a wider, sliding arc.
- Switch any bike either way in the garage with the **INSIDE / OUTSIDE DRIFT** button
  on its preview. The choice is saved per bike. Lean amounts are in `Config.Bikes`.

### Items (E): your loadout decides what item boxes give you

Common: Nitro, Oil Slick, Spike Strip, Smoke Bomb · Rare: Rocket, EMP, Steal Part, Bubble
Shield · Epic: Freeze Ray, Magnet Hook, Tornado · Mythic: Jetpack, Orbital Laser, Black Hole.
Everyone starts with Nitro, Oil and Rocket. Item Rolls: 62% / 30% / 7% / 1%, with a
guaranteed Epic within 20 rolls and Mythic within 60. Duplicates refund coins.

### The 6 stats (0–10)

| Stat | Effect |
| --- | --- |
| Speed | Top speed |
| Acceleration | How fast you reach top speed |
| Weight | Heavy cars shove light ones and get stunned/thrown less |
| Handling | Turn rate |
| Traction | Grip, and how little dirt/grass/sand/mud slows you down |
| Mini-Turbo | How fast drifts charge and how strong the boost is |

### Tracks (players vote between 3 random ones each round)

| Track | Set pieces | Shortcuts |
| --- | --- | --- |
| Downtown Getaway | Grandstand, skyscraper tunnel, canal overpass, construction hairpin | Park grass, parking lot, park |
| Dusty Canyon Run | West town, mine tunnel, gorge jump, dinosaur skeleton | Mud pit, dusty trail |
| Neon City | Neon ring tunnel, elevated freeway crossing, blimp | Back alley, rooftops |
| Coral Coast | Pier grandstand, lighthouse, island jump, sea cave, shipwreck | West sandbar, coral reef |
| Crusher Factory | Crushers, conveyor boosts, catwalk, furnace tunnel, scrap jump | Catwalk hairpin, east grating |
| Grand Mansion | Gallery corridor, marble staircase + balcony, ballroom, chandeliers | Library |
| Bathroom Blitz | Soap spill, towel climb, tub rim, drain jump, toilet-paper tunnel | Bath mat, under the sink |

Every track has invisible system checkpoints. Go out of bounds (past the barrier, off a
jump, into the water), get stuck, or end up on the wrong part of the map, and the screen
fades and a rescue drone puts you back at the last checkpoint.

To add a track, copy a file in `src/server/Tracks/`, change the control `Points`
(each Vector3's Y is road height) and add its file name to `TRACK_IDS` in
`RaceManager.luau`. Features are placed by "control point + fraction" (`At = 4.5` is
halfway between points 4 and 5). Decor can use `api.tunnel`, `api.grandstand`,
`api.arch`, `api.alongTrack`, `api.isClear` and the props in `Props.luau`.

### Between races (Mario Kart style)

1. **Results** for the race (avatars, times, coins, awards).
2. **Cup standings**: points per place (15, 12, 10, 9, ...) add up over a 4-race cup;
   the top 3 after the last race get bonus coins. Tune it in `Config.Cup`.
3. **Vote** (30s, ends early once everyone has voted): pick one of 3 tracks. The board
   shows every player's pick with their avatar. Close it with the X and reopen it with
   the VOTE button.
4. **Roulette**: it spins over everyone's picks and lands on one (a track with more
   votes is more likely to win).

Only one menu is open at a time: opening the shop, garage, spin, daily or emotes closes
whichever was open. Every menu has a red X.

### Lobby

A compact round pit garage: logo floor with the spawn in the middle, numbered pit bays
(tire stacks, oil drums, tool carts, air-hose rigs, a car on a lift), every vehicle on
a pedestal, a purple roll-up race door with the next-race screen above it, the garage
counter (E opens the garage), the Daily Spin wheel (E at its podium), a trophy case,
and the side menu: Vote, Garage, Shop, Daily, Spin, Emotes, Music.

Tracks drive on one invisible, perfectly flat collision floor; the visible road,
curbs and borders sit a hair above it, so seams can't stop a car.

## Setup (one time)

1. Install [Rokit](https://github.com/rojo-rbx/rokit), then in this folder run `rokit install`
   (installs Rojo). Or install Rojo any other way.
2. In Roblox Studio install the **Rojo** plugin (Creator Store).
3. Create a new place from the **Baseplate** template. Delete the default `Baseplate` and
   `SpawnLocation` (the game builds its own ground and spawn).
4. In this folder run `rojo serve`, then in Studio click **Rojo → Connect**.
5. Press **Play**. With `MinPlayers = 1` a solo race starts after the 15 s intermission.
6. To save data in Studio: **Game Settings → Security → Enable Studio Access to API Services**
   (the game must be published first).

To test multiplayer: **Test → Clients and Servers → 2+ players → Start**.

Before going live, set `Config.Race.MinPlayers = 2`.

## Tuning ideas

- Cars: edit `Stats` in `Cars.luau` (0–10). Physics formulas are in `Stats.derive`.
- New car: copy an entry in `Cars.luau`, give it a new `Id`, and build it with the
  `d.block / d.wedge / d.cyl / d.wheels` helpers documented at the top of the file.
- Drift feel: `Config.Drift` (tier times, boost lengths). Boost pads: `Config.BoostPad`.
- New power-up: add to `Config.PowerUps` + `Config.PowerUpOrder`, then a
  `handlers.YourId` function in `PowerUps.luau`.

## Monetization (store, passes)

1. Publish the game. On the Creator Dashboard open your experience →
   **Monetization → Developer Products** and create one product per entry in
   `Config.Store` (coin packs, spin packs, 1 and 10 item rolls). Paste each product ID
   into its `ProductId` in `src/shared/Config.luau`.
2. Under **Monetization → Passes** create the passes in `Config.Passes` (2x Coins, VIP)
   and paste their IDs into `PassId`.

Until IDs are filled in, buttons say the product/pass isn't set up yet.

## Music and engine sound

Sound effects work out of the box (built-in Roblox sounds). For music:

1. In Studio open the **Toolbox → Creator Store → Audio**, or create.roblox.com/store,
   and pick free tracks from Roblox's licensed library (APM).
2. Copy the number from each track's URL into `Config.Audio` (`LobbyMusic`,
   `RaceMusic` list, `ResultsMusic`). Optionally add a looping engine sound as
   `EngineLoop`; its pitch follows your speed.

Players can mute music with the 🔊 button in the lobby menu. Camera zoom is limited to a
short distance (`Main.server.luau`).

## Custom car models

The physics never touch the visual body, so you can swap any model in without changing
handling. Put a **Model** named exactly like a car Id (see `Cars.luau`, e.g. `Beater`, `GoKart`,
`Monster`) in `ReplicatedStorage.CarModels` and it replaces the brick body.

Model requirements:
- Faces **-Z** (Roblox's "front"; the Front face of a part points that way).
- Pivot at the centre of the car **on the ground**, sized to the car's `d.hitbox`.
  Set a `YOffset` number attribute on the model to raise or lower it.
- Optional: a `Stealable` folder of parts (spoiler, bumpers…) that Steal Part can rip off.
- Any scripts inside are deleted automatically (free models can contain backdoors).

Ways to get models:

1. **Roblox's own AI (Cube 3D):** in Studio's Assistant, ask it to generate a mesh, e.g.
   `/generate low-poly red muscle car`. Fastest path, already inside Roblox.
2. **Text/image-to-3D tools** (Meshy, Tripo, Rodin, etc.): generate, export **FBX/OBJ/GLB**,
   then **File → Import 3D** in Studio. Ask for "low poly, game-ready" and keep the triangle
   count low. Read each tool's license for commercial use.
3. **Free CC0 packs** such as Kenney's *Car Kit*: import the same way, no licensing worries.
4. **Blender:** model or clean up AI output (fix scale, centre the pivot, point it to -Z),
   then export FBX.
5. **Creator Store:** fine for props, but check every model for hidden scripts.

You can also save models as `.rbxm` files in `assets/CarModels/`; Rojo syncs that folder
into `ReplicatedStorage.CarModels`. Pick one approach: while Rojo is connected, it manages
that folder and removes models you added by hand in Studio.
