group_uniforms Wind;
// How much the grass will offset the sway strech. Animate along sway_frequency_animatable
uniform vec3 wind_strength;
// How much the grass will stretch every sway
uniform vec3 sway_strength = vec3(0.1, 0.08, 0.15);
// Trying to animate this property will result in skipping or clipping frames
uniform vec3 sway_frequency_base = vec3(1.25, 0.6, 0.45);
// Animate by incrementing constantly. End the animation in multiples of full periods (2*PI) and reset to zero
uniform vec3 sway_frequency_animatable = vec3(0);


#include "common.gdshaderinc"


vec3 vertex_sway(vec3 vertex, vec2 uv, mat4 model_matrix, float time, vec3 node_pos_world){
	float root = vertex.y;
	vec3 wave = sin(sway_frequency_animatable + node_pos_world + time * sway_frequency_base + vertex.y);
	vec3 sway = wave * sway_strength; // even oscilations
	vec3 wind = (wave*0.5 + 0.5) * wind_direction; // 50% offseted oscilations in wind_direction
	vec3 result = (sway + wind) * root;

	// Converts sway from global to local transforms
	vertex += (vec4(result, 0.0) * model_matrix).xyz;
	return vertex;
}