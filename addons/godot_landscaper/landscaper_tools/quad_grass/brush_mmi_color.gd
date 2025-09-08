@tool
extends Brush
class_name ActionMMIColor

var _mmi:MultiMeshInstance3D



func unpack(tool:LandscaperTool, project:SaveData, configs:InstanceConfigs):
	super(tool, project, configs)
	
	# Rename resource
	if _configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its name. This will be its Node name in the scene" %[_configs.instance_index,_configs.instance_index])
		_configs.resource_name = "Grass %s" %configs.instance_index
	
	_mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, _tool.anchor_node, _configs.resource_name)
	
	if not _mmi.multimesh:
		_mmi.multimesh = MultiMesh.new()
		_mmi.multimesh.use_colors = true
		_mmi.multimesh.use_custom_data = true
		_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Force assign refs just in case
	_mmi.multimesh.mesh = _configs.mesh
	_mmi.set_instance_shader_parameter("variant_index", _configs.instance_index)


func clear():
	_mmi = _tool.anchor_node.get_node_or_null(_configs.resource_name)
	if is_instance_valid(_mmi):
		_mmi.queue_free()

func start(hit_info:Dictionary):
	# Rename resource
	if _configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its name. This will be its Node name in the scene" %[_configs.instance_index,_configs.instance_index])
		_configs.resource_name = "Grass %s" %_configs.instance_index
	
	# Set up null multimesh
	if not _mmi.multimesh:
		_mmi.multimesh = MultiMesh.new()
		_mmi.multimesh.use_colors = true
		_mmi.multimesh.use_custom_data = true
		_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Force assign refs just in case
	_mmi.multimesh.mesh = _configs.mesh
	_mmi.set_instance_shader_parameter("variant_index", _configs.instance_index)
	
	# Rebuild with the stored data
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		rebuild()
	



func primary(hit_info:Dictionary):
	_paint( hit_info, _tool.primary_color, false )


func secondary(hit_info:Dictionary):
	_paint( hit_info, _tool.secondary_color, true )


func _paint(hit_info:Dictionary, color:Color, secondary:bool):
	var brush_size_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var mm:MultiMesh = _mmi.multimesh
	
	# Re-Colors the grass from the current transforms
	for i in mm.instance_count:
		var transf:Transform3D = mm.get_instance_transform( i )
		var instance_world_pos:Vector3 = _mmi.to_global( transf.origin )
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		if dist_sqr < brush_size_sqr:
			if secondary and _tool.paint_with_sencondary_color:
				mm.set_instance_color( i, color )
				_configs.bottom_colors[i] = color
			else:
				mm.set_instance_custom_data( i, color )
				_configs.top_colors[i] = color



func rebuild():
	var mm:MultiMesh = _mmi.multimesh
	mm.instance_count = _configs.transforms.size()
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, _configs.transforms[i] )
		mm.set_instance_color( i, _configs.bottom_colors[i] )
		mm.set_instance_custom_data( i, _configs.top_colors[i] )
	
