shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, depth_prepass_alpha;

const int INSTANCES_CAP = 4;


group_uniforms Color;
// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform float splash_height:hint_range(-1.0, 1.0, 0.05) = 0.0;
// Instance variables. Set the index from the MeshInstance3D node
uniform sampler2D grass_textures[INSTANCES_CAP];
uniform bool details_enable[INSTANCES_CAP];
uniform vec3 detail_colors[INSTANCES_CAP]:source_color;
// Selector of textures, details, and detail colors.
// Set from instance_shader_parameters/variant_index
instance uniform int variant_index;


group_uniforms Wind;
// How much the grass will offset the sway strech. Animate along sway_frequency_animatable
uniform vec3 wind_strength;
// How much the grass will stretch every sway
uniform vec3 sway_strength = vec3(0.1, 0.08, 0.15);
// Trying to animate this property will result in skipping or clipping frames
uniform vec3 sway_frequency_base = vec3(1.25, 0.6, 0.45);
// Animate by incrementing constantly. End the animation in multiples of full periods (2*PI) and reset to zero
uniform vec3 sway_frequency_animatable = vec3(0);



vec3 vertex_sway(vec3 vertex, vec2 uv, mat4 model_matrix, float time, vec3 node_pos_world){
	float root = vertex.z;
	vec3 wave = sin(sway_frequency_animatable + node_pos_world + time * sway_frequency_base + vertex.y);
	vec3 sway = wave * sway_strength; // even oscilations
	vec3 result = (wind_strength + sway) * root;

	// Converts sway from global to local transforms
	vertex += (vec4(result, 0.0) * model_matrix).xyz;
	return vertex;
}

vec3 gamma_corrected(vec3 srgb) {
	if(OUTPUT_IS_SRGB) return srgb; //Compatibility uses sRGB by default
	else return pow(srgb, vec3(2.2)); //Converts to lineal-space
}

vec3 vertex_color(vec3 color_bottom, vec3 recolor_top, vec3 vertex){
	color_bottom = gamma_corrected(color_bottom);
	float mask = clamp(vertex.z + splash_height, 0.0, 1.0);

	// Mask the top of the grass with one color, mask the root with another, and add them
	vec3 color = color_bottom * mask;
	color += recolor_top * (1.0-mask);
	return color;
}

void vertex(){
	VERTEX = vertex_sway( VERTEX, UV, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = vertex_color( COLOR.rgb, INSTANCE_CUSTOM.rgb, VERTEX );
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
