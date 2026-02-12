@tool
extends GLEffect
class_name GLSceneRescanLevel

## Lower height in meters on Y axis that the grass will try to cache_scan_all for a surface to recolor with
@export var scan_min_height:float = -2.0
## Upper height in meters on Y axis that the grass will try to cache_scan_all for a surface to recolor with
@export var scan_max_height:float = 2.0


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerPackedScene:
		GLDebug.error("Scene Rescan Level Failed: This effect is only valid for GLControllerPackedScene controller types")
		return false
		
	controller = controller as GLControllerPackedScene
	var processed:GLBuildDataPackedScene = controller.processed
	var transforms:Array[Transform3D] = processed.transforms
	var holder:Node = controller.holder
	var scanner:GLSurfaceScanner = GLSurfaceScanner.new( controller )
	var total:int = transforms.size()
	
	for i in holder.get_child_count():
		var instance:Node = holder.get_child( i )
		var meta_controller:String = instance.get_meta(GLBuilderPackedScene.META_CONTROLLER, "")
		var meta_index:int = instance.get_meta(GLBuilderPackedScene.META_INDEX, -1)
		if meta_controller != controller.name or meta_index < 0:
			continue
		
		var original_transf:Transform3D = transforms[i]
		var global_position:Vector3 = original_transf.origin
		var scan_upper:Vector3 = global_position + Vector3.UP*scan_max_height
		var scan_lower:Vector3 = global_position + Vector3.UP*scan_min_height
		
		var cache:GLScanData = await scanner.scan_point_to_point( scan_upper, scan_lower, false )
		if cache:
			instance.global_position = cache.position
			transforms[i].origin = cache.position
			await _100_index( i )
	
	scanner.clear_all_surfaces()
	GLDebug.state("Instances were re leveled to ground. Total=%s" %total)
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerPackedScene:
		GLDebug.error("Scene Rescan Level Failed: This effect is only valid for GLControllerPackedScene controller types")
		return false
	return true






	
