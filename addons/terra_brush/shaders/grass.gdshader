shader_type spatial;
render_mode unshaded, shadows_disabled;

const int TOTAL_GRASS_VARIANTS = 4;

uniform bool bilboard_y;
uniform bool enable_margin;
uniform vec3 color_margin:source_color;
uniform vec2 terrain_size;

// Colors of all of the grass instanced from a MultiMesh as seen from the top
uniform sampler2D grass_color:source_color,filter_linear_mipmap,repeat_disable;
uniform sampler2D terrain_color:source_color,filter_linear_mipmap,repeat_disable;

// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform sampler2D mask_front:source_color,filter_linear_mipmap,repeat_disable,hint_default_black;
uniform sampler2D grass_variants[TOTAL_GRASS_VARIANTS];

// Only supported for Mobile and Forward+ renderers
instance uniform int variant_index;



void vertex(){
	// I totally stole this line
	VERTEX.x += sin(NODE_POSITION_WORLD.x + TIME * 1.25 + UV.y) * ( 1.0 - UV.y) * 0.08;
	
	if(bilboard_y){
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0), vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	}
	
	// Vertex to world space (from center of texture)
	vec2 world_position = 0.5 + (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz / terrain_size;
	
	// Coloring the mesh vertices will look exactly the same as coloring the pixels but more performant (asuming there are enough subdivisions along z-axis)
	vec3 recolor_top = texture(grass_color, world_position).rgb;
	vec3 recolor_root = texture(terrain_color, world_position).rgb;
	float gradient_mask = texture(mask_front, UV).r;
	
	// Mask the top of the grass with one color, mask the root with another, and add them
	COLOR.rgb = recolor_top * gradient_mask;
	COLOR.rgb += recolor_root * (1.0-gradient_mask);
}

void fragment() {
	// Apply vertex color to albedo
	ALBEDO = COLOR.rgb;
	
	// The margin will look awfull if you try to vertex-color it, so is better to process it here
	vec4 margin_mask = texture(grass_variants[variant_index], UV);
	if(enable_margin){
		ALBEDO = mix(color_margin, ALBEDO, margin_mask.r);
	}
	
	// TBH, i don't know why alpha must be multiplied or why it needs the threshold without glitching
	ALPHA *= margin_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.8;
}
