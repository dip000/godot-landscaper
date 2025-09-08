shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha;

#include "res://addons/godot_landscaper/shaderlib/sway.gdshaderinc"
#include "res://addons/godot_landscaper/shaderlib/splash.gdshaderinc"

const int INSTANCES_CAP = 4;

// Instance variables. Set the index from the MeshInstance3D node
uniform sampler2D grass_textures[INSTANCES_CAP];
uniform bool details_enable[INSTANCES_CAP];
uniform vec3 detail_colors[INSTANCES_CAP]:source_color;
// Selector of textures, details, and detail colors.
// Set from instance_shader_parameters/variant_index
instance uniform int variant_index;


void vertex(){
	VERTEX = vertex_sway( VERTEX, UV, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = vertex_splash_color( COLOR.rgb, INSTANCE_CUSTOM.rgb, VERTEX );
}

void fragment() {
	// Apply vertex color to albedo
	ALBEDO = COLOR.rgb;

	// Web exports cannot index samplers with variables
	vec4 detail_mask;
	switch(variant_index){
		case 0:
			detail_mask = texture(grass_textures[0], UV);
			break;
		case 1:
			detail_mask = texture(grass_textures[1], UV);
			break;
		case 2:
			detail_mask = texture(grass_textures[2], UV);
			break;
		case 3:
			detail_mask = texture(grass_textures[3], UV);
			break;
	}

	if(details_enable[variant_index]){
		ALBEDO = mix(detail_colors[variant_index], ALBEDO, detail_mask.r);
	}

	// Enables alpha scissor
	ALPHA = detail_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
