## Interface members and utilities for every action (spawning grass, painting terrain, etc..)
## Every LandscaperTool has at least one Action.
## Actions implement and store their own custom redo() data
## start() must validate its own inputs (globals are validated outside)

@tool
extends Resource
class_name Action

var _instancer:LandscaperTool
var _configs:ConfigsInstance
var _project:SaveData


# Unpack source action and action configs
func start(tool:LandscaperTool, project:SaveData, configs:ConfigsInstance):
	_instancer = tool
	_configs = configs
	_project = project

func primary(hit_info:Dictionary):
	pass

func secondary(hit_info:Dictionary):
	pass

func end():
	_configs = null
	_instancer = null
	_project = null

# Not really evenly distributed but whatever
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
