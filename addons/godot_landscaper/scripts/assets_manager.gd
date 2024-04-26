@tool
extends VBoxContainer
class_name AssetsManager
## Hosts resources, saves/loads UI properties, saves/loads files
## There are two kind of textures:
##  1. Internal textures: like 'gc_texture' or 'th_texture', they are processed while being saved in the project file 'ProjectLandscaper'
##  2. External textures: 'grass_texture' and 'terrain_texture', and they only get updated by saving/loading the project file 'ProjectLandscaper'
## [TODO] Fix bug where you press [Save Project], extend the terrain, then press [Load Project]. It will try to extend the previous image, looks awfull and creates errors down the line

#[TODO] Add this property to global settings
const DEBUGS := true

#[TODO] Add this property to global settings
const DEFAULT_BRUSH:GradientTexture2D = preload("res://addons/godot_landscaper/textures/default_brush.tres")

# File System Resources
const ICONS_MEDIUM:Texture2D = preload("res://addons/godot_landscaper/textures/icons_medium.svg")
const ICONS:Texture2D = preload("res://addons/godot_landscaper/textures/icons.svg")
const GRASS_SHADER:Shader = preload("res://addons/godot_landscaper/shaders/grass_shader.gdshader")
const TERRAIN_OVERLAY_SHADER:Shader = preload("res://addons/godot_landscaper/shaders/terrain_overlay_shader.gdshader")
const DEFAULT_GRASS_GRADIENT:Texture2D = preload("res://addons/godot_landscaper/textures/default_grass_gradient.tres")
const DEFAULT_GRASS_0:Texture2D = preload("res://addons/godot_landscaper/textures/default_grass_v0.svg")
const DEFAULT_GRASS_1:Texture2D = preload("res://addons/godot_landscaper/textures/default_grass_v1.svg")
const DEFAULT_GRASS_2:Texture2D = preload("res://addons/godot_landscaper/textures/default_grass_v2.svg")
const DEFAULT_STONE:PackedScene = preload("res://addons/godot_landscaper/scenes/default_stone.glb")
const DEFAULT_TREE:PackedScene = preload("res://addons/godot_landscaper/scenes/default_tree.glb")
const TERRAIN_OVERLAY:PackedScene = preload("res://addons/godot_landscaper/scenes/terrain_overlay.tscn")

# For grass shader logic
const SHADER_COMPATIBILITY := "#define GL_COMPATIBILITY"
const SHADER_BILLBOARD_Y := "#define BILLBOARD_Y"

# Content child indexes and extensions for external resources
enum { FILE_PROJECT, FILE_TERRAIN_MESH, FILE_TERRAIN_MATERIAL, FILE_TERRAIN_TEXTURE, FILE_GRASS_MESH, FILE_GRASS_MATERIAL, FILE_GRASS_SHADER, FILE_GRASS_TEXTURE}
const EXTENSIONS:PackedStringArray = ["res", "res", "res", "png", "res", "res", "gdshader", "png"]

@onready var _toggle_files:CustomToggleContent = $ToggleContent
@onready var _save_all:Button = $All/Save
@onready var _load_all:Button = $All/Load
@onready var _accept_dialog:AcceptDialog = $AcceptDialog
@onready var _confirm_save:ConfirmationDialog = $ConfirmationSaveDialog
@onready var _confirm_load:ConfirmationDialog = $ConfirmationLoadDialog
@onready var _ui:UIControl = owner

var _scene:SceneLandscaper
var _project:ProjectLandscaper
var has_vulkan:bool


func _ready():
	_toggle_files.on_change.connect( _on_toggle_files )
	_save_all.pressed.connect( _on_save_all_pressed )
	_load_all.pressed.connect( _on_load_all_pressed )
	_confirm_save.confirmed.connect( _save_confirmed )
	_confirm_load.confirmed.connect( _load_confirmed )
	has_vulkan = true if RenderingServer.get_rendering_device() else false

func set_unsaved_changes(unsaved:bool):
	_save_all.text = "Save Project *" if unsaved else "Save Project"

func _on_toggle_files(button_pressed:bool):
	_ui.set_dock_enable( not button_pressed )

func _load_ui():
	debug("Loading UI properties of '%s'.." %_scene.name)
	for brush in _ui.brushes:
		brush.load_ui( _scene )

func save_ui():
	# UI input paths are saved inside the external resources
	debug("Saving UI properties of '%s'.." %_scene.name)
	for brush in _ui.brushes:
		brush.save_ui()

func _rebuild_terrain():
	debug("Rebuilding terrain of '%s'.." %_scene.name)
	for brush in _ui.brushes:
		brush.rebuild()


