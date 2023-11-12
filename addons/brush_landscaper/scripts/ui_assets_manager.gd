@tool
extends VBoxContainer
class_name AssetsManager
# Due some acctions taking quite a bit of time to perform, the following table was implemented:
#
#                | Save UI    | Load UI    | Rebuild  | Create   | Save External | Load External |
#                | Properties | Properties | Terrain  | Template | Resources     | Resources     |
# ---------------|------------|------------|----------|----------|---------------|---------------|
# NEW SCENE      |      F     |      T     |     T    |     T    |       F       |       F       |
# CHANGE SCENE   |      T     |      T     |     F    |     F    |       F       |       F       |
# LOAD BUTTON    |      F     |      T     |     T    |     F    |       F       |       T       |
# SAVE BUTTON    |      T     |      F     |     F    |     F    |       T       |       F       |


# File System Resources
const GRASS_SHADER:Shader = preload("res://addons/brush_landscaper/shaders/grass_shader.gdshader")
const TERRAIN_OVERLAY_SHADER:Shader = preload("res://addons/brush_landscaper/shaders/terrain_overlay_shader.gdshader")
const DEFAULT_BRUSH:Resource = preload("res://addons/brush_landscaper/textures/default_brush.tres")

# Content child indexes and extensions for external resources
enum { _PROJECT, _TERRAIN_MESH, _TERRAIN_MATERIAL, _TERRAIN_TEXTURE, _GRASS_MESH, _GRASS_MATERIAL, _GRASS_SHADER, _GRASS_TEXTURE}
const _EXTENSIONS:PackedStringArray = ["tres", "tres", "tres", "png", "tres", "tres", "gdshader", "png"]

@onready var _toggle_files:CustomToggleContent = $ToggleContent
@onready var _save_all:Button = $All/Save
@onready var _load_all:Button = $All/Load
@onready var _accept_dialog:AcceptDialog = $AcceptDialog
@onready var _confirm_save:ConfirmationDialog = $ConfirmationSaveDialog
@onready var _confirm_load:ConfirmationDialog = $ConfirmationLoadDialog

var _ui:UILandscaper
var _scene:SceneLandscaper
var _raw:RawLandscaper
var _brushes:Array[Brush]


func _ready():
	_toggle_files.on_change.connect( _on_toggle_files )
	_save_all.pressed.connect( _on_save_all_pressed )
	_load_all.pressed.connect( _on_load_all_pressed )
	_confirm_save.confirmed.connect( _save_confirmed )
	_confirm_load.confirmed.connect( _load_confirmed )

func _on_toggle_files(button_pressed:bool):
	_ui.set_dock_enable( not button_pressed )


func _load_ui():
	# Update UI input paths from external resources
	var files:Array = _toggle_files.value
	if _raw.saved_external:
		files[_PROJECT].value = _raw.resource_path
		files[_TERRAIN_MESH].value = _raw.terrain_mesh.resource_path
		files[_TERRAIN_MATERIAL].value = _raw.terrain_material.resource_path
		files[_TERRAIN_TEXTURE].value = _raw.tc_texture.resource_path
		files[_GRASS_MESH].value = _raw.grass_mesh.resource_path
		files[_GRASS_MATERIAL].value = _raw.grass_material.resource_path
		files[_GRASS_SHADER].value = _raw.grass_shader.resource_path
#		files[_GRASS_TEXTURE].value = _raw.gc_texture.resource_path #[TEST] uncomment
	
	# Load brush UI properties
	for brush in _brushes:
		brush.load_ui( _ui, _scene, _raw )

func save_ui():
	# UI input paths are saved inside the external resources
	for brush in _brushes:
		brush.save_ui()

func _rebuild_terrain():
	for brush in _brushes:
		brush.rebuild_terrain()


func _on_load_all_pressed():
	var project:CustomFileInput = _toggle_files.value[_PROJECT]
	
	if not FileAccess.file_exists( project.value ):
		_accept_dialog.dialog_text = "Project file '%s' does not exist\n" %project.value
		_accept_dialog.popup()
		_ui.set_foot_enable( true )
		return
	
	# Warn user if the project was not saved in File System
	if _raw.saved_external:
		_confirm_load.dialog_text = "Override current project?"
		_confirm_load.popup()
		return
	
	_load_confirmed()

