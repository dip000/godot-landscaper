// Basic Terrain Shader with vertex coloring.
// A demonstration of a shader that uses vertex colors instead of textures.
// Used by default with GLTerrainVertexColor effect

shader_type spatial;
render_mode unshaded;


void fragment() {
	// A bit funny that there's so much more explaining that actual code.
	// Anyway, the colors are already baked into the COLOR thanks to Mesh.ARRAY_COLOR
	ALBEDO = COLOR.rgb;
}