func _update_paths():
	var files:Array = _toggle_files.value
	if _project.saved_external:
		files[FILE_PROJECT].value = _project.resource_path
		files[FILE_TERRAIN_MESH].value = _project.terrain_mesh.resource_path
		files[FILE_TERRAIN_MATERIAL].value = _project.terrain_material.resource_path
		files[FILE_TERRAIN_TEXTURE].value = _project.terrain_texture.resource_path
		files[FILE_GRASS_MESH].value = _project.grass_mesh.resource_path
		files[FILE_GRASS_MATERIAL].value = _project.grass_material.resource_path
		files[FILE_GRASS_SHADER].value = _project.grass_shader.resource_path
		files[FILE_GRASS_TEXTURE].value = _project.grass_texture.resource_path
	else:
		for i in files.size():
			files[i].value = files[i].default_file_path


func _on_load_all_pressed():
	var files:Array = _toggle_files.value
	var warnings:String
	var errors:String
	
	for file_index in files.size():
		var file:CustomFileInput = files[file_index]
		var extension:String = EXTENSIONS[file_index]
		
		if not FileAccess.file_exists( file.value ):
			errors += "File '%s' does not exist. Must be an absolute path like res://my_file.%s\n" %[file.value, extension]
			continue
		
		if not file.value:
			errors += "File path to '%s' is empty. Please provide a valid path\n" %file.property_name
			continue
		
		# Watch out for extensions
		if file.value.get_extension() != extension:
			errors += "The extension of %s file '%s' is not supported. Use '%s' instead\n" %[file.property_name, file.value.get_extension(), extension]
			continue
	
	# Warn override
	if _project.saved_external:
		warnings += "Override current project?"
	
	# Don't load if errors. Ask to load if warnings. Or just load
	if errors:
		popup_accept( errors )
	elif warnings:
		_confirm_load.dialog_text = warnings
		_confirm_load.popup()
	else:
		_load_confirmed()


func _load_confirmed():
	debug("Loading project '%s'.." %_scene.name)
	var project:CustomFileInput = _toggle_files.value[FILE_PROJECT]
	_ui.set_foot_enable( false, "Loading.." )
	
	# Quicksave the current project just in case
	save_ui()
	await get_tree().process_frame
	
	# Load project resource
	_project = load(project.value)
	_scene.project = _project
	await get_tree().process_frame
	
	# Load the specific files selected by the user
	var files:Array = _toggle_files.value
	_project.terrain_mesh = _load_resource( files[FILE_TERRAIN_MESH], _project.terrain_mesh )
	_project.terrain_material = _load_resource( files[FILE_TERRAIN_MATERIAL], _project.terrain_material )
	_project.terrain_texture = _load_resource( files[FILE_TERRAIN_TEXTURE], _project.terrain_texture )
	await get_tree().process_frame
	
	_project.grass_mesh = _load_resource( files[FILE_GRASS_MESH], _project.grass_mesh )
	_project.grass_material = _load_resource( files[FILE_GRASS_MATERIAL], _project.grass_material )
	_project.grass_texture = _load_resource( files[FILE_GRASS_TEXTURE], _project.grass_texture )
	await get_tree().process_frame
	
	# Update interal textures from the external ones
	_project.gc_texture = format_texture( _project.grass_texture )
	_project.tc_texture = format_texture( _project.terrain_texture )
	
	# Update UI properties and rebuild terrain
	_load_ui()
	_rebuild_terrain()
	await get_tree().create_timer(0.2).timeout
	
	# Update shader references
	_project.terrain_material.albedo_texture = _project.terrain_texture
	_project.grass_material.set_shader_parameter("grass_color", _project.grass_texture)
	_project.grass_material.set_shader_parameter("terrain_color", _project.terrain_texture)
	set_unsaved_changes( false )
	
	_ui.set_foot_enable( true )


func _on_save_all_pressed():
	var files:Array = _toggle_files.value
	var warnings:String
	var errors:String
	
	for file_index in files.size():
		var file:CustomFileInput = files[file_index]
		
		if not file.value:
			errors += "File path to '%s' is empty. Please provide a valid path\n" %file.property_name
			continue
		
		var extension:String = EXTENSIONS[file_index]
		if not file.value.is_absolute_path():
			errors += "File path to '%s' is invalid. Must be an absolute path like res://my_file.%s\n" %[file.property_name, extension]
			continue
		
		# Watch out for extensions
		if file.value.get_extension() != extension:
			errors += "The extension of %s file '%s' is not supported. Use '%s' instead\n" %[file.property_name, file.value.get_extension(), extension]
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
		popup_accept( errors )
	elif warnings:
		_confirm_save.dialog_text = warnings
		_confirm_save.popup()
	else:
		_save_confirmed()


