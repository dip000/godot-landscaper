shader_type spatial;
render_mode unshaded, depth_draw_opaque;

uniform float cell_size: hint_range(0.1, 100.0) = 1.0;
uniform float line_width = 1.0;

uniform vec4 grid_color: source_color = vec4(0.859, 0.439, 0.576, 1.0);
varying vec3 world_position;

uniform vec3 mask_center = vec3(0.0, 0.0, 0.0);
uniform float mask_radius = 1.0;
uniform float mask_softness = 10.0;


void vertex()
{
	world_position = VERTEX;
}

void fragment() {
	vec2 uv = world_position.xz / cell_size;
	vec2 d = abs(fract(uv - 0.5) - 0.5) / fwidth(uv);
	float grid = 1.0 - smoothstep(0.0, line_width, min(d.x, d.y));

	// Single tracking mask
	float dist = distance(world_position.xz, mask_center.xz);
	float mask = 1.0 - smoothstep(
		mask_radius,
		mask_radius + mask_softness,
		dist
	);

	ALBEDO = grid_color.rgb;
	ALPHA  = grid * mask * grid_color.a;
}
