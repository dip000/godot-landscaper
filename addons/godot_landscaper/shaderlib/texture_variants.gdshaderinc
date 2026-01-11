group_uniforms TextureVariants;
uniform sampler2DArray texture_array;
uniform vec4 detail_color[16]:source_color;

// Selector of textures, details, and detail colors.
// Set from instance_shader_parameters/texture_layer
instance uniform int texture_layer;


int _get_bit(int mask, int layer){
	return (mask & (1 << layer));
}


vec4 texture_fragment_color(vec3 albedo, vec2 uv) {
	if(texture_layer < 0){
		return vec4(albedo, 1.0);
	}
	//uv = clamp(uv, vec2(0.1), vec2(0.9));
	vec4 mask = texture(texture_array, vec3(uv, float(texture_layer)));
	vec4 detail = detail_color[texture_layer];
	if(detail.a > 0.0){
		albedo = mix(detail.rgb, albedo, mask.r);
	}

	return vec4(albedo, mask.g);
}