# Saves in file system every resource, which might take a while on big textures
func _save_confirmed():
	debug("Saving project '%s'.." %_scene.name)
	var files:Array = _toggle_files.value
	_ui.set_foot_enable( false, "Saving.." )
	save_ui()
	await get_tree().process_frame
	
	_project.terrain_mesh = _scene.terrain_mesh
	await _save_resource( files[FILE_TERRAIN_MESH], _project.terrain_mesh )
	
	_project.terrain_material = _scene.terrain.material_override
	await _save_resource( files[FILE_TERRAIN_MATERIAL], _project.terrain_material )
	
	_project.terrain_texture = _project.tc_texture
	await _save_resource( files[FILE_TERRAIN_TEXTURE], _project.terrain_texture )
	
	_project.grass_mesh = _scene.grass_mesh
	await _save_resource( files[FILE_GRASS_MESH], _project.grass_mesh )
	
	_project.grass_material = _scene.grass_mesh.material
	await _save_resource( files[FILE_GRASS_MATERIAL], _project.grass_material )
	
	_project.grass_shader = _scene.grass_mesh.material.shader
	await _save_resource( files[FILE_GRASS_SHADER], _project.grass_shader )
	
	_project.grass_texture = _project.gc_texture
	await _save_resource( files[FILE_GRASS_TEXTURE], _project.grass_texture )

	await _save_resource( files[FILE_PROJECT], _project )
	
	# This will independize the internal textures from the saved ones
	_project.gc_texture = format_texture( _project.grass_texture )
	_ui.grass_color.texture = _project.gc_texture
	_project.tc_texture = format_texture( _project.terrain_texture )
	_ui.terrain_color.texture = _project.tc_texture
	
	EditorInterface.get_resource_filesystem().scan()
	await get_tree().create_timer(0.2).timeout
	set_unsaved_changes( false )
	_ui.set_foot_enable( true )
	_project.saved_external = true


# Just saving the resource will not let us with the saved references unless 'take_over_path()' is called
# Wait a frame to avoid potentially freezing the computer
func _save_resource(file:CustomFileInput, res:Resource):
	if file.value and res:
		await get_tree().process_frame
		res.take_over_path( file.value )
		ResourceSaver.save( res )

func _load_resource(file:CustomFileInput, res:Resource) -> Resource:
	if file.value != res.resource_path:
		return load(file.value)
	return res


func selected_scene(scene:SceneLandscaper):
	debug("Selected '%s'" %scene.name)
	
	# If initialized but not updated (like opening the scene or the editor for the first time)
	if scene.project and not scene.updated:
		debug("Scene '%s' is initialized. Updating.." %scene.name)
		scene.update_terrain()
	
	# Save previous
	if _scene:
		save_ui()
	
	# Update references
	_scene = scene
	_project = scene.project
	
	# Load new UI properties
	if scene.project:
		_load_ui()
		_update_paths()
		scene.overlay.enable()
		scene.body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_TERRAIN, true )
		return
	
	# Build and setup new scene
	debug("Initializing and updating '%s' for the first time.." %scene.name)
	_project = ProjectLandscaper.new()
	scene.project = _project
	scene.update_terrain()
	scene.body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_TERRAIN, true )
	scene.overlay.resize(_project.canvas.size.x, _project.canvas.size.y)
	scene.overlay.enable()
	scene.overlay.set_brush_scale( _ui.brush_size.value )
	set_unsaved_changes( true ) # Project was just been created and is not saved on file system yet
	
	_load_ui()
	_rebuild_terrain()
	_update_paths()
	

func deselected_scene(scene:SceneLandscaper):
	debug("Deselected '%s'" %scene.name)
	scene.overlay.disable()
	scene.body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_TERRAIN, false )
	save_ui()
	for brush in _ui.brushes:
		brush.deselected_scene()
	_scene = null

func popup_accept(msg:String):
	_accept_dialog.dialog_text = msg
	_accept_dialog.popup()


func fix_shader_compatibility(variants:Array):
	var total_variants:int = variants.filter(func(v): return v).size()
	var needs_vulkan:bool = (total_variants > 1)
	
	if needs_vulkan and has_vulkan:
		set_shader_directive( SHADER_COMPATIBILITY , false )
	elif needs_vulkan and not has_vulkan:
		popup_accept("Upgrade to Mobile or Forward+ renderer to add more than one grass variant")
		set_shader_directive( SHADER_COMPATIBILITY , true )
	else:
		set_shader_directive( SHADER_COMPATIBILITY , true )

# Litteraly changes te code to avoid compilation errors and allow this plugin to work in low-end devices
func set_shader_directive(directive:String, active:bool):
	var shader:Shader = _scene.grass_mesh.material.shader
	var not_directive:String = "//" + directive
	
	if active:
		shader.set_code( shader.code.replace(not_directive, directive) )
	elif not shader.code.contains( not_directive ):
		shader.set_code( shader.code.replace(directive, not_directive) )


static func format_texture(texture:Texture2D, resize:=Vector2i.ZERO) -> ImageTexture:
	var img:Image = texture.get_image()
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	if resize != Vector2i.ZERO:
		img.resize( resize.x, resize.y )
	
	return ImageTexture.create_from_image( img )


func debug(msg:String):
	if DEBUGS:
		print("GodotLandscaper --> ", msg)

