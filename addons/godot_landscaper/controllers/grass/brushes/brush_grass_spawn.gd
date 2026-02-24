@tool
extends GLBrush
class_name GLBrushGrassSpawn

enum Behavior {
	SPAWN, ## Creates grass instances.
	ERASE, ## Erases grass instances.
}

var behavior:Behavior
var scanner:GLSurfaceScanner


func start(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void:
	controller = controller as GLControllerGrass 
	scanner = GLSurfaceScanner.new( controller )
	# Resolve
	match action:
		GLandscaper.Action.PRIMARY:
			behavior = controller.primary_spawn_behavior
		GLandscaper.Action.SECONDARY:
			behavior = controller.secondary_spawn_behavior


func action(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	match behavior:
		Behavior.SPAWN:
			_add_radial( scan_data, controller )
		Behavior.ERASE:
			_get_remove_radial( scan_data, controller )


func end(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	pass


# Gets every MultiMesh transform except the ones inside the brush
func _get_remove_radial(scan_data:GLScanData, controller:GLControllerGrass):
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	var brush_radius_sqr:float = pow( GLandscaper.scene.brush.get_radius(), 2)
	var mouse_world_pos:Vector3 = scan_data.position
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


func _add_radial(scan_data:GLScanData, controller:GLControllerGrass):
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	var data:GLBuildDataGrass = controller.source
	var brush_radius:float = controller.brush_size * 0.5
	var mouse_world_pos:Vector3 = scan_data.position
	var align_with_normal:float = controller.align_with_normal * 0.01
	
	for i in range(controller.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_global_point1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_global_point2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		# Scan in between the sphere points
		var scan_cache:GLScanData = await scanner.scan_point_to_point( sphere_global_point1, sphere_global_point2 )
		if not scan_cache:
			continue
		
		# How aligned to the UP vector
		var normal:Vector3 = Vector3.UP.slerp( scan_cache.normal, align_with_normal )
		
		# Add a little offset so it doesn't throw errors on axis alignment
		# This will actually make the grass "look" face up at the sky instead of standing at 90°
		var basis := Basis.looking_at( normal + Vector3.ONE*0.01 )
		
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
		var local_pos:Vector3 = mmi.to_local( scan_cache.position )
		
		# Save base and random values
		var local_transf := Transform3D( basis, local_pos )
		var size_offset:Vector3 = controller.size_randomize * _randv(0, 1)
		
		local_transf = local_transf.scaled_local( controller.size_base + size_offset )
		data.transforms.append( local_transf )
		
		# Save colors. Uses cached colors for performance
		var color:Color = scanner.scan_color( scan_cache )
		data.bottom_colors.append( color )
		data.top_colors.append( controller.primary_color )


# Finds a random point in an imaginary sphere from its center.
# Not perfectly normalized since it comes from a square but meh
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
