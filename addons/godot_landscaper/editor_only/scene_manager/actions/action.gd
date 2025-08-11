@tool
extends Resource
class_name Action
## Interface members and utilities for every action (spawning grass, painting terrain, etc..)
## Every BaseInstancer has at least one Action.
## Actions implement and store their own custom redo() data

var _instancer:BaseInstancer
var _configs:ConfigsInstance
var _project:ProjectSaveData


# Unpack source action and action configs
func start(instancer:BaseInstancer, project:ProjectSaveData, configs:ConfigsInstance):
	_instancer = instancer
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
