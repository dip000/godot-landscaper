extends EditorInspectorPlugin
class_name AssetsManager
# SAVER AND LOADER OF TERRA-BRUSH ASSETS
# Creates buttons in the inspector to process the assets needed like Meshes, materials, etc..
#
# NOTES:
#  * Creating a 'floating resource' (withouth a resource_path) will not work from @exports


const DEFAULT_GRASS_GRADIENT:GradientTexture2D = preload("res://addons/terra_brush/textures/default_grass_gradient.tres")
const DEFAULT_BRUSH:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres")
const DEFAULT_GRASS_VARIANT1:Texture2D = preload("res://addons/terra_brush/textures/default_grass_v1.png")
const DEFAULT_GRASS_VARIANT2:Texture2D = preload("res://addons/terra_brush/textures/default_grass_v2.png")

const _TERRAIN_TEMPLATE:PackedScene = preload("res://addons/terra_brush/Scenes/terrain_template.tscn")
const _INSPECTOR_MENU:PackedScene = preload("res://addons/terra_brush/Scenes/inspector_menu.tscn")

const _TERRAIN_SHADER:Shader = preload("res://addons/terra_brush/shaders/terrain_shader.gdshader")
const _TERRAIN_SHADER_OVERLAY:Shader = preload("res://addons/terra_brush/shaders/terrain_overlay_shader.gdshader")
const _GRASS_SHADER:Shader = preload("res://addons/terra_brush/shaders/grass_shader.gdshader")

var _terra_brush:TerraBrush
var _tree:SceneTree
var _progress:ProgressBar
var _popup_confirm:ConfirmationDialog
var _popup_accept:AcceptDialog
var _editor:EditorPlugin

# Start with a SceneTree reference from "plugin_terra_brush.gd" for notifications and delays
func _init(scene_tree:SceneTree, editor:EditorPlugin):
	_tree = scene_tree
	_editor = editor

# Creates "Load", "Save" and "Generate" buttons in inspector
func _parse_category(object, category):
	if category != "tool_terra_brush.gd":
		return
	
	var inspector_menu:Control = _INSPECTOR_MENU.instantiate()
	_progress = inspector_menu.get_node("Progress")
	_popup_confirm = inspector_menu.get_node("PopupConfirm")
	_popup_accept = inspector_menu.get_node("PopupAccept")
	
	inspector_menu.get_node("Load").pressed.connect( _load_assets )
	inspector_menu.get_node("Save").pressed.connect( _save_assets )
	add_custom_control( inspector_menu )

# Update TerraBrush tool from scene node
func _can_handle(object):
	if object is TerraBrush:
		_terra_brush = object
		return true
	return false


func _load_assets():
	if _progress.value != 0:
		return
	
	# Safety check
	var folder:String = _terra_brush.assets_folder
	var dir := DirAccess.open(folder)
	if not dir:
		_popup_accept.popup_centered()
		return
	
	# Save textures. This might take some time
	var brushes:Array[TBrush] = [_terra_brush.grass_spawn, _terra_brush.grass_color, _terra_brush.terrain_color, _terra_brush.terrain_height]
	for i in brushes.size():
		await _set_progress( i*15 )
		var path:String = folder.path_join(brushes[i].resource_name + ".tres")
		brushes[i].texture = load( path )
	
	await _set_progress(65)
	var path:String = folder.path_join("terrain_mesh.tres")
	_terra_brush.terrain_mesh = load( path )
	
	await _set_progress(70)
	path = folder.path_join("terrain_material.tres")
	_terra_brush.terrain_mesh.material = load( path )
	
	await _set_progress(75)
	path = folder.path_join("terrain_shader.gdshader")
	_terra_brush.terrain_mesh.material.shader = load( path )
	
	await _set_progress(80)
	path = folder.path_join("grass_mesh.tres")
	_terra_brush.grass_mesh = load( path )
	
	await _set_progress(85)
	path = folder.path_join("grass_material.tres")
	_terra_brush.grass_mesh.material = load( path )
	
	await _set_progress(90)
	path = folder.path_join("grass_shader.gdshader")
	_terra_brush.grass_mesh.material.shader = load( path )
	
	# Setting any property from "grass_spawn" will update anything needed to the terrain
	var grass_spawn:TBrushGrassSpawn = _terra_brush.grass_spawn
	var grass_mat:ShaderMaterial = _terra_brush.grass_mesh.material
	_terra_brush.map_size = grass_mat.get_meta("terrain_size")
	grass_spawn.density = grass_mat.get_meta("density")
	grass_spawn.billboard_y = grass_mat.get_meta("billboard_y")
	grass_spawn.cross_billboard = grass_mat.get_meta("cross_billboard", )
	grass_spawn.enable_margin = grass_mat.get_meta("enable_margin")
	grass_spawn.margin_color = grass_mat.get_meta("margin_color")
	grass_spawn.quality = grass_mat.get_meta("quality")
	grass_spawn.size = grass_mat.get_meta("size")
	grass_spawn.variants = grass_mat.get_shader_parameter("variants")
	
	# Textures were updated at the begining but we need to update them again after all of the now changes
	await _set_progress(95)
	for brush in brushes:
		brush.on_texture_update()
	
	await _end_progress()


