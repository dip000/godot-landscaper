@tool
extends GLEffect
class_name GLGrassRescanColor

## Lower height in meters on Y axis that the grass will try to cache_scan_all for a surface to recolor with
@export var min_height_offset:float = -2.0
## Upper height in meters on Y axis that the grass will try to cache_scan_all for a surface to recolor with
@export var max_height_offset:float = 2.0


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Color Failed: This effect is only valid for GLControllerGrass controller types")
		return false
		
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var processed:GLBuildDataGrass = controller.processed
	var scanner:GLSurfaceScanner = GLSurfaceScanner.new( controller )
	
	for i in processed.size():
		var original_transf:Transform3D = processed.transforms[i]
		var global_position:Vector3 = original_mmi.to_global( original_transf.origin )
		var scan_upper:Vector3 = global_position + Vector3.UP*max_height_offset
		var scan_lower:Vector3 = global_position + Vector3.UP*min_height_offset
		
		var cache:GLScanData = await scanner.scan_point_to_point( scan_upper, scan_lower )
		if cache:
			processed.bottom_colors[i] = scanner.scan_color( cache )
			await _100_index( i )
	
	scanner.clear_all_surfaces()
	GLDebug.state("Bottom grass was recolored from Ground Coloring settings. Total=%s" %processed.size())
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Color Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	return true
