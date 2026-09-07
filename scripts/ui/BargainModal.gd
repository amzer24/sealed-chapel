extends CanvasLayer

## The level-up bargain: three curse cards centred over a dimmed, paused
## playfield. Picking one applies the upgrade and resumes combat.

const BARGAIN_CARD_SCENE := preload("res://scenes/ui/BargainCard.tscn")

@onready var root: Control = $Root
@onready var title_label: Label = $Root/CenterContainer/Panel/Margin/VBox/Title
@onready var cards_box: HBoxContainer = $Root/CenterContainer/Panel/Margin/VBox/Cards

func _ready() -> void:
	root.theme = UITheme.theme
	title_label.text = Copy.BARGAIN_TITLE
	visible = false
	Game.bargain_offered.connect(_on_bargain_offered)

func _on_bargain_offered(cards: Array) -> void:
	for child in cards_box.get_children():
		child.queue_free()
	for card_data in cards:
		var card := BARGAIN_CARD_SCENE.instantiate()
		cards_box.add_child(card)
		card.setup(card_data)
		card.chosen.connect(_on_card_chosen)
	visible = true

func _on_card_chosen(card_data: Dictionary) -> void:
	visible = false
	Game.choose_bargain(card_data)
