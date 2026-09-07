extends Area2D

## XP pickup dropped by dead blobs. Drifts toward the player once inside
## their pickup radius (a simple magnet), then grants XP on contact.

@export var value := 4.0

const MAGNET_SPEED := 220.0
const COLLECT_DISTANCE := 10.0

var _collected := false

func _ready() -> void:
	add_to_group("pickups")

func _physics_process(delta: float) -> void:
	if _collected:
		return
	var player := Game.get_player()
	if not player or not is_instance_valid(player):
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= COLLECT_DISTANCE:
		_collected = true
		Game.add_xp(value)
		return
	if dist <= player.pickup_radius:
		var dir := (player.global_position - global_position).normalized()
		global_position += dir * MAGNET_SPEED * delta

## Actual removal is deferred to `_process` (outside the physics step) to
## avoid racing the physics server's query flush the same way projectiles
## and blobs do.
func _process(_delta: float) -> void:
	if _collected:
		queue_free()
