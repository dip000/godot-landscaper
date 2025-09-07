group_uniforms Common;

uniform vec3 player_position;

uniform vec3 wind_direction;

uniform vec2 ground_size;
uniform vec2 ground_position;


vec3 get_instance_position(mat4 model_matrix){
	return model_matrix[3].xyz;
}
