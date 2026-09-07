extends Area2D

## Simple player auto-attack bolt: travels in a straight line, damages the
## first enemy body it touches, then despawns (also despawns after its
## lifetime so shots that miss don't linger).

const SPEED := 340.0
const LIFETIME := 1.1

var _velocity := Vector2.ZERO
var _damage := 0.0
var _age := 0.0
var _pending_free := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func launch(direction: Vector2, damage: float) -> void:
	_velocity = direction * SPEED
	_damage = damage
	rotation = direction.angle()

## Freeing an Area2D from directly inside its own physics signal callback
## (or the same physics tick) can race the physics server's query flush, so
## the actual removal is deferred to `_process`, which only runs once the
## frame's physics step has fully settled.
func _physics_process(delta: float) -> void:
	if _pending_free:
		return
	position += _velocity * delta
	_age += delta
	if _age >= LIFETIME:
		_pending_free = true

func _process(_delta: float) -> void:
	if _pending_free:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if _pending_free:
		return
	if body.has_method("take_damage"):
		body.take_damage(_damage)
	_pending_free = true
