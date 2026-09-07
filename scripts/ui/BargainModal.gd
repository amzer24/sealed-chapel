extends CanvasLayer

## The level-up bargain: three curse cards centred over a dimmed, paused
## playfield. Picking one applies the upgrade and resumes combat. Once all
## three studio-locked pacts have been struck, later level-ups instead show
## `Copy.BARGAIN_EMPTY` for a moment before auto-resuming.

const BARGAIN_CARD_SCENE := preload("res://scenes/ui/BargainCard.tscn")
const EMPTY_DISMISS_DELAY := 1.6

@onready var root: Control = $Root
@onready var title_label: Label = $Root/CenterContainer/Panel/Margin/VBox/Title
@onready var cards_box: HBoxContainer = $Root/CenterContainer/Panel/Margin/VBox/Cards
@onready var empty_timer: Timer = $EmptyTimer

func _ready() -> void:
	root.theme = UITheme.theme
	visible = false
	Game.bargain_offered.connect(_on_bargain_offered)
	empty_timer.timeout.connect(_on_empty_timer_timeout)

func _on_bargain_offered(cards: Array) -> void:
	for child in cards_box.get_children():
		child.queue_free()

	if cards.is_empty():
		title_label.text = Copy.BARGAIN_EMPTY
		cards_box.visible = false
		visible = true
		empty_timer.start(EMPTY_DISMISS_DELAY)
		return

	title_label.text = Copy.BARGAIN_TITLE
	cards_box.visible = true
	for card_data in cards:
		var card := BARGAIN_CARD_SCENE.instantiate()
		cards_box.add_child(card)
		card.setup(card_data)
		card.chosen.connect(_on_card_chosen)
	visible = true

func _on_card_chosen(card_data: Dictionary) -> void:
	visible = false
	Game.choose_bargain(card_data)

func _on_empty_timer_timeout() -> void:
	visible = false
	Game.dismiss_empty_bargain()
