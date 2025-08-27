@tool
extends Action
class_name ActionMMISpawn

var _mmi:MultiMeshInstance3D
var _index:int


func unpack(tool:LandscaperTool, project:SaveData, configs:InstanceConfigs):
	super(tool, project, configs)
	
	# What variant instance is this config
	_index = _project.grass_configs.find(_configs)
	
	# Rename resource
	if _configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its Node name" %[_index,_index])
		_configs.resource_name = "Grass %s" %_index
	
	_mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, _tool.ground_mesh, _configs.resource_name)
	
	if not _mmi.multimesh:
		_mmi.multimesh = MultiMesh.new()
		_mmi.multimesh.use_colors = true
		_mmi.multimesh.use_custom_data = true
		_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Force assign refs just in case
	_mmi.multimesh.mesh = _project.mesh
	_mmi.set_instance_shader_parameter("variant_index", _index)


func start(hit_info:Dictionary):
	# More safety checks
	if is_zero_approx( _configs.size_base.x*_configs.size_base.y*_configs.size_base.z ):
		GLDebug.warning("Grass volume is zero. Used Vector3.ONE")
		_configs.size_base = Vector3.ONE
		
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		rebuild()
	
	# Start with new references in case they were updated
	Scanner.clear_cache()


# Spawn
func primary(hit_info:Dictionary):
	_add_radial( hit_info )
	rebuild()


# Despawn
func secondary(hit_info:Dictionary):
	_get_remove_radial( hit_info )
	rebuild()



# Re-Spawns the grass from the transforms given
func rebuild():
	var mm:MultiMesh = _mmi.multimesh
	mm.instance_count = _configs.transforms.size()
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, _configs.transforms[i] )
		mm.set_instance_color( i, _configs.bottom_colors[i] )
		mm.set_instance_custom_data( i, _configs.top_colors[i] )


func end():
	Scanner.clear_cache()


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(hit_info:Dictionary):
	var brush_radius_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var mm:MultiMesh = _mmi.multimesh
	_configs.transforms.clear()
	_configs.bottom_colors.clear()
	_configs.top_colors.clear()
	
	for i in mm.instance_count:
		var instance_transform:Transform3D = mm.get_instance_transform(i)
		var instance_world_pos:Vector3 = _mmi.to_global( instance_transform.origin )
		var dist_sqr:float = instance_world_pos.distance_squared_to( mouse_world_pos )
		
		if dist_sqr > brush_radius_sqr or _tool.erase_ratio < randf():
			_configs.transforms.append( instance_transform )
			_configs.bottom_colors.append(  mm.get_instance_color(i) )
			_configs.top_colors.append(  mm.get_instance_custom_data(i) )


func _add_radial(hit_info:Dictionary):
	var brush_radius:float = Landscaper.scene.brush.get_scale_ratio()*0.5
	var mouse_world_pos:Vector3 = hit_info.position
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in range(_tool.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_global_point1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_global_point2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		var result:Dictionary = raycaster.point_to_point(sphere_global_point1, sphere_global_point2)
		if not result:
			continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		
		# to_local() takes rotation and scale in consideration
		var local_pos:Vector3 = _mmi.to_local( result.position )
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = _configs.size_randomize * _randv(0, 1)
		
		local_transf = local_transf.scaled_local( _configs.size_base + size_offset )
		local_transf = local_transf.rotated_local( Vector3.FORWARD, randf()*_configs.rotation_randomize.y )
		local_transf = local_transf.rotated_local( Vector3.RIGHT, randf()*_configs.rotation_randomize.x )
		local_transf = local_transf.rotated_local( Vector3.UP, randf()*_configs.rotation_randomize.z )
		_configs.transforms.append( local_transf )
		
		# Save colors
		var color:Color = Scanner.get_cached_color( result, _tool )
		_configs.bottom_colors.append( color )
		_configs.top_colors.append( Color.WHITE )


func rescan_position_y(scan_range:float):
	GLDebug.state("Rescaning is disabled right now sorry :P")
	return
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	var original_size:int = _configs.transforms.size()
	var original_top_colors:Array[Color] = _configs.top_colors
	var original_bottom_colors:Array[Color] = _configs.bottom_colors
	var new_transforms:Array[Transform3D]
	var new_bottom_colors:Array[Color]
	var new_top_colors:Array[Color]
	
	for i in original_size:
		var original_transf:Transform3D = _configs.transforms[i]
		var scan_upper:Vector3 = _mmi.to_global( original_transf.origin )
		var scan_lower:Vector3 = scan_upper
		scan_upper.y += scan_range
		scan_lower.y -= scan_range
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result:
			continue
		
		# WORK DAMNIT!!
		Scanner.cache_colliders( result, _tool )
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		
		# to_local() takes rotation in consideration. Then feed back to result as global for color scaning
		var local_pos:Vector3 = _mmi.to_local( result.position )
		result.position = local_pos + _tool.ground_mesh.global_position
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = _configs.size_randomize * _randv(0, 1)
		
		local_transf = local_transf.scaled_local( _configs.size_base + size_offset )
		local_transf = local_transf.rotated_local( Vector3.FORWARD, randf()*_configs.rotation_randomize.y )
		local_transf = local_transf.rotated_local( Vector3.RIGHT, randf()*_configs.rotation_randomize.x )
		local_transf = local_transf.rotated_local( Vector3.UP, randf()*_configs.rotation_randomize.z )
		
		new_transforms.append( local_transf )
		new_bottom_colors.append( original_bottom_colors[i] )
		new_top_colors.append( original_top_colors[i] )
	
	_configs.top_colors = new_top_colors
	_configs.bottom_colors = new_bottom_colors
	_configs.transforms = new_transforms
	_mmi.global_position = _tool.ground_mesh.global_position
	
	var new_size:int = _configs.transforms.size()
	var lost_instances:int = original_size - new_size
	GLDebug.state("Grass was repositioned in Y axis. %s instances were lost" %lost_instances)


func rescan_bottom_colors(scan_range:float):
	GLDebug.state("Recoloring is disabled right now sorry :P")
	return
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in _configs.transforms.size():
		var original_transf:Transform3D = _configs.transforms[i]
		var global_position:Vector3 = _mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position
		var scan_lower:Vector3 = global_position
		scan_upper.y += scan_range
		scan_lower.y -= scan_range
		
		# WORK DAMNIT!!
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		_configs.bottom_colors[i] = Scanner.get_cached_color( result, _tool )
	
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings")
