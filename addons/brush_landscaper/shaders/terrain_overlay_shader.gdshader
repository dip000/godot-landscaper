shader_type spatial;
render_mode unshaded,shadows_disabled,ambient_light_disabled;

group_uniforms BrushOverlay;
uniform sampler2D brush_texture:repeat_disable;
uniform vec2 brush_position = vec2(2.0);
uniform float brush_scale = 0.005;
uniform vec4 brush_color:source_color;
group_uniforms;


vec2 scale_from_center(vec2 uv, float s){
	return (uv-0.5)/s + 0.5;
}

void fragment(){
	vec2 uv_transformed_outer_line = scale_from_center( UV - brush_position, brush_scale+0.001 );
	vec4 brush_pixel_outer_line = texture( brush_texture, uv_transformed_outer_line );
	
	vec2 uv_transformed = scale_from_center( UV - brush_position, brush_scale );
	vec4 brush_pixel = texture( brush_texture, uv_transformed );
	
	// Blinking brush color
	vec3 brush = brush_color.rgb*brush_pixel.rgb*0.8 + 0.05*sin(TIME*4.0) + 0.15;
	
	// Black ring
	ALPHA = brush_pixel_outer_line.r * 0.8 * clamp(brush_color.a, 0.5, 0.9);
	ALBEDO = brush;
//	ALBEDO = vec3(0.8);
}
