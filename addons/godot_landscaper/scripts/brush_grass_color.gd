@tool
extends Brush
class_name GrassColor
## Brush that paints the top of the grass when you paint_brushing over the terrain
## Paints different colors over the "texture" depending on "color"

const DESCRIPTION := "Paint with left click, smooth color with right click"
@onready var color:CustomColorPicker = $ColorPicker


func _ready():
	color.on_change.connect( _on_color_changed )

func _on_color_changed(new_color:Color, _enabled:bool):
	_update_overlay_shader("brush_color", new_color)

func selected_brush():
	_update_overlay_shader("brush_color", color.value)

func _on_save_ui():
	_project.gc_texture = texture
	_project.gc_resolution = _resolution
	_project.gc_color = color.value

func _on_load_ui(scene:SceneLandscaper):
	_input_texture( _project.gc_texture )
	_resolution = _project.gc_resolution
	color.value = _project.gc_color
	_scene.update_grass_texture()
	ui.assets_manager.set_unsaved_changes( true ) # Setting internal texture into the shader
	_update_grass_shader("grass_color", texture)
	_update_grass_shader("world_size", _project.world.size as Vector2)

func paint_primary(pos:Vector3):
	_bake_color_into_texture( color.value, pos )
	rebuild()
	ui.assets_manager.set_unsaved_changes( true ) # Modifying internal texture

func paint_secondary(pos:Vector3):
	_bake_color_into_texture( Color(color.value, 0.1), pos )
	rebuild()
	ui.assets_manager.set_unsaved_changes( true ) # Modifying internal texture

func _on_rebuild():
	_update_grass_shader("grass_color", texture)

# Let grass shader know the new properties
# Fill with the current grass color
func resize_texture(rect:Rect2i, fill_color:Color):
	super(rect, color.value)
	_scene.update_grass_texture()
	_update_grass_shader("world_size", _project.world.size as Vector2)
	_update_grass_shader("grass_color", texture)

