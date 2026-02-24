shader_type spatial;

render_mode
cull_disabled, // For rendering all face sides. Remove for billboards
shadows_disabled, // For disabling shadows received. To enable/disable shadows cast use GeometryInstance3D.cast_shadow
unshaded, ambient_light_disabled, // Disables lighting. Enabling lighting requires normals data to visualize shadows correctly
specular_occlusion_disabled, specular_disabled, // For shine effects. Remove if implementing sun glow
depth_prepass_alpha, blend_premul_alpha; // For alpha fixes

#include "uid://c4bpmlymo3m6c" //wind
#include "uid://cy31xxsscj8k8" //splash
#include "uid://b3gsadcnam4l0" //light

void vertex(){
	VERTEX = wind_vertex_animation( VERTEX, MODEL_MATRIX, TIME, NODE_POSITION_WORLD );
	COLOR.rgb = splash_vertex_color( INSTANCE_CUSTOM.rgb, COLOR.rgb, VERTEX );
}

void light(){
    SPECULAR_LIGHT += light_terrain_and_grass(NORMAL, LIGHT, ALBEDO, LIGHT_COLOR, ATTENUATION);
}

void fragment() {
	vec4 result = splash_fragment_color(COLOR, UV);
	ALBEDO = result.rgb;
	ALPHA = result.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
