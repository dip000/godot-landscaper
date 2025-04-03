@tool
extends Area3D
class_name SceneBrush

@onready var _preview_mmi:MultiMeshInstance3D = $Preview
@export var _preview_mesh:QuadMesh


func _ready():
	Landscaper.ui.brush_size.on_change.connect( _brush_size_changed )
	
func _brush_size_changed():
	scale = Vector3.ONE * Landscaper.ui.brush_size.value

func preview(multimesh:MultiMesh):
	_preview_mmi.multimesh = multimesh.duplicate()
	_preview_mmi.multimesh.mesh = _preview_mesh
	
