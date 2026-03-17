// Basic Terrain Shader.
// It is heavily encouraged to use the paint layer mechanics for customization:
//   1. Open the layers panel: GLControllerTerrain > Paint
//   2. Press [+ Add Layer] and configure it as needed. Match the sampler name to the declare sampler in this shader.
//   3. The Landscaper will update that sampler while the layer is active.

shader_type spatial;
render_mode
unshaded, ambient_light_disabled, // Disables lighting. Disabling requires normals data to visualize shadows correctly
shadows_disabled, // For disabling shadows received. To enable/disable shadows cast use GeometryInstance3D.cast_shadow
specular_occlusion_disabled, specular_disabled; // For shine effects. Remove if implementing sun glow

#include "uid://b3gsadcnam4l0" //light

uniform sampler2D base_tiles;
uniform sampler2D terrain_texture:hint_default_transparent;

varying vec2 world_position;


void vertex(){
	world_position = VERTEX.xz;
}


void fragment() {
	// Small, tiled, consistent, high resolution texture
	vec3 base = texture(base_tiles, world_position * 0.2).rgb;
	
	// Full size, lower resolution details over the tiles (alpha blend)
	vec4 terrain = texture(terrain_texture, UV);
	ALBEDO = mix(base, terrain.rgb, terrain.a);
}


void light(){
    SPECULAR_LIGHT += light_terrain_and_grass(NORMAL, LIGHT, ALBEDO, LIGHT_COLOR, ATTENUATION);
}


