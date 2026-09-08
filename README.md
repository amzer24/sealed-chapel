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
  square chunks (32×32 tiles, ~1024×1024px each) of ground, painted from
  the authored peat tile atlas onto a `TileMapLayer`, in around the
  player, unloading chunks once they're a couple of
  chunks behind. Each chunk's ground + dressing is generated from a seed
  derived from its own coordinate, so revisiting a chunk always regenerates
  the *same* layout deterministically, without needing to keep it resident.
  There is no wall and no camera/position clamp anywhere — the player can
  walk in one direction indefinitely and new wood keeps streaming in.
- **Player** — move + automatic attack (nearest-enemy targeting, simple
  projectile) via `scripts/player/Player.gd`, plus a passive clear-tool
  aura (`scripts/player/Aura.gd`) that periodically ticks soft damage to
  every enemy inside its radius — no orbit/MultiMesh weapon, just a thin
  hard-edged ring. `LONGER_SHADOW` grows the aura's radius.
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
- **Bargain (level-up)** — collecting enough XP opens a modal, up to three
  cards, centred over a **dimmed, paused** playfield; picking one applies
  the upgrade and resumes combat. Diegetic panel/button styling only — no
  default Godot theme chrome. `scripts/autoload/Game.gd` +
  `scripts/ui/BargainModal.gd` + `scripts/ui/BargainCard.gd`.
  - **Seven stackable bargains** — `Game.UPGRADE_POOL` holds seven bargain
    commons (`longer_shadow`/`fever_pulse`/`tithe_of_flesh`/`bone_ward`/
    `greedy_hands`/`glass_bell`/`heavy_hand`); every id can be offered and
    struck more than once in a run (no once-per-run gate). Each level-up
    offer is 3 cards drawn from the full pool, capped at 2 cards per
    bless/curse tag (`Game._build_offer`, `Game.MAX_OFFER_PER_TAG`) so the
    offer prefers a mix over three of a kind. `BargainCard`'s curse pip
    shows on whichever cards are tagged `"curse"` (the two that pay their
    gain with a `max_health` cost), not a fixed id.
  - **Pick juice** — striking a bargain plays a brief bone-coloured screen
    flash plus a floating tick label (`Copy.TICK_*`, e.g. `+range`,
    `+dmg −HP`) over the just-resumed playfield, then the modal fully
    hides again (`BargainModal._play_pick_juice`).
- **Heart pickup** — a mute HP pickup (`scripts/pickups/Heart.gd`,
  `assets/sprites/pickups/heart.png`), sibling to the XP orb: same
  drift-into-pickup-radius-then-collect behaviour, but no floating label on
  collect. Restores a flat chunk of health (`Heart.heal_amount`) via
  `Player.heal`, which tops up current HP without moving the `max_health`
  ceiling. Dropped rarely from enemy deaths (`Game.HEART_DROP_CHANCE`,
  rarer than the XP drop).
- **Curse intro** — a one-shot diegetic card (`scripts/ui/CurseIntro.gd`,
  `scenes/ui/CurseIntro.tscn`) explains what the HUD's Curse counter means
  before the player's very first run. It pauses the tree exactly like the
  bargain modal does (nothing spawns or ticks) until **Begin** is pressed,
  then never shows again for that save — a flag persists to a small
  `ConfigFile` under `user://save.cfg`.
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
  player/                    Player + auto-attack Projectile + clear-tool Aura
  enemies/                   Crawler + Wraith mobs (share scripts/enemies/Enemy.gd)
  pickups/                   XP orb
  props/                     Dead tree, chapel ruin, iron fence, candles, shrine
  ui/                        HUD, bargain modal + card, end panel, Curse intro
