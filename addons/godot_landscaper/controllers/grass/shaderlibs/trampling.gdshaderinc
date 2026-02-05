group_uniforms Trampling;
uniform vec3 player_position;
uniform float character_radius = 3.0;
uniform sampler2D character_distance_falloff_curve : hint_default_black;


// Taken from @gdquest
vec3 vertex_trampling(vec3 vertex, mat4 model_matrix, vec2 uv) {
	float root = (1.0 - uv.y);
	vec3 dir_to_character = player_position - model_matrix[3].xyz;
	float distance_to_character = length(dir_to_character);
	float falloff = 1.0 - smoothstep(0.0, 1.0, distance_to_character/character_radius);

	// Because we operate in vertex space, we need to convert the direction to the character
	// in vertex space. Otherwise, it wouldn't work for rotated blades of grass.
	// comment the next line to observe how the blades are not all facing away from the character.
	dir_to_character = (inverse(model_matrix) * vec4(dir_to_character, 0.0)).xyz;
	dir_to_character = normalize(dir_to_character);

	// sample the curve based on how far we are from the character, in normalized coordinates
	float falloff_curve = texture(character_distance_falloff_curve, vec2(falloff)).x;

	// direction to character is inverted because we want to point away from it
	vertex += normalize(-dir_to_character) * falloff_curve * root;
	return vertex;
}
