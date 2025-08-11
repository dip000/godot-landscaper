@tool
extends Action
class_name ActionMMISpawn

var _mmi:MultiMeshInstance3D


func start(instancer:BaseInstancer, project:ProjectSaveData, configs:ConfigsInstance):
	super(instancer, project, configs)
	var parent_holder:Node = instancer.get_node( instancer.parent_node )
	_mmi = parent_holder.get_node( configs.resource_name )
	Landscaper.undo_redo.add_undo_method( self, "restore",
		 _project.top_colors.duplicate(),
		_project.bottom_colors.duplicate(),
		_project.transforms.duplicate(),
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
		 _project.top_colors.duplicate(),
		_project.bottom_colors.duplicate(),
		_project.transforms.duplicate(),
	)


func restore(top_colors:Array[Color], bottom_colors:Array[Color], transforms:Array[Transform3D]):
	_project.top_colors = top_colors
	_project.bottom_colors = bottom_colors
	_project.transforms = transforms
	_spawn()


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(hit_info:Dictionary):
	var object_world_position:Vector3 = hit_info.collider.global_position
	var brush_radius_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	_project.transforms.clear()
	_project.bottom_colors.clear()
	_project.top_colors.clear()
	
	for i in _mmi.multimesh.instance_count:
		var instance_transform:Transform3D =  _mmi.multimesh.get_instance_transform(i)
		var instance_world_pos:Vector3 = instance_transform.origin + object_world_position
		var dist_sqr:float = instance_world_pos.distance_squared_to( mouse_world_pos )
		
		if dist_sqr > brush_radius_sqr or _instancer.erase_ratio < randf():
			_project.transforms.append( instance_transform )
			_project.bottom_colors.append(  _mmi.multimesh.get_instance_color(i) )
			_project.top_colors.append(  _mmi.multimesh.get_instance_custom_data(i) )


# Gets every MultiMesh transform and color
func _get_all():
	var inst_count:int = _mmi.multimesh.instance_count
	_project.transforms.resize(inst_count)
	_project.bottom_colors.resize(inst_count)
	_project.top_colors.resize(inst_count)
	for i in inst_count:
		_project.transforms[i] = _mmi.multimesh.get_instance_transform(i)
		_project.bottom_colors[i] = _mmi.multimesh.get_instance_color(i)
		_project.top_colors[i] = _mmi.multimesh.get_instance_custom_data(i)


func _add_radial(hit_info:Dictionary):
	var brush_radius:float = Landscaper.scene.brush.get_scale_ratio()*0.5
	var object_world_position:Vector3 = hit_info.collider.global_position
	var mouse_world_pos:Vector3 = hit_info.position
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	
	for i in range(_instancer.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_surface1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_surface2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		# Add transforms for every surface found
		var result:Dictionary = raycaster.point_to_point(sphere_surface1, sphere_surface2)
		if result:
			var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)#.from_euler( stroke.stroke.rotation_base )
			var transf := Transform3D( basis, result.position - object_world_position )
			var size_offset:Vector3 = _configs.size_randomize * _randv(0, 1)
			
			transf = transf.scaled_local( _configs.size_base + size_offset)
			transf = transf.rotated_local(Vector3.FORWARD, randf()*_configs.rotation_randomize.y )
			transf = transf.rotated_local(Vector3.RIGHT, randf()*_configs.rotation_randomize.x )
			transf = transf.rotated_local(Vector3.UP, randf()*_configs.rotation_randomize.z )
			_project.transforms.append( transf )
			
			var mesh:Mesh = result.collider.get_parent().mesh
			var color:Color = _scan_color( mesh, result.face_index, result.position, object_world_position )
			_project.bottom_colors.append( color )
			_project.top_colors.append( Color.WHITE )


# Re-Spawns the grass from the transforms given
func _spawn():
	_mmi.multimesh.instance_count = _project.transforms.size()
	for i in range(_mmi.multimesh.instance_count):
		_mmi.multimesh.set_instance_transform( i, _project.transforms[i] )
		_mmi.multimesh.set_instance_color( i, _project.bottom_colors[i] )
		_mmi.multimesh.set_instance_custom_data( i, _project.top_colors[i] )


func _scan_color(mesh:Mesh, face_index:int, cursor:Vector3, surface_position:Vector3) -> Color:
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
	var cursor_world_local:Vector3 = cursor - surface_position
	var relative:Vector3 = Geometry3D.get_triangle_barycentric_coords(cursor_world_local, xy[0], xy[1], xy[2])
	var cursor_texture:Vector2 = relative.x*uv[0] + relative.y*uv[1] + relative.z*uv[2]
	
	# Find color from that coordinate
	var texture:Texture2D = mesh.surface_get_material(0).albedo_texture
	var size:Vector2 = texture.get_size()-Vector2.ONE
	var img:Image = texture.get_image()
	var px:Color = img.get_pixelv( cursor_texture*size )
	
	GLDebug.spam("Scanned color: [color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px
	
