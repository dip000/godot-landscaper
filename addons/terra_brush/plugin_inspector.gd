extends EditorInspectorPlugin

var _terrain:TerraBrush
var _notif_label:Label #[DEPRECATED]
var _tree:SceneTree
const _INSPECTOR_MENU:PackedScene = preload("res://addons/terra_brush/Scenes/inspector_menu.tscn")

# Start with a SceneTree reference from "plugin_terra_brush.gd" for notifications and delays
func _init(scene_tree:SceneTree):
	_tree = scene_tree


# Creates "Load", "Save" and "Generate" buttons in inspector
func _parse_category(object, category):
	if category != "tool_terra_brush.gd":
		return
	
	add_custom_control( _INSPECTOR_MENU.instantiate() )


# Hides all irrelevant inspector properties. Specialy beacuse transforms aren't supported right now
#func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
#	return not [
#		"brush_scale",
#		"map_size",
#		"terrain_color",
#		"terrain_height",
#		"grass_color",
#		"grass_spawn",
#	].any(func(n): return n == name)


# Update TerraBrush tool from scene node
func _can_handle(object):
	if object is TerraBrush:
		_terrain = object
		return true
	else:
		return false


func _load_assets():
	# Igore if already loading
	if _notif_label.is_visible():
		return
	
	# Safety checks
	var folder:String = _terrain.assets_folder
	if not DirAccess.dir_exists_absolute(folder):
		await _notif_end("Folder Not Found :c")
		return
	
	_terrain.assets_folder = folder
	var dir := DirAccess.open(folder)
	
	if not dir:
		await _notif_end("Error: %s" %DirAccess.get_open_error())
		return
	
	# Find resources through the folder
	dir.list_dir_begin()
	var texture_names:Array[String] = ["grass_color", "grass_spawn", "terrain_color", "terrain_height"]
	var file_name:String = dir.get_next()
	
	while not file_name.is_empty():
		if dir.current_is_dir():
			file_name = dir.get_next()
			continue
		
		var res:Resource = load( folder.path_join(file_name) )
		var name:String = file_name.get_basename()
		await _notif("Loading '%s'" %name)
		
		# Set texture's brush. If user changed its file name, try with resource_name
		if name in texture_names or res.resource_name in texture_names:
			_terrain[name].surface_texture = res
		
		# Update size from the loaded mesh
		elif name == "terrain_mesh":
			_terrain.mesh = res
			_terrain.map_size = res.size
		
		# Update from loaded gras mesh
		elif name == "grass_mesh":
			_terrain.grass_mesh = res
		
		# Use another material
		_terrain.terrain_mesh.material = load("res://addons/terra_brush/materials/terrain_mat.tres").duplicate()
		_terrain.terrain_mesh.material.set_shader_parameter("terrain_color", _terrain.terrain_color.surface_texture)
		_terrain.terrain_mesh.material.set_shader_parameter("terrain_height", _terrain.terrain_height.surface_texture)
		
		file_name = dir.get_next()
	await _notif_end()


# Saves all relevant resources into a external folder so you can safetly exit or make different versions
func _save(show_end_notif:bool = true):
	# Igore if already saving
	if _notif_label.is_visible():
		return
	
	var folder:String = _terrain.assets_folder
	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_absolute(folder)
	
	# Copy textures. This might take some time
	# Needs to load them again so we have a reference to the new updated file in FileSystem
	var brushes:Array[TBrush] = [_terrain.grass_spawn, _terrain.grass_color, _terrain.terrain_color, _terrain.terrain_height]
	for brush in brushes:
		await _notif('Saving "%s"..'%brush.resource_name)
		var destination_path:String = folder.path_join(brush.resource_name + ".tres")
		ResourceSaver.save(brush.surface_texture, destination_path)
		brush.surface_texture = load(destination_path)
	
	# Setup a new Terrain Mesh, Material, and Shader
	# Use the _terrain shader that doesn't have the brush overlay
	await _notif("Saving Terrain Mesh..")
	var terrain_mesh:PlaneMesh = _terrain.terrain_mesh.duplicate()
	var terrain_mat := ShaderMaterial.new()
	terrain_mat.shader = load("res://addons/terra_brush/shaders/terrain_shader.gdshader").duplicate()
	terrain_mat.set_shader_parameter("terrain_color", _terrain.terrain_color.surface_texture)
	terrain_mat.set_shader_parameter("terrain_height", _terrain.terrain_height.surface_texture)
	terrain_mesh.material = terrain_mat
	var destination_path:String = _get_destination_from_res_path(_terrain.terrain_mesh)
	ResourceSaver.save(terrain_mesh, destination_path)
	
	# Change current terrain mesh from now on
	_terrain.terrain_mesh = load(destination_path)
	
	
	# Setup a new Grass Mesh, Material, and Shader
	# Here we can duplicate everything. But not deep-duplicate so the textures doesn't get pulled again
	await _notif("Saving Grass Mesh..")
	var grass_mesh:QuadMesh = _terrain.grass_mesh.duplicate()
	grass_mesh.material = _terrain.grass_mesh.material.duplicate()
	grass_mesh.material.shader = _terrain.grass_mesh.material.shader.duplicate()
	grass_mesh.material.set_shader_parameter("grass_color", _terrain.grass_color.surface_texture)
	grass_mesh.material.set_shader_parameter("terrain_color", _terrain.terrain_color.surface_texture)
	grass_mesh.material.set_shader_parameter("terrain_size", Vector2(_terrain.map_size))
	destination_path = _get_destination_from_res_path(_terrain.grass_mesh)
	ResourceSaver.save(grass_mesh, destination_path)
	var saved_mesh:QuadMesh = load(destination_path)
	
	# Change current grass mesh from now on
	_terrain.grass_mesh = saved_mesh
	
	if show_end_notif:
		await _notif_end()


func _generate_terrain():
	# Igore if already generating
	if _notif_label.is_visible():
		return
	
	await _save(false)
	await _notif("Generating References..")
	
	# Create a new _terrain node beside the TherraBrush node
	var generated_terrain:MeshInstance3D = load("res://addons/terra_brush/Scenes/terrain_template.tscn").instantiate()
	_terrain.add_sibling(generated_terrain)
	generated_terrain.owner = _terrain.owner
	generated_terrain.name = "Generated Terrain"
	
	await _notif_end()


# Uses the resource_name from the original resource to build a new destination path
func _get_destination_from_res_path(res:Resource) -> String:
	return _terrain.assets_folder.path_join(res.resource_path.get_file())


# Prints a notification in inspector. Needs to be awaited so the editor doesn't get stuck and crash for long processes
func _notif(msg:String):
	_notif_label.show()
	_notif_label.text = msg
	await _tree.process_frame
func _notif_end(msg:String="Done!"):
	_notif_label.show()
	_notif_label.text = msg
	await _tree.create_timer(2.0).timeout
	_notif_label.hide()
