shader_type spatial;
render_mode unshaded,shadows_disabled,ambient_light_disabled;

uniform sampler2D terrain_color:source_color, repeat_disable;
uniform sampler2D terrain_height:repeat_disable, hint_default_black;


void fragment(){
	ALBEDO = texture(terrain_color, UV).rgb;
}

void vertex(){
	VERTEX.y = texture(terrain_height, UV).r;
}