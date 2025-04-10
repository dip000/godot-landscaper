@tool
extends Area3D
class_name SceneBrush

@onready var _preview_mmi:MultiMeshInstance3D = $Preview
@export var _preview_mesh:QuadMesh


func _ready():
	await Landscaper.ui.tree_entered
	Landscaper.ui.brush_diameter.on_change.connect( _brush_size_changed )
	

func _brush_size_changed():
	scale = Vector3.ONE * Landscaper.ui.brush_diameter.value

func over_surface(pos:Vector3):
	show()
	global_position = pos

func not_over_surface():
	hide()

func scale_by(_value:float):
	_brush_size_changed()
