// Basic Terrain Shader.
// It is heavily encouraged to use the paint layer mechanics for customization:
//   1. Add a paint layer: GLControllerTerrain > Paint > Layers
//   2. Set 'Material Channel' to match your uniform sampler2D, like "roughness_texture"
//   3. The Landscaper will update that uniform if the layer is active.

shader_type spatial;
render_mode
unshaded, ambient_light_disabled, // Disables lighting. Disabling requires normals data to visualize shadows correctly
shadows_disabled, // For disabling shadows received. To enable/disable shadows cast use GeometryInstance3D.cast_shadow
specular_occlusion_disabled, specular_disabled; // For shine effects. Remove if implementing sun glow

#include "uid://b3gsadcnam4l0" //light

uniform sampler2D terrain_texture;


void fragment() {
	ALBEDO = texture(terrain_texture, UV).rgb;
}


void light(){
    SPECULAR_LIGHT += light_terrain_and_grass(NORMAL, LIGHT, ALBEDO, LIGHT_COLOR, ATTENUATION);
}


