group_uniforms Wind;

// How much the grass will stretch every sway
uniform vec3 wind_direction = vec3(0.1, 0.1, 0.1);

// Aggressiveness of the grass movement.
// Animate by constantly incrementing.
// End the animation in any multiple of a full period (2*PI).
uniform vec3 sway_frequency_animatable = vec3(0);

// Aggressiveness of the grass movement.
// Trying to animate this property will result in skipping or clipping frames
uniform float sway_frequency_base:hint_range(0.0, 10.0, 0.1) = 2.0;


vec3 global_to_local(vec3 vector, mat4 model_matrix){
	return (vec4(vector, 0.0) * model_matrix).xyz;
}

vec3 wind_vertex_animation(vec3 vertex, mat4 model_matrix, float time, vec3 node_pos_world){
	// Avoids stretching
	float root = clamp(vertex.y, 0.0, 1.0);

	// The old classic sine(t*w + f), where..
	// [time] - Scalar. Loops the output over time.
	// [sway_frequency_base] - Scalar. Oscilation speed.
	// [sway_frequency_animatable] - Vector3. Directional oscilation speed based on time
	// [root] - Scalar. Adds smooth bending along Y axys
	// [node_pos_world] - Vector3. World-space-aware variations
	vec3 phase_offset = sway_frequency_animatable + root + node_pos_world;
	vec3 wave = sin(time * sway_frequency_base + phase_offset);

	// Offset oscilations in wind_direction
	vec3 sway = (wave + 1.0) * wind_direction * root;

	// Converts to per-instance movement
	vertex += global_to_local(sway, model_matrix);
	return vertex;
}
