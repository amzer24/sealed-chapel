# Sealed Chapel

*Tag: Curse Arena*

A Grimm fairy-tale, Vampire-Survivors-style prototype built in **Godot 4.x**
(GDScript). One open roaming map through a haunted wood and a ruined chapel
clearing — soot, bone, bruise-purple, dried-blood and curse-gold set
dressing, diegetic storybook UI, and a curse-bargain level-up loop.

This is explicitly **not** a sealed combat ring: the map has soft roam
bounds (an invisible edge to the wood, not a wall or closing circle), and
none of the dressing (iron fence, chapel ruin) forms a closed loop.

## Opening the project

1. Install **Godot 4.x** (built and tested against 4.3 stable; any 4.x
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

- **Open roam arena** — a procedurally-painted `TileMap` (no imported art)
  inside a `Y`-sorted 2D world, with **soft bounds**: the player and camera
  simply cannot pass the edge of the wood. No walls, no closing ring.
- **Player** — move + automatic attack (nearest-enemy targeting, simple
  projectile) via `scripts/player/Player.gd`.
- **One enemy type ("Blob")** — shambles toward the player and deals contact
  damage; dies to the player's auto-attack and drops an XP pickup.
  `scripts/enemies/Blob.gd`.
- **Waves** — a simple spawner (`scripts/world/World.gd`) that spawns more
  blobs, more often, the longer the run goes.
- **Curse bargain (level-up)** — collecting enough XP opens three curse
  cards centred as a modal over a **dimmed, paused** playfield; picking one
  applies the upgrade and resumes combat. Diegetic panel/button styling only
  — no default Godot theme chrome. `scripts/autoload/Game.gd` +
  `scripts/ui/BargainModal.gd` + `scripts/ui/BargainCard.gd`.
- **End states** — death (overrun) or a timed clear both show a themed panel
  (not the default engine dialog) with a short Grimm line and an **Again**
  button that restarts the run. `scripts/ui/EndPanel.gd`.
- **Diegetic HUD** — carved health/curse bars and a "till dawn" countdown,
  all hand-styled (`scripts/autoload/UITheme.gd`), no default `Theme`.
- **Kitbashed dressing** — dead trees, a broken chapel ruin, candle
  clusters with a soft glow, a *broken* iron fence (two short, disconnected
  runs — deliberately not a ring), a drifting fog layer, and a bargain
  shrine landmark, all built from simple `Polygon2D` placeholders in
  `scenes/props/`.
- A shared **colour palette** (`scripts/ui/Palette.gd`) and **copy
  constants** (`scripts/ui/Copy.gd`, including the locked `DEATH_TITLE` /
  `CTA_AGAIN` strings) so the whole prototype pulls from one place.

## What the Prototype excludes (out of scope)

- Inventory and minimap systems (shown in the UI mood-board for mood only).
- Multiplayer, a campaign/meta layer, or any paid/licensed assets.
- Unreal Engine — this is Godot 4 / GDScript only.
- A sealed ring / collider-as-level design. The roam uses soft bounds, not
  a shrinking or walled arena.
- Real balancing/tuning numbers. Stats (health, damage, spawn rates, XP
  curve) are placeholder values sized to make the loop legible for a short
  prototype run; they are **not** meant to hit the eventual 8–12 minute run
  target, and no specific player metrics were invented beyond what's needed
  to demonstrate the loop.
- A replay system. `Game.bargain_history` records the order bargains were
  accepted in as a forward-looking hook, but nothing consumes it yet.

## Placeholder art & where real sheets will land

Every visual in the Prototype is a simple coloured `Polygon2D`/`ColorRect`
shape generated in-editor (no imported textures except the project icon),
so the project has zero binary art dependencies and opens cleanly on any
machine. Approximate on-screen sizes match the brief:

| Element              | Scene                                | Size (approx.) |
|-----------------------|---------------------------------------|-----------------|
| Player                | `scenes/player/Player.tscn`           | ~24×24 |
| Blob (mob)            | `scenes/enemies/Blob.tscn`            | ~20×20 |
| XP pickup             | `scenes/pickups/XPOrb.tscn`           | ~12×12 |
| Bargain shrine (landmark) | `scenes/props/PropBargainShrine.tscn` | ~48×64 |

When real art is ready, drop sprite sheets under `assets/sprites/` (folders
already scaffolded for `player/`, `enemies/`, `pickups/`, `props/`) and swap
the placeholder `Polygon2D`/`ColorRect` visual children in each scene for a
`Sprite2D`/`AnimatedSprite2D` at the same scale — the gameplay scripts only
reference collision shapes and node paths that would remain unchanged.

## Project layout

```
project.godot              Engine config (Godot 4.x, GL Compatibility renderer)
scenes/
  main/Main.tscn            Composition root: World + HUD + BargainModal + EndPanel
  world/World.tscn           The roam: TileMap, Y-sorted entity layer, fog, spawner
  player/                    Player + auto-attack Projectile
  enemies/                   Blob mob
  pickups/                   XP orb
  props/                     Dead tree, chapel ruin, iron fence, candles, shrine
  ui/                        HUD, bargain modal + card, end panel
scripts/
  autoload/Game.gd           Run state: timer, XP/level curve, bargain flow, win/lose
  autoload/UITheme.gd        Builds the one shared diegetic Theme in code
  ui/Palette.gd              Shared colour constants (soot/bone/bruise/blood/gold)
  ui/Copy.gd                 Locked UK-English copy constants
  player/, enemies/, pickups/, world/, props/   Gameplay scripts
```

## Notes for reviewers

- `Game` and `UITheme` are the only autoloads; everything else is composed
  through normal scene instancing (`Main.tscn` instances `World`, `HUD`,
  `BargainModal`, `EndPanel` as siblings).
- Movement reads `Input.is_physical_key_pressed()` directly (WASD/arrows)
  rather than an Input Map, so there's nothing to configure in Project
  Settings before playing.
- The project was smoke-tested headlessly (`godot --headless --path .`)
  through multiple full runs, including forced death and repeated
  bargain-pick cycles, to confirm there are no runtime errors.
