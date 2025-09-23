shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha, blend_premul_alpha;

#include "res://addons/godot_landscaper/shaderlib/sway.gdshaderinc"
#include "res://addons/godot_landscaper/shaderlib/splash.gdshaderinc"
#include "res://addons/godot_landscaper/shaderlib/texture_variants.gdshaderinc"


void vertex(){
	VERTEX = vertex_sway( VERTEX, UV, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = vertex_splash_color( COLOR.rgb, INSTANCE_CUSTOM.rgb, VERTEX );
}

void fragment() {
	// Apply vertex color to albedo
	vec4 color = fragment_texture_color(COLOR.rgb, UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
