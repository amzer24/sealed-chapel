class_name Player
extends CharacterBody2D

## The player: WASD/arrow movement plus a timed auto-attack that fires at the
## nearest enemy in range. Stats are mutated directly by bargain upgrades via
## `apply_upgrade_stat`. The roam is endless (chunks stream in around the
## player in `World.gd`), so there is no bounds clamp here and no wall to
## hit -- movement is unconstrained in every direction.

const PROJECTILE_SCENE := preload("res://scenes/player/Projectile.tscn")

@export var move_speed := 130.0
@export var max_health := 60.0
@export var attack_damage := 8.0
@export var attack_interval := 0.85
@export var attack_range := 170.0
@export var pickup_radius := 46.0
## Clear-tool aura stats -- mirrored onto the child `Aura` node in `_ready`
## and whenever `LONGER_SHADOW` (the "aura_radius" upgrade stat) grows it.
@export var aura_radius := 56.0
@export var aura_damage := 3.0
@export var aura_tick_interval := 0.6

var health: float

@onready var attack_timer: Timer = $AttackTimer
@onready var aura: Aura = $Aura

func _ready() -> void:
	health = max_health
	add_to_group("player")
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	aura.radius = aura_radius
	aura.damage = aura_damage
	aura.tick_interval = aura_tick_interval
	Game.register_player(self)

func _physics_process(_delta: float) -> void:
	var input_vec := Vector2(
		_axis(KEY_D, KEY_RIGHT) - _axis(KEY_A, KEY_LEFT),
		_axis(KEY_S, KEY_DOWN) - _axis(KEY_W, KEY_UP)
	)
	if input_vec.length() > 1.0:
		input_vec = input_vec.normalized()
	velocity = input_vec * move_speed
	move_and_slide()

func _axis(key_a: Key, key_b: Key) -> float:
	return 1.0 if (Input.is_physical_key_pressed(key_a) or Input.is_physical_key_pressed(key_b)) else 0.0

func get_health() -> float:
	return health

func get_max_health() -> float:
	return max_health

func _on_attack_timer_timeout() -> void:
	var target := _find_nearest_enemy()
	if target:
		_fire_at(target)

func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist <= nearest_dist:
			nearest_dist = dist
			nearest = enemy
	return nearest

func _fire_at(target: Node2D) -> void:
	var projectile := PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.launch((target.global_position - global_position).normalized(), attack_damage)

## Restores health without moving the `max_health` ceiling -- the Heart
## pickup's heal. Distinct from `apply_upgrade_stat`'s "max_health" case,
## which shifts the ceiling itself rather than just refilling under it.
func heal(amount: float) -> void:
	if health <= 0.0:
		return
	health = clampf(health + amount, 0.0, max_health)
	Game.update_health(health, max_health)

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = max(0.0, health - amount)
	Game.update_health(health, max_health)
	if health <= 0.0:
		_die()

func _die() -> void:
	set_physics_process(false)
	Game.player_died()

func apply_upgrade_stat(stat: String, amount: float) -> void:
	match stat:
		"damage":
			attack_damage += amount
		"attack_speed":
			attack_interval = maxf(0.15, attack_interval - amount)
			attack_timer.wait_time = attack_interval
		"move_speed":
			move_speed += amount
		"max_health":
			# Tithe of Flesh pays for its damage with a max-health cost; floor
			# both so a bargain can never be the literal cause of death.
			max_health = maxf(10.0, max_health + amount)
			health = clampf(health + amount, 1.0, max_health)
			Game.update_health(health, max_health)
		"pickup_radius":
			pickup_radius += amount
		"attack_range":
			attack_range += amount
		"aura_radius":
			aura_radius += amount
			aura.radius = aura_radius
		_:
			push_warning("Unknown upgrade stat: %s" % stat)
