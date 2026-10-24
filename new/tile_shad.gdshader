shader_type canvas_item;

uniform sampler2D tile_tex;

void fragment() {
	COLOR=texture(tile_tex,UV);
	//COLOR = vec4(UV.x, UV.y, 0.0, 1.0);
}