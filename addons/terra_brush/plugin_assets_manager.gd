extends EditorInspectorPlugin
class_name AssetsManager
# SAVER AND LOADER OF TERRA-BRUSH ASSETS
# Creates buttons in the inspector to process the assets needed like Meshes, materials, etc..
# Everything is static because user can only select one TerraBrush at a time from the scene
#
# NOTES ABOUT RESOURCE MANAGEMENT:
#  * Creating a 'floating resource' (withouth a resource_path) does not work well from @exports until you save it manually (so it gains a path)
#  * 'ResourceSaver.save(floating_res, path)' would save but you won't get a reference from the now-saved resource. Use 'Resource.take_over_path()' before
#  * ShaderMaterial uniforms can only save sampler textures in disk, not primitives like bools


const DEFAULT_GRASS_GRADIENT:GradientTexture2D = preload("res://addons/terra_brush/textures/default_grass_gradient.tres")
const DEFAULT_BRUSH:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres")
const DEFAULT_GRASS_VARIANT1:Texture2D = preload("res://addons/terra_brush/textures/default_grass_v1.png")
const DEFAULT_GRASS_VARIANT2:Texture2D = preload("res://addons/terra_brush/textures/default_grass_v2.png")

const _INSPECTOR_MENU:PackedScene = preload("res://addons/terra_brush/Scenes/inspector_menu.tscn")

const TERRAIN_SHADER:Shader = preload("res://addons/terra_brush/shaders/terrain_shader.gdshader")
const TERRAIN_SHADER_OVERLAY:Shader = preload("res://addons/terra_brush/shaders/terrain_overlay_shader.gdshader")
const GRASS_SHADER:Shader = preload("res://addons/terra_brush/shaders/grass_shader.gdshader")

#[DEPRECATED]
const GRASS_SHADER_DOUBLE_SIDE:Shader = preload("res://addons/terra_brush/shaders/grass_shader_double_side.gdshader")
const GRASS_SHADER_BILLBOARD_Y:Shader = preload("res://addons/terra_brush/shaders/grass_shader_billboard_y.gdshader")


static var _tree:SceneTree
static var _terra_brush:TerraBrush
static var _progress:ProgressBar
static var _popup_confirm:ConfirmationDialog
static var _popup_accept:AcceptDialog
static var _save_btn:Button
static var _load_btn:Button


# Start with a SceneTree reference from "MainPlugin" for notifications and delays
func _init(scene_tree:SceneTree):
	_tree = scene_tree

# Creates "Load", "Save" and "Generate" buttons in inspector
func _parse_category(_object, category):
	if category != "tool_terra_brush.gd":
		return
	
	var inspector_menu:Control = _INSPECTOR_MENU.instantiate()
	_progress = inspector_menu.get_node("Progress")
	_popup_confirm = inspector_menu.get_node("PopupConfirm")
	_popup_accept = inspector_menu.get_node("PopupAccept")
	_save_btn = inspector_menu.get_node("Save")
	_load_btn = inspector_menu.get_node("Load")
	AssetsManager.update_saved_state( _terra_brush )
	
	_load_btn.pressed.connect( load_assets.bind(_terra_brush) )
	_save_btn.pressed.connect( save_assets.bind(_terra_brush) )
	add_custom_control( inspector_menu )

# Update TerraBrush tool from scene node
func _can_handle(object):
	if object is TerraBrush:
		_terra_brush = object
		return true
	return false


static func update_saved_state(terra_brush:TerraBrush):
	if is_instance_valid(_save_btn):
		_save_btn.text = "Save Assets To  Folder"
		if terra_brush.unsaved_changes:
			_save_btn.text += " *"