scripts/
  autoload/Game.gd           Run state: timer, XP/level curve, bargain flow, win/lose
  autoload/UITheme.gd        Builds the one shared diegetic Theme in code
  ui/Palette.gd              Shared colour constants (soot/bone/bruise/curse/rot)
  ui/Copy.gd                 Locked UK-English copy constants
  world/World.gd             Chunk streamer: peat TileMapLayer ground + dressing + waves
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
- Loading a chunk creates one `TileMapLayer` (ground, painted from the
  authored peat atlas at `assets/tiles/peat_atlas.png`) plus a handful of
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
- **Peat atlas: quiet 32px TileMapLayer (this pass):** the ground was a
  runtime-generated 4-colour atlas (soot/rot/bruise/curse squares with a
  tiny per-pixel flicker) painted onto a legacy `TileMap` — the bruise and
  curse tiles in particular read as loud tan/purple wallpaper blocks, and
  the flat per-tile colour made the streaming grid visible while roaming.
  Ground is now a single authored 96×32 PNG,
  `assets/tiles/peat_atlas.png` (three 32×32 tiles: sparse / mid /
  packed), built only from soot `#1A1410` and rot `#2D1F18` — kept close
  in value via a per-pixel stochastic dither (not a flat fill, not an
  ordered Bayer grid, so no periodic checkerboard) — plus a sparse
  scatter of 1–2px bone/curse grit per tile (never a block, and under 2%
  of pixels even on `packed`). All three variants share the exact same
  base dither field, so any two tiles butt together with no visible seam
  regardless of which pair lands next to each other. `World.gd` now
  builds its shared `TileSet` from that real PNG (`GROUND_ATLAS`) instead
  of synthesizing an `Image` at runtime, every chunk's ground node is a
  `TileMapLayer` (Godot 4.3+) rather than the deprecated multi-layer
  `TileMap` (`set_cell` calls updated to the layer-less signature), and
  each `TileMapLayer` sets `texture_filter = NEAREST` so the atlas stays
  hard-pixel like the cast. Tile size is unchanged (`World.TILE_SIZE =
  32`); weighting shifted from 4 colour variants to 3 density variants
  (sparse 60% / mid 30% / packed 10%) so the floor stays quiet on
  average. Cast sprites, the bargain flow, `Copy.gd` and
  `CanvasModulate`/HUD are untouched.
- **Fog retint (Shade PASS+NOTES follow-up):** the five `Fog` `Polygon2D`
  clouds in `World.tscn` no longer use the pale lilac
  `Color(0.55, 0.55, 0.62, 0.14)` placeholder, which read as glowing light
  pools rather than atmosphere. They now alternate low-alpha soot
  `#1A1410` and rot `#2D1F18` (alpha 0.22–0.28) so the clouds read as dark
  Grimm haze against the ground instead of a lit fill — only existing
  palette hexes are used, no sixth colour. The world-anchored,
  chunk-reanchor behaviour from the earlier fog fix is untouched: `Fog.gd`
  still drifts each cloud locally, and `World.gd` still only snaps
  `fog.global_position` to the player's current chunk origin — fog is
  still not glued to the player. Re-ran the headless smoke test (Godot
  4.7.2 headless, `--import` then a short run) with no runtime errors.
