shader_type spatial;
render_mode unshaded,shadows_disabled,ambient_light_disabled;

uniform sampler2D terrain_color:source_color, repeat_disable;
uniform sampler2D terrain_height:repeat_disable, hint_default_black;

group_uniforms BrushOverlay;
uniform sampler2D brush_texture:repeat_disable;
uniform vec2 brush_position;
uniform float brush_scale:hint_range(0.0, 1.0);
uniform vec4 brush_color:source_color;
group_uniforms;


vec2 scale_from_center(vec2 uv, float s){
	return ((uv - 0.5)/s) + 0.5;
}

vec3 draw_brush(vec2 uv, vec3 surface){
	vec2 uv_transformed_outer_line = scale_from_center( uv - brush_position, brush_scale+0.02 );
	vec4 brush_pixel_outer_line = texture( brush_texture, uv_transformed_outer_line );
	
	vec2 uv_transformed = scale_from_center( uv - brush_position, brush_scale );
	vec4 brush_pixel = texture( brush_texture, uv_transformed );
	
	// Brush with black ring
	vec3 brush = brush_color.rgb*brush_pixel.rgb*0.8 + 0.05*sin(TIME*4.0) + 0.15;
	
	// Alpha blend
	return mix(surface, brush, brush_pixel_outer_line.a);
}

void fragment(){
	vec3 base = texture(terrain_color, UV).rgb;
	ALBEDO = draw_brush(UV, base);
}

void vertex(){
	VERTEX.y = texture(terrain_height, UV).r;
}