@tool
extends Brush
class_name GrassColor
# Brush that paints the top of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"

@onready var color:CustomColorPicker = $ColorPicker


func save_ui():
	_raw.gc_texture = _texture
	_raw.gc_resolution = _resolution
	_raw.gc_color = color.value

func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	super(ui, scene, raw)
	_texture = _raw.gc_texture
	_resolution = _raw.gc_resolution
	color.value = raw.gc_color
	out_color = raw.gc_color
	_preview_texture()
	_update_grass_shader("grass_color", _texture)


func paint(pos:Vector3, primary_action:bool):
	# Paint alpha with secondary to smooth the texture
	out_color = color.value if primary_action else Color(color.value, 0.1)
	_bake_out_color_into_texture(pos)
	rebuild_terrain()

