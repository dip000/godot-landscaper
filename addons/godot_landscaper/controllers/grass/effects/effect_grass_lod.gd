@tool
extends GLEffect
class_name GLGrassLoD

@export var end_margin:float = 2.0
@export_range(0.0, 100.0, 1.0, "suffix:%") var visible_instances:float = 100.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass LoD failed: This effect is only valid for GLControllerGrass controller types")
		return false
	
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var original_mm:MultiMesh = original_mmi.multimesh
	original_mm.visible_instance_count = -1
	original_mmi.visibility_range_end = custom_lod_meters
	original_mmi.visibility_range_end_margin = end_margin
	
	if is_equal_approx( visible_instances, 100 ):
		GLDebug.state("Effect LoD Applied to MultiMesh '%s'" %original_mmi.name)
		return true
	
	## Randomizes instance positions. for visible_instances:
	## - Before randomizing: Will most likely hide/show entire uneven patches of grass (as they were spawned).
	## - After randomizing: Will always hide/show them as density-based
	var source:GLBuildDataGrass = controller.source
	var processed:GLBuildDataGrass = controller.processed
	var new_transforms:Array[Transform3D]
	var new_top_colors:PackedColorArray
	var new_bottom_colors:PackedColorArray
	var rand_indices:Array = range(0, processed.size())
	rand_indices.shuffle()
	
	for i in rand_indices:
		new_transforms.append( processed.transforms[i] )
		new_top_colors.append( processed.top_colors[i] )
		new_bottom_colors.append( processed.bottom_colors[i] )
		await _100_index( i )
	
	processed.transforms = new_transforms
	processed.top_colors = new_top_colors
	processed.bottom_colors = new_bottom_colors
	original_mm.visible_instance_count = original_mm.instance_count * visible_instances * 0.01
	GLDebug.state("Effect LoD Applied to MultiMesh '%s' with visible_instance_count=%s" %[original_mmi.name, original_mm.visible_instance_count])
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass LoD failed: This effect is only valid for GLControllerGrass controller types")
		return false
		
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	original_mmi.multimesh.visible_instance_count = -1
	original_mmi.visibility_range_end = 0.0
	original_mmi.visibility_range_end_margin = 0.0
	return true
	
