extends Node2D

## Open roaming arena: builds a procedural ground TileMap (no external art
## needed), scatters haunted-wood / ruined-chapel dressing, spawns the
## player with soft bounds + camera follow, and runs the enemy spawner.
##
## This is a roam with soft edges, not a sealed ring: the iron fence prop is
## intentionally broken/partial rather than a closed loop.

const TILE_SIZE := 32
const MAP_TILES := Vector2i(72, 50)
const BOUNDS_INSET := 2

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/Blob.tscn")
const PROP_DEAD_TREE := preload("res://scenes/props/PropDeadTree.tscn")
const PROP_CHAPEL_RUIN := preload("res://scenes/props/PropChapelRuin.tscn")
const PROP_IRON_FENCE := preload("res://scenes/props/PropIronFence.tscn")
const PROP_CANDLE_CLUSTER := preload("res://scenes/props/PropCandleCluster.tscn")
const PROP_BARGAIN_SHRINE := preload("res://scenes/props/PropBargainShrine.tscn")

@export var spawn_interval_start := 2.2
@export var spawn_interval_min := 0.55
@export var spawn_ramp_time := 100.0

@onready var tile_map: TileMap = $TileMap
@onready var ysort: Node2D = $YSort
@onready var spawn_timer: Timer = $SpawnTimer

var player: Player
var bounds_min: Vector2
var bounds_max: Vector2

func _ready() -> void:
	var pixel_size := Vector2(MAP_TILES) * TILE_SIZE
	bounds_min = Vector2.ONE * TILE_SIZE * BOUNDS_INSET
	bounds_max = pixel_size - Vector2.ONE * TILE_SIZE * BOUNDS_INSET

	_build_ground()
	_scatter_dressing()
	_spawn_player(pixel_size * 0.5)

	Game.register_world_container(ysort)

	spawn_timer.wait_time = spawn_interval_start
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

# ---------------------------------------------------------------------------
# Ground
# ---------------------------------------------------------------------------

func _build_ground() -> void:
	var variants := [Palette.SOOT, Palette.SOOT_DARK, Palette.BRUISE_PURPLE_DARK, Palette.DRIED_BLOOD_DARK]
	var atlas_image := Image.create(TILE_SIZE * variants.size(), TILE_SIZE, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for v in variants.size():
		var base: Color = variants[v]
		for x in TILE_SIZE:
			for y in TILE_SIZE:
				var flicker := rng.randf_range(-0.04, 0.04)
				var c := Color(
					clampf(base.r + flicker, 0.0, 1.0),
					clampf(base.g + flicker, 0.0, 1.0),
					clampf(base.b + flicker, 0.0, 1.0)
				)
				atlas_image.set_pixel(v * TILE_SIZE + x, y, c)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(atlas_image)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for v in variants.size():
		source.create_tile(Vector2i(v, 0))
	var source_id := tile_set.add_source(source)
	tile_map.tile_set = tile_set

	for x in MAP_TILES.x:
		for y in MAP_TILES.y:
			var weights := [70, 18, 8, 4]
			var roll := rng.randi_range(0, 99)
			var variant := 0
			var acc := 0
			for i in weights.size():
				acc += weights[i]
				if roll < acc:
					variant = i
					break
			tile_map.set_cell(0, Vector2i(x, y), source_id, Vector2i(variant, 0))

# ---------------------------------------------------------------------------
# Dressing (kitbashed haunted wood + ruined chapel), hand placed so the
# layout stays a deliberate broken clearing rather than a sealed ring.
# ---------------------------------------------------------------------------

func _scatter_dressing() -> void:
	var center := Vector2(MAP_TILES) * TILE_SIZE * 0.5

	_place(PROP_CHAPEL_RUIN, center + Vector2(-160, -60))
	_place(PROP_CHAPEL_RUIN, center + Vector2(120, -90))
	_place(PROP_CHAPEL_RUIN, center + Vector2(-40, -140))
	_place(PROP_BARGAIN_SHRINE, center + Vector2(20, 40))
	_place(PROP_CANDLE_CLUSTER, center + Vector2(-90, 10))
	_place(PROP_CANDLE_CLUSTER, center + Vector2(90, -20))
	_place(PROP_CANDLE_CLUSTER, center + Vector2(0, 110))

	# Broken fence segments flanking the chapel clearing on two sides only.
	_place(PROP_IRON_FENCE, center + Vector2(-260, 60))
	_place(PROP_IRON_FENCE, center + Vector2(-260, 130))
	_place(PROP_IRON_FENCE, center + Vector2(220, 90))

	var tree_offsets := [
		Vector2(-420, -260), Vector2(-520, 40), Vector2(-380, 260),
		Vector2(-120, 340), Vector2(180, 320), Vector2(440, 180),
		Vector2(500, -60), Vector2(380, -280), Vector2(60, -360),
		Vector2(-260, -380), Vector2(560, 340), Vector2(-560, -140),
		Vector2(300, 400), Vector2(-40, -440),
	]
	for offset in tree_offsets:
		var pos: Vector2 = center + offset
		pos.x = clamp(pos.x, bounds_min.x, bounds_max.x)
		pos.y = clamp(pos.y, bounds_min.y, bounds_max.y)
		_place(PROP_DEAD_TREE, pos)

func _place(scene: PackedScene, pos: Vector2) -> void:
	var instance := scene.instantiate()
	ysort.add_child(instance)
	instance.global_position = pos

# ---------------------------------------------------------------------------
# Player + camera
# ---------------------------------------------------------------------------

func _spawn_player(spawn_pos: Vector2) -> void:
	player = PLAYER_SCENE.instantiate() as Player
	ysort.add_child(player)
	player.global_position = spawn_pos
	player.set_bounds(bounds_min, bounds_max)

	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = int(bounds_min.x)
	camera.limit_top = int(bounds_min.y)
	camera.limit_right = int(bounds_max.x)
	camera.limit_bottom = int(bounds_max.y)

# ---------------------------------------------------------------------------
# Enemy waves
# ---------------------------------------------------------------------------

func _on_spawn_timer_timeout() -> void:
	if Game.state != Game.State.PLAYING:
		return
	_spawn_wave()
	var t := clampf(Game.elapsed / spawn_ramp_time, 0.0, 1.0)
	spawn_timer.wait_time = lerpf(spawn_interval_start, spawn_interval_min, t)

func _spawn_wave() -> void:
	var count := 1 + int(Game.elapsed / 22.0)
	for i in count:
		_spawn_enemy()

func _spawn_enemy() -> void:
	if not player:
		return
	var enemy := ENEMY_SCENE.instantiate()
	ysort.add_child(enemy)
	enemy.global_position = _random_spawn_point_around_player()

func _random_spawn_point_around_player() -> Vector2:
	var angle := randf() * TAU
	var dist := randf_range(340, 460)
	var pos := player.global_position + Vector2(cos(angle), sin(angle)) * dist
	pos.x = clamp(pos.x, bounds_min.x, bounds_max.x)
	pos.y = clamp(pos.y, bounds_min.y, bounds_max.y)
	return pos
