extends Node2D

## Endless, procedural roam: ground and dressing stream in as square chunks
## around the player (Survivors-style), not one fixed, hand-authored map
## rectangle. Chunks load ahead of the player and unload behind them, so
## there is no hard wall anywhere and no sealed ring.
##
## Each chunk's ground + dressing is generated from a seed derived from its
## own coordinate, so revisiting a chunk always regenerates the same layout
## deterministically without needing to keep it resident forever.

const TILE_SIZE := 32
const CHUNK_TILES := 32
const CHUNK_PIXELS := TILE_SIZE * CHUNK_TILES

## Chunks within LOAD_RADIUS of the player's chunk must always be resident;
## anything beyond KEEP_RADIUS gets unloaded. The gap between the two is a
## buffer so chunks don't thrash in and out right at the edge.
const LOAD_RADIUS := 1
const KEEP_RADIUS := 2
const CHUNK_CHECK_INTERVAL := 0.35

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

@onready var ground: Node2D = $Ground
@onready var ysort: Node2D = $YSort
@onready var fog: Node2D = $Fog
@onready var spawn_timer: Timer = $SpawnTimer
@onready var chunk_timer: Timer = $ChunkTimer

var player: Player

var _ground_tile_set: TileSet
var _ground_source_id := 0
## Vector2i chunk coord -> {"tile_map": TileMap, "props": Array[Node2D]}
var _loaded_chunks: Dictionary = {}
var _player_chunk := Vector2i.ZERO

func _ready() -> void:
	_build_shared_ground_tile_set()
	_spawn_player(Vector2.ZERO)
	_update_chunks(true)

	Game.register_world_container(ysort)

	spawn_timer.wait_time = spawn_interval_start
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

	chunk_timer.wait_time = CHUNK_CHECK_INTERVAL
	chunk_timer.timeout.connect(_on_chunk_timer_timeout)
	chunk_timer.start()

# ---------------------------------------------------------------------------
# Shared procedural ground atlas -- built once and reused by every chunk's
# TileMap so we never pay the texture-generation cost more than once.
# ---------------------------------------------------------------------------

func _build_shared_ground_tile_set() -> void:
	var variants := [Palette.SOOT, Palette.ROT, Palette.BRUISE, Palette.CURSE]
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
	_ground_source_id = tile_set.add_source(source)
	_ground_tile_set = tile_set

# ---------------------------------------------------------------------------
# Chunk streaming
# ---------------------------------------------------------------------------

func _world_to_chunk(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / CHUNK_PIXELS)), int(floor(pos.y / CHUNK_PIXELS)))

func _chunk_distance(a: Vector2i, b: Vector2i) -> int:
	return max(abs(a.x - b.x), abs(a.y - b.y))

func _on_chunk_timer_timeout() -> void:
	_update_chunks(false)

func _update_chunks(force: bool) -> void:
	if not player:
		return
	var center := _world_to_chunk(player.global_position)
	if not force and center == _player_chunk and not _loaded_chunks.is_empty():
		return
	_player_chunk = center

	# Fog is atmosphere, not a spotlight on the player: it only re-anchors
	# to the origin of the player's current chunk (a discrete jump on chunk
	# crossings, matching the authored cloud layout at world origin), so it
	# stays put in world space while the player wanders within a chunk, and
	# Fog.gd's own local drift still applies on top.
	fog.global_position = Vector2(center) * CHUNK_PIXELS

	for x in range(center.x - LOAD_RADIUS, center.x + LOAD_RADIUS + 1):
		for y in range(center.y - LOAD_RADIUS, center.y + LOAD_RADIUS + 1):
			var coord := Vector2i(x, y)
			if not _loaded_chunks.has(coord):
				_load_chunk(coord)

	for coord in _loaded_chunks.keys():
		if _chunk_distance(coord, center) > KEEP_RADIUS:
			_unload_chunk(coord)

