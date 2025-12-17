@tool
extends GLEffect
class_name GLEffectLoD

@export var end_margin:float = 2.0
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export var chunks_parent:NodePath = "."


func _apply(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	if not original_mmi:
		GLDebug.error("No 'MultiMeshInstance' to chunkify")
		return false
	
	# Update original MMI
	original_mmi.multimesh.visible_instance_count = original_mmi.multimesh.instance_count*visible_instances
	original_mmi.visibility_range_end = custom_lod_meters
	original_mmi.visibility_range_end_margin = 0.0
	
	# Update chunked MMI
	var root_parent:Node = controller.get_node_or_null(chunks_parent)
	if not root_parent:
		GLDebug.state("Level of Detail Updated")
		return true
	
	for chunk in root_parent.get_children():
		for instance in chunk.get_children():
			if instance.name.begins_with(NodePath(controller.name)):
				instance.multimesh.visible_instance_count = instance.multimesh.instance_count*visible_instances
				instance.visibility_range_end = custom_lod_meters
				instance.visibility_range_end_margin = end_margin
	
	GLDebug.state("Level of Detail Updated")
	return true
