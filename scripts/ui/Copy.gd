class_name Copy
extends RefCounted

## Locked UK-English copy constants (studio-approved). Keep the Grimm tone
## short; no ring-close language (this is an open roam, not a sealed arena).
## Do not paraphrase or substitute these strings.

const DEATH_TITLE := "The grounds took you."
const CLEAR_TITLE := "You walked out. The chapel kept the debt."
const BARGAIN_EMPTY := "No bargains tonight."
const CTA_AGAIN := "Again"

## Bargain card body copy (studio-locked, effect-first): the first sentence
## states the mechanical effect plainly (matching the numbers in `Game.
## UPGRADE_POOL`), the second is the short Grimm line. Uses the Unicode
## minus sign (−, not a hyphen) wherever a stat is reduced, to match the
## lock exactly. Do not paraphrase or substitute these strings.
const LONGER_SHADOW := "Attack range +40.\nYour reach grows."
const FEVER_PULSE := "Time between strikes −0.12s.\nThe fever rises."
const TITHE_OF_FLESH := "Damage +6. Max HP −10.\nBleed for a heavier hand."
const BONE_WARD := "Max HP +20. Current HP rises by the same.\nBone holds."
const GREEDY_HANDS := "Pickup range +18.\nTake what the fog drops."
const GLASS_BELL := "Move speed +18. Max HP −10.\nFaster feet. Thinner blood."
const HEAVY_HAND := "Damage +4. No HP cost.\nHarder blows. Flesh stays."

## Pick-juice tick text (studio-locked, exact strings): a brief floating
## label `BargainModal.gd` shows over the resumed playfield the instant a
## bargain is struck. Do not paraphrase -- these are intentionally terse.
## Uses the Unicode minus sign (−, not a hyphen) to match the lock exactly.
## The Heart pickup has no tick; it is mute by design.
const TICK_LONGER_SHADOW := "+range"
const TICK_FEVER_PULSE := "+rate"
const TICK_TITHE_OF_FLESH := "+dmg −HP"
const TICK_BONE_WARD := "+HP"
const TICK_GREEDY_HANDS := "+pickup"
const TICK_GLASS_BELL := "+speed −HP"
const TICK_HEAVY_HAND := "+dmg"

## Curse intro copy (studio-locked): the one-shot diegetic card shown before
## the player's first run (`CurseIntro.gd`), explaining what the HUD's
## `HUD_LEVEL` ("Curse %d") counter means before it starts climbing. Do not
## paraphrase or substitute these strings.
const CURSE_INTRO_TITLE := "Curse"
const CURSE_INTRO_BODY := "Curse counts the bargains you take this run. Deeper Curse means deeper debt and harder power."
const CURSE_INTRO_CTA := "Begin"

## HUD copy (studio-locked). `HUD_LEVEL` takes the current level (`%d`);
## `HUD_TIMER` takes minutes then seconds (`%d`, `%02d`).
const HUD_LEVEL := "Curse %d"
const HUD_TIMER := "%d:%02d to dawn"
