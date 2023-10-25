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


# Start with a SceneTree reference from "plugin_terra_brush.gd" for notifications and delays
func _init(scene_tree:SceneTree):
	_tree = scene_tree

# Creates "Load", "Save" and "Generate" buttons in inspector
func _parse_category(object, category):
	if category != "tool_terra_brush.gd":
		return
	
	var inspector_menu:Control = _INSPECTOR_MENU.instantiate()
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
	# Safety check
	var folder:String = _terra_brush.assets_folder
	var dir := DirAccess.open(folder)
	if not dir:
		return
	
	# Save textures. This might take some time
	var brushes:Array[TBrush] = [_terra_brush.grass_spawn, _terra_brush.grass_color, _terra_brush.terrain_color, _terra_brush.terrain_height]
	for brush in brushes:
		print("Loading: ", brush.resource_name)
		await _tree.process_frame
		var path:String = folder.path_join(brush.resource_name + ".tres")
		brush.texture = load( path )
		
	var path:String
	
	print("Loading terrain_mesh")
	await _tree.process_frame
	path = folder.path_join("terrain_mesh.tres")
	_terra_brush.terrain_mesh = load( path )
	
	print("Loading terrain_material")
	await _tree.process_frame
	path = folder.path_join("terrain_material.tres")
	_terra_brush.terrain_mesh.material = load( path )
	
	print("Loading terrain_shader")
	await _tree.process_frame
	path = folder.path_join("terrain_shader.gdshader")
	_terra_brush.terrain_mesh.material.shader = load( path )
	
	print("Loading grass_mesh")
	await _tree.process_frame
	path = folder.path_join("grass_mesh.tres")
	_terra_brush.grass_mesh = load( path )
	
	print("Loading grass_material")
	await _tree.process_frame
	path = folder.path_join("grass_material.tres")
	_terra_brush.grass_mesh.material = load( path )
	
	print("Loading grass_shader")
	await _tree.process_frame
	path = folder.path_join("grass_shader.gdshader")
	_terra_brush.grass_mesh.material.shader = load( path )
	

# Saves all relevant resources into a external folder so you can safetly exit or make different versions
func _save_assets():
	var folder:String = _terra_brush.assets_folder
	if DirAccess.dir_exists_absolute(folder):
		print("[TODO] Implement a 'Replace assets' popup")
	else:
		DirAccess.make_dir_absolute(folder)
	
	# Save textures. This might take some time
	var brushes:Array[TBrush] = [_terra_brush.grass_spawn, _terra_brush.grass_color, _terra_brush.terrain_color, _terra_brush.terrain_height]
	for brush in brushes:
		print("Saving: ", brush.resource_name)
		await _tree.process_frame
		var path:String = folder.path_join(brush.resource_name + ".tres")
		brush.texture.take_over_path( path )
		ResourceSaver.save(brush.texture, path)
	
	
	print("Saving terrain_shader")
	await _tree.process_frame
	var path := folder.path_join("terrain_shader.gdshader")
	_terra_brush.terrain_mesh.material.shader.take_over_path( path )
	ResourceSaver.save( _terra_brush.terrain_mesh.material.shader, path )
	
	print("Saving terrain_material")
	await _tree.process_frame
	path = folder.path_join("terrain_material.tres")
	_terra_brush.terrain_mesh.material.take_over_path( path )
	ResourceSaver.save( _terra_brush.terrain_mesh.material, path )
	
	print("Saving terrain_mesh")
	await _tree.process_frame
	path = folder.path_join("terrain_mesh.tres")
	_terra_brush.terrain_mesh.take_over_path( path )
	ResourceSaver.save( _terra_brush.terrain_mesh, path )
	
	print("Saving grass_shader")
	await _tree.process_frame
	path = folder.path_join("grass_shader.gdshader")
	_terra_brush.grass_mesh.material.shader.take_over_path( path )
	ResourceSaver.save( _terra_brush.grass_mesh.material.shader, path )
	
	print("Saving grass_material")
	await _tree.process_frame
	path = folder.path_join("grass_material.tres")
	_terra_brush.grass_mesh.material.take_over_path( path )
	ResourceSaver.save( _terra_brush.grass_mesh.material, path )
	
	print("Saving grass_mesh")
	await _tree.process_frame
	path = folder.path_join("grass_mesh.tres")
	_terra_brush.grass_mesh.take_over_path( path )
	ResourceSaver.save( _terra_brush.grass_mesh, path )


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
