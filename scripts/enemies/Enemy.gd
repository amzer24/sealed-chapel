extends CharacterBody2D

## Shared mob behaviour: shambles straight at the player and deals contact
## damage on an interval while overlapping. Dies to player projectiles and
## drops an XP pickup. `Crawler.tscn` and `Wraith.tscn` both use this script,
## differing only in their exported stats and their visual/collision size.

@export var max_health := 16.0
@export var move_speed := 52.0
@export var contact_damage := 6.0
@export var contact_interval := 0.7
@export var xp_value := 4.0

## A dead enemy's Heart (when it drops one) is scattered a random distance
## in this range from the XP pickup spawned at the same `global_position`,
## so the two never render stacked on top of each other.
const HEART_SCATTER_MIN := 12.0
const HEART_SCATTER_MAX := 18.0

var health: float
var _target: Player
var _touching_player := false
var _pending_free := false

@onready var attack_area: Area2D = $AttackArea
@onready var contact_timer: Timer = $ContactTimer
@onready var visual: Node2D = $Visual
@onready var sprite: Sprite2D = $Visual/Sprite

var _hit_flash: HitFlash

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_target = Game.get_player()
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.body_exited.connect(_on_attack_area_body_exited)
	contact_timer.wait_time = contact_interval
	contact_timer.timeout.connect(_on_contact_timer_timeout)
	contact_timer.start()
	_hit_flash = HitFlash.new()
	visual.add_child(_hit_flash)
	_hit_flash.mirror(sprite)

func _physics_process(_delta: float) -> void:
	if _pending_free:
		return
	if _target and is_instance_valid(_target):
		velocity = (_target.global_position - global_position).normalized() * move_speed
		move_and_slide()

## `take_damage` is usually reached from a projectile's own collision signal,
## so the actual queue_free is deferred to `_process`, which only runs once
## the frame's physics step has fully settled (avoids racing the physics
## server's query flush).
func _process(_delta: float) -> void:
	if _pending_free:
		queue_free()

func take_damage(amount: float) -> void:
	if _pending_free:
		return
	_hit_flash.flash()
	health -= amount
	if health <= 0.0:
		_pending_free = true
		# Spawning the XP pickup adds a brand new Area2D to the tree; deferring
		# it keeps that add_child call out of the physics query flush that is
		# usually still in progress when a projectile's hit signal fires.
		call_deferred("_on_death")

func _on_death() -> void:
	Game.spawn_xp_pickup(global_position, xp_value)
	# Rarer than the XP drop, and scattered aside so the two pickups don't
	# spawn stacked exactly on top of each other.
	if randf() < Game.HEART_DROP_CHANCE:
		Game.spawn_heart_pickup(global_position + _heart_scatter_offset())
	Game.enemy_defeated()

func _heart_scatter_offset() -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(HEART_SCATTER_MIN, HEART_SCATTER_MAX)
	return Vector2(cos(angle), sin(angle)) * dist

func _on_attack_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = true

func _on_attack_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_touching_player = false

func _on_contact_timer_timeout() -> void:
	if _touching_player and _target and is_instance_valid(_target) and _target.has_method("take_damage"):
		_target.take_damage(contact_damage)