# Saves all relevant resources into a external folder so you can safetly exit or make different versions
func _save_assets():
	if _progress.value != 0:
		return
	
	var folder:String = _terra_brush.assets_folder
	if DirAccess.dir_exists_absolute(folder):
		_popup_confirm.popup_centered()
		if not _popup_confirm.confirmed.is_connected( _save_confirmed ):
			_popup_confirm.confirmed.connect( _save_confirmed )
	else:
		DirAccess.make_dir_absolute(folder)
		_save_confirmed()


func _save_confirmed():
	# Save textures. This might take some time
	var folder:String = _terra_brush.assets_folder
	var brushes:Array[TBrush] = [_terra_brush.grass_spawn, _terra_brush.grass_color, _terra_brush.terrain_color, _terra_brush.terrain_height]
	
	for i in brushes.size():
		await _set_progress( i*15 )
		var path:String = folder.path_join(brushes[i].resource_name + ".tres")
		brushes[i].texture.take_over_path( path )
		ResourceSaver.save( brushes[i].texture, path )
	
	# Save terrain mesh, material and shader
	await _set_progress(65)
	var path:String = folder.path_join("terrain_mesh.tres")
	_terra_brush.terrain_mesh.take_over_path( path )
	ResourceSaver.save( _terra_brush.terrain_mesh, path )
	
	await _set_progress(70)
	path = folder.path_join("terrain_material.tres")
	_terra_brush.terrain_mesh.material.take_over_path( path )
	ResourceSaver.save( _terra_brush.terrain_mesh.material, path )
	
	await _set_progress(75)
	path = folder.path_join("terrain_shader.gdshader")
	_terra_brush.terrain_mesh.material.shader.take_over_path( path )
	ResourceSaver.save( _terra_brush.terrain_mesh.material.shader, path )
	
	# Save grass mesh, material and shader
	await _set_progress(80)
	path = folder.path_join("grass_mesh.tres")
	_terra_brush.grass_mesh.take_over_path( path )
	ResourceSaver.save( _terra_brush.grass_mesh, path )
	
	await _set_progress(85)
	path = folder.path_join("grass_material.tres")
	_terra_brush.grass_mesh.material.take_over_path( path )
	ResourceSaver.save( _terra_brush.grass_mesh.material, path )
	
	await _set_progress(90)
	path = folder.path_join("grass_shader.gdshader")
	_terra_brush.grass_mesh.material.shader.take_over_path( path )
	ResourceSaver.save( _terra_brush.grass_mesh.material.shader, path )
	
	var grass_spawn:TBrushGrassSpawn = _terra_brush.grass_spawn
	var grass_mat:ShaderMaterial = _terra_brush.grass_mesh.material
	grass_mat.set_meta("terrain_size", _terra_brush.map_size)
	grass_mat.set_meta("density", grass_spawn.density)
	grass_mat.set_meta("billboard_y", grass_spawn.billboard_y)
	grass_mat.set_meta("cross_billboard", grass_spawn.cross_billboard)
	grass_mat.set_meta("enable_margin", grass_spawn.enable_margin)
	grass_mat.set_meta("margin_color", grass_spawn.margin_color)
	grass_mat.set_meta("quality", grass_spawn.quality)
	grass_mat.set_meta("size", grass_spawn.size)
	
	await _end_progress()


func _set_progress(p:int):
	_progress.show()
	_progress.value = p
	await _tree.process_frame

func _end_progress():
	_progress.value = 100
	await _tree.create_timer(0.7).timeout
	_progress.value = 0
	_progress.hide()


static func generate_grass_mesh(terra_brush:TerraBrush) -> QuadMesh:
	var grass_mesh := QuadMesh.new()
	grass_mesh.material = ShaderMaterial.new()
	grass_mesh.material.shader = _GRASS_SHADER.duplicate()
	
	grass_mesh.material.set_shader_parameter("grass_color", terra_brush.grass_color.texture)
	grass_mesh.material.set_shader_parameter("terrain_color", terra_brush.terrain_color.texture)
	grass_mesh.material.set_shader_parameter("terrain_size", terra_brush.map_size)
	return grass_mesh


static func generate_terrain_mesh(terra_brush:TerraBrush, overlay:bool) -> PlaneMesh:
	var terrain_mesh = PlaneMesh.new()
	terrain_mesh.material = ShaderMaterial.new()
	
	if overlay:
		terrain_mesh.material.shader = _TERRAIN_SHADER_OVERLAY.duplicate()
		terrain_mesh.material.set_shader_parameter("brush_texture", DEFAULT_BRUSH)
	else:
		terrain_mesh.material.shader = _TERRAIN_SHADER.duplicate()
	
	terrain_mesh.material.set_shader_parameter("terrain_color", terra_brush.terrain_color.texture)
	terrain_mesh.material.set_shader_parameter("terrain_height", terra_brush.terrain_height.texture)
	return terrain_mesh


static func generate_terrain_nodes(terra_brush:TerraBrush) -> MeshInstance3D:
	var terrain:MeshInstance3D = _TERRAIN_TEMPLATE.instantiate()
	terra_brush.add_child(terrain)
	terrain.owner = terra_brush.owner
	
	terra_brush.grass_holder = terrain.get_node("Grass")
	terra_brush.height_shape = terrain.get_node("Body/Height").shape
	terra_brush.base_shape = terrain.get_node("Body/Base").shape
	return terrain
