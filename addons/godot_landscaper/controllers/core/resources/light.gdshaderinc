
// Same lighting results smooths the terrain-grass color transition.
// - Terrain requires to have normals.
// - Grass normals should preferibly be customly bent for softer blending.
// TODO: Fix normals still showing harsh lighting.
vec3 light_terrain_and_grass(vec3 normal, vec3 light, vec3 albedo, vec3 light_color, float attenuation){
    float self_shade = max(dot(normal, light), 0.0);
	return albedo * light_color * attenuation * self_shade;
}

