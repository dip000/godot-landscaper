// Basic Terrain Shader.
// It is heavily encouraged to use the paint layer mechanics for customization:
//   1. Add a paint layer in GLControllerTerrain > Paint > Layers
//   2. Rename 'GLPaintLayer.material_channel' to match your uniform sampler2D, like "roughness_texture"
//   3. The Landscaper will update that uniform if the layer is active.

shader_type spatial;
render_mode unshaded;

uniform sampler2D terrain_texture;


void fragment() {
	// Simple coloring.
	vec4 terrain = texture(terrain_texture, UV);
	ALBEDO = terrain.rgb;
	
	// Add or replace features with your own setup like roughness, ao, emission, etc..
}
