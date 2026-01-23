@tool
extends GLEffect
class_name GLEffectLoD

@export var end_margin:float = 2.0
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32


func _apply(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	original_mmi.multimesh.visible_instance_count = original_mmi.multimesh.instance_count*visible_instances
	original_mmi.visibility_range_end = custom_lod_meters
	original_mmi.visibility_range_end_margin = end_margin
	GLDebug.state("Effect LoD Applied to MultiMesh '%s'" %original_mmi.name)
	return true


func _clear(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	original_mmi.multimesh.visible_instance_count = -1
	original_mmi.visibility_range_end = 0.0
	original_mmi.visibility_range_end_margin = 0.0
	return true
	
