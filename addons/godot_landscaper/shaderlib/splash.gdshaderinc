const int SLOTS = 16;

group_uniforms Splash;
// This must be in gray scale. Usually a GradientTexture2D but can be anything you want, even empty for plain color
uniform float splash_height:hint_range(-1.0, 1.0, 0.05) = 0.0;

#include "common.gdshaderinc"


vec3 gamma_corrected(vec3 srgb) {
	if(OUTPUT_IS_SRGB) return srgb; //Compatibility uses sRGB by default
	else return pow(srgb, vec3(2.2)); //Converts to lineal-space
}

vec3 vertex_splash_color(vec3 color_bottom, vec3 recolor_top, vec3 vertex){
	color_bottom = gamma_corrected(color_bottom);
	float mask = clamp(vertex.y + splash_height, 0.0, 1.0);

	// Mask the top of the grass with one color, mask the root with another, and add them
	vec3 color = recolor_top * mask;
	color += color_bottom * (1.0-mask);
	return color;
}
