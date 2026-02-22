@tool
extends GLEffect
class_name GLGrassRescanLevel

## Range in meters on Y axis that the grass will try to cache_scan_all for a surface to sit on
@export var min_height_offset:float = -2.0
@export var max_height_offset:float = 2.0


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Level Failed: This effect is only valid for GLControllerGrass controller types")
		return false
		
	controller = controller as GLControllerGrass
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var processed:GLBuildDataGrass = controller.processed
	var scanner:GLSurfaceScanner = GLSurfaceScanner.new( controller )
	var original_instance_count:int = processed.size()
	var new_data:GLBuildDataGrass = GLBuildDataGrass.new()
	
	for i in range(original_instance_count):
		var original_transf:Transform3D = processed.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_height_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_height_offset
		
		var cache:GLScanData = await scanner.scan_point_to_point( scan_upper, scan_lower, false )
		if not cache:
			continue
		
		# Align Normals. Add a little offset so it doesn't throw errors on axis alignment
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
		
		# to_local() takes rotation in consideration. Then feed back to result as global for color scaning
		var local_pos:Vector3 = original_mmi.to_local( cache.position )
		cache.position = local_pos + original_mmi.global_position
		
		# Save base and random values
		var local_transf:Transform3D = Transform3D( basis, local_pos )
		var size_offset:Vector3 = controller.size_randomize * randf()
		local_transf = local_transf.scaled_local( controller.size_base + size_offset )
		
		# Save new transforms and original colors
		new_data.transforms.append( local_transf )
		new_data.top_colors.append( processed.top_colors[i] )
		new_data.bottom_colors.append( processed.bottom_colors[i] )
		await _100_index(i)
	
	# Apply new transforms and set previous colors
	processed.fill( new_data )
	
	var lost_instances:int = original_instance_count - new_data.size()
	scanner.clear_all_surfaces()
	GLDebug.state("Grass was repositioned in Y axis. %s instances were lost out of %s" %[lost_instances, original_instance_count])
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Level Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	return true
