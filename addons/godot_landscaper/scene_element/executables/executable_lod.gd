@tool
extends Executable
class_name ExecMMILoD

@export var end_margin:float = 2.0
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export var chunks_parent_name:String = "Chunks"


func run(element:SceneElement, save_data:GLSaveData) -> String:
	var anchor_node:Node = element.anchor_node
	if not anchor_node: return "'Anchor Node' not found"
	
	var original_mmi:MultiMeshInstance3D = element.anchor_node.get_node_or_null(NodePath(element.name))
	if not original_mmi: return "No 'MultiMeshInstance' to chunkify"
	
	# Update original MMI
	original_mmi.multimesh.visible_instance_count = original_mmi.multimesh.instance_count*visible_instances
	original_mmi.visibility_range_end = custom_lod_meters
	original_mmi.visibility_range_end_margin = 0.0
	
	# Update chunked MMI
	var root_parent:Node = element.anchor_node.get_node_or_null(chunks_parent_name)
	if not root_parent:
		GLDebug.state("Level of Detail Updated")
		return "OK"
	
	for chunk in root_parent.get_children():
		for instance in chunk.get_children():
			if instance.name.begins_with(NodePath(element.name)):
				instance.multimesh.visible_instance_count = instance.multimesh.instance_count*visible_instances
				instance.visibility_range_end = custom_lod_meters
				instance.visibility_range_end_margin = end_margin
	
	GLDebug.state("Level of Detail Updated")
	return "OK"


func reset(element:SceneElement, save_data:GLSaveData) -> String:
	var anchor_node:Node = element.anchor_node
	if not anchor_node: return "'Anchor Node' not found"
	
	var original_mmi:MultiMeshInstance3D = element.anchor_node.get_node_or_null(NodePath(element.name))
	if not original_mmi: return "No 'MultiMeshInstance' to chunkify"
	
	# Reset original MMI
	original_mmi.multimesh.visible_instance_count = -1
	original_mmi.visibility_range_end = 0
	original_mmi.visibility_range_end_margin = 0
	
	# Reset chunked MMI
	var root_parent:Node = element.anchor_node.get_node_or_null(chunks_parent_name)
	if not root_parent:
		GLDebug.state("Level of Detail Reseted")
		return "OK"
	
	for chunk in root_parent.get_children():
		for instance in chunk.get_children():
			if instance.name.begins_with(NodePath(element.name)):
				instance.multimesh.visible_instance_count = -1
				instance.visibility_range_end = 0
				instance.visibility_range_end_margin = 0

	GLDebug.state("Level of Detail Reseted")
	return "OK"
	
