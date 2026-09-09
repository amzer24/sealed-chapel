class_name HitFlash
extends Sprite2D

## Reusable hit/hurt flash: a plain, unshaded `Sprite2D` that Tweens its own
## `self_modulate` toward bone and back on `flash()`. Lives as a plain
## sibling added after the outlined `Sprite` (drawn on top of it, same
## local transform) -- this is the node "that should flash", so its own
## `self_modulate` is what the Tween drives, never `modulate` (which would
## also cascade onto any future sibling/child instead of staying scoped to
## this one sprite).
##
## Two things ruled out modulating the existing outlined `Sprite`
## (`Player`/`Crawler`/`Wraith`'s own `Sprite`, carrying
## `cast_outline_material.tres`) directly, found investigating this pass:
##
## 1. That shared shader (`cast_outline.gdshader`) samples `TEXTURE` and
##    assigns `COLOR` straight from it, never reading the incoming vertex
##    `COLOR` that a `modulate`/`self_modulate` multiply is baked into --
##    verified empirically (an offscreen capture with `Sprite.modulate` and
##    `Visual.modulate` both set showed byte-identical pixels to the
##    unmodulated baseline). Out of scope to fix here (no custom
##    canvas_item hit shader, no VERTEX offset, no `set_shader_parameter`
##    on the shared material for this PR).
## 2. Even past that, a plain multiply-modulate can only ever darken this
##    cast's silhouette colours toward black (every locked hex's channels
##    are already <=1.0, and bone's are too, so multiplying by it can only
##    hold or darken a colour, never brighten it toward bone).
##
## So `mirror()` bakes a flat bone-recoloured copy of the target's texture
## once (same alpha shape, solid `Palette.BONE` fill), and `flash()` Tweens
## this sprite's own `self_modulate` alpha up then back down over it --
## bone is already baked into the pixels, so the Tween only needs to
## control how much of it shows through.

const RISE_TIME := 0.04
const FALL_TIME := 0.08

var _tween: Tween

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
	self_modulate = Color(Palette.BONE, 0.0)

func flash() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", 1.0, RISE_TIME)
	_tween.tween_property(self, "self_modulate:a", 0.0, FALL_TIME)
