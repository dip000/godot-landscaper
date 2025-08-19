shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled, ambient_light_disabled, specular_disabled, cull_disabled;

// Internally capped at 16
const int INSTANCES_CAP = 4;

uniform bool enable_details = true;
uniform vec3 detail_color:source_color = vec3(0.2);
uniform vec2 world_size;
uniform vec2 world_position;

// Colors of all of the grass instanced from a MultiMesh as seen from the top
uniform sampler2D grass_color:source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D terrain_color:source_color,filter_linear_mipmap,repeat_disable;

// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform sampler2D gradient_mask:source_color,filter_linear_mipmap,repeat_disable,hint_default_black;
uniform sampler2D variants[INSTANCES_CAP];

instance uniform int variant_index;


void vertex(){
	// Wind sway
	float root = (1.0 - UV.y);
	vec3 sway;
	sway.x = sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * root * 0.10;
	sway.y = sin(NODE_POSITION_WORLD.x + TIME * 0.6 + UV.y) * root * 0.08;
	sway.z = cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * root * 0.15;

	VERTEX += (vec4(sway, 1.0) * MODEL_MATRIX).xyz;
	// Vertex to world space (from center of texture). See [NOTES 1]
	vec2 world_space = world_position + (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz / world_size;
	
	// Coloring the mesh vertices will look exactly the same as coloring the pixels but more performant (asuming there are enough subdivisions along z-axis)
	vec3 recolor_top = texture(grass_color, world_space).rgb;
	vec3 recolor_root = texture(terrain_color, world_space).rgb;
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

	if(enable_details){
		ALBEDO = mix(detail_color, ALBEDO, detail_mask.r);
	}

	// Enables alpha scissor
	ALPHA = detail_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
