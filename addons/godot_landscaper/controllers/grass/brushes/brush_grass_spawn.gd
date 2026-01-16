@tool
extends GLBrush
class_name GLBrushGrassSpawn

var scanner:GLSurfaceScanner


func start(hit_info:Dictionary, controller:GLController) -> void:
	scanner = GLSurfaceScanner.new( controller )
	scanner.clear_cache()

func primary(hit_info:Dictionary, controller:GLController):
	_add_radial( hit_info, controller )

func secondary(hit_info:Dictionary, controller:GLController):
	_get_remove_radial( hit_info, controller )

func end():
	scanner.clear_cache()


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(hit_info:Dictionary, controller:GLControllerGrass):
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	var brush_radius_sqr:float = pow( Landscaper.scene.brush.get_radius(), 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var prev_data:GLBuildDataGrass = controller.source
	var new_data:GLBuildDataGrass = GLBuildDataGrass.new()
	
	for i in prev_data.size():
		var instance_transform:Transform3D = prev_data.transforms[i]
		var instance_world_pos:Vector3 = mmi.to_global( instance_transform.origin )
		var dist_sqr:float = instance_world_pos.distance_squared_to( mouse_world_pos )
		
		if dist_sqr > brush_radius_sqr or controller.erase_ratio < randf():
			new_data.transforms.append( instance_transform )
			new_data.top_colors.append( prev_data.top_colors[i] )
			new_data.bottom_colors.append( prev_data.bottom_colors[i] )
	
	prev_data.fill( new_data )


func _add_radial(hit_info:Dictionary, controller:GLControllerGrass):
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	
	var data:GLBuildDataGrass = controller.source
	var brush_radius:float = Landscaper.scene.brush.get_scale_ratio()*0.5
	var mouse_world_pos:Vector3 = hit_info.position
	
	for i in range(controller.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_global_point1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_global_point2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		# Scan in between the sphere points
		var cache:GLSurfaceScanner.Cache = await scanner.scan( sphere_global_point1, sphere_global_point2 )
		if not cache:
			continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		# This will actually make the grass "look" up at the sky instead of standing at 90°
		var basis := Basis.looking_at( cache.normal + Vector3.ONE*0.01 )
		
		# Compose rotation using quaternion magic
		basis *= Basis(
			# PI*0.5 on X axis compenzates for looking at the sky as mentioned before
			Quaternion(Vector3.RIGHT, controller.rotation_base.x - PI * 0.5) *
			Quaternion(Vector3.UP, controller.rotation_base.y) *
			Quaternion(Vector3.FORWARD, controller.rotation_base.z) *
			Quaternion(Vector3.RIGHT, randf()*controller.rotation_randomize.x) *
			Quaternion(Vector3.UP, randf()*controller.rotation_randomize.y) *
			Quaternion(Vector3.FORWARD, randf()*controller.rotation_randomize.z)
		)
		
		# to_local() takes rotation and scale in consideration
		var local_pos:Vector3 = mmi.to_local( cache.position )
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = controller.size_randomize * _randv(0, 1)
		
		local_transf = local_transf.scaled_local( controller.size_base + size_offset )
		data.transforms.append( local_transf )
		
		# Save colors. Use cached colors for performance
		var color:Color = scanner.scan_color( cache )
		data.bottom_colors.append( color )
		data.top_colors.append( controller.primary_color )


# Finds a random point in an imaginary sphere from its center.
# Not perfectly normalized since it comes from a square but meh
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
