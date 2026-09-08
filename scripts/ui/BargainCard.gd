extends Button

## A single curse-bargain choice. The whole card is one Button so the player
## can click/tap anywhere on it to choose that pact. The card's only text is
## its locked one-liner (e.g. `Copy.LONGER_SHADOW`), used directly as the
## title. The card frame is a NinePatchRect (bone outline / soot fill /
## bruise thorns, `assets/ui/bargain_card_frame.png`); the Button's own
## theme styles are emptied out in the scene so that art is all that shows.

signal chosen(card_data: Dictionary)

const HOVER_TINT := Color(1.12, 1.12, 1.08)

@onready var frame_rect: NinePatchRect = $Frame
@onready var curse_pip: TextureRect = $CursePip
@onready var icon_rect: ColorRect = $Margin/VBox/Icon
@onready var title_label: Label = $Margin/VBox/Title

var card_data: Dictionary

func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(card_data))
	mouse_entered.connect(func() -> void: frame_rect.modulate = HOVER_TINT)
	mouse_exited.connect(func() -> void: frame_rect.modulate = Color.WHITE)

func setup(data: Dictionary) -> void:
	card_data = data
	title_label.text = data.title
	var icon_color := _icon_color_for(data.id)
	icon_rect.color = icon_color
	# The curse-gold pip only marks the one bargain whose icon colour is
	# curse-gold, so it stays a highlight rather than a fourth swatch.
	curse_pip.visible = icon_color == Palette.CURSE

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
