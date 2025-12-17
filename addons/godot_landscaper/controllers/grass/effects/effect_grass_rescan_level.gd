@tool
extends GLEffect
class_name GLEffectRescanLevel

## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var min_vertical_offset:float = -2.0
@export var max_vertical_offset:float = 2.0


func _apply(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	if not original_mmi:
		GLDebug.error("No 'MultiMeshInstance' to chunkify")
		return false
	
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	var data:GLBuildDataGrass = controller.resources.source
	var original_size:int = data.transforms.size()
	var updated_instances:int = 0
	var new_transforms:Array[Transform3D]
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	
	for i in original_size:
		var original_transf:Transform3D = data.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_vertical_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_vertical_offset
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:GLScanner.Cache = GLScanner.cache_scan( result.collider, controller, false )
		if cache.new:
			await _frame()
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
		var basis := Basis.looking_at(result.normal + Vector3.ONE*0.01)
		# Compose rotation using quaternion magic
		basis *= Basis(
			# PI*0.5 on X axis compenzates for looking at the sky as mentioned before
			Quaternion(Vector3.RIGHT, data.rotation_base.x - PI * 0.5) *
			Quaternion(Vector3.UP, data.rotation_base.y) *
			Quaternion(Vector3.FORWARD, data.rotation_base.z) *
			Quaternion(Vector3.RIGHT, randf()*data.rotation_randomize.x) *
			Quaternion(Vector3.UP, randf()*data.rotation_randomize.y) *
			Quaternion(Vector3.FORWARD, randf()*data.rotation_randomize.z)
		)
		
		# to_local() takes rotation in consideration. Then feed back to result as global for color scaning
		var local_pos:Vector3 = original_mmi.to_local( result.position )
		result.position = local_pos + mmi.global_position
		
		# Save base and random values
		var local_transf:Transform3D = Transform3D( basis, local_pos )
		var size_offset:Vector3 = data.size_randomize * randf()
		local_transf = local_transf.scaled_local( data.size_base + size_offset )
		
		new_transforms.append( local_transf )
		await _index(i)
	
	# Resize down the new values if some were lost
	var new_size:int = new_transforms.size()
	if updated_instances != new_size:
		data.top_colors.resize(new_size)
		data.bottom_colors.resize(new_size)
	
	# Dump new transforms
	data.transforms = new_transforms
	
	original_mmi.global_position = mmi.global_position
	var lost_instances:int = original_size - new_size
	
	GLScanner.clear_cache()
	GLDebug.state("Grass was repositioned in Y axis. %s instances were lost" %lost_instances)
	return true
