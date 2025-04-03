shader_type spatial;
render_mode unshaded, shadows_disabled, cull_disabled, ambient_light_disabled, diffuse_toon, fog_disabled, specular_disabled, vertex_lighting;

const int TOTAL_GRASS_VARIANTS = 16;

uniform vec3 wind_direction = vec3(0.15, 0.08, 0.1);

// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform sampler2D gradient_mask:source_color,filter_linear_mipmap,repeat_disable,hint_default_black;
uniform sampler2D variants[TOTAL_GRASS_VARIANTS];

instance uniform int variant_index;

void vertex(){
	// Wind sway
	float root = (1.0 - UV.y);
	vec3 sway;
	sway.x = sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * root * wind_direction.x;
	sway.y = sin(NODE_POSITION_WORLD.x + TIME * 0.6 + UV.y) * root * wind_direction.y;
	sway.z = cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * root * wind_direction.z;
	
	VERTEX += (vec4(sway, 1.0) * MODEL_MATRIX).xyz;
	
	// Coloring the mesh vertices will look exactly the same as coloring the pixels but more performant (asuming there are enough subdivisions along z-axis)
	vec3 recolor_root = COLOR.rgb; // Comes from MultiMesh.set_instance_color()
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
	
	// Enables alpha scissor
	ALPHA = detail_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
