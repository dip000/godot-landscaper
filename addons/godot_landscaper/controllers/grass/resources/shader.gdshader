shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha, blend_premul_alpha;

#include "uid://c4bpmlymo3m6c" //wind
#include "uid://cy31xxsscj8k8" //splash

group_uniforms TextureVariants;
uniform sampler2DArray texture_array;
uniform vec4 detail_color[16]:source_color;

// Selector of texture_array textures
// Set from instance_shader_parameters/texture_layer
instance uniform int texture_layer;


void vertex(){
	VERTEX = wind_vertex_animation( VERTEX, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = splash_vertex_color( INSTANCE_CUSTOM.rgb, COLOR.rgb, VERTEX );
}


void fragment() {
	// If texture enabled
	if(texture_layer >= 0){
		// Uses layer as the array index.
		// Web exports have limited arrays of textures.
		// sampler2DArray is more performant and dynamic.
		vec4 mask = texture(texture_array, vec3(UV, float(texture_layer)));
		vec4 detail = detail_color[texture_layer];
		
		// Encoding details in transparency is easier than an array of enables and has the same cost
		// Apply details
		if(detail.a > 0.0){
			ALBEDO = mix(detail.rgb, COLOR.rgb, mask.r);
		}
		else{
			// Apply vertex color (with alpha below)
			ALBEDO = COLOR.rgb;
		}
		
		// Unfortunately, lowering this value will bleed texture mipmaps between layers
		ALPHA_SCISSOR_THRESHOLD = 0.5;
		
		// Texture format is RedGreen where red is black and white and green is alpha encoded.
		// LA8 is more ambiguous than RedGreen, so RedGreen is the safer choice.
		ALPHA = mask.g;
	}
	
	else{
		// Apply raw vertex color.
		ALBEDO = COLOR.rgb;
	}
}
