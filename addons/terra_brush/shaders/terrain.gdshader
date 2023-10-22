shader_type spatial;
render_mode unshaded,shadows_disabled,ambient_light_disabled;
#include "res://addons/terra_brush/shaders/brush_overlay.gdshaderinc"

uniform sampler2D terrain_color:source_color, repeat_disable;
uniform sampler2D terrain_height:repeat_disable, hint_default_black;


void fragment(){
	vec3 base = texture(terrain_color, UV).rgb;
	ALBEDO = draw_brush(UV, base);
}

void vertex(){
	VERTEX.y = texture(terrain_height, UV).r;
}