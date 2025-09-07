@tool
extends Executable
class_name ExecMMILoD

@export var end_margin:float = 2.0
@export_range(0.0, 1.0, 0.01) var visible_instances:float = 1.0
@export_range(0.0, 100.0, 0.1, "or_greater") var custom_lod_meters:float = 32
@export var chunks_parent_name:String = "Chunks"

@export_tool_button("    Update LoD    ", "UndoRedo") var _run:Callable = run_executable
@export_tool_button("      Reset LoD     ", "Object") var _reset:Callable = reset_executable


func run(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	var mmi:MultiMeshInstance3D = tool.anchor_node.get_node_or_null(config.resource_name)
	if not mmi: return
	
	# Update original MMI
	mmi.multimesh.visible_instance_count = mmi.multimesh.instance_count*visible_instances
	mmi.visibility_range_end = custom_lod_meters
	mmi.visibility_range_end_margin = 0.0
	
	# Update chunked MMI
	var root_parent:Node = SceneManager.find_or_create_node(Node3D, tool.anchor_node, chunks_parent_name)
	for chunk in root_parent.get_children():
		for instance in chunk.get_children():
			if instance.name.begins_with(config.resource_name):
				instance.multimesh.visible_instance_count = instance.multimesh.instance_count*visible_instances
				instance.visibility_range_end = custom_lod_meters
				instance.visibility_range_end_margin = end_margin


func reset(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	var mmi:MultiMeshInstance3D = tool.anchor_node.get_node_or_null(config.resource_name)
	if not mmi: return
	
	# Reset original MMI
	mmi.multimesh.visible_instance_count = -1
	mmi.visibility_range_end = 0
	mmi.visibility_range_end_margin = 0
	
	# Reset chunked MMI
	var root_parent:Node = SceneManager.find_or_create_node(Node3D, tool.anchor_node, chunks_parent_name)
	for chunk in root_parent.get_children():
		for instance in chunk.get_children():
			if instance.name.begins_with(config.resource_name):
				instance.multimesh.visible_instance_count = -1
				instance.visibility_range_end = 0
				instance.visibility_range_end_margin = 0

	GLDebug.state("Level of Detail Reseted")
