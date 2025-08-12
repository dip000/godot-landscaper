@tool
extends Action
class_name ActionMMIColor

var _mmi:MultiMeshInstance3D


func start(tool:LandscaperTool, project:SaveData, configs:ConfigsInstance):
	super(tool, project, configs)
	var index:int = project.grass_configs.find(configs)
	
	if configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its Node name" %[index,index])
		configs.resource_name = "Grass %s" %index
	
	var parent:Node = tool.get_node( tool.parent_node )
	_mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, parent, configs.resource_name)
	
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
	
	Landscaper.undo_redo.add_undo_method( self, "restore", _configs.top_colors.duplicate() )


func primary(hit_info:Dictionary):
	_spawn( hit_info, _instancer.primary_color )


func secondary(hit_info:Dictionary):
	_spawn( hit_info, _instancer.secondary_color )


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
		
