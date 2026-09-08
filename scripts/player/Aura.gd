class_name Aura
extends Area2D

## Player's clear-tool: a short-tick soft-DPS pulse to every enemy inside
## `radius`, no orbit/MultiMesh weapon. Starts fully OFF -- no ring, no
## damage tick, no overlap monitoring, no `_draw()` -- until the player
## strikes their first `LONGER_SHADOW` bargain. `Player` never pokes
## `radius`/`damage`/`tick_interval` directly: it calls `apply_config()`
## (safe to call before or after this node's own `_ready`, so `Player`
## never has to depend on child-before-parent `_ready` ordering) and, on
## the first stack only, `activate()` to switch the aura on. Every stack
## after that grows `radius` by +40 via another `apply_config` call (see
## `Player.apply_upgrade_stat`'s "aura_radius" case), so a stacked bargain
## visibly widens the ring. The ring itself is a hard, non-antialiased
## outline (nearest-neighbour-style, no soft glow) so it reads like the
## rest of the hard-pixel cast rather than a VFX halo.

var radius := 56.0
var damage := 3.0
var tick_interval := 0.6
var active := false

const RING_COLOR := Color(Palette.CURSE, 0.65)
const RING_WIDTH := 2.0
## Brief hard-edged brighten of the ring whenever a tick actually lands a
## hit, so the quiet soft-DPS still reads as a visible pulse rather than
## silent drain. Same hard stroke as the resting ring, just the bone hex
## instead of curse -- no soft glow/blur layered on top.
const FLASH_COLOR := Color(Palette.BONE, 0.9)
const FLASH_DURATION := 0.12

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer

var _flash_time_left := 0.0

func _ready() -> void:
	monitoring = active
	set_process(active)
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	_apply_shape()
	if active:
		tick_timer.start()

## Pushes stat values onto the aura. Called explicitly by `Player` --
## once after `Player._ready()` with the base stats, and again on every
## `LONGER_SHADOW` stack after the first. Safe to call before this node's
## own `_ready` has run: the shape/timer are (re)applied here when ready,
## and again below if `_ready` already fired.
func apply_config(new_radius: float, new_damage: float, new_tick_interval: float) -> void:
	radius = new_radius
	damage = new_damage
	tick_interval = new_tick_interval
	if is_node_ready():
		tick_timer.wait_time = tick_interval
		_apply_shape()

## Turns the aura on for the first time: starts overlap monitoring, the
## tick timer and the ring draw. One-way -- the aura never re-locks once
## struck. Safe to call before this node's own `_ready` has run.
func activate() -> void:
	if active:
		return
	active = true
	monitoring = true
	set_process(true)
	if is_node_ready():
		tick_timer.start()
	queue_redraw()

func _apply_shape() -> void:
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = radius
	queue_redraw()

func _on_tick_timer_timeout() -> void:
	if not active:
		return
	var hit_any := false
	for body in get_overlapping_bodies():
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(damage)
			hit_any = true
	if hit_any:
		_flash_time_left = FLASH_DURATION
		queue_redraw()

func _process(delta: float) -> void:
	if _flash_time_left <= 0.0:
		return
	_flash_time_left = maxf(0.0, _flash_time_left - delta)
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	var color := FLASH_COLOR if _flash_time_left > 0.0 else RING_COLOR
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, RING_WIDTH, false)
