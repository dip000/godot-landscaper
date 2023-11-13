@tool
extends Brush
class_name TerrainColor
# Brush that paints the terrain as well as the bottom of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"

@onready var color:CustomColorPicker = $ColorPicker



func save_ui():
	_raw.tc_texture = _texture
	_raw.tc_resolution = _resolution
	_raw.tc_color = color.value
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_ui = ui
	_scene = scene
	_raw = raw
	_texture = raw.tc_texture
	_resolution = _raw.tc_resolution
	color.value = raw.tc_color
	out_color = raw.tc_color
	_preview_texture()

func template(_size:Vector2i, raw:RawLandscaper):
	raw.tc_resolution = 10
	raw.tc_color = Color.SEA_GREEN
	raw.tc_texture = _create_texture( Color.SEA_GREEN, _size*raw.tc_resolution, Image.FORMAT_RGBA8 )

func paint(pos:Vector3, primary_action:bool):
	out_color = color.value if primary_action else Color(color.value, 0.1)
	_bake_out_color_into_texture( pos )
	rebuild_terrain()

func rebuild_terrain():
	_update_grass_shader("terrain_color", _texture)
	_scene.terrain.material_override.albedo_texture = _texture