static func load_assets(terra_brush:TerraBrush):
	# Safety checks
	var folder:String = terra_brush.assets_folder
	var dir := DirAccess.open(folder)
	if not dir:
		_popup_accept.dialog_text = "Selected folder does not exist"
		_popup_accept.popup_centered()
		return
	
	var meta_path:String = folder.path_join("metadata.tres")
	if not FileAccess.file_exists( meta_path ):
		_popup_accept.dialog_text = "Folder doesn't have the metadata file"
		_popup_accept.popup_centered()
		return
	
	_load_confirmed( terra_brush )


static func _load_confirmed(terra_brush:TerraBrush):
	await _set_progress(10)
	var folder:String = terra_brush.assets_folder
	var meta_res:Resource = load( folder.path_join("metadata.tres") )
	var texture_brushes:Array[TBrush] = [terra_brush.grass_color, terra_brush.terrain_color, terra_brush.terrain_height]
	
	# Load meshes. Correct material and shader resource paths are included with the mesh
	await _set_progress(15)
	var path:String = folder.path_join("terrain_mesh.tres")
	terra_brush.terrain_mesh = load( path )
	
	await _set_progress(20)
	path = folder.path_join("grass_mesh.tres")
	terra_brush.grass_mesh = load( path )
	
	# Load from metadata. See "TBrushGrassSpawn" for possible secondary effects
	await _set_progress(25)
	var grass_spawn:TBrushGrassSpawn = terra_brush.grass_spawn
	grass_spawn.density = meta_res.get_meta("density")
	grass_spawn.billboard = meta_res.get_meta("billboard")
	grass_spawn.enable_details = meta_res.get_meta("enable_details")
	grass_spawn.detail_color = meta_res.get_meta("detail_color")
	grass_spawn.quality = meta_res.get_meta("quality")
	grass_spawn.size = meta_res.get_meta("size")
	terra_brush.terrain_height.max_height = meta_res.get_meta("max_height")
	
	#[WARNING] Always set map size before textures because it will crop or expand them unintentionally
	terra_brush.map_size = meta_res.get_meta("terrain_size")
	
	# These are embed inside the shader material. Just let the brush know it
	grass_spawn.variants = terra_brush.grass_mesh.material.get_shader_parameter("variants")
	grass_spawn.gradient_mask = terra_brush.grass_mesh.material.get_shader_parameter("gradient_mask")
	
	# Load textures. See the "TBrush.set_texture()"
	grass_spawn.set_texture( meta_res.get_meta("grass_spawn") )
	for i in texture_brushes.size():
		await _set_progress( 30 + i*25 )
		path = folder.path_join(texture_brushes[i].resource_name + ".png")
		texture_brushes[i].set_texture( load(path) )
	
	await _end_progress()
	terra_brush.unsaved_changes = false
	update_saved_state( terra_brush )


# Saves all relevant resources into a external folder so you can safetly exit or make different versions
static func save_assets( terra_brush:TerraBrush ):
	
	var folder:String = terra_brush.assets_folder
	if not folder:
		_popup_accept.dialog_text = "Invalid folder"
		_popup_accept.popup_centered()
	
	# Make user confirm overwritig on non-empty folders
	elif DirAccess.dir_exists_absolute(folder) and DirAccess.get_files_at(folder).size() > 0:
		_popup_confirm.dialog_text = "Override folder assets?"
		_popup_confirm.popup_centered()
		if not _popup_confirm.confirmed.is_connected( _save_confirmed ):
			_popup_confirm.confirmed.connect( _save_confirmed.bind(terra_brush) )
	
	# Create new directory and save there
	else:
		DirAccess.make_dir_absolute(folder)
		_save_confirmed( terra_brush )


