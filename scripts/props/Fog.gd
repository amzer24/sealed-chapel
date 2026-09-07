extends Node2D

## Cheap atmosphere: a few soft translucent blobs that drift in slow loops
## above the ground layer, evoking the mood-board fog without any imported
## art or particle textures.

@export var drift_radius := 40.0
@export var drift_speed := 0.12

var _origins: Array[Vector2] = []
var _time := 0.0

func _ready() -> void:
	for child in get_children():
		_origins.append(child.position)

func _process(delta: float) -> void:
	_time += delta
	var children := get_children()
	for i in children.size():
		var phase := i * 2.1
		var offset := Vector2(
			cos(_time * drift_speed + phase),
			sin(_time * drift_speed * 0.7 + phase)
		) * drift_radius
		children[i].position = _origins[i] + offset
