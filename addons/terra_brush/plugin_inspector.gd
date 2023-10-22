extends EditorInspectorPlugin

const DESTINATION_ROOT := "res://terra_brush"
var instanced_tool:TerraBrush
var notif:Label
var tree:SceneTree


func _init(scene_tree:SceneTree):
	tree = scene_tree

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
	btn_quit.tooltip_text = "Creates a new terrain cutting all plugin tools and dependencies. Ready for gameplay!"
	btn_quit.pressed.connect(_generate_terrain)
	
	var sep := HSeparator.new()
	var cont := VBoxContainer.new()
	cont.add_child(btn_save)
	cont.add_child(btn_quit)
	cont.add_child(notif)
	cont.add_child(sep)
	
	add_custom_control(cont)

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	return not [
		"brush_scale",
		"map_size",
		"terrain_color",
		"terrain_height",
		"grass_color",
		"grass_spawn",
	].any(func(n): return n == name)

func _can_handle(object):
	if object is TerraBrush:
		instanced_tool = object
		return true
	else:
		return false


func _save(show_end_notif:bool = true):
	if not DirAccess.dir_exists_absolute(DESTINATION_ROOT):
		DirAccess.make_dir_absolute(DESTINATION_ROOT)
	
	var brushes:Array[TBrush] = [instanced_tool.grass_spawn, instanced_tool.grass_color, instanced_tool.terrain_color, instanced_tool.terrain_height]
	for brush in brushes:
		var destination_path:String = _get_destination_path(brush.surface_texture)
		if brush.texture_updated or not FileAccess.file_exists(destination_path):
			await _notif("Saving %s.."%brush.surface_texture.resource_path.get_file())
			ResourceSaver.save(brush.surface_texture, destination_path)
			brush.surface_texture = load(destination_path)
	
	await _notif("Saving Terrain Mesh..")
	var terrain_mesh:PlaneMesh = instanced_tool.TERRAIN_MESH.duplicate()
	var terrain_mat := ShaderMaterial.new()
	terrain_mat.shader = load("res://addons/terra_brush/shaders/terrain.gdshader").duplicate()
	terrain_mat.set_shader_parameter("terrain_color", brushes[2].surface_texture)
	terrain_mat.set_shader_parameter("terrain_height", brushes[3].surface_texture)
	terrain_mesh.material = terrain_mat
	var destination_path := _get_destination_path(instanced_tool.TERRAIN_MESH)
	ResourceSaver.save(terrain_mesh, destination_path)
	
	await _notif("Saving Grass Mesh..")
	var grass_mesh:QuadMesh = instanced_tool.GRASS_MESH.duplicate()
	var grass_mat:ShaderMaterial = instanced_tool.GRASS_MAT.duplicate()
	grass_mat.shader = instanced_tool.GRASS_MAT.shader.duplicate()
	grass_mat.set_shader_parameter("grass_color", brushes[1].surface_texture)
	grass_mat.set_shader_parameter("terrain_color", brushes[2].surface_texture)
	grass_mat.set_shader_parameter("terrain_size", instanced_tool.map_size)
	grass_mesh.material = grass_mat
	destination_path = _get_destination_path(instanced_tool.GRASS_MESH)
	ResourceSaver.save(grass_mesh, destination_path)
	var saved_mesh := load(destination_path)
	
	for child in instanced_tool.get_children():
		if child is MultiMeshInstance3D:
			child.multimesh.mesh = saved_mesh
	
	if show_end_notif:
		await _notif_end()

func _generate_terrain():
	await _save(false)
	await _notif("Generating References..")
	
	var destination_file:String = _get_destination_path(instanced_tool.TERRAIN_MESH)
	var new := MeshInstance3D.new()
	new.mesh =  load(destination_file)
	instanced_tool.add_sibling(new)
	new.owner = instanced_tool.owner
	new.name = "Generated Terrain"
	
	await _notif("Generating Nodes..")
	
	for child in instanced_tool.get_children():
		var child_dup := child.duplicate()
		new.add_child( child_dup )
		child_dup.owner = instanced_tool.owner
		if child_dup.name == TerraBrush.BODY_NAME:
			var grandchild := child_dup.get_node(TerraBrush.HEIGHT_COLLIDER_NAME).duplicate()
			child_dup.add_child( grandchild )
			grandchild.name = TerraBrush.HEIGHT_COLLIDER_NAME
			grandchild.owner = instanced_tool.owner
	
	await _notif_end()


func _get_destination_path(res:Resource) -> String:
	return DESTINATION_ROOT.path_join(res.resource_path.get_file())

func _notif(msg:String):
	notif.show()
	notif.text = msg
	await tree.process_frame

func _notif_end():
	notif.show()
	notif.text = "Done!"
	await tree.create_timer(2.0)
	notif.hide()
