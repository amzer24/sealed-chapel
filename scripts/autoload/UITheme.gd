extends Node

## Autoload singleton "UITheme".
##
## Builds one shared Theme resource in code so every HUD/modal Control uses
## carved-stone / curse-gold styling instead of the default Godot theme.
## Assign `UITheme.theme` to the root Control of any UI scene in `_ready()`.

var theme: Theme

func _ready() -> void:
	theme = _build_theme()

func _build_theme() -> Theme:
	var t := Theme.new()

	var panel_style := _stylebox(Color(Palette.SOOT, 0.90), Palette.CURSE_GOLD, 2, 3)
	panel_style.content_margin_left = 18
	panel_style.content_margin_right = 18
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	t.set_stylebox("panel", "Panel", panel_style)

	var btn_normal := _stylebox(Palette.BRUISE_PURPLE_DARK, Palette.DRIED_BLOOD, 2, 3)
	btn_normal.content_margin_left = 14
	btn_normal.content_margin_right = 14
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10

	var btn_hover := _stylebox(Palette.BRUISE_PURPLE, Palette.CURSE_GOLD, 2, 3)
	btn_hover.content_margin_left = 14
	btn_hover.content_margin_right = 14
	btn_hover.content_margin_top = 10
	btn_hover.content_margin_bottom = 10

	var btn_pressed := _stylebox(Palette.SOOT_DARK, Palette.CURSE_GOLD, 2, 3)
	btn_pressed.content_margin_left = 14
	btn_pressed.content_margin_right = 14
	btn_pressed.content_margin_top = 10
	btn_pressed.content_margin_bottom = 10

	var btn_focus := _stylebox(Color(0, 0, 0, 0), Palette.CURSE_GOLD, 2, 3)

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("focus", "Button", btn_focus)
	t.set_color("font_color", "Button", Palette.BONE)
	t.set_color("font_hover_color", "Button", Palette.CURSE_GOLD)
	t.set_color("font_pressed_color", "Button", Palette.CURSE_GOLD)
	t.set_color("font_focus_color", "Button", Palette.CURSE_GOLD)
	t.set_font_size("font_size", "Button", 16)

	t.set_color("font_color", "Label", Palette.BONE)
	t.set_font_size("font_size", "Label", 16)

	var empty := StyleBoxEmpty.new()
	t.set_stylebox("panel", "PanelContainer", panel_style)
	t.set_stylebox("panel", "MarginContainer", empty)

	return t

func _stylebox(bg: Color, border: Color, border_width: int, corner: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(corner)
	return s
