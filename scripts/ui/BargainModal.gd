extends CanvasLayer

## The level-up bargain: up to three stackable cards centred over a dimmed,
## paused playfield. There is no modal headline -- each card carries its
## own locked one-liner, so that is the only bargain copy shown while cards
## are up. Striking a bargain plays a brief pick-juice flash + floating
## tick text (the card's own "tick" field, `Copy.TICK_*`) over the
## just-resumed playfield, then the layer goes fully invisible again.
##
## The seven-card pool never runs dry (every id is stackable, see
## `Game._build_offer`), so `Copy.BARGAIN_EMPTY` only remains as a
## defensive fallback for the case `Game.bargain_offered` somehow emits
## zero cards.

const BARGAIN_CARD_SCENE := preload("res://scenes/ui/BargainCard.tscn")
const EMPTY_DISMISS_DELAY := 1.6

## Pick-juice timing: the flash pops in fast and fades quickly; the tick
## label rises steadily for its whole `TICK_LIFETIME` while fading out only
## over the back half of it (`TICK_FADE_DELAY` in), so it reads instantly
## but doesn't loiter.
const FLASH_PEAK_TIME := 0.05
const FLASH_FADE_TIME := 0.35
const TICK_LIFETIME := 0.75
const TICK_FADE_DELAY := 0.3
const TICK_RISE_DISTANCE := 26.0
const FLASH_PEAK_ALPHA := 0.32

@onready var root: Control = $Root
@onready var title_label: Label = $Root/CenterContainer/Panel/Margin/VBox/Title
@onready var cards_box: HBoxContainer = $Root/CenterContainer/Panel/Margin/VBox/Cards
@onready var empty_timer: Timer = $EmptyTimer
@onready var juice: Control = $Juice
@onready var flash_rect: ColorRect = $Juice/Flash
@onready var tick_label: Label = $Juice/TickLabel

var _tick_base_y: float

func _ready() -> void:
	root.theme = UITheme.theme
	visible = false
	juice.visible = false
	_tick_base_y = tick_label.position.y
	Game.bargain_offered.connect(_on_bargain_offered)
	empty_timer.timeout.connect(_on_empty_timer_timeout)

func _on_bargain_offered(cards: Array) -> void:
	for child in cards_box.get_children():
		child.queue_free()

	if cards.is_empty():
		title_label.text = Copy.BARGAIN_EMPTY
		title_label.visible = true
		cards_box.visible = false
		root.visible = true
		visible = true
		empty_timer.start(EMPTY_DISMISS_DELAY)
		return

	# No modal headline: the cards carry the only bargain copy.
	title_label.text = ""
	title_label.visible = false
	cards_box.visible = true
	for card_data in cards:
		var card := BARGAIN_CARD_SCENE.instantiate()
		cards_box.add_child(card)
		card.setup(card_data)
		card.chosen.connect(_on_card_chosen)
	root.visible = true
	visible = true

func _on_card_chosen(card_data: Dictionary) -> void:
	root.visible = false
	Game.choose_bargain(card_data)
	_play_pick_juice(card_data.get("tick", ""))

## Brief flash + a floating tick label (bone colour, soot outline) over the
## playfield, which has already resumed by the time this plays (`Game.
## choose_bargain` unpauses before this is called). Hides the whole layer
## again once both animations finish.
func _play_pick_juice(tick_text: String) -> void:
	if tick_text.is_empty():
		visible = false
		return

	tick_label.text = tick_text
	tick_label.position.y = _tick_base_y
	tick_label.modulate = Color(Palette.BONE, 1.0)
	flash_rect.color = Color(Palette.BONE, 0.0)
	juice.visible = true
	visible = true

	var flash_tween := create_tween()
	flash_tween.tween_property(flash_rect, "color:a", FLASH_PEAK_ALPHA, FLASH_PEAK_TIME)
	flash_tween.tween_property(flash_rect, "color:a", 0.0, FLASH_FADE_TIME)

	var tick_tween := create_tween()
	tick_tween.tween_property(tick_label, "position:y", _tick_base_y - TICK_RISE_DISTANCE, TICK_LIFETIME)
	tick_tween.parallel().tween_property(tick_label, "modulate:a", 0.0, TICK_LIFETIME - TICK_FADE_DELAY) \
		.set_delay(TICK_FADE_DELAY)
	tick_tween.finished.connect(_on_pick_juice_finished)

func _on_pick_juice_finished() -> void:
	juice.visible = false
	visible = false

func _on_empty_timer_timeout() -> void:
	visible = false
	Game.dismiss_empty_bargain()
