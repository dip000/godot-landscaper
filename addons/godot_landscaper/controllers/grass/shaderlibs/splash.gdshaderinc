const int SLOTS = 16;

group_uniforms Color;
uniform sampler2DArray texture_array;
uniform vec4 detail_color[SLOTS]:source_color;
uniform float splash_height:hint_range(-1.0, 1.0, 0.05) = 0.0;


// Selector of texture_array textures. Set to -1 to disable
// Set from instance_shader_parameters/texture_layer
instance uniform int texture_layer;


vec3 _gamma_corrected(vec3 srgb) {
	if(OUTPUT_IS_SRGB) return srgb; //Compatibility uses sRGB by default
	else return pow(srgb, vec3(2.2)); //Converts to lineal-space
}

vec3 splash_vertex_color(vec3 color_bottom, vec3 recolor_top, vec3 vertex){
	color_bottom = _gamma_corrected(color_bottom);
	
	// Cheap gradient
	float mask = clamp(vertex.y + splash_height, 0.0, 1.0);

	// Mask the top of the grass with one color, mask the root with another
	return mix(color_bottom, recolor_top, mask);
}

vec4 splash_fragment_color(vec4 color, vec2 uv){
	// If texturing is disabled
	if(texture_layer < 0){
		return vec4(color.rgb, 1.0);
	}
	
	// Uses layer as the array index.
	// Web exports have limited arrays of textures.
	// sampler2DArray is more performant and dynamic.
	vec4 mask = texture(texture_array, vec3(uv, float(texture_layer)));
	vec4 detail = detail_color[texture_layer];
	vec4 result;
	
	// Encoding details in transparency is easier than an array of enables and has the same cost
	// Apply details
	if(detail.a > 0.0){
		result.rgb = mix(detail.rgb, color.rgb, mask.r);
	}
	else{
		// Apply vertex color (with alpha below)
		result.rgb = color.rgb;
	}
	
	// Texture format is RedGreen where red is black and white and green is alpha encoded.
	// LA8 is more ambiguous than RedGreen, so RedGreen is the safer choice.
	result.a = mask.g;
	return result;
}
