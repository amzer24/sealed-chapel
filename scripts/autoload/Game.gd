extends Node

## Autoload singleton "Game".
##
## Owns run state: elapsed survival timer, XP/level curve, the bargain
## (level-up) flow, and win/lose transitions. Scenes register themselves
## (player, world spawn container) so this singleton can talk to them
## without tight scene coupling.

enum State { PLAYING, BARGAIN, DEAD, CLEARED }

signal state_changed(new_state: State)
signal health_changed(current: float, max_health: float)
signal xp_changed(current: float, needed: float, level: int)
signal timer_changed(elapsed: float, remaining: float)
signal bargain_offered(cards: Array)
signal run_ended(win: bool)

## Prototype run length is intentionally short; the full brief targets an
## 8-12 minute run once content (more waves/upgrades) is fleshed out.
const CLEAR_TIME := 150.0
const BASE_XP_TO_LEVEL := 10.0
const XP_GROWTH := 1.35

const XP_ORB_SCENE := preload("res://scenes/pickups/XPOrb.tscn")
const HEART_SCENE := preload("res://scenes/pickups/Heart.tscn")
## Hearts are a rarer drop than XP orbs -- most enemy deaths only drop XP.
const HEART_DROP_CHANCE := 0.12

## The seven stackable bargain commons. Every id is repeatable: the same
## bargain can be offered and struck again in a later level-up (there is
## no once-per-run gate). Each card is tagged "bless" (pure gain) or
## "curse" (gain paid for with a `max_health` cost) so `_build_offer` can
## keep an offer from reading as three of a kind.
const UPGRADE_POOL := [
	{
		"id": "longer_shadow",
		"title": Copy.LONGER_SHADOW,
		"tick": Copy.TICK_LONGER_SHADOW,
		"tag": "bless",
		# Remapped from the old "attack_range" bump to the clear-tool aura's
		# radius: the same +40 magnitude, now widening the soft-DPS aura
		# (the player-facing effect) instead of the projectile's targeting
		# range.
		"effects": [{"stat": "aura_radius", "amount": 40.0}],
	},
	{
		"id": "fever_pulse",
		"title": Copy.FEVER_PULSE,
		"tick": Copy.TICK_FEVER_PULSE,
		"tag": "bless",
		"effects": [{"stat": "attack_speed", "amount": 0.12}],
	},
	{
		"id": "tithe_of_flesh",
		"title": Copy.TITHE_OF_FLESH,
		"tick": Copy.TICK_TITHE_OF_FLESH,
		"tag": "curse",
		"effects": [{"stat": "damage", "amount": 6.0}, {"stat": "max_health", "amount": -10.0}],
	},
	{
		"id": "bone_ward",
		"title": Copy.BONE_WARD,
		"tick": Copy.TICK_BONE_WARD,
		"tag": "bless",
		# `apply_upgrade_stat`'s "max_health" case already tops up current
		# health by the same positive delta and floors at 1.0, so a bargain
		# can never be the cause of death -- no extra heal-helper call
		# needed here.
		"effects": [{"stat": "max_health", "amount": 20.0}],
	},
	{
		"id": "greedy_hands",
		"title": Copy.GREEDY_HANDS,
		"tick": Copy.TICK_GREEDY_HANDS,
		"tag": "bless",
		"effects": [{"stat": "pickup_radius", "amount": 18.0}],
	},
	{
		"id": "glass_bell",
		"title": Copy.GLASS_BELL,
		"tick": Copy.TICK_GLASS_BELL,
		"tag": "curse",
		"effects": [{"stat": "move_speed", "amount": 18.0}, {"stat": "max_health", "amount": -10.0}],
	},
	{
		"id": "heavy_hand",
		"title": Copy.HEAVY_HAND,
		"tick": Copy.TICK_HEAVY_HAND,
		"tag": "bless",
		"effects": [{"stat": "damage", "amount": 4.0}],
	},
]

const OFFER_SIZE := 3
## Cap on how many cards of the same bless/curse tag one offer may contain,
## so a level-up prefers a mixed offer over three of a kind. The pool has
## more blesses than curses, so this is what keeps an all-bless offer from
## being the common case.
const MAX_OFFER_PER_TAG := 2

var state: State = State.PLAYING
var elapsed := 0.0
var level := 1
var xp := 0.0
var xp_to_next := BASE_XP_TO_LEVEL
var enemies_defeated := 0
## Order the player accepted bargains in this run. All seven bargains are
## stackable now (no once-per-run gate reads this), so it is kept purely as
## a future replay seed; the prototype does not consume it yet.
var bargain_history: Array[String] = []

