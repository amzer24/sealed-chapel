class_name Aura
extends Area2D

## Player's clear-tool: a short-tick soft-DPS pulse to every enemy inside
## `radius`, no orbit/MultiMesh weapon. `LONGER_SHADOW` grows `radius` (see
## `Player.apply_upgrade_stat`'s "aura_radius" case), so a stacked bargain
## visibly widens the ring. The ring itself is a hard, non-antialiased
## outline (nearest-neighbour-style, no soft glow) so it reads like the
## rest of the hard-pixel cast rather than a VFX halo.

@export var radius := 56.0:
	set(value):
		radius = value
		_apply_radius()

@export var damage := 3.0
@export var tick_interval := 0.6:
	set(value):
		tick_interval = value
		if tick_timer:
			tick_timer.wait_time = tick_interval

const RING_COLOR := Color(Palette.CURSE, 0.4)
const RING_WIDTH := 2.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer

func _ready() -> void:
	_apply_radius()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	tick_timer.start()

func _apply_radius() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	queue_redraw()

func _on_tick_timer_timeout() -> void:
	for body in get_overlapping_bodies():
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage)

func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, RING_COLOR, RING_WIDTH, false)
