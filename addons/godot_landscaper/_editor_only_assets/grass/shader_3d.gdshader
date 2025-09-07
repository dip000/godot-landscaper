shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha;

#include "res://addons/godot_landscaper/shaderlib/sway.gdshaderinc"
#include "res://addons/godot_landscaper/shaderlib/splash.gdshaderinc"


void vertex(){
	VERTEX = vertex_sway( VERTEX, UV, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = vertex_splash_color( COLOR.rgb, INSTANCE_CUSTOM.rgb, VERTEX );
}

void fragment() {
	// Apply vertex color to albedo
	ALBEDO = COLOR.rgb;
}
