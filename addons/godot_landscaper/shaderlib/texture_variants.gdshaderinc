group_uniforms TextureVariants;
const int CAP = 32; //negligible memory usage
uniform bool enable_textures[CAP];
uniform sampler2DArray grass_texture_array;
uniform bool details_enable[CAP];
uniform vec3 detail_colors[CAP]:source_color;

// Selector of textures, details, and detail colors.
// Set from instance_shader_parameters/variant_index
instance uniform int variant_index;


vec4 fragment_texture_color(vec3 albedo, vec2 uv) {
	if(enable_textures[variant_index] == false){
		return vec4(albedo, 1.0);
	}
	
	vec4 detail_mask = texture(grass_texture_array, vec3(uv, float(variant_index)));
	if(details_enable[variant_index]){
		albedo = mix(detail_colors[variant_index], albedo, detail_mask.r);
	}
	
	return vec4(albedo, detail_mask.a);
}
