@tool
extends Area3D
class_name SceneBrush

@export var _preview_mesh:QuadMesh
@onready var _core:MeshInstance3D = $Core
@onready var _icon:Sprite3D = %Icon


func over_surface(pos:Vector3):
	show()
	global_position = pos
	_icon.global_position.y = pos.y + get_scale_ratio()

func not_over_surface():
	hide()


func select_action(action_icon:AtlasIcon.Icon):
	_icon.texture.icon = action_icon


func scale_by(value:float):
	scale = Vector3.ONE * clamp(scale.x+value, 0.1, 100)

func set_scale_ratio(value:float):
	scale = Vector3.ONE * clamp(value, 0.1, 100)

func get_scale_ratio() -> float:
	return scale.x


func set_color(color:Color):
	_core.mesh.material.albedo_color = color

func get_color() -> Color:
	return _core.mesh.material.albedo_color
