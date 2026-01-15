@tool
extends GLEffect
class_name GLEffectRescanColor

## Lower height in meters on Y axis that the grass will try to scan for a surface to recolor with
@export var min_height_offset:float = -2.0
## Upper height in meters on Y axis that the grass will try to scan for a surface to recolor with
@export var max_height_offset:float = 2.0


func _apply(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var processed:GLBuildDataGrass = controller.processed
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	var scanner:GLScanner = GLScanner.new()
	
	for i in processed.size():
		var original_transf:Transform3D = processed.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_height_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_height_offset
		
		#if scanner.try_raycast( scan_upper, scan_lower ):
			#var cache:GLScanner.Cache = await scanner.cache_all()
			#var color:Color = scanner.scan_color( cache )
		#if scanner.try_raycast( scan_upper, scan_lower ):
			#var cache:GLScanner.Cache = await scanner.cache_surface()
		
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:GLScanner.Cache = GLScanner.cache_scan( result.collider, controller, true )
		if cache.new:
			# PhysicsBody3D nodes require a frame after being created to detect raycasts
			await _frame()
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		var color:Color = GLScanner.scan_color( result, cache )
		processed.bottom_colors[i] = color
		await _index(i)
	
	GLScanner.clear_cache()
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings. Total=%s" %processed.size())
	return true


func _clear(controller:GLController) -> bool:
	return true
