class_name Palette
extends RefCounted

## Shared colour language for the whole prototype: every placeholder sprite,
## prop and UI panel pulls from this palette so the kitbashed look stays
## consistent.
##
## LOCKED (Shade pass): exactly these five hexes. Do not add a sixth colour
## or reintroduce derived/dimmed float variants -- pick the closest of the
## five instead.

const SOOT := Color("1A1410")
const BONE := Color("E8DCC8")
const BRUISE := Color("4A3A5C")
const CURSE := Color("C4A35A")
const ROT := Color("2D1F18")
