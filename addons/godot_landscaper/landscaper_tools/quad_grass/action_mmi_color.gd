@tool
extends Action
class_name ActionMMIColor

var _mmi:MultiMeshInstance3D


func unpack(tool:LandscaperTool, project:SaveData, configs:InstanceConfigs):
	super(tool, project, configs)
	_mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, _tool.parent_node, _configs.resource_name)


func start(hit_info:Dictionary):
	# What variant instance is this config
	var index:int = _project.grass_configs.find(_configs)
	
	# Rename resource
	if _configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its Node name" %[index,index])
		_configs.resource_name = "Grass %s" %index
	
	# Set up null multimesh
	if not _mmi.multimesh:
		_mmi.multimesh = MultiMesh.new()
		_mmi.multimesh.use_colors = true
		_mmi.multimesh.use_custom_data = true
		_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Force assign refs just in case
	_mmi.multimesh.mesh = _project.mesh
	_mmi.set_instance_shader_parameter("variant_index", index)
	_project.material["shader_parameter/details_enable"][index] = int(_configs.detail_enable)
	_project.material["shader_parameter/detail_colors"][index] = _configs.detail_color
	_project.material["shader_parameter/grass_textures"][index] = _configs.grass_texture
	
	if not _configs.grass_texture:
		GLDebug.warning("No Grass Texture is selected for '%s'" %_configs.resource_name)
	
	# Rebuild with the stored data
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		rebuild()
	



func primary(hit_info:Dictionary):
	var brush_size_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var object_world_position:Vector3 = hit_info.collider.global_position
	var color:Color = _tool.primary_color
	
	# Re-Colors the grass from the current transforms
	for i in _mmi.multimesh.instance_count:
		var transf:Transform3D = _mmi.multimesh.get_instance_transform( i )
		var instance_world_pos:Vector3 = transf.origin + object_world_position
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		if dist_sqr < brush_size_sqr:
			_mmi.multimesh.set_instance_custom_data( i, color )
			_configs.top_colors[i] = color


func secondary(hit_info:Dictionary):
	var brush_size_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var object_world_position:Vector3 = hit_info.collider.global_position
	var color:Color = _tool.secondary_color
	
	# Re-Colors the grass from the current transforms
	for i in _mmi.multimesh.instance_count:
		var transf:Transform3D = _mmi.multimesh.get_instance_transform( i )
		var instance_world_pos:Vector3 = transf.origin + object_world_position
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		if dist_sqr < brush_size_sqr:
			if _tool.ground_coloring == QuadGrassTool.GroundColoring.PAINT_WITH_SECONDARY:
				_mmi.multimesh.set_instance_color( i, color )
				_configs.bottom_colors[i] = color
			else:
				_mmi.multimesh.set_instance_custom_data( i, color )
				_configs.top_colors[i] = color


func rebuild():
	_mmi.multimesh.instance_count = _configs.transforms.size()
	for i in range(_mmi.multimesh.instance_count):
		_mmi.multimesh.set_instance_transform( i, _configs.transforms[i] )
		_mmi.multimesh.set_instance_color( i, _configs.bottom_colors[i] )
		_mmi.multimesh.set_instance_custom_data( i, _configs.top_colors[i] )
	