var _player: Player = null
var _world_container: Node2D = null

func _process(delta: float) -> void:
	if state != State.PLAYING:
		return
	elapsed += delta
	timer_changed.emit(elapsed, max(0.0, CLEAR_TIME - elapsed))
	if elapsed >= CLEAR_TIME:
		_end_run(true)

func register_player(player: Player) -> void:
	_player = player
	health_changed.emit(player.get_health(), player.get_max_health())

func get_player() -> Player:
	return _player

func register_world_container(container: Node2D) -> void:
	_world_container = container

func update_health(current: float, max_health: float) -> void:
	health_changed.emit(current, max_health)

func add_xp(amount: float) -> void:
	if state != State.PLAYING:
		return
	xp += amount
	xp_changed.emit(xp, xp_to_next, level)
	if xp >= xp_to_next:
		_trigger_bargain()

func _trigger_bargain() -> void:
	state = State.BARGAIN
	xp -= xp_to_next
	level += 1
	xp_to_next = ceilf(xp_to_next * XP_GROWTH)
	state_changed.emit(state)
	# Pause before emitting: any synchronous listener that chooses a card
	# immediately (resuming play) must win over this pause, not the other
	# way around.
	get_tree().paused = true
	bargain_offered.emit(_build_offer())

## Builds an `OFFER_SIZE`-card offer from the full stackable pool, capping
## how many cards share a tag at `MAX_OFFER_PER_TAG` so the offer prefers a
## bless/curse mix over three of a kind. Every id can reappear across
## offers (and be struck more than once in a run) since there is no
## once-only history gate.
func _build_offer() -> Array:
	var shuffled: Array = UPGRADE_POOL.duplicate()
	shuffled.shuffle()

	var offer: Array = []
	var tag_counts: Dictionary = {}
	for card: Dictionary in shuffled:
		if offer.size() >= OFFER_SIZE:
			break
		var tag: String = card.tag
		if tag_counts.get(tag, 0) >= MAX_OFFER_PER_TAG:
			continue
		offer.append(card)
		tag_counts[tag] = tag_counts.get(tag, 0) + 1

	# Defensive top-up: only reachable if the pool's tag composition ever
	# shrinks enough that the per-tag cap alone can't fill `OFFER_SIZE`.
	if offer.size() < OFFER_SIZE:
		for card: Dictionary in shuffled:
			if offer.size() >= OFFER_SIZE:
				break
			if not offer.has(card):
				offer.append(card)

	return offer

func choose_bargain(card: Dictionary) -> void:
	bargain_history.append(card.id)
	if _player:
		for effect in card.effects:
			_player.apply_upgrade_stat(effect.stat, effect.amount)
	_resume_from_bargain()

## The seven-card pool never empties (every id is stackable), so this is
## only a defensive fallback for the case `bargain_offered` somehow emits
## zero cards; `BargainModal.gd` shows `Copy.BARGAIN_EMPTY` and calls this
## on auto-dismiss.
func dismiss_empty_bargain() -> void:
	_resume_from_bargain()

func _resume_from_bargain() -> void:
	state = State.PLAYING
	get_tree().paused = false
	state_changed.emit(state)
	xp_changed.emit(xp, xp_to_next, level)

func player_died() -> void:
	_end_run(false)

func enemy_defeated() -> void:
	enemies_defeated += 1

func spawn_xp_pickup(pos: Vector2, value: float) -> void:
	if not _world_container:
		return
	var orb := XP_ORB_SCENE.instantiate()
	_world_container.add_child(orb)
	orb.global_position = pos
	orb.value = value

func spawn_heart_pickup(pos: Vector2) -> void:
	if not _world_container:
		return
	var heart := HEART_SCENE.instantiate()
	_world_container.add_child(heart)
	heart.global_position = pos

func _end_run(win: bool) -> void:
	state = State.CLEARED if win else State.DEAD
	state_changed.emit(state)
	run_ended.emit(win)
	get_tree().paused = true

func restart() -> void:
	reset()
	get_tree().paused = false
	get_tree().reload_current_scene()

func reset() -> void:
	state = State.PLAYING
	elapsed = 0.0
	level = 1
	xp = 0.0
	xp_to_next = BASE_XP_TO_LEVEL
	enemies_defeated = 0
	bargain_history.clear()
	_player = null
	_world_container = null
