# Sealed Chapel

*Tag: Curse Arena*

A Grimm fairy-tale, Vampire-Survivors-style prototype built in **Godot 4.x**
(GDScript). A **procedural, endless** roam through a haunted wood and a
ruined chapel clearing — soot, bone, bruise-purple, curse-gold and rot set
dressing, diegetic storybook UI, and a curse-bargain level-up loop.

This is explicitly **not** a sealed combat ring: the map is not a single
fixed, hand-authored rectangle. Square chunks of ground + dressing stream
in around the player as they walk (Survivors-style) and unload behind
them, so the roam has **no hard wall anywhere** and can continue
indefinitely in any direction. None of the dressing (iron fence, chapel
ruin) ever forms a closed loop, in any chunk.

## Opening the project

1. Install **Godot 4.x** (built and tested against 4.7.2 stable; any 4.x
   engine build should work since only stable, long-standing APIs are used).
2. Launch Godot, choose **Import**, and select this repository's
   `project.godot`.
3. Press **F5** (or the Play button) to run. The main scene
   (`scenes/main/Main.tscn`) is already set as the project's run scene.

No external asset import step is required — see [Placeholder art](#placeholder-art--where-real-sheets-will-land) below.

## Controls

- **Move**: `WASD` or arrow keys.
- Attacking is automatic: the player fires at the nearest enemy inside
  attack range on a timer. There is nothing else to press during a run.
- Bargain cards and the "Again" button are mouse-driven.

## What the Prototype includes

- **Procedural, endless roam** — no fixed map rectangle. `World.gd` streams
  square chunks (32×32 tiles, ~1024×1024px each) of procedurally-painted
  ground in around the player, unloading chunks once they're a couple of
  chunks behind. Each chunk's ground + dressing is generated from a seed
  derived from its own coordinate, so revisiting a chunk always regenerates
  the *same* layout deterministically, without needing to keep it resident.
  There is no wall and no camera/position clamp anywhere — the player can
  walk in one direction indefinitely and new wood keeps streaming in.
- **Player** — move + automatic attack (nearest-enemy targeting, simple
  projectile) via `scripts/player/Player.gd`.
- **Two enemy types ("Crawler" and "Wraith")** — both shamble toward the
  player and deal contact damage; both die to the player's auto-attack and
  drop an XP pickup. They share one behaviour script
  (`scripts/enemies/Enemy.gd`) and differ only in their exported stats and
  their `Crawler.tscn` / `Wraith.tscn` visual + collision size — a Crawler
  is a low multi-leg skulker, a Wraith is a taller, faster flame-tipped
  wisp with less health.
- **Waves** — a simple spawner (`scripts/world/World.gd`) that spawns more
  enemies (mostly Crawlers, a rarer chance of a Wraith), more often, the
  longer the run goes.
- **Curse bargain (level-up)** — collecting enough XP opens three curse
  cards centred as a modal over a **dimmed, paused** playfield; picking one
  applies the upgrade and resumes combat. Diegetic panel/button styling only
  — no default Godot theme chrome. `scripts/autoload/Game.gd` +
  `scripts/ui/BargainModal.gd` + `scripts/ui/BargainCard.gd`.
- **End states** — death (overrun) or a timed clear both show a themed panel
  (not the default engine dialog) with a short Grimm line and an **Again**
  button that restarts the run. `scripts/ui/EndPanel.gd`.
- **Diegetic HUD** — carved health/curse bars, a level label and a
  countdown to dawn, all hand-styled (`scripts/autoload/UITheme.gd`), no
  default `Theme`. The level/countdown labels use the studio-locked
  `Copy.HUD_LEVEL` ("Curse %d") and `Copy.HUD_TIMER` ("%d:%02d to dawn")
  format strings.
- **Kitbashed dressing** — dead trees, a broken chapel ruin, candle
  clusters with a soft glow, a *broken* iron fence (two short, disconnected
  runs — deliberately not a ring), a drifting fog layer, and a bargain
  shrine landmark, all built from simple `Polygon2D` placeholders in
  `scenes/props/`.
- A shared **colour palette** (`scripts/ui/Palette.gd`) and **copy
  constants** (`scripts/ui/Copy.gd`, including the locked `DEATH_TITLE` /
  `CTA_AGAIN` strings) so the whole prototype pulls from one place. The
  palette is locked to exactly five hexes: soot `#1A1410`, bone `#E8DCC8`,
  bruise `#4A3A5C`, curse `#C4A35A`, rot `#2D1F18`.

## What the Prototype excludes (out of scope)

- Inventory and minimap systems (shown in the UI mood-board for mood only).
- Multiplayer, a campaign/meta layer, or any paid/licensed assets.
- Unreal Engine — this is Godot 4 / GDScript only.
- A sealed ring / collider-as-level design, or any fixed hand-authored map
  rectangle. The roam is procedural and endless — chunks stream in around
  the player with no wall, no shrinking bounds, and no closed loop.
- Real balancing/tuning numbers. Stats (health, damage, spawn rates, XP
  curve) are placeholder values sized to make the loop legible for a short
  prototype run; they are **not** meant to hit the eventual 8–12 minute run
  target, and no specific player metrics were invented beyond what's needed
  to demonstrate the loop.
- A replay system. `Game.bargain_history` records the order bargains were
  accepted in as a forward-looking hook, but nothing consumes it yet.

## Placeholder art & where real sheets will land

The player, both mobs and the XP pickup are small procedurally-painted PNG
sprites under `assets/sprites/` (`Sprite2D` nodes), sized and silhouetted to
read clearly at 1× survivors zoom; the bargain shrine landmark is still a
`Polygon2D` placeholder. Every placeholder pulls only from the locked
five-hex palette (soot/bone/bruise/curse/rot) — no sixth colour, no
multi-resolution art packs. Approximate on-screen sizes match the brief:

| Element              | Scene                                | Size (approx.) |
|-----------------------|---------------------------------------|-----------------|
| Player (hooded last-soul) | `scenes/player/Player.tscn`       | ~24×24 |
| Crawler (low multi-leg mob) | `scenes/enemies/Crawler.tscn`   | ~20×20 |
| Wraith (tall flame-tip mob) | `scenes/enemies/Wraith.tscn`    | ~20×20 |
| XP pickup (curse orb) | `scenes/pickups/XPOrb.tscn`           | ~12×12 |
| Bargain shrine (landmark) | `scenes/props/PropBargainShrine.tscn` | ~48×64 |

When real art is ready, drop sprite sheets over the placeholder PNGs under
`assets/sprites/` (folders already scaffolded for `player/`, `enemies/`,
`pickups/`, `props/`) and swap the `Sprite2D`/`Polygon2D` visual children
for `AnimatedSprite2D` where animation is needed — the gameplay scripts
only reference collision shapes and node paths that would remain
unchanged.

## Project layout

```
project.godot              Engine config (Godot 4.7, GL Compatibility renderer)
scenes/
  main/Main.tscn            Composition root: World + HUD + BargainModal + EndPanel
  world/World.tscn           The roam: Ground/YSort/Fog layers, spawn + chunk timers
  player/                    Player + auto-attack Projectile
  enemies/                   Crawler + Wraith mobs (share scripts/enemies/Enemy.gd)
  pickups/                   XP orb
  props/                     Dead tree, chapel ruin, iron fence, candles, shrine
  ui/                        HUD, bargain modal + card, end panel
scripts/
  autoload/Game.gd           Run state: timer, XP/level curve, bargain flow, win/lose
  autoload/UITheme.gd        Builds the one shared diegetic Theme in code
  ui/Palette.gd              Shared colour constants (soot/bone/bruise/curse/rot)
  ui/Copy.gd                 Locked UK-English copy constants
  world/World.gd             Chunk streamer: procedural ground + dressing + waves
  player/, enemies/, pickups/, props/   Gameplay scripts
```

## Endless map / chunk streaming

`scripts/world/World.gd` is a small chunk streamer rather than a level
generator, on purpose (a simple streamer over a "perfect" infinite world):

- The world is divided into 32×32-tile chunks (`CHUNK_TILES`, ~1024px at
  32px tiles). Every `ChunkTimer` tick (0.35s) it works out which chunk the
  player is standing in.
- Chunks within `LOAD_RADIUS` (1, i.e. a 3×3 grid) of the player's chunk
  are guaranteed loaded; anything farther than `KEEP_RADIUS` (2) is
  unloaded. The gap between the two radii is deliberate hysteresis so nearby
  chunks don't load/unload every time the player nudges a boundary.
- Loading a chunk creates one `TileMap` (ground) plus a handful of
  `Polygon2D` dressing props, seeded from a hash of the chunk's own
  coordinate — so the same chunk always regenerates identically if the
  player wanders back into it, without the engine needing to keep it
  resident the whole time.
- The world-origin chunk always carries the bargain shrine landmark, so
  it's guaranteed visible near the player's starting position; every other
  prop (dead trees, chapel ruin fragments, candle clusters, broken iron
  fence pieces) is placed randomly and sparsely per chunk, so no chunk ever
  assembles a closed loop.
- There is no bounds clamp on the player or camera at all (see
  `Player.gd`) — this is the "keep streaming, no hard wall" option: the
  roam simply keeps generating new chunks in whichever direction the player
  walks, for as long as a run lasts.
- Enemy waves spawn procedurally around the player's current position
  (random angle/distance), independent of chunk boundaries, so waves keep
  working the same way regardless of how far the player has roamed.

## Notes for reviewers

- **Copy strip (post-merge polish):** the bargain modal no longer shows an
  "A bargain is offered..." headline — each `BargainCard` carries the only
  copy (its one-liner). `EndPanel` shows a title + the **Again** button
  only, with no invented body line (the old "Curse level %d reached...
  creatures put down." summary is gone). The HUD's level and countdown
  labels are studio-locked, not invented: `Copy.HUD_LEVEL` ("Curse %d")
  and `Copy.HUD_TIMER` ("%d:%02d to dawn"), wired in `HUD.gd`. The seven
  panel/bargain constants in `Copy.gd` (`DEATH_TITLE`, `CLEAR_TITLE`,
  `BARGAIN_EMPTY`, `CTA_AGAIN`, `LONGER_SHADOW`, `FEVER_PULSE`,
  `TITHE_OF_FLESH`) are unchanged.
- **Palette lock (post-merge polish):** `Palette.gd` now exposes exactly
  five colours — soot `#1A1410`, bone `#E8DCC8`, bruise `#4A3A5C`, curse
  `#C4A35A`, rot `#2D1F18` — with no derived "dim"/"dark" float variants
  and no sixth "dried-blood" colour. Every UI script/scene (`HUD`,
  `BargainModal`, `BargainCard`, `EndPanel`, `UITheme`) and the world's
  procedural ground texture (`World.gd`) now pull only from those five.
  Non-UI placeholder art (mobs, props, player, pickups) was left as-is —
  recolouring those is an art pass, not part of this palette-lock ticket.
- **Bargain dim → soot vignette wash (Shade note):** the bargain modal's
  flat `Dim` `ColorRect` is now a soft radial vignette instead of a single
  flat fill. `BargainModal.tscn` layers a low-alpha rot (`#2D1F18`) base
  wash under a radial `GradientTexture2D` (soot `#1A1410`, alpha ramping
  from ~0.3 at centre to ~0.94 at the corners) so the screen darkens
  toward the edges while the centre — where the bargain cards sit — stays
  readable. Both nodes are still `mouse_filter`-passthrough and sit behind
  the card `Panel`; pause-on-open and centred-card behaviour are
  untouched. Only existing palette hexes are used — no grey slab, no
  sixth colour.
- **End panel flat slab → soot vignette wash (Shade note):** `EndPanel`
  (death/clear) now mirrors that same `Dim`/`Vignette` structure instead
  of its old flat `Dim` fill — a low-alpha rot (`#2D1F18`) base wash under
  a radial `GradientTexture2D` (soot `#1A1410`, alpha ramping from ~0.35
  at centre to ~0.96 at the corners), tuned very slightly darker at the
  edges than the bargain modal's to keep the same heavier end-of-run
  weight the old flat slab had. Title + **Again** button behaviour and
  the locked `Copy.DEATH_TITLE` / `Copy.CLEAR_TITLE` / `Copy.CTA_AGAIN`
  copy are untouched; only existing palette hexes are used.
- **Fog un-glued from the player (playtest fix):** `World.gd` no longer
  sets `fog.global_position = player.global_position` every frame — that
  made the fog `Polygon2D` clouds read as a personal light pool glued to
  the player instead of ambient atmosphere. Fog now only re-anchors, in a
  discrete jump, to the origin of the player's current chunk when the
  player crosses into a new chunk, so it stays fixed in world space while
  the player wanders within a chunk (`Fog.gd`'s own slow local drift is
  unchanged and still layers on top). Fog is still not a child of
  `Player`.
- **Engine bump to 4.7 (playtest fix):** `project.godot`'s
  `config/features` now reports `4.7` (tested against 4.7.2 stable)
  instead of `4.3`. No renderer or API changes were needed — the
  `gl_compatibility` renderer and all existing GDScript APIs are
  unaffected — so this is a version-label bump only.
- **Readable cast + NinePatch bargain cards (this pass):** the single
  Blob mob is replaced by two readable silhouettes — `Crawler.tscn` (low
  multi-leg skulker) and `Wraith.tscn` (taller, flame-tipped, faster,
  squishier) — both driven by the same `scripts/enemies/Enemy.gd`, and
  `World.gd`'s spawn pool now rolls Crawler-or-Wraith per spawn
  (`WRAITH_CHANCE`) instead of a single mob. The player and the XP pickup
  are now small PNG `Sprite2D`s too (hooded last-soul silhouette; curse-gold
  orb), all under `assets/sprites/`, all pulling only from the locked five
  hexes. `BargainCard` swaps its `StyleBoxFlat` Button theme for a
  `NinePatchRect` frame (`assets/ui/bargain_card_frame.png`: bone outline /
  soot fill / bruise thorn corners) — the Button's own normal/hover/
  pressed/focus styles are emptied out in the scene so the frame art is all
  that paints, with a small hover brighten on the frame's `modulate` to
  keep pointer feedback. A curse-gold pip (`assets/ui/curse_pip.png`) shows
  only on the one card whose icon colour is already curse-gold (`longer_
  shadow`), so it stays a highlight rather than inventing a fourth swatch.
  The bargain shrine landmark, `Game`'s bargain flow, `Copy.gd` and the
  modal's pause/vignette behaviour are all untouched.
- `Game` and `UITheme` are the only autoloads; everything else is composed
  through normal scene instancing (`Main.tscn` instances `World`, `HUD`,
  `BargainModal`, `EndPanel` as siblings).
- Movement reads `Input.is_physical_key_pressed()` directly (WASD/arrows)
  rather than an Input Map, so there's nothing to configure in Project
  Settings before playing.
- The project was smoke-tested headlessly (`godot --headless --path .`)
  through multiple full runs, including forced death, repeated
  bargain-pick cycles, and a scripted walk of 3000+ pixels to confirm the
  chunk streamer loads/unloads correctly and stays memory-bounded (loaded
  chunk count plateaus rather than growing unbounded) — no runtime errors
  in any of it. This pass re-ran that smoke test (Godot 4.3 headless, both
  a plain multi-minute run and Crawler/Wraith spawning + combat + a
  bargain pick) plus an offscreen `--rendering-driver opengl3` capture of
  the new sprites at 1× and the NinePatch bargain modal to confirm the
  cast and cards read correctly — no runtime errors in either.
