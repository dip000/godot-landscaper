//#define BILLBOARD_Y
#define GL_COMPATIBILITY

/* Ok i know directives are annoying but is absolutely needed to change render mode.
 * And most importantly, for OpenGL compatibility! Otherwise this plugin won't even open
 * if your potato PC doesn't have vulkan drivers, like mine :D
 */

shader_type spatial;
render_mode unshaded, shadows_disabled,
#if defined BILLBOARD_Y
cull_back;
#else
cull_disabled;
#endif


// Internally capped at 16
const int TOTAL_GRASS_VARIANTS = 4;

uniform bool enable_details = true;
uniform vec3 detail_color:source_color = vec3(0.2);
uniform vec2 terrain_size = vec2(10.0);

// Colors of all of the grass instanced from a MultiMesh as seen from the top
uniform sampler2D grass_color:source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D terrain_color:source_color,filter_linear_mipmap,repeat_disable;

// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform sampler2D gradient_mask:source_color,filter_linear_mipmap,repeat_disable,hint_default_black;
uniform sampler2D variants[TOTAL_GRASS_VARIANTS];

// "instance" keyword is only for Vulkan rendering drivers. This avoids compilation errors
#if defined GL_COMPATIBILITY
const int variant_index = 0;
#else
instance uniform int variant_index;
#endif


void vertex(){
	// Wind sway
	float root = (1.0 - UV.y);
	float sway_x = sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * root * 0.10;
	float sway_y = sin(NODE_POSITION_WORLD.x + TIME * 0.6 + UV.y) * root * 0.08;
	float sway_z = cos(NODE_POSITION_WORLD.z + TIME * 0.45 + UV.y) * root * 0.15;
	VERTEX += (vec4(vec3(sway_x, sway_y, sway_z), 1.0) * MODEL_MATRIX).xyz;
	
#if defined BILLBOARD_Y
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
#endif

	// Vertex to world space (from center of texture). See [NOTES 1]
	vec2 world_position = 0.5 + (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz / terrain_size;
	
	// Coloring the mesh vertices will look exactly the same as coloring the pixels but more performant (asuming there are enough subdivisions along z-axis)
	vec3 recolor_top = texture(grass_color, world_position).rgb;
	vec3 recolor_root = texture(terrain_color, world_position).rgb;
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
