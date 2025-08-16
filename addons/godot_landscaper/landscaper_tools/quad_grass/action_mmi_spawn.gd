@tool
extends Action
class_name ActionMMISpawn

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
	
	# More safety checks
	if not _configs.grass_texture:
		GLDebug.warning("No Grass Texture is selected for '%s'" %_configs.resource_name)
	
	if is_zero_approx( _configs.size_base.x*_configs.size_base.y*_configs.size_base.z ):
		GLDebug.warning("Grass volume is zero. Used Vector3.ONE")
		_configs.size_base = Vector3.ONE
		
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		rebuild()
	
	# Setup ground_coloring configs
	match _tool.ground_coloring:
		QuadGrassTool.GroundColoring.SCAN_FROM_SELECTTION:
			if not _tool.ground_texture or not _tool.ground_mesh:
				GLDebug.error("No Mesh or Texture Assigned. Assign your ground references or change ground coloring")
				return
			_mmi.global_position = _tool.ground_mesh.global_position
		QuadGrassTool.GroundColoring.SCAN_FROM_AUTO_DETECT:
			if not try_scan_for_mesh(hit_info):
				GLDebug.error("Auto detect mesh did not found any mesh. Select your references manually from 'Ground Coloring' section")
				return
			if not try_scan_for_texture():
				GLDebug.error("Auto detect texture did not found texture in Mesh. Select your references manually from 'Ground Coloring' section")
				return
			_mmi.global_position = hit_info.collider.global_position


func try_scan_for_mesh(hit_info:Dictionary) -> bool:
	var collider:CollisionObject3D = hit_info.collider
	var hit_parent:Node = collider.get_parent()
	if hit_parent is MeshInstance3D:
		_tool.ground_mesh = hit_parent
	else:
		for node in collider.get_children():
			if node is MeshInstance3D:
				_tool.ground_mesh = node
				break
	if not _tool.ground_mesh:
		return false
	return true

func try_scan_for_texture() -> bool:
	var mesh:MeshInstance3D = _tool.ground_mesh
	var material:Material = mesh.get_active_material(0)
	if not material:
		return false
	if material is StandardMaterial3D and material.albedo_texture:
		_tool.ground_texture = material.albedo_texture
		return true
	if material is ShaderMaterial and material.get_shader_parameter("texture"):
		_tool.ground_texture = material.albedo_texture
		return true
	return false


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
	var object_world_position:Vector3 = hit_info.collider.global_position
	var brush_radius_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	_configs.transforms.clear()
	_configs.bottom_colors.clear()
	_configs.top_colors.clear()
	
	for i in _mmi.multimesh.instance_count:
		var instance_transform:Transform3D =  _mmi.multimesh.get_instance_transform(i)
		var instance_world_pos:Vector3 = instance_transform.origin + object_world_position
		var dist_sqr:float = instance_world_pos.distance_squared_to( mouse_world_pos )
		
		if dist_sqr > brush_radius_sqr or _tool.erase_ratio < randf():
			_configs.transforms.append( instance_transform )
			_configs.bottom_colors.append(  _mmi.multimesh.get_instance_color(i) )
			_configs.top_colors.append(  _mmi.multimesh.get_instance_custom_data(i) )


func _add_radial(hit_info:Dictionary):
	var brush_radius:float = Landscaper.scene.brush.get_scale_ratio()*0.5
	var object_world_position:Vector3 = hit_info.collider.global_position
	var mouse_world_pos:Vector3 = hit_info.position
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in range(_tool.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_surface1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_surface2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		# Add transforms for every surface found
		var result:Dictionary = raycaster.point_to_point(sphere_surface1, sphere_surface2)
		if result:
			var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
			var transf := Transform3D( basis, result.position - object_world_position )
			var size_offset:Vector3 = _configs.size_randomize * _randv(0, 1)
			
			transf = transf.scaled_local( _configs.size_base + size_offset)
			transf = transf.rotated_local(Vector3.FORWARD, randf()*_configs.rotation_randomize.y )
			transf = transf.rotated_local(Vector3.RIGHT, randf()*_configs.rotation_randomize.x )
			transf = transf.rotated_local(Vector3.UP, randf()*_configs.rotation_randomize.z )
			_configs.transforms.append( transf )
			
			var color:Color = _scan_color( result.face_index, result.position, object_world_position )
			_configs.bottom_colors.append( color )
			_configs.top_colors.append( Color.WHITE )



func _scan_color(face_index:int, cursor:Vector3, surface_position:Vector3) -> Color:
	match _tool.ground_coloring:
		QuadGrassTool.GroundColoring.CONSTANT_COLOR:
			return _tool.ground_color
		QuadGrassTool.GroundColoring.PAINT_WITH_SECONDARY:
			return _tool.secondary_color
		_:
			if not _tool.ground_mesh or not _tool.ground_texture:
				return Color.GRAY
	
	var mesh_arrays:Array = _tool.ground_mesh.mesh.surface_get_arrays(0)
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
	var cursor_world_local:Vector3 = cursor - surface_position
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords(cursor_world_local, xy[0], xy[1], xy[2])
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	# Find color from that coordinate
	var texture:Texture2D = _tool.ground_texture
	var size:Vector2 = texture.get_size()-Vector2.ONE
	var img:Image = texture.get_image()
	var px:Color = img.get_pixelv( cursor_texture*size )
	
	GLDebug.spam("Scanned color: [color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px
	
