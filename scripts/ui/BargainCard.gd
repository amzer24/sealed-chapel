extends Button

## A single curse-bargain choice. The whole card is one Button so the player
## can click/tap anywhere on it to choose that upgrade.

signal chosen(card_data: Dictionary)

@onready var icon_rect: ColorRect = $Margin/VBox/Icon
@onready var title_label: Label = $Margin/VBox/Title
@onready var desc_label: Label = $Margin/VBox/Desc

var card_data: Dictionary

func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(card_data))

func setup(data: Dictionary) -> void:
	card_data = data
	title_label.text = data.name
	desc_label.text = data.desc
	icon_rect.color = _icon_color_for(data.stat)

func _icon_color_for(stat: String) -> Color:
	match stat:
		"damage", "attack_range":
			return Palette.DRIED_BLOOD
		"move_speed":
			return Palette.BONE
		"attack_speed", "pickup_radius":
			return Palette.CURSE_GOLD
		"max_health":
			return Palette.BRUISE_PURPLE
		_:
			return Palette.BONE
