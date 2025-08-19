group_uniforms Sway;
uniform vec3 sway_frequency = vec3(1.25, 0.6, 0.45);
uniform vec3 sway_strength = vec3(0.1, 0.08, 0.15);
uniform vec3 local_wind_modifier = vec3(1.0);

instance uniform vec3 extra_wind_frequency;

#include "include_common.gdshaderinc"


vec3 vertex_sway(vec3 vertex, vec2 uv, mat4 model_matrix, float time, vec3 node_pos_world){
	float root = vertex.y * (1.0-uv.y);
	vec3 wave = sin(node_pos_world + time * (sway_frequency+extra_wind_frequency) + vertex.y);
	vec3 sway = wave * sway_strength; // even oscilations
	vec3 wind = (wave*0.5 + 0.5) * wind_direction * local_wind_modifier; // 50% offseted oscilations in wind_direction
	vec3 result = (sway + wind) * root;
	
	// Converts sway from global to local transforms
	vertex += (vec4(result, 0.0) * model_matrix).xyz;
	return vertex;
}

