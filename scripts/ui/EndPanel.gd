extends CanvasLayer

## Themed end-of-run panel for both death and clear states. Replaces the
## default Godot dialog entirely.

@onready var root: Control = $Root
@onready var title_label: Label = $Root/CenterContainer/Panel/Margin/VBox/Title
@onready var sub_label: Label = $Root/CenterContainer/Panel/Margin/VBox/Sub
@onready var again_button: Button = $Root/CenterContainer/Panel/Margin/VBox/AgainButton

func _ready() -> void:
	root.theme = UITheme.theme
	visible = false
	again_button.text = Copy.CTA_AGAIN
	again_button.pressed.connect(_on_again_pressed)
	Game.run_ended.connect(_on_run_ended)

func _on_run_ended(win: bool) -> void:
	if win:
		title_label.text = Copy.CLEAR_TITLE
		title_label.modulate = Palette.CURSE_GOLD
	else:
		title_label.text = Copy.DEATH_TITLE
		title_label.modulate = Palette.DRIED_BLOOD
	sub_label.text = "Curse level %d reached. %d creatures put down." % [Game.level, Game.enemies_defeated]
	visible = true

func _on_again_pressed() -> void:
	Game.restart()
