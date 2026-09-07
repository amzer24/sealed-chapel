class_name Player
extends CharacterBody2D

## The player: WASD/arrow movement plus a timed auto-attack that fires at the
## nearest enemy in range. Stats are mutated directly by bargain upgrades via
## `apply_upgrade_stat`.

const PROJECTILE_SCENE := preload("res://scenes/player/Projectile.tscn")

@export var move_speed := 130.0
@export var max_health := 60.0
@export var attack_damage := 8.0
@export var attack_interval := 0.85
@export var attack_range := 170.0
@export var pickup_radius := 46.0

var health: float
var bounds_min := Vector2.ZERO
var bounds_max := Vector2.ZERO

@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	health = max_health
	add_to_group("player")
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
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
	_apply_soft_bounds()

func _axis(key_a: Key, key_b: Key) -> float:
	return 1.0 if (Input.is_physical_key_pressed(key_a) or Input.is_physical_key_pressed(key_b)) else 0.0

## Soft bounds: no walls or colliders, the roam simply cannot walk past the
## edge of the wood. This is deliberately not a sealed ring.
func _apply_soft_bounds() -> void:
	global_position.x = clamp(global_position.x, bounds_min.x, bounds_max.x)
	global_position.y = clamp(global_position.y, bounds_min.y, bounds_max.y)

func set_bounds(min_pos: Vector2, max_pos: Vector2) -> void:
	bounds_min = min_pos
	bounds_max = max_pos

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
			max_health += amount
			health = min(max_health, health + amount)
			Game.update_health(health, max_health)
		"pickup_radius":
			pickup_radius += amount
		"attack_range":
			attack_range += amount
		_:
			push_warning("Unknown upgrade stat: %s" % stat)
