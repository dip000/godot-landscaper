@tool
extends GLEffect
class_name GLEffectRescanColor

## Range in meters on Y axis that the grass will try to scan for a surface to sit on
@export var min_vertical_offset:float = -2.0
@export var max_vertical_offset:float = 2.0

var original_bottom_colors:Array[Color]


func _apply(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	if not original_mmi:
		GLDebug.error("No 'MultiMeshInstance' to chunkify")
		return false
	
	var raycaster:SceneRaycaster = Landscaper.scene.raycaster
	var data:GLBuildDataGrass = controller.resources.source
	
	for i in data.transforms.size():
		var original_transf:Transform3D = data.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_vertical_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_vertical_offset
		
		var result:Dictionary = raycaster.point_to_point(scan_upper, scan_lower)
		if not result: continue
		
		var cache:GLScanner.Cache = GLScanner.cache_scan( result.collider, controller, true )
		if cache.new:
			# PhysicsBody3D nodes require a frame after being created to detect raycasts
			await _frame()
			result = raycaster.point_to_point(scan_upper, scan_lower)
			if not result: continue
		
		var color:Color = GLScanner.scan_color( result, cache )
		data.bottom_colors[i] = color
		await _index(i)
	
	GLScanner.clear_cache()
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings")
	return true
