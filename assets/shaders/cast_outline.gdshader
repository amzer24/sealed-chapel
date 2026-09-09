shader_type canvas_item;

// 1-texel bone rim outside the cast's silhouette (player/crawler/wraith).
// Only ever paints a fully-transparent texel that touches an opaque one --
// never over existing silhouette pixels, never a partial-alpha blend -- so
// the five-hex sprites keep their hard edges at any zoom. Samples all 8
// neighbours (not just the 4 orthogonal ones) so the rim has no gap at a
// diagonal silhouette corner. Every sample goes through TEXTURE, which
// follows the Sprite2D's own texture_filter (nearest, matching the rest of
// the cast), so there is no blur or soft edge anywhere in the rim.
uniform vec4 outline_color : source_color = vec4(0.909804, 0.862745, 0.784314, 1.0); // Palette.BONE #E8DCC8

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	if (col.a < 0.5) {
		bool touches_silhouette = false;
		for (int dx = -1; dx <= 1; dx++) {
			for (int dy = -1; dy <= 1; dy++) {
				if (dx == 0 && dy == 0) {
					continue;
				}
				vec2 offset = vec2(float(dx), float(dy)) * TEXTURE_PIXEL_SIZE;
				if (texture(TEXTURE, UV + offset).a >= 0.5) {
					touches_silhouette = true;
				}
			}
		}
		if (touches_silhouette) {
			col = vec4(outline_color.rgb, 1.0);
		}
	}
	COLOR = col;
}
