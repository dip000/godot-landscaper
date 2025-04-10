shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, vertex_lighting;

const int TOTAL_GRASS_VARIANTS = 16;

uniform vec3 wind_vector = vec3(0.0);

// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform sampler2D gradient_mask:source_color,filter_linear_mipmap,repeat_disable,hint_default_black;
uniform sampler2D variants[TOTAL_GRASS_VARIANTS];

uniform bool enable_details[TOTAL_GRASS_VARIANTS];
uniform vec3 detail_color[TOTAL_GRASS_VARIANTS]:source_color;

instance uniform int variant_index;

vec3 gamma_corrected(vec3 srgb) {
	if(OUTPUT_IS_SRGB) return srgb; //Compatibility uses sRGB by default 
	else return pow(srgb, vec3(2.2)); //Converts to lineal-space
}

void vertex(){
	// Wind sway
	float root = (1.0 - UV.y);
	vec3 sway = vec3(0.15, 0.08, 0.15);
	vec3 dir = NODE_POSITION_WORLD + TIME;
	sway.x *= sin(dir.y);
	sway.y *= sin(dir.x);
	sway.z *= cos(dir.z);
	sway = (sway + wind_vector) * root;
	VERTEX += (vec4(sway, 1.0) * MODEL_MATRIX).xyz;
	
	// Coloring the mesh vertices will look exactly the same as coloring the pixels but more performant (asuming there are enough subdivisions along z-axis)
	vec3 recolor_root = gamma_corrected(COLOR.rgb); // Comes from MultiMesh.set_instance_color()
	vec3 recolor_top = INSTANCE_CUSTOM.rgb; // Comes from MultiMesh.set_instance_custom_data()
	float mask = texture(gradient_mask, UV).r;
	
	// Mask the top of the grass with one color, mask the root with another, and add them
	COLOR.rgb = recolor_top * mask;
	COLOR.rgb += recolor_root * (1.0-mask);
}

void fragment() {
	// Apply vertex color to albedo
	ALBEDO = COLOR.rgb;
	// The margin will look awfull if you try to vertex-color it, so is better to process it here
	vec4 detail_mask = texture(variants[variant_index], UV);
	
	if(enable_details[variant_index]){
		ALBEDO = mix(detail_color[variant_index], ALBEDO, detail_mask.r);
	}
	
	// Enables alpha scissor
	ALPHA = detail_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
