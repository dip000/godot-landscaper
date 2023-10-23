extends EditorInspectorPlugin

const DESTINATION_ROOT := "res://terra_brush"
var _terrain:TerraBrush
var notif:Label
var tree:SceneTree


# Start with a SceneTree reference from "plugin_terra_brush.gd" for notifications and delays
func _init(scene_tree:SceneTree):
	tree = scene_tree


# Creates "Save" and "Generate" buttons in inspector
func _parse_category(object, category):
	if category != "tool_terra_brush.gd":
		return
	
	notif = Label.new()
	notif.text = 'Saved successfully in "res://terra_brush/"'
	notif.hide()
	
	var btn_save := Button.new()
	btn_save.text = "Save Textures, Materials, Etc.."
	btn_save.tooltip_text = "It will save all used resources in 'res://terra_brush/'"
	btn_save.pressed.connect(_save)
	
	var btn_quit := Button.new()
	btn_quit.text = "Generate Terrain"
	btn_quit.tooltip_text = "Creates a new _terrain cutting all plugin tools and dependencies. Ready for gameplay!"
	btn_quit.pressed.connect(_generate_terrain)
	
	var sep := HSeparator.new()
	var cont := VBoxContainer.new()
	cont.add_child(btn_save)
	cont.add_child(btn_quit)
	cont.add_child(notif)
	cont.add_child(sep)
	
	add_custom_control(cont)

# Hides all irrelevant inspector properties. Specialy beacuse transforms aren't supported right now
func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	return not [
		"brush_scale",
		"map_size",
		"terrain_color",
		"terrain_height",
		"grass_color",
		"grass_spawn",
	].any(func(n): return n == name)


# Update TerraBrush tool from scene node
func _can_handle(object):
	if object is TerraBrush:
		_terrain = object
		return true
	else:
		return false

# Saves all relevant resources into a external folder so you can safetly exit or make different versions
func _save(show_end_notif:bool = true):
	if not DirAccess.dir_exists_absolute(DESTINATION_ROOT):
		DirAccess.make_dir_absolute(DESTINATION_ROOT)
	
	# Copy textures. This might take some time
	# Needs to load them again so we have a reference to the new updated file in FileSystem
	var brushes:Array[TBrush] = [_terrain.grass_spawn, _terrain.grass_color, _terrain.terrain_color, _terrain.terrain_height]
	for brush in brushes:
		await _notif('Saving "%s"..'%brush.resource_name)
		var destination_path:String = DESTINATION_ROOT.path_join(brush.resource_name + ".tres")
		ResourceSaver.save(brush.surface_texture, destination_path)
		brush.surface_texture = load(destination_path)
	
	# Setup a new Terrain Mesh, Material, and Shader
	# Use the _terrain shader that doesn't have the brush overlay
	await _notif("Saving Terrain Mesh..")
	var terrain_mesh:PlaneMesh = _terrain.mesh.duplicate()
	var terrain_mat := ShaderMaterial.new()
	terrain_mat.shader = load("res://addons/terra_brush/shaders/terrain_shader.gdshader").duplicate()
	terrain_mat.set_shader_parameter("terrain_color", _terrain.terrain_color.surface_texture)
	terrain_mat.set_shader_parameter("terrain_height", _terrain.terrain_height.surface_texture)
	terrain_mesh.material = terrain_mat
	var destination_path:String = _get_destination_from_res_path(_terrain.mesh)
	ResourceSaver.save(terrain_mesh, destination_path)
	
	# Change target mesh from now on
	_terrain.mesh = load(destination_path)
	
	
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
	
	# Change target mesh from now on
	_terrain.grass_mesh = saved_mesh
	
	
	# Independize all MultimeshInstance3D meshes as well
	for child in _terrain.get_children():
		if child is MultiMeshInstance3D:
			child.multimesh.mesh = saved_mesh
	
	if show_end_notif:
		await _notif_end()


func _generate_terrain():
	await _save(false)
	await _notif("Generating References..")
	
	# Create a new _terrain node beside the TherraBrush node
	var generated_terrain := MeshInstance3D.new()
	generated_terrain.mesh =  load( _get_destination_from_res_path(_terrain.mesh) )
	_terrain.add_sibling(generated_terrain)
	generated_terrain.owner = _terrain.owner
	generated_terrain.name = "Generated Terrain"
	
	await _notif("Generating Nodes..")
	
	# Copy all MultimeshInstance3D (grass)
	# But only copy the _terrain collider, the base collider was just for responsive brushing
	for child in _terrain.get_children():
		var child_dup := child.duplicate()
		generated_terrain.add_child( child_dup )
		child_dup.owner = _terrain.owner
		if child_dup.name == TerraBrush.BODY_NAME:
			var grandchild := child_dup.get_node(TerraBrush.HEIGHT_COLLIDER_NAME).duplicate()
			child_dup.add_child( grandchild )
			grandchild.name = TerraBrush.HEIGHT_COLLIDER_NAME
			grandchild.owner = _terrain.owner
	
	await _notif_end()


# Uses the resource_name from the original resource to build a new destination path
func _get_destination_from_res_path(res:Resource) -> String:
	return DESTINATION_ROOT.path_join(res.resource_path.get_file())

# Prints a notification in inspector. Needs to be awaited so the editor doesn't get stuck and crash for long processes
func _notif(msg:String):
	notif.show()
	notif.text = msg
	await tree.process_frame
func _notif_end():
	notif.show()
	notif.text = "Done!"
	await tree.create_timer(2.0)
	notif.hide()
