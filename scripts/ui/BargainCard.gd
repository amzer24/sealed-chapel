extends Button

## A single curse-bargain choice. The whole card is one Button so the player
## can click/tap anywhere on it to choose that pact. The card's only text is
## its locked one-liner (e.g. `Copy.LONGER_SHADOW`), used directly as the
## title. The card frame is a NinePatchRect (bone outline / soot fill /
## bruise thorns, `assets/ui/bargain_card_frame.png`); the Button's own
## theme styles are emptied out in the scene so that art is all that shows.

signal chosen(card_data: Dictionary)

const HOVER_TINT := Color(1.12, 1.12, 1.08)

## Diegetic bargain-card icons (32x32, five-hex palette, hard pixels) keyed
## by `Game.UPGRADE_POOL` card id. Covers every bargain id in the pool, so
## wiring a new pool entry with a matching id picks up its icon
## automatically.
const ICON_PATHS := {
	"longer_shadow": "res://assets/ui/bargain_icons/longer_shadow.png",
	"fever_pulse": "res://assets/ui/bargain_icons/fever_pulse.png",
	"tithe_of_flesh": "res://assets/ui/bargain_icons/tithe_of_flesh.png",
	"bone_ward": "res://assets/ui/bargain_icons/bone_ward.png",
	"greedy_hands": "res://assets/ui/bargain_icons/greedy_hands.png",
	"glass_bell": "res://assets/ui/bargain_icons/glass_bell.png",
	"heavy_hand": "res://assets/ui/bargain_icons/heavy_hand.png",
}

@onready var frame_rect: NinePatchRect = $Frame
@onready var curse_pip: TextureRect = $CursePip
@onready var icon_rect: TextureRect = $Margin/VBox/Icon
@onready var title_label: Label = $Margin/VBox/Title

var card_data: Dictionary

func _ready() -> void:
	pressed.connect(func() -> void: chosen.emit(card_data))
	mouse_entered.connect(func() -> void: frame_rect.modulate = HOVER_TINT)
	mouse_exited.connect(func() -> void: frame_rect.modulate = Color.WHITE)

func setup(data: Dictionary) -> void:
	card_data = data
	title_label.text = data.title
	icon_rect.texture = _icon_texture_for(data.id)
	# The pip flags the card's own gain/cost trade-off (`Game.UPGRADE_POOL`'s
	# "curse" tag), not a decorative accent -- so it lands on whichever
	# cards actually cost `max_health`, not a fixed id list.
	curse_pip.visible = data.get("tag", "") == "curse"

func _icon_texture_for(id: String) -> Texture2D:
	var path: String = ICON_PATHS.get(id, "")
	if path.is_empty():
		return null
	return load(path)
