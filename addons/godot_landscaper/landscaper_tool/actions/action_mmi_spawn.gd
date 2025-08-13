@tool
extends Action
class_name ActionMMISpawn

var _mmi:MultiMeshInstance3D
var _scan_texture:Texture2D


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
	
	if is_zero_approx( configs.size_base.x*configs.size_base.y*configs.size_base.z ):
		GLDebug.warning("Grass volume is zero. Used Vector3.ONE")
		configs.size_base = Vector3.ONE
		
	if _configs.transforms.size() != _mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		_spawn()
	
	Landscaper.undo_redo.add_undo_method( self, "restore",
		_configs.top_colors.duplicate(),
		_configs.bottom_colors.duplicate(),
		_configs.transforms.duplicate(),
	)


# Spawn
func primary(hit_info:Dictionary):
	_add_radial( hit_info )
	_spawn()


# Despawn
func secondary(hit_info:Dictionary):
	_get_remove_radial( hit_info )
	_spawn()


func end():
	Landscaper.undo_redo.add_do_method( self, "restore",
		 _configs.top_colors.duplicate(),
		_configs.bottom_colors.duplicate(),
		_configs.transforms.duplicate(),
	)


func restore(top_colors:Array[Color], bottom_colors:Array[Color], transforms:Array[Transform3D]):
	_configs.top_colors = top_colors
	_configs.bottom_colors = bottom_colors
	_configs.transforms = transforms
	_spawn()


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


# Re-Spawns the grass from the transforms given
func _spawn():
	_mmi.multimesh.instance_count = _configs.transforms.size()
	for i in range(_mmi.multimesh.instance_count):
		_mmi.multimesh.set_instance_transform( i, _configs.transforms[i] )
		_mmi.multimesh.set_instance_color( i, _configs.bottom_colors[i] )
		_mmi.multimesh.set_instance_custom_data( i, _configs.top_colors[i] )


func _scan_color(face_index:int, cursor:Vector3, surface_position:Vector3) -> Color:
	var mesh_arrays:Array = _tool.surface_mesh.mesh.surface_get_arrays(0)
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
	var texture:Texture2D = _tool.surface_texture
	if not texture:
		GLDebug.error("Could not scan surface texture")
		return Color.GRAY
	var size:Vector2 = texture.get_size()-Vector2.ONE
	var img:Image = texture.get_image()
	if not img:
		GLDebug.error("Could not scan surface texture")
		return Color.GRAY
	var px:Color = img.get_pixelv( cursor_texture*size )
	
	GLDebug.spam("Scanned color: [color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px
	
