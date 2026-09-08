extends Button

## A single curse-bargain choice. The whole card is one Button so the player
## can click/tap anywhere on it to choose that pact. The card's only text is
## its locked one-liner (e.g. `Copy.LONGER_SHADOW`), used directly as the
## title.

signal chosen(card_data: Dictionary)

@onready var icon_rect: ColorRect = $Margin/VBox/Icon
@onready var title_label: Label = $Margin/VBox/Title

var card_data: Dictionary

func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(card_data))

func setup(data: Dictionary) -> void:
	card_data = data
	title_label.text = data.title
	icon_rect.color = _icon_color_for(data.id)

func _icon_color_for(id: String) -> Color:
	match id:
		"longer_shadow":
			return Palette.CURSE
		"fever_pulse":
			return Palette.ROT
		"tithe_of_flesh":
			return Palette.BRUISE
		_:
			return Palette.BONE