func _load_confirmed():
	var project:CustomFileInput = _toggle_files.value[_PROJECT]
	_ui.set_foot_enable( false, "Loading.." )
	
	# Quicksave the current project just in case
	save_ui()
	
	# Load project resource
	await get_tree().process_frame
	_raw = load(project.value)
	_scene.raw = _raw
	
	# Update UI properties and rebuild terrain
	_load_ui()
	for brush in _brushes:
		await get_tree().process_frame
		brush.rebuild_terrain()
	
	await get_tree().create_timer(0.2).timeout
	_ui.set_foot_enable( true )


func _on_save_all_pressed():
	var files:Array = _toggle_files.value
	var warnings:String
	var errors:String
	
	for file_index in files.size():
		var file:CustomFileInput = files[file_index]
		
		# Files without path are saved locally in RawLandscaper by default
		if not file.value:
			continue
		
		# Watch out for extensions
		var extension:String = _EXTENSIONS[file_index]
		if file.value.get_extension() != extension:
			errors += "File '%s' extension not supported. Use '%s' instead\n" %[file.value, extension]
			continue
		
		# Create directory if it wasn't found
		var dir:String = file.value.get_base_dir()
		if not DirAccess.dir_exists_absolute( dir ):
			DirAccess.make_dir_absolute( dir )
		
		# Warn overrides
		if FileAccess.file_exists( file.value ):
			warnings += "File '%s' will be overriden\n" %file.value
			continue
	
	# Don't save if errors. Ask to save if warnings. Or just save
	if errors:
		_accept_dialog.dialog_text = errors
		_accept_dialog.popup()
	elif warnings:
		_confirm_save.dialog_text = warnings
		_confirm_save.popup()
	else:
		_save_confirmed()


# Saves in file system every resource, which might take a while on big textures
func _save_confirmed():
	var files:Array = _toggle_files.value
	_ui.set_foot_enable( false, "Saving.." )
	save_ui()
	
	_raw.terrain_mesh = _scene.terrain_mesh
	await _save_resource( files[_TERRAIN_MESH], _raw.terrain_mesh )
	
	_raw.terrain_material = _scene.terrain.material_override
	await _save_resource( files[_TERRAIN_MATERIAL], _raw.terrain_material )
	
	await _save_resource( files[_TERRAIN_TEXTURE], _raw.tc_texture )
	
	_raw.grass_mesh = _scene.grass_mesh
	await _save_resource( files[_GRASS_MESH], _raw.grass_mesh )
	
	_raw.grass_material = _scene.grass_mesh.material
	await _save_resource( files[_GRASS_MATERIAL], _raw.grass_material )
	
	_raw.grass_shader = _scene.grass_mesh.material.shader
	await _save_resource( files[_GRASS_SHADER], _raw.grass_shader )
	
	await _save_resource( files[_GRASS_TEXTURE], _raw.gc_texture )
	await _save_resource( files[_PROJECT], _raw )
	
	await get_tree().create_timer(0.2).timeout
	_ui.set_foot_enable( true )
	_raw.saved_external = true


# Just saving the resource will not let us with the saved references unless 'take_over_path()' is called
# Wait a frame to avoid potentially freezing the computer
func _save_resource(file:CustomFileInput, res:Resource):
	if file.value and res:
		await get_tree().process_frame
		res.take_over_path( file.value )
		ResourceSaver.save( res )


func change_scene(ui:UILandscaper, scene:SceneLandscaper, brushes:Array[Brush]):
	# Save previous UI properties if we have them
	if _raw:
		save_ui()
	
	_ui = ui
	_scene = scene
	_brushes = brushes
	_raw = scene.raw
	
	# Load new UI properties
	if _raw:
		_load_ui()
		return
	
	# Or create a new terrain from templates on a new scene
	_raw = RawLandscaper.new()
	_scene.raw = _raw
	for brush in _brushes:
		brush.template( Vector2i(10, 10), _raw )
		brush.load_ui( _ui, _scene, _raw )
		brush.rebuild_terrain()
	
	# Default external resource file inputs
	var files:Array = _toggle_files.value
	for i in files.size():
		files[i].value = files[i].default_file_path
	

