shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform sampler2D terrain_texture:hint_default_white;
uniform bool vertex_paint = false;


void fragment() {
	ALBEDO = vertex_paint ? COLOR.rgb : texture(terrain_texture, UV).rgb;
}
