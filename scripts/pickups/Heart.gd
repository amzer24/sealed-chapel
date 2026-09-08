extends Area2D

## HP pickup dropped rarely by dead enemies (see `Game.HEART_DROP_CHANCE`).
## Sibling to `XPOrb.gd` -- same drift-then-collect behaviour -- but mute:
## unlike XP (and unlike a struck bargain), collecting a Heart shows no
## floating label, just the heal. `z_index = 1` (set on the scene's root
## node in `Heart.tscn`) keeps it drawn above XP orbs on the world's
## Y-sorted layer when the two land at the same on-screen height, so a
## rare Heart never gets buried under a stack of common XP gems.

@export var heal_amount := 22.0

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
		player.heal(heal_amount)
		return
	if dist <= player.pickup_radius:
		var dir := (player.global_position - global_position).normalized()
		global_position += dir * MAGNET_SPEED * delta

## Actual removal is deferred to `_process` (outside the physics step) to
## avoid racing the physics server's query flush the same way XP orbs and
## enemies do.
func _process(_delta: float) -> void:
	if _collected:
		queue_free()
