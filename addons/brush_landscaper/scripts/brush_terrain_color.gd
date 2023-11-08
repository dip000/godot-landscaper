@tool
extends Brush
class_name TerrainColor
# Brush that paints the terrain as well as the bottom of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"

@onready var color:CustomColorPicker = $ColorPicker



func pack(raw:ResourceLandscaper):
	raw.tc_texture = _texture
	raw.tc_color = color.value
func unpack(ui:UILandscaper, scene:SceneLandscaper, raw:ResourceLandscaper):
	_texture = raw.tc_texture
	color.value = raw.tc_color
	_preview_texture()
	_ui = ui
	_scene = scene

func template(_size:Vector2i):
	color.value = Color.LIGHT_GREEN
	_create_texture( Color.SEA_GREEN, _size*10, Image.FORMAT_RGBA8 )
	_preview_texture()
	update_texture()

func paint(pos:Vector3, primary_action:bool):
	out_color = color.value if primary_action else Color(color.value, 0.1)
	_bake_out_color_into_texture( pos )
	update_texture()

func update_texture():
	_update_grass_shader("terrain_color", _texture)
	_scene.terrain.material_override.albedo_texture = _texture
