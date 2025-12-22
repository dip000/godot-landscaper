group_uniforms Common;

uniform vec3 player_position;

uniform vec2 ground_size;
uniform vec2 ground_position;


vec3 common_get_instance_position(mat4 model_matrix){
	return model_matrix[3].xyz;
}

vec3 common_global_to_local(vec3 vector, mat4 model_matrix){
	return (vec4(vector, 0.0) * model_matrix).xyz;
}