static func _save_confirmed( terra_brush:TerraBrush ):
	# "grass_spawn" texture is embedded in the metadata file because it is of no use for an end user (the grass is already scattered)
	var brushes:Array[TBrush] = [terra_brush.grass_color, terra_brush.terrain_color, terra_brush.terrain_height]
	var folder:String = terra_brush.assets_folder
	
	# Save textures
	for i in brushes.size():
		await _set_progress( i*15 )
		var path:String = folder.path_join(brushes[i].resource_name + ".png")
		brushes[i].texture.take_over_path( path )
		ResourceSaver.save( brushes[i].texture, path )
	
	# Save terrain mesh, material and shader (sigh.. if only there was a way to reduce this)
	await _set_progress(65)
	var path:String = folder.path_join("terrain_mesh.tres")
	terra_brush.terrain_mesh.take_over_path( path )
	ResourceSaver.save( terra_brush.terrain_mesh, path )
	
	await _set_progress(70)
	path = folder.path_join("terrain_material.tres")
	terra_brush.terrain_mesh.material.take_over_path( path )
	ResourceSaver.save( terra_brush.terrain_mesh.material, path )
	
	await _set_progress(75)
	path = folder.path_join("terrain_shader.gdshader")
	terra_brush.terrain_mesh.material.shader.take_over_path( path )
	ResourceSaver.save( terra_brush.terrain_mesh.material.shader, path )
	
	# Save grass mesh, material and shader
	await _set_progress(80)
	path = folder.path_join("grass_mesh.tres")
	terra_brush.grass_mesh.take_over_path( path )
	ResourceSaver.save( terra_brush.grass_mesh, path )
	
	await _set_progress(85)
	path = folder.path_join("grass_material.tres")
	terra_brush.grass_mesh.material.take_over_path( path )
	ResourceSaver.save( terra_brush.grass_mesh.material, path )
	
	await _set_progress(90)
	path = folder.path_join("grass_shader.gdshader")
	terra_brush.grass_mesh.material.shader.take_over_path( path )
	ResourceSaver.save( terra_brush.grass_mesh.material.shader, path )
	
	# Save all the data that is of no use for the end user but it is needed internally to load a TerraBrush instance
	await _set_progress(95)
	var grass_spawn:TBrushGrassSpawn = terra_brush.grass_spawn
	var meta_res := Resource.new()
	path = folder.path_join("metadata.tres")
	meta_res.set_meta("what_is_this", "You need this file to load and continue editing this terrain using TerraBrush Addon")
	meta_res.set_meta("terrain_size", terra_brush.map_size)
	meta_res.set_meta("density", grass_spawn.density)
	meta_res.set_meta("billboard", grass_spawn.billboard)
	meta_res.set_meta("enable_details", grass_spawn.enable_details)
	meta_res.set_meta("detail_color", grass_spawn.detail_color)
	meta_res.set_meta("quality", grass_spawn.quality)
	meta_res.set_meta("size", grass_spawn.size)
	meta_res.set_meta("grass_spawn", grass_spawn.texture)
	meta_res.take_over_path( path )
	meta_res.set_meta("max_height", terra_brush.terrain_height.max_height)
	ResourceSaver.save( meta_res, path )
	
	await _end_progress()
	terra_brush.unsaved_changes = false
	update_saved_state( terra_brush )


# So the computer doesn't get stuck in one frame and possibly crash
static func _set_progress(p:int):
	if _progress:
		_progress.show()
		_progress.value = p
	await _tree.process_frame

static func _end_progress():
	if _progress:
		_progress.value = 100
	await _tree.create_timer(0.7).timeout
	if _progress:
		_progress.value = 0
		_progress.hide()


const LINE_OFFSET:int = 6
enum ShaderDirectives {BILLBOARD_Y=LINE_OFFSET, DETAILS, GL_COMPATIBILITY}
static func set_shader_directive(shader:Shader, directive:ShaderDirectives, active:bool):
	var directive_string:String = "#define %s" %ShaderDirectives.keys()[directive-LINE_OFFSET]
	var new_code:String = shader.code
	
	if active:
		new_code = new_code.replace("//" + directive_string, directive_string)
	elif "//" + directive_string in new_code:
		new_code = new_code.replace(directive_string, "//" + directive_string)
	
	shader.set_code( new_code )
	print(new_code)
