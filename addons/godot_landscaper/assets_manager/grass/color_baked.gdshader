shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha;

const int INSTANCES_CAP = 4;

uniform vec3 wind_vector = vec3(0.0);

// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform float splash_height:hint_range(-1.0, 1.0, 0.05) = 0.0;

uniform sampler2D grass_textures[INSTANCES_CAP];
uniform bool details_enable[INSTANCES_CAP];
uniform vec3 detail_colors[INSTANCES_CAP]:source_color;

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
	float mask = clamp(UV.y + splash_height, 0.0, 1.0);

	// Mask the top of the grass with one color, mask the root with another, and add them
	COLOR.rgb = recolor_root * mask;
	COLOR.rgb += recolor_top * (1.0-mask);
}

void fragment() {
	// Apply vertex color to albedo
	ALBEDO = COLOR.rgb;

	vec4 detail_mask = texture(grass_textures[variant_index], UV);
	
	if(details_enable[variant_index]){
		ALBEDO = mix(detail_colors[variant_index], ALBEDO, detail_mask.r);
	}
	
	// Enables alpha scissor
	ALPHA = detail_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
