shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform sampler2D albedo:hint_default_white;


void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}