- **Seven stackable bargains + Heart heal (this pass):** the bargain pool
  grew from three once-only curses to seven stackable commons — added
  `bone_ward` (`max_health+`, tops up current HP by the same delta via the
  existing `apply_upgrade_stat` "max_health" case, so it can never be the
  cause of death), `greedy_hands` (`pickup_radius+`), `glass_bell`
  (`move_speed+` / `max_health-`, a curse) and `heavy_hand` (`damage+`) to
  the existing `longer_shadow` / `fever_pulse` / `tithe_of_flesh`. Their
  icons and copy one-liners were already wired
  (`BargainCard.ICON_PATHS`, `Copy.gd`); `Player.apply_upgrade_stat`
  needed no new stat cases since every bargain reuses the six stats it
  already handles. `Game._trigger_bargain` no longer filters
  `UPGRADE_POOL` by `bargain_history` — every id can be offered and struck
  again, so the pool never runs dry and `Copy.BARGAIN_EMPTY` is now only a
  defensive fallback path (kept, but effectively unreachable). Each offer
  is still exactly 3 cards, now drawn from the full seven and capped at 2
  cards per bless/curse tag (`Game._build_offer`) so an offer prefers a
  mix over three of a kind; `BargainCard`'s curse-gold pip now reflects
  that same tag (the two cards with a `max_health` cost) instead of a
  single hardcoded id. Picking a card now also plays a brief pick-juice
  flash + floating tick label (`Copy.TICK_*`, e.g. `+reach`, `+might
  −flesh`) over the resumed playfield before the modal fully re-hides
  (`BargainModal._play_pick_juice`) — pause-on-open and centred-card
  behaviour are untouched. A new **Heart** pickup
  (`scripts/pickups/Heart.gd`, `assets/sprites/pickups/heart.png`) is a
  mute sibling to the XP orb (same drift-then-collect behaviour, no
  floating label) that restores a flat chunk of HP via a new
  `Player.heal()` helper (refills under the existing `max_health` ceiling,
  distinct from a bargain's max-health-shifting case); `Enemy._on_death`
  drops one rarely (`Game.HEART_DROP_CHANCE`), rarer than the XP drop.
  Verified headlessly against a temporary harness scene driving the real
  `Main.tscn` + `BargainModal` UI (Godot 4.7.2 headless): forced
  back-to-back bargains confirmed every offer is 3 cards with ≤2 per tag,
  confirmed stacking (the same id struck more than once in one run),
  clicked a real `BargainCard` button through the actual signal path to
  confirm the pick-juice tween runs and the modal re-hides afterward, and
  confirmed `Player.heal()` restores HP and clamps at `max_health`. Also
  re-ran the plain `Main.tscn` headlessly (`--quit-after 300`) with no
  runtime errors. Out of scope per the brief: orbit garlic, regen,
  lifesteal, multi-shot, rarity tiers, and any stat beyond
  `attack_range`/`attack_speed`/`damage`/`max_health`/`move_speed`/
  `pickup_radius`.
- **Effect-first bargain copy + Curse intro card (this pass):** every
  `Copy.gd` bargain body is now effect-first — a plain mechanical sentence
  (e.g. `"Attack range +40."`) followed by the existing short Grimm line
  (e.g. `"Your reach grows."`) on its own line, so the number the card
  actually grants is readable, not just the flavour. `BargainCard`'s
  single `Title` label already autowraps, so the two-line body needed no
  scene change. Every `Copy.TICK_*` pick-juice string was relocked to a
  terser, stat-labelled form (e.g. `+reach` → `+range`, `+might −flesh` →
  `+dmg −HP`) — same tick mechanism, new locked text. Both card and tick
  strings use the Unicode minus sign (`−`) wherever a stat drops, matching
  the existing `TICK_TITHE_OF_FLESH` precedent rather than an ASCII
  hyphen. A new one-shot **Curse intro** card
  (`scripts/ui/CurseIntro.gd` + `scenes/ui/CurseIntro.tscn`) explains the
  HUD's `Copy.HUD_LEVEL` ("Curse %d") counter before the player's first
  run: title/body/`Begin` CTA use the new locked `Copy.CURSE_INTRO_*`
  constants, the card reuses the same bargain-card `NinePatchRect` frame
  (bone outline / soot fill / bruise thorn corners) stretched to ~280×160,
  and sits over the same rot-wash-under-soot-vignette backdrop as
  `BargainModal`/`EndPanel` (no new chrome, no sixth colour). `Begin` is
  styled bone-on-bruise (`bg` bruise / border curse / font bone,
  inverting to curse/bone/soot on hover) to read as a distinct CTA from
  the soot-styled `UITheme` buttons elsewhere. The card pauses the tree
  in `_ready()` exactly the way `BargainModal` pauses it mid-run (so no
  wave spawns or survive-timer ticks happen underneath it), and unpauses
  on `Begin`. It shows at most once per save: a `seen_curse_intro` flag
  persists to a small `ConfigFile` at `user://save.cfg`, so `Main.tscn`
  (which now also instances `CurseIntro`) skips straight into the roam on
  every later boot. Out of scope for this pass per the brief: any aura/
  Area2D visual, a clear-tool, remapping `LONGER_SHADOW`'s tick to
  `+clear`, and any new icon art. Verified headlessly (Godot 4.7.2
  `--headless --path . --import`, then a `--quit-after` smoke run) with
  no runtime errors, plus a byte-level diff-check that every relocked
  `Copy.gd` string (including the Unicode minus signs) matches the locked
  text exactly.
- **Clear-tool aura + `LONGER_SHADOW` remap + softer mid-run density (this
  pass):** the player gets a passive clear tool for late-run blobs instead
  of a fourth hard weapon — a new `Aura` `Area2D` (`scripts/player/
  Aura.gd`, a child of `Player.tscn`) that periodically ticks a small
  amount of soft DPS (`Aura.damage`, default 3.0 every `Aura.
  tick_interval`, default 0.6s) to every enemy overlapping its
  `CollisionShape2D`, hard nearest-neighbour targeting via `get_
  overlapping_bodies()` (same collision-layer convention `Projectile.gd`
  already uses to hit the enemy layer). No orbit/MultiMesh weapon: the
  only visual is a thin, non-antialiased curse-gold ring drawn in `Aura.
  _draw()` at the current radius, so it reads as a hard-pixel readout of
  the clear zone rather than a VFX glow — still only the five locked
  hexes. `LONGER_SHADOW` is remapped from bumping `attack_range` to
  bumping this aura's radius instead (`Player.aura_radius`, default 56.0,
  +40 per pick via a new `Player.apply_upgrade_stat` "aura_radius" case
  that also resizes the live `CollisionShape2D` so a stacked pick visibly
  widens the ring immediately) — the projectile's own `attack_range` is
  untouched, per the brief's steer toward the aura as the player-facing
  effect. Copy is relocked to match exactly:
  `Copy.LONGER_SHADOW` → `"Clear aura grows wider (+40).\nYour reach
  grows."` and `Copy.TICK_LONGER_SHADOW` → `"+clear"`; every other bargain/
  tick string is untouched. Separately, `World.gd`'s mid-run spawn density
  is softened by a number tweak only (no new enemy types): `spawn_
  interval_min` raised `0.55` → `0.65` (the fastest the spawn timer can
  ramp down to) and the per-wave enemy-count growth divisor (`_spawn_
  wave`'s `1 + int(Game.elapsed / N)`) raised `22.0` → `28.0` (now a named
  `WAVE_SIZE_RAMP_SECONDS` const) so wave size climbs a little slower —
  together these two loosen the late-run "brick wall" where spawn rate and
  wave size both peaked at once, giving the new aura more room to keep up.
  Verified headlessly with a temporary harness scene (not committed) that
  instanced a real `Player` + `Crawler` outside the editor: confirmed a
  stationary Crawler's health ticks down under the aura alone (attack
  damage zeroed out to isolate it), confirmed `apply_upgrade_stat
  ("aura_radius", 40.0)` grows both `Player.aura_radius` and the live
  `CollisionShape2D` radius by exactly 40, and confirmed the relocked
  `Copy` strings and `Game.UPGRADE_POOL`'s `longer_shadow` entry both
  read back exactly as above. Also re-ran the plain `Main.tscn` headlessly
  (`--quit-after 300`) with no runtime errors. Out of scope per the brief:
  orbit garlic sprites, MultiMesh, regen, lifesteal, multi-shot, new enemy
  types, and any TileMapLayer/ground changes.
