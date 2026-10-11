# Illegal Racing (Roblox)

Arcade kart-style racing where cheating is the point: nitro, oil slicks, homing rockets,
EMP blasts, and **Steal Part**, which rips a part off the car ahead (they get slower,
you get faster, and the part stacks on your roof as a trophy).

Everything is built from code (track, cars, UI), so it runs in an empty Baseplate place.

## What's in the box

| File | Does |
| --- | --- |
| `src/shared/Config.luau` | Race rules, rewards, drift/boost tuning, upgrades, power-ups, monetization IDs |
| `src/shared/Cars.luau` | **All 10 cars**: price, the 6 stats, colors and brick-built design |
| `src/shared/Stats.luau` | The 6 stats and how they turn into physics |
| `src/shared/CarBody.luau` | Builds a car's brick body (studs on top) from its design |
| `src/shared/Remotes.luau` | Client/server remotes |
| `src/server/Tracks/*.luau` | **One file per track** (Downtown, Canyon, Neon Highway) |
| `src/server/TrackBuilder.luau` | Turns a track file into road, surfaces, walls, jumps, boost pads, scenery |
| `src/server/RaceManager.luau` | Track rotation, countdown, progress/laps, standings, rewards |
| `src/server/Lobby.luau` | Studded lobby with a showroom of every car |
| `src/server/CarBuilder.luau` | Physics chassis + body, swaps in custom models |
| `src/server/PowerUps.luau` | Pick-ups and all weapon effects |
| `src/server/PlayerData.luau` | DataStore saving (cash, wins, owned cars, upgrades) + leaderstats |
| `src/server/Shop.luau` | Garage purchases, validated on the server |
| `src/server/Monetization.luau` | 2x Cash game pass + cash developer products |
| `src/client/Drive.client.luau` | Arcade driving, drifting + Mini-Turbo, surfaces, boost pads |
| `src/client/Garage.client.luau` | Garage UI: 3D preview, stat bars, buy/equip, upgrades |
| `src/client/Hud.client.luau` | HUD, notifications, E/R input + mobile buttons |

**Game loop:** race → earn cash (placement + steals, 2x with pass) → buy cars and
upgrades in the Garage → next track. Back-of-pack racers roll Rockets/Steals more often.

**Controls:** WASD / arrows / gamepad / mobile stick to drive, **Space or Shift** (hold
while turning) to drift, **E** use power-up, **R** reset to the track.

### The 6 stats (0–10)

| Stat | Effect |
| --- | --- |
| Speed | Top speed |
| Acceleration | How fast you reach top speed |
| Weight | Heavy cars shove light ones and get stunned/thrown less |
| Handling | Turn rate |
| Traction | Grip, and how little dirt/grass/sand/mud slows you down |
| Mini-Turbo | How fast drifts charge and how strong the boost is |

Drift sparks go blue → orange → purple; release for a bigger boost each tier.

### Tracks (players vote between 3 random ones each round)

| Track | Theme |
| --- | --- |
| Downtown Getaway | City streets, overpass, dirt construction zone, alley + park-grass shortcuts |
| Dusty Canyon Run | Dirt rally, mesa climb, gorge jump, mud-pit shortcut |
| Neon City | Dusk figure-8 with an elevated freeway and neon rails |
| Coral Coast | Boardwalk causeway over the sea, island jump (fall in = reset), sandbar shortcut |
| Crusher Factory | Steel catwalks, conveyor boost pads, crushers that slam the road |
| Grand Mansion | Red carpets, marble staircase to a balcony, library shortcut |
| Bathroom Blitz | Toy-sized in a giant bathroom: soap (ice), bathtub rim, drain jump |

Every track has Mario Kart-style edges: an offroad border strip, then a barrier, with
openings where shortcuts start. Off-track or stuck for a few seconds = auto rescue.

To add a track, copy a file in `src/server/Tracks/`, change the control `Points`
(each Vector3's Y is road height) and add its file name to `TRACK_IDS` in
`RaceManager.luau`. Track features are placed by "control point + fraction"
(e.g. `At = 4.5` is halfway between points 4 and 5).

### Lobby, daily spin and store

The lobby has a car shop (walk up + **E** opens the garage), showroom halls with every
car, tower screens with the next race, and a **Daily Spin** wheel (one free spin every
24 hours; extra spins from the wheel or the store).

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

## Monetization (store + 2x cash pass)

1. Publish the game, then on the Creator Dashboard open your experience →
   **Monetization → Developer Products** and create one product per entry in
   `Config.Store` (cash packs and spin packs). Paste each product's ID into its
   `ProductId` in `src/shared/Config.luau`.
2. Optionally create a **Pass** for 2x Cash and put its ID in
   `Config.Monetization.DoubleCashPassId`.

Until IDs are filled in, the store buttons just say it isn't set up yet.

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
