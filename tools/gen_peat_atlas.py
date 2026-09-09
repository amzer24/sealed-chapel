#!/usr/bin/env python3
"""Regenerate assets/tiles/peat_atlas.png (the peat ground TileMapLayer atlas).

Peat contrast pass (Shade board A/C, Flick PASS): the atlas was landing
close to 50/50 soot/rot, which read as a flat mid-value floor and left the
bruise-purple player/crawler silhouettes low-contrast against it. This
regenerates the same three density variants (sparse/mid/packed, one 32x32
tile per variant, laid out left-to-right) with soot #1A1410 now the clear
per-pixel majority and rot #2D1F18 as the minority texture, so the floor
reads darker and the cast pops. Per-pixel stochastic dither (not an ordered
Bayer matrix), no periodic checkerboard. All three variants share the exact
same base soot/rot field so any two tiles butt together with no visible
seam; only the sparse bone/curse grit scatter differs per variant, at the
same rough densities as before (well under 2% of pixels even on packed).

Palette hexes are the five locked in scripts/ui/Palette.gd. Re-run this
script whenever the atlas needs regenerating; it is fully deterministic
(fixed seeds) so a re-run with unchanged constants reproduces byte-identical
output.

Usage: python3 tools/gen_peat_atlas.py
"""

import random

from PIL import Image

TILE_SIZE = 32
VARIANTS = ["sparse", "mid", "packed"]

# Palette.gd hexes (soot/rot/bone/curse) -- do not add a sixth colour.
SOOT = (0x1A, 0x14, 0x10, 255)
ROT = (0x2D, 0x1F, 0x18, 255)
BONE = (0xE8, 0xDC, 0xC8, 255)
CURSE = (0xC4, 0xA3, 0x5A, 255)

# Soot is now the clear per-pixel majority (was ~53% rot / 46% soot, which
# read as a flat mid-value floor). Light-touch bias, not a solid soot fill.
SOOT_PROBABILITY = 0.66

BASE_FIELD_SEED = 20260909
# One grit density (fraction of pixels) and RNG seed per variant, roughly
# matching the original atlas's sparse/mid/packed grit rates (~0.3% / 0.8%
# / 1.6%). Grit stays a rare fleck, never a block, on every variant.
GRIT_DENSITY = {"sparse": 0.003, "mid": 0.008, "packed": 0.016}
GRIT_SEED = {"sparse": 111, "mid": 222, "packed": 333}
# Curse grit reads slightly more often than bone grit, matching the
# original atlas's roughly 6:4 curse:bone mix.
GRIT_CURSE_SHARE = 0.6


def build_base_field() -> list[list[tuple[int, int, int, int]]]:
    rng = random.Random(BASE_FIELD_SEED)
    field = []
    for _y in range(TILE_SIZE):
        row = []
        for _x in range(TILE_SIZE):
            row.append(SOOT if rng.random() < SOOT_PROBABILITY else ROT)
        field.append(row)
    return field


def scatter_grit(pixels: list[list[tuple[int, int, int, int]]], variant: str) -> None:
    rng = random.Random(GRIT_SEED[variant])
    density = GRIT_DENSITY[variant]
    for y in range(TILE_SIZE):
        for x in range(TILE_SIZE):
            if rng.random() < density:
                pixels[y][x] = CURSE if rng.random() < GRIT_CURSE_SHARE else BONE


def main() -> None:
    base_field = build_base_field()
    atlas = Image.new("RGBA", (TILE_SIZE * len(VARIANTS), TILE_SIZE))

    for i, variant in enumerate(VARIANTS):
        tile = [row[:] for row in base_field]
        scatter_grit(tile, variant)
        tile_img = Image.new("RGBA", (TILE_SIZE, TILE_SIZE))
        tile_img.putdata([px for row in tile for px in row])
        atlas.paste(tile_img, (i * TILE_SIZE, 0))

    out_path = "assets/tiles/peat_atlas.png"
    atlas.save(out_path)
    print(f"wrote {out_path} ({atlas.size[0]}x{atlas.size[1]})")


if __name__ == "__main__":
    main()
