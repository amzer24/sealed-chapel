extends CanvasLayer

## One-shot diegetic card that explains "Curse" (the HUD's level counter)
## before the player's very first run. Shown at most once per save --
## `_has_seen_intro`/`_mark_seen` persist a flag in a small `ConfigFile`
## under `user://`, so every later boot skips straight into the roam.
##
## While showing, this pauses the whole tree exactly the way `BargainModal`
## pauses it mid-run: nothing in `World`/`Game` ticks (waves don't spawn,
## the survive timer doesn't advance) until the player dismisses the card
## with Begin. `process_mode` is `ALWAYS` so this layer's own button still
## works while the tree is paused.

const SAVE_PATH := "user://save.cfg"
const SAVE_SECTION := "progress"
const SAVE_KEY_SEEN := "seen_curse_intro"

@onready var root: Control = $Root
@onready var title_label: Label = $Root/CenterContainer/Frame/Margin/VBox/Title
@onready var body_label: Label = $Root/CenterContainer/Frame/Margin/VBox/Body
@onready var begin_button: Button = $Root/CenterContainer/Frame/Margin/VBox/BeginButton

func _ready() -> void:
	root.theme = UITheme.theme
	title_label.text = Copy.CURSE_INTRO_TITLE
	body_label.text = Copy.CURSE_INTRO_BODY
	begin_button.text = Copy.CURSE_INTRO_CTA
	begin_button.pressed.connect(_on_begin_pressed)

	if _has_seen_intro():
		visible = false
		return

	visible = true
	get_tree().paused = true

func _has_seen_intro() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return config.get_value(SAVE_SECTION, SAVE_KEY_SEEN, false)

func _mark_seen() -> void:
	var config := ConfigFile.new()
	# Load first (a missing/fresh save just fails quietly) so a later
	# save-system pass adding other keys to the same file isn't clobbered.
	config.load(SAVE_PATH)
	config.set_value(SAVE_SECTION, SAVE_KEY_SEEN, true)
	config.save(SAVE_PATH)

func _on_begin_pressed() -> void:
	_mark_seen()
	visible = false
	get_tree().paused = false
