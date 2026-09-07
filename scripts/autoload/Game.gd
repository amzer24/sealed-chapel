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

const UPGRADE_POOL := [
	{"id": "bone_barbs", "name": "Bone Barbs", "desc": "+4 attack damage.", "stat": "damage", "amount": 4.0},
	{"id": "grave_speed", "name": "Grave Speed", "desc": "+20 move speed.", "stat": "move_speed", "amount": 20.0},
	{"id": "curseglass", "name": "Curseglass Vial", "desc": "Attacks strike faster.", "stat": "attack_speed", "amount": 0.12},
	{"id": "dried_vein", "name": "Dried Vein", "desc": "+20 max health, healed.", "stat": "max_health", "amount": 20.0},
	{"id": "wraith_step", "name": "Wraith Step", "desc": "+18 pickup reach.", "stat": "pickup_radius", "amount": 18.0},
	{"id": "ravens_sight", "name": "Raven's Sight", "desc": "+40 attack range.", "stat": "attack_range", "amount": 40.0},
]

var state: State = State.PLAYING
var elapsed := 0.0
var level := 1
var xp := 0.0
var xp_to_next := BASE_XP_TO_LEVEL
var enemies_defeated := 0
## Order the player accepted bargains in this run. Kept for a future replay
## seed; the prototype does not consume it yet.
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
	var pool := UPGRADE_POOL.duplicate()
	pool.shuffle()
	bargain_offered.emit(pool.slice(0, 3))

func choose_bargain(card: Dictionary) -> void:
	bargain_history.append(card.id)
	if _player and _player.has_method("apply_upgrade_stat"):
		_player.apply_upgrade_stat(card.stat, card.amount)
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
