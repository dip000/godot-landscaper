@tool
extends Brush
class_name ActionMMISpawn

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
		
		# Await a frame if the cache was newly created so it can be re-scanned
		var cache:Scanner.Cache = Scanner.cache_scan( result.collider, _tool, true )
		if cache.new:
			await Engine.get_main_loop().process_frame
			result = raycaster.point_to_point(sphere_global_point1, sphere_global_point2)
			if not result:
				continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		# This will actually make the grass "look" up at the sky instead of standing at 90°
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		
		# Compose rotation using quaternion magic
		basis *= Basis(
			# PI*0.5 on X axis compenzates for looking at the sky as mentioned before
			Quaternion(Vector3.RIGHT, _configs.rotation_base.x - PI * 0.5) *
			Quaternion(Vector3.UP, _configs.rotation_base.y) *
			Quaternion(Vector3.FORWARD, _configs.rotation_base.z) *
			Quaternion(Vector3.RIGHT, randf()*_configs.rotation_randomize.x) *
			Quaternion(Vector3.UP, randf()*_configs.rotation_randomize.y) *
			Quaternion(Vector3.FORWARD, randf()*_configs.rotation_randomize.z)
		)
		
		# to_local() takes rotation and scale in consideration
		var local_pos:Vector3 = _mmi.to_local( result.position )
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = _configs.size_randomize * _randv(0, 1)
		
		local_transf = local_transf.scaled_local( _configs.size_base + size_offset )
		_configs.transforms.append( local_transf )
		
		# Save colors. Use cached colors for performance
		var color:Color = Scanner.scan_color( result, cache )
		_configs.bottom_colors.append( color )
		_configs.top_colors.append( _tool.primary_color )
