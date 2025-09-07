@tool
extends Resource
class_name Executable


func run_executable():
	Landscaper.tool.run_executable(self)

func reset_executable():
	Landscaper.tool.reset_executable(self)


func run(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	pass

func reset(tool:LandscaperTool, project:SaveData, config:InstanceConfigs):
	pass
