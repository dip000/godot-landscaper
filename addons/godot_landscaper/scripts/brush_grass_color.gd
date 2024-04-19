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
	_texture = raw.gc_texture
	super(ui, scene, raw)
	_resolution = raw.gc_resolution
	color.value = raw.gc_color
	out_color = raw.gc_color
	_update_grass_shader("grass_color", _texture)
	_update_grass_shader("world_position", _get_offset_texture())
	_update_grass_shader("world_size", _raw.world.size)
	print("world_size changed: ", _raw.world.size)

func paint(pos:Vector3, primary_action:bool):
	# Paint alpha with secondary to smooth the texture
	out_color = color.value if primary_action else Color(color.value, 0.1)
	_bake_out_color_into_texture(pos)

# Let grass shader know the new properties
# Fill with the current grass color
func resize_texture(rect:Rect2i, fill_color:Color):
	super(rect, color.value)
	_update_grass_shader("world_position", _get_offset_texture())
	_update_grass_shader("world_size", _raw.world.size)
	print("world_size changed: ", _raw.world.size)

func _get_offset_texture() -> Vector2:
	return float(-_resolution) * _raw.world.position / Vector2(img.get_size())
