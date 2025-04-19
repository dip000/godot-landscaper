@tool
extends Action
class_name ActionMMISpawn

var mmi:MultiMeshInstance3D


func start(instance:InstanceData):
	# Add Multimesh if needed
	mmi = SceneManager.find_or_create_node(MultiMeshInstance3D, instance.root_node, instance.resource_name )
	if not mmi.multimesh:
		mmi.multimesh = MultiMesh.new()
		mmi.multimesh.mesh = AssetsManager.QUAD_GRASS
		mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		mmi.multimesh.use_colors = true
		mmi.multimesh.use_custom_data = true
	mmi.global_position = instance.surface_position
	mmi.set_instance_shader_parameter("variant_index", instance.instance_index)
	
	# Initialize
	_get_all( instance )


# Spawn
func primary(instance:InstanceData):
	_add_radial( instance )
	_spawn( instance )


# Despawn
func secondary(instance:InstanceData):
	_get_remove_radial( instance )
	_spawn( instance )


func redo(instance:InstanceData):
	_spawn( instance )


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(instance:InstanceData):
	instance.transforms.clear()
	instance.bottom_colors.clear()
	instance.top_colors.clear()
	for i in mmi.multimesh.instance_count:
		var transform:Transform3D =  mmi.multimesh.get_instance_transform(i)
		var instance_pos:Vector3 = transform.origin + instance.surface_position
		var dist:float = instance_pos.distance_to( instance.cursor_position )
		if dist > instance.radius or instance.remove_ratio < randf():
			instance.transforms.append( transform )
			instance.bottom_colors.append(  mmi.multimesh.get_instance_color(i) )
			instance.top_colors.append(  mmi.multimesh.get_instance_custom_data(i) )


# Gets every MultiMesh transform and color
func _get_all(instance:InstanceData):
	for i in mmi.multimesh.instance_count:
		instance.transforms.append( mmi.multimesh.get_instance_transform(i) )
		instance.bottom_colors.append( mmi.multimesh.get_instance_color(i) )
		instance.top_colors.append( mmi.multimesh.get_instance_custom_data(i) )


func _add_radial(instance:InstanceData):
	for i in range(instance.add_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_surface1:Vector3 = _get_surface_point(instance.radius) + instance.cursor_position
		var sphere_surface2:Vector3 = _get_surface_point(instance.radius) + instance.cursor_position
		
		# Add transforms for every surface found
		var result:Dictionary = Landscaper.scene.raycaster.point_to_point(sphere_surface1, sphere_surface2)
		if result:
			var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)#.from_euler( stroke.stroke.rotation_base )
			var transf := Transform3D( basis, result.position - instance.surface_position )
			var size_offset:Vector3 = instance.size_randomize * _randv(0, 1)
			
			transf = transf.scaled_local( instance.size_base + size_offset)
			transf = transf.rotated_local(Vector3.FORWARD, randf()*instance.rotation_randomize.x )
			instance.transforms.append( transf )
			
			var mesh:Mesh = result.collider.get_parent().mesh
			var color:Color = _scan_color( mesh, result.face_index, result.position, instance.surface_position )
			instance.bottom_colors.append( color )
			instance.top_colors.append( Color.WHITE )


# Re-Spawns the grass from the transforms given
func _spawn(instance:InstanceData):
	mmi.multimesh.instance_count = instance.transforms.size()
	for i in range(mmi.multimesh.instance_count):
		mmi.multimesh.set_instance_transform( i, instance.transforms[i] )
		mmi.multimesh.set_instance_color( i, instance.bottom_colors[i] )
		mmi.multimesh.set_instance_custom_data( i, instance.top_colors[i] )


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
	
	Debug.spam("[color=%s]#%s[/color]" %[px.to_html(), px.to_html()])
	return px
	
