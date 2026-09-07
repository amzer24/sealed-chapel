extends CanvasLayer

## Diegetic HUD: a carved health bar, curse (XP) bar, level rune and a
## countdown to dawn. No default Godot progress bars/panels are used; the
## bars are hand-driven ColorRects sized via anchors.
##
## The level and countdown labels are muted (left blank) for now: "Curse
## Lv. %d" and "%d:%02d till dawn" were invented HUD copy, not studio-locked
## strings. They stay wired to their signals so the moment Verse locks
## Grimm replacements, only the format strings below need to change.

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

func _on_xp_changed(current: float, needed: float, _level: int) -> void:
	var ratio := 0.0 if needed <= 0.0 else clampf(current / needed, 0.0, 1.0)
	xp_fill.anchor_right = ratio
	# Muted: no studio-locked "Curse Lv. %d" copy yet.
	level_label.text = ""

func _on_timer_changed(_elapsed: float, _remaining: float) -> void:
	# Muted: no studio-locked "%d:%02d till dawn" copy yet.
	timer_label.text = ""
