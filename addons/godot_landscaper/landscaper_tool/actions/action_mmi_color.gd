@tool
extends Action
class_name ActionMMIColor

var _mmi:MultiMeshInstance3D


func start(hit_info:Dictionary, tool:LandscaperTool, project:SaveData, configs:ConfigsInstance):
	super(hit_info, tool, project, configs)
	var index:int = project.grass_configs.find(configs)
	
	if configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its Node name" %[index,index])
		configs.resource_name = "Grass %s" %index
	
	_mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, tool.surface_mesh, configs.resource_name)
	_mmi.global_position = tool.surface_mesh.global_position
	
	if not _mmi.multimesh:
		_mmi.multimesh = MultiMesh.new()
		_mmi.multimesh.use_colors = true
		_mmi.multimesh.use_custom_data = true
		_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D

	_mmi.multimesh.mesh = project.mesh
	_mmi.set_instance_shader_parameter("variant_index", index)
	project.material["shader_parameter/details_enable"][index] = int(configs.detail_enable)
	project.material["shader_parameter/detail_colors"][index] = configs.detail_color
	project.material["shader_parameter/grass_textures"][index] = configs.grass_texture

	if not configs.grass_texture:
		GLDebug.warning("No Grass Texture is selected for '%s'" %configs.resource_name)
		
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		_rebuild()
	
	Landscaper.undo_redo.add_undo_method( self, "restore", _configs.top_colors.duplicate() )


func primary(hit_info:Dictionary):
	_spawn( hit_info, _tool.primary_color )


func secondary(hit_info:Dictionary):
	_spawn( hit_info, _tool.secondary_color )


func end():
	Landscaper.undo_redo.add_do_method( self, "restore", _configs.top_colors.duplicate() )
	super()


func restore(colors:Array[Color]):
	for i in _mmi.multimesh.instance_count:
		_mmi.multimesh.set_instance_custom_data( i, colors[i] )
		


# Re-Colors the grass from the current transforms
func _spawn(hit_info:Dictionary, color:Color):
	var brush_size_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var object_world_position:Vector3 = hit_info.collider.global_position
	
	for i in _mmi.multimesh.instance_count:
		var transf:Transform3D = _mmi.multimesh.get_instance_transform( i )
		var instance_world_pos:Vector3 = transf.origin + object_world_position
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		if dist_sqr < brush_size_sqr:
			_mmi.multimesh.set_instance_custom_data( i, color )
			_configs.top_colors[i] = color

func _rebuild():
	_mmi.multimesh.instance_count = _configs.transforms.size()
	for i in range(_mmi.multimesh.instance_count):
		_mmi.multimesh.set_instance_transform( i, _configs.transforms[i] )
		_mmi.multimesh.set_instance_color( i, _configs.bottom_colors[i] )
		_mmi.multimesh.set_instance_custom_data( i, _configs.top_colors[i] )
	
