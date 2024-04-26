@tool
extends Brush
class_name TerrainColor
## Brush that paints the terrain as well as the bottom of the grass when you paint_brushing over the terrain
## Paints different colors over the "texture" depending on "color"

const DESCRIPTION := "Paint with left click, smooth color with right click"

@onready var color:CustomColorPicker = $ColorPicker
@onready var resolution:CustomNumberInput = $Resolution


func _ready():
	resolution.on_change.connect( _change_resolution )
	color.on_change.connect( _on_color_changed )

func _on_color_changed(new_color:Color, _enabled:bool):
	_update_overlay_shader("brush_color", new_color)

func selected_brush():
	_update_overlay_shader("brush_color", color.value)

func _on_save_ui():
	_project.tc_texture = texture
	_resolution = resolution.value
	_project.tc_color = color.value
	_project.tc_resolution = _resolution

func _on_load_ui(scene:SceneLandscaper):
	_input_texture( _project.tc_texture )
	color.value = _project.tc_color
	_resolution = _project.tc_resolution
	resolution.value = _resolution
	ui.assets_manager.set_unsaved_changes( true ) # Setting internal texture into the shader
	_update_grass_shader("terrain_color", texture)


func paint_primary(pos:Vector3):
	_bake_color_into_texture( color.value, pos )
	rebuild()
	ui.assets_manager.set_unsaved_changes( true ) # Modifying internal texture

func paint_secondary(pos:Vector3):
	# Smooth color
	_bake_color_into_texture( Color(color.value, 0.1), pos )
	rebuild()
	ui.assets_manager.set_unsaved_changes( true ) # Modifying internal texture


func _on_rebuild():
	_update_grass_shader("terrain_color", texture)
	_scene.terrain.material_override.albedo_texture = texture

# Fill with the current terrain color
func resize_texture(rect:Rect2i, _fill_color:Color):
	super(rect, color.value)
	_update_grass_shader("terrain_color", texture)
	_scene.terrain.material_override.albedo_texture = texture

