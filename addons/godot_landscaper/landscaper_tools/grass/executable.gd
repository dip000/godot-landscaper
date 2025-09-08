@tool
extends Resource
class_name Executable

@export_tool_button("    Run    ", "UndoRedo") var _run:Callable = _run_executable
@export_tool_button("    Reset  ", "Object") var _reset:Callable = _reset_executable

func _run_executable():
	Landscaper.tool.run_executable(self)

func _reset_executable():
	Landscaper.tool.reset_executable(self)


func run(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	pass

func reset(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	pass
