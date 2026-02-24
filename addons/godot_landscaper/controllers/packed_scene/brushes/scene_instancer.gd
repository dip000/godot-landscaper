@tool
extends GLBrush
class_name GLBrushSceneInstancer

enum Behavior {
	INSTANTIATE, # Calls [method PackedScene.instantiate] on the [member GLBuildDataPackedScene.scene]
	ERASE, # Erases [PackedScene] instances
}

var behavior:Behavior
var scanner:GLSurfaceScanner


func start(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void:
	controller = controller as GLControllerPackedScene
	scanner = GLSurfaceScanner.new( controller )
	# Resolve
	match action:
		GLandscaper.Action.PRIMARY:
			behavior = controller.primary_action
		GLandscaper.Action.SECONDARY:
			behavior = controller.secondary_action


func action(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void:
	match behavior:
		Behavior.INSTANTIATE:
			_instance( scan_data, controller )
		Behavior.ERASE:
			_erase( scan_data, controller )


func end(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController) -> void:
	pass


func _erase(scan_data:GLScanData, controller:GLController) -> void:
	controller = controller as GLControllerPackedScene
	var source:GLBuildDataPackedScene = controller.source
	var transforms:Array[Transform3D] = source.transforms
	var radius_sqr:float = pow( controller.brush_size * 0.5, 2 )
	
	for i in transforms.size():
		var position:Vector3 = transforms[i].origin
		if position.distance_squared_to( scan_data.position ) < radius_sqr:
			source.dirty_erases.append( i )


func _instance(scan_data:GLScanData, controller:GLController) -> void:
	controller = controller as GLControllerPackedScene
	var source:GLBuildDataPackedScene = controller.source
	var transforms:Array[Transform3D] = source.transforms
	var dirty_instances:PackedInt32Array = source.dirty_instances
	var brush_radius:float = controller.brush_size * 0.5
	var mouse_world_pos:Vector3 = scan_data.position
	var align_with_normal:float = controller.align_with_normal * 0.01
	
	for i in range(controller.spawn_ratio):
		# Two random points over the brush sphere to make a ray
		var sphere_global_point1:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		var sphere_global_point2:Vector3 = _get_surface_point(brush_radius) + mouse_world_pos
		
		# Scan in between the sphere points
		var scan_cache:GLScanData = await scanner.scan_point_to_point( sphere_global_point1, sphere_global_point2, false )
		if not scan_cache:
			continue
		
		# How aligned to the UP vector
		var normal:Vector3 = Vector3.UP.slerp( scan_cache.normal, align_with_normal )
		
		# Add a little offset so it doesn't throw errors on axis alignment
		# This will actually make the instance "look" face up at the sky instead of standing at 90°
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
		
		var position:Vector3 = scan_cache.position + controller.offset_position
		var size_offset:Vector3 = controller.size_base + controller.size_randomize * _randv(0, 1)
		
		var transform:Transform3D = Transform3D( basis, position )
		dirty_instances.append( transforms.size() )
		transforms.append( transform.scaled_local(size_offset) )
	

# Finds a random point in an imaginary sphere from its center.
# Not perfectly normalized since it comes from a square but meh
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
