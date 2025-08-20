@tool
extends Action
class_name ActionMMISpawn

var _mmi:MultiMeshInstance3D
var _scanned_colliders:Dictionary[CollisionObject3D, Dictionary]
var _index:int


func unpack(tool:LandscaperTool, project:SaveData, configs:InstanceConfigs):
	super(tool, project, configs)
	_mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, _tool.ground_mesh, _configs.resource_name)
	
	if not _mmi.multimesh:
		_mmi.multimesh = MultiMesh.new()
		_mmi.multimesh.use_colors = true
		_mmi.multimesh.use_custom_data = true
		_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# What variant instance is this config
	_index = _project.grass_configs.find(_configs)
	# Force assign refs just in case
	_mmi.multimesh.mesh = _project.mesh
	_mmi.set_instance_shader_parameter("variant_index", _index)


func start(hit_info:Dictionary):
	# Rename resource
	if _configs.resource_name.is_empty():
		GLDebug.warning("'Grass %s' doesn't have a resource_name. Using 'Grass %s' as its Node name" %[_index,_index])
		_configs.resource_name = "Grass %s" %_index
	
	# More safety checks
	if is_zero_approx( _configs.size_base.x*_configs.size_base.y*_configs.size_base.z ):
		GLDebug.warning("Grass volume is zero. Used Vector3.ONE")
		_configs.size_base = Vector3.ONE
		
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		rebuild()
	

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
	_mmi.multimesh.instance_count = _configs.transforms.size()
	for i in range(_mmi.multimesh.instance_count):
		_mmi.multimesh.set_instance_transform( i, _configs.transforms[i] )
		_mmi.multimesh.set_instance_color( i, _configs.bottom_colors[i] )
		_mmi.multimesh.set_instance_custom_data( i, _configs.top_colors[i] )
	


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(hit_info:Dictionary):
	var brush_radius_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	_configs.transforms.clear()
	_configs.bottom_colors.clear()
	_configs.top_colors.clear()
	
	for i in _mmi.multimesh.instance_count:
		var instance_transform:Transform3D = _mmi.multimesh.get_instance_transform(i)
		var instance_world_pos:Vector3 = _mmi.to_global( instance_transform.origin )
		var dist_sqr:float = instance_world_pos.distance_squared_to( mouse_world_pos )
		
		if dist_sqr > brush_radius_sqr or _tool.erase_ratio < randf():
			_configs.transforms.append( instance_transform )
			_configs.bottom_colors.append(  _mmi.multimesh.get_instance_color(i) )
			_configs.top_colors.append(  _mmi.multimesh.get_instance_custom_data(i) )


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
		_configs.transforms.append( local_transf )
		
		# Scan color. Color source is either a constant or a texture
		var color:Color = _tool.fallback_color
		if _tool.paint_with_sencondary_color:
			color = _tool.secondary_color
		
		else:
			var collider:CollisionObject3D = result.collider
			var instance:MeshInstance3D = SceneManager.scan_mesh( collider, _tool.parent_of_physics_body, _tool.children_of_physics_body, _tool.relative_path_from_physics_body )
			var material:Material = SceneManager.scan_material( instance, _tool.active_material_indexes )
			var color_source:Variant = SceneManager.scan_color_source( material, _tool.paths_in_standar_materials, _tool.paths_in_shader_materials )
			
			if color_source is Color:
				color = color_source
			elif color_source is Texture2D:
				color = _scan_color( result, color_source, instance.mesh )
		
		# Save colors
		_configs.bottom_colors.append( color )
		_configs.top_colors.append( Color.WHITE )


func _scan_color(hit_info:Dictionary, texture:Texture2D, mesh:Mesh) -> Color:
	var face_index:int = hit_info.face_index
	var mouse_world_position:Vector3 = hit_info.position
	var collider_world_position:Vector3 = hit_info.collider.global_position
	var mouse_local_position:Vector3 = mouse_world_position - collider_world_position
	
	var mesh_arrays:Array = mesh.surface_get_arrays(0)
	var arr_mesh := ArrayMesh.new()
	var mdt := MeshDataTool.new()
	
	# Setup MeshDataTool from the current mesh
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	mdt.create_from_surface( arr_mesh, 0 )
	
	# Get vertex coordinates of raycasted trangled-face using MeshDataTool magic
	var xy:Array[Vector3] #World-space
	var uv:Array[Vector2] #Texture-space
	for i in range(3):
		var idx:int = mdt.get_face_vertex( face_index, i )
		xy.append( mdt.get_vertex(idx) )
		uv.append( mdt.get_vertex_uv(idx) )
	
	# Find the cursor point coordinates of the texture-space using the triangle points
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords(mouse_local_position, xy[0], xy[1], xy[2])
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	# Find color from that coordinate
	var size:Vector2 = texture.get_size()-Vector2.ONE
	var img:Image = texture.get_image() #this might lag a bit, a lot maybe hehe
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	var px:Color = img.get_pixelv( cursor_texture*size )
	GLDebug.spam("Scanned color: [color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px
	

func rescan_position_y(scan_range:float):
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
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		
		# Save base and random values
		var local_pos:Vector3 = _mmi.to_local( result.position )
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
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in _configs.transforms.size():
		var original_transf:Transform3D = _configs.transforms[i]
		var scan_upper:Vector3 = _mmi.to_global( original_transf.origin )
		var scan_lower:Vector3 = scan_upper
		scan_upper.y += scan_range
		scan_lower.y -= scan_range
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result:
			continue
		
		# Scan color. Color source is either a constant or a texture
		var color:Color = _tool.fallback_color
		if _tool.paint_with_sencondary_color:
			color = _tool.secondary_color
		
		else:
			var collider:CollisionObject3D = result.collider
			var instance:MeshInstance3D = SceneManager.scan_mesh( collider, _tool.parent_of_physics_body, _tool.children_of_physics_body, _tool.relative_path_from_physics_body )
			var material:Material = SceneManager.scan_material( instance, _tool.active_material_indexes )
			var color_source:Variant = SceneManager.scan_color_source( material, _tool.paths_in_standar_materials, _tool.paths_in_shader_materials )
			
			if color_source is Color:
				color = color_source
			elif color_source is Texture2D:
				color = _scan_color( result, color_source, instance.mesh )
		
		_configs.bottom_colors[i] = color
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings")
