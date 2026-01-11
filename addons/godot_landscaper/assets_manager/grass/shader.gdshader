shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha, blend_premul_alpha;

#include "res://addons/godot_landscaper/shaderlib/wind.gdshaderinc"
#include "res://addons/godot_landscaper/shaderlib/splash.gdshaderinc"
#include "res://addons/godot_landscaper/shaderlib/texture_variants.gdshaderinc"


void vertex(){
	VERTEX = wind_vertex_animation( VERTEX, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = splash_vertex_color( INSTANCE_CUSTOM.rgb, COLOR.rgb, VERTEX );
}

void fragment() {
	// Apply vertex color to albedo
	vec4 color = texture_fragment_color(COLOR.rgb, UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
	ALPHA_SCISSOR_THRESHOLD = 0.1;
}
