class_name Copy
extends RefCounted

## Locked UK-English copy constants (studio-approved). Keep the Grimm tone
## short; no ring-close language (this is an open roam, not a sealed arena).
## Do not paraphrase or substitute these strings.

const DEATH_TITLE := "The grounds took you."
const CLEAR_TITLE := "You walked out. The chapel kept the debt."
const BARGAIN_EMPTY := "No bargains tonight."
const CTA_AGAIN := "Again"
const LONGER_SHADOW := "Reach farther into the dark."
const FEVER_PULSE := "Strike as the fever rises."
const TITHE_OF_FLESH := "Bleed for a heavier hand."
const BONE_WARD := "Bone holds what flesh cannot."
const GREEDY_HANDS := "Reach farther for the fallen."
const GLASS_BELL := "Faster feet. Thinner blood."
const HEAVY_HAND := "Strike heavier than bone."

## Pick-juice tick text (studio-locked, exact strings): a brief floating
## label `BargainModal.gd` shows over the resumed playfield the instant a
## bargain is struck. Do not paraphrase -- these are intentionally terse.
## The Heart pickup has no tick; it is mute by design.
const TICK_LONGER_SHADOW := "+reach"
const TICK_FEVER_PULSE := "+fever"
const TICK_TITHE_OF_FLESH := "+might −flesh"
const TICK_BONE_WARD := "+bone"
const TICK_GREEDY_HANDS := "+grasp"
const TICK_GLASS_BELL := "+pace −flesh"
const TICK_HEAVY_HAND := "+might"

## HUD copy (studio-locked). `HUD_LEVEL` takes the current level (`%d`);
## `HUD_TIMER` takes minutes then seconds (`%d`, `%02d`).
const HUD_LEVEL := "Curse %d"
const HUD_TIMER := "%d:%02d to dawn"
