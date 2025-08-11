@tool
extends Area3D
class_name SceneBrush

@onready var _preview_mmi:MultiMeshInstance3D = $Preview
@export var _preview_mesh:QuadMesh


func over_surface(pos:Vector3):
	show()
	global_position = pos

func not_over_surface():
	hide()

func scale_by(value:float):
	scale = Vector3.ONE * clamp(scale.x+value, 0.01, 100)

func set_scale_ratio(value:float):
	scale = Vector3.ONE * clamp(value, 0.1, 100)

func get_scale_ratio():
	return scale.x