func _load_chunk(coord: Vector2i) -> void:
	var origin := Vector2(coord) * CHUNK_PIXELS

	var tile_map := TileMap.new()
	tile_map.tile_set = _ground_tile_set
	tile_map.position = origin
	ground.add_child(tile_map)
	_paint_chunk_ground(tile_map, coord)

	_loaded_chunks[coord] = {
		"tile_map": tile_map,
		"props": _scatter_chunk_dressing(coord, origin),
	}

func _unload_chunk(coord: Vector2i) -> void:
	var data: Dictionary = _loaded_chunks[coord]
	(data.tile_map as Node).queue_free()
	for prop in data.props:
		if is_instance_valid(prop):
			prop.queue_free()
	_loaded_chunks.erase(coord)

func _paint_chunk_ground(tile_map: TileMap, coord: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_seed(coord, 0)
	var weights := [70, 18, 8, 4]
	for x in CHUNK_TILES:
		for y in CHUNK_TILES:
			var roll := rng.randi_range(0, 99)
			var variant := 0
			var acc := 0
			for i in weights.size():
				acc += weights[i]
				if roll < acc:
					variant = i
					break
			tile_map.set_cell(0, Vector2i(x, y), _ground_source_id, Vector2i(variant, 0))

## Deterministic integer hash so a chunk always regenerates the same ground
## and dressing when revisited, without needing to store it while unloaded.
func _chunk_seed(coord: Vector2i, salt: int) -> int:
	var h := coord.x * 374761393 + coord.y * 668265263 + salt * 2147483647
	h = (h ^ (h >> 13)) * 1274126177
	return h ^ (h >> 16)

# ---------------------------------------------------------------------------
# Dressing (kitbashed haunted wood + ruined chapel). Scattered sparsely and
# randomly per chunk -- never enough in one chunk to form a closed loop, so
# the iron fence in particular stays a broken fragment, not a ring.
# ---------------------------------------------------------------------------

func _scatter_chunk_dressing(coord: Vector2i, origin: Vector2) -> Array[Node2D]:
	var props: Array[Node2D] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_seed(coord, 1)

	# The world-origin chunk always carries the bargain shrine landmark, so
	# it's guaranteed visible near the player's starting position.
	if coord == Vector2i.ZERO:
		props.append(_spawn_prop(PROP_BARGAIN_SHRINE, Vector2(140, 90)))

	for i in rng.randi_range(2, 5):
		props.append(_spawn_prop(PROP_DEAD_TREE, _random_point_in_chunk(rng, origin)))

	if rng.randf() < 0.35:
		props.append(_spawn_prop(PROP_CHAPEL_RUIN, _random_point_in_chunk(rng, origin)))

	if rng.randf() < 0.3:
		props.append(_spawn_prop(PROP_CANDLE_CLUSTER, _random_point_in_chunk(rng, origin)))

	if rng.randf() < 0.25:
		props.append(_spawn_prop(PROP_IRON_FENCE, _random_point_in_chunk(rng, origin)))

	return props

func _random_point_in_chunk(rng: RandomNumberGenerator, origin: Vector2) -> Vector2:
	var margin := TILE_SIZE * 2.0
	return origin + Vector2(
		rng.randf_range(margin, CHUNK_PIXELS - margin),
		rng.randf_range(margin, CHUNK_PIXELS - margin)
	)

func _spawn_prop(scene: PackedScene, pos: Vector2) -> Node2D:
	var instance := scene.instantiate()
	ysort.add_child(instance)
	instance.global_position = pos
	return instance

# ---------------------------------------------------------------------------
# Player + camera
# ---------------------------------------------------------------------------

func _spawn_player(spawn_pos: Vector2) -> void:
	player = PLAYER_SCENE.instantiate() as Player
	ysort.add_child(player)
	player.global_position = spawn_pos
	# No bounds are set on the player/camera: the roam is endless and keeps
	# streaming chunks in every direction, so there is no wall to clamp to.

# ---------------------------------------------------------------------------
# Enemy waves (still fully procedural: random angle/distance around the
# player, no map-bounds clamp needed since the roam has no edge)
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
	return player.global_position + Vector2(cos(angle), sin(angle)) * dist
