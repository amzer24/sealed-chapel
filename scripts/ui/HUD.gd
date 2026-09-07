extends CanvasLayer

## Diegetic HUD: a carved health bar, curse (XP) bar, level rune and a
## countdown to dawn. No default Godot progress bars/panels are used; the
## bars are hand-driven ColorRects sized via anchors. The level and
## countdown labels use the studio-locked `Copy.HUD_LEVEL` /
## `Copy.HUD_TIMER` format strings.

@onready var root: Control = $Root
@onready var health_fill: ColorRect = $Root/TopBar/HBox/VitalsBox/HealthFrame/HealthFill
@onready var level_label: Label = $Root/TopBar/HBox/VitalsBox/LevelLabel
@onready var timer_label: Label = $Root/TopBar/HBox/TimerLabel
@onready var xp_fill: ColorRect = $Root/BottomBar/XPFrame/XPFill

func _ready() -> void:
	root.theme = UITheme.theme
	Game.health_changed.connect(_on_health_changed)
	Game.xp_changed.connect(_on_xp_changed)
	Game.timer_changed.connect(_on_timer_changed)
	_on_xp_changed(Game.xp, Game.xp_to_next, Game.level)
	_on_timer_changed(Game.elapsed, Game.CLEAR_TIME)

func _on_health_changed(current: float, max_health: float) -> void:
	var ratio := 0.0 if max_health <= 0.0 else clampf(current / max_health, 0.0, 1.0)
	health_fill.anchor_right = ratio

func _on_xp_changed(current: float, needed: float, level: int) -> void:
	var ratio := 0.0 if needed <= 0.0 else clampf(current / needed, 0.0, 1.0)
	xp_fill.anchor_right = ratio
	level_label.text = Copy.HUD_LEVEL % level

func _on_timer_changed(_elapsed: float, remaining: float) -> void:
	var total := int(ceil(remaining))
	var minutes := total / 60
	var seconds := total % 60
	timer_label.text = Copy.HUD_TIMER % [minutes, seconds]
