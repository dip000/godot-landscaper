const int SLOTS = 16;

group_uniforms Splash;
uniform float splash_height:hint_range(-1.0, 1.0, 0.05) = 0.0;

#include "include_common.gdshaderinc"


vec3 gamma_corrected(vec3 srgb) {
	if(OUTPUT_IS_SRGB) return srgb; //Compatibility uses sRGB by default
	else return pow(srgb, vec3(2.2)); //Converts to lineal-space
}

vec4 vertex_splash_color(vec4 base_color, vec3 instance_custom, vec3 vertex, vec2 uv){
	// Coloring the mesh vertices will look exactly the same as coloring the pixels but more performant (asuming there are enough subdivisions along z-axis)
	vec3 recolor_root = gamma_corrected(base_color.rgb); // Comes from MultiMesh.set_instance_color()
	vec3 recolor_top = instance_custom.rgb; // Comes from MultiMesh.set_instance_custom_data()
	float mask = clamp(uv.y + splash_height, 0.0, 1.0);
	
	// Mask the top of the grass with one color, mask the root with another, and add them
	vec3 color = recolor_root * (1.0-mask) + recolor_top * mask;
	return vec4(color, 0.0);
}
