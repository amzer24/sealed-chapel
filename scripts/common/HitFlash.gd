class_name HitFlash
extends Sprite2D

## Reusable hit/hurt flash: a plain, unshaded `Sprite2D` that briefly pulses
## a flat bone silhouette of a target sprite over it on `flash()`, fading
## back to fully transparent.
##
## This does NOT modulate the outlined sprite (`Player`/`Crawler`/`Wraith`'s
## own `Sprite`, which carries `cast_outline_material.tres`) directly, for
## two reasons found investigating this pass:
##
## 1. That shared shader (`cast_outline.gdshader`) samples `TEXTURE` and
##    assigns `COLOR` straight from it, never reading the incoming vertex
##    `COLOR` that a `modulate`/`self_modulate` multiply is baked into --
##    verified empirically (an offscreen capture with `Sprite.modulate` and
##    `Visual.modulate` both set showed byte-identical pixels to the
##    unmodulated baseline).
## 2. Even past that, a plain multiply-modulate can only ever darken this
##    cast's silhouette colours (every locked hex's channels are below
##    bone's), never pulse them "toward bone" -- multiplying by a colour
##    whose channels are all <=1.0 cannot brighten.
##
## So `mirror()` bakes a flat bone-recoloured copy of the target's texture
## once (same alpha shape, solid `Palette.BONE` fill) and this sprite lives
## as a plain sibling added after the outlined `Sprite` (drawn on top of
## it, same local transform), pulsing only its own alpha.

const FLASH_DURATION := 0.12

var _time_left := 0.0

func mirror(target: Sprite2D) -> void:
	var source_image := target.texture.get_image()
	if source_image.is_compressed():
		source_image.decompress()
	var flash_image := Image.create(source_image.get_width(), source_image.get_height(), false, source_image.get_format())
	for x in source_image.get_width():
		for y in source_image.get_height():
			var alpha := source_image.get_pixel(x, y).a
			flash_image.set_pixel(x, y, Color(Palette.BONE, alpha))
	texture = ImageTexture.create_from_image(flash_image)
	texture_filter = target.texture_filter
	centered = target.centered
	offset = target.offset
	modulate.a = 0.0

func flash() -> void:
	_time_left = FLASH_DURATION
	modulate.a = 1.0

func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left = maxf(0.0, _time_left - delta)
	modulate.a = _time_left / FLASH_DURATION
