@tool
extends Brush
class_name TerrainColor
# Brush that paints the terrain as well as the bottom of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"

@onready var color:CustomColorPicker = $ColorPicker
@onready var resolution:CustomNumberInput = $Resolution


func _ready():
	resolution.on_change.connect( _change_resolution )

func save_ui():
	_raw.tc_texture = _texture
	_raw.tc_resolution = _resolution
	_raw.tc_color = color.value
	_resolution = resolution.value

func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_texture = raw.tc_texture
	super(ui, scene, raw)
	color.value = raw.tc_color
	out_color = raw.tc_color
	_resolution = raw.tc_resolution
	_change_resolution( _resolution )
	resolution.value = _resolution


func paint(pos:Vector3, primary_action:bool):
	out_color = color.value if primary_action else Color(color.value, 0.1)
	_bake_out_color_into_texture( pos )
	rebuild_terrain()


func rebuild_terrain():
	_update_grass_shader("terrain_color", _texture)
	_scene.terrain.material_override.albedo_texture = _texture

# Fill with the current terrain color
func resize_texture(rect:Rect2i, _fill_color:Color):
	super(rect, color.value)