- **Bug fix: aura-off at run start + hit-flash + Heart draw order (this
  pass):** the previous pass's `Aura` was live from the moment `Player`
  entered the tree -- ticking soft DPS and drawing its ring before any
  `LONGER_SHADOW` had ever been struck. `Aura.gd` now starts fully OFF
  (`monitoring` false, its own `_process` off, `_draw()` a no-op) and
  only switches on via a new one-way `activate()`, called the first time
  `Player.apply_upgrade_stat("aura_radius", ...)` runs; every stack after
  that just grows the radius by the bargain's own amount (still +40) and
  re-applies it. `Player` no longer pokes `Aura`'s `radius`/`damage`/
  `tick_interval` fields directly (which quietly relied on `Aura`'s own
  `_ready` -- child nodes ready before their parent -- having already run
  by the time `Player._ready` touched them): both `_ready` and every
  later stack now go through an explicit `Aura.apply_config(radius,
  damage, tick_interval)`, which is safe to call whether or not `Aura`'s
  own `_ready` has fired yet. `Player.apply_upgrade_stat`'s long-dead
  `"attack_range"` arm (orphaned by the previous pass's remap to
  `"aura_radius"`, but never actually deleted) is now gone; the
  projectile's `attack_range` is untouched and still just `Player`'s
  fixed default. The ring itself is bumped from the old `0.4` alpha to
  the locked `~0.65` (still curse-gold `#C4A35A`, still a bare
  `draw_arc` stroke -- no interior fill was ever added) and now briefly
  flashes bone `#E8DCC8` for `0.12s` on any tick that actually lands a
  hit, so the quiet soft-DPS reads as a visible pulse rather than silent
  drain (same hard, non-antialiased stroke -- no soft glow layered on
  top). Separately, `Heart.tscn` gets `z_index = 1` so a Heart always
  draws over XP orbs on the `World` `YSort` layer at the same on-screen
  height, and `Enemy.gd`'s heart-drop offset is replaced with a
  `_heart_scatter_offset()` that lands the Heart a random `12`-`18`px
  from the XP pickup spawned at the same death (the old fixed `(0, -8)`
  nudge was under the `12px` floor). `LONGER_SHADOW`'s `Copy.gd` body and
  tick strings are untouched (still locked exact) since the effect-first
  copy already reads as the general "+40, wider aura" mechanic and isn't
  tied to a specific stack. Verified headlessly with a temporary harness
  scene (not committed) that instanced a real `Player` + `Crawler`
  outside the editor: confirmed the aura starts with `monitoring` off and
  the Crawler takes no damage before any bargain is struck; confirmed the
  first `"aura_radius"` stack activates the aura at the base `56.0`
  radius (not `+40`) and the Crawler then does take tick damage; confirmed
  a second stack grows `Player.aura_radius`/`Aura.radius` to `96.0`;
  confirmed a tick that lands a hit sets `Aura`'s flash timer; confirmed
  the dead `"attack_range"` arm now only logs `push_warning`'s generic
  "Unknown upgrade stat" and leaves `Player.attack_range` untouched; and
  confirmed a `Heart` instance's `z_index` sits above an `XPOrb`'s and
  `Enemy._heart_scatter_offset()` never returns a vector shorter than
  `12px` across 20 samples. Also re-imported and re-ran the plain
  `Main.tscn` headlessly (Godot `4.7.2-stable` linux, `--headless --path .
  --import` then `--quit-after 180`) with no runtime errors. Out of scope
  per the brief: always-on aura, multi-orbit, new bargain cards, any UI
  rewrite, the `_process`-deferred-`queue_free` refactor noted in
  `Enemy.gd`/`XPOrb.gd`/`Heart.gd` (flagged for a future pass, not touched
  here), dual-grid, and PixelLab.
