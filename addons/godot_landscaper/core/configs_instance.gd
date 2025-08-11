extends Resource
class_name ConfigsInstance

@export var enable:bool = true

@export_group("Size", "size_")
@export var size_base:Vector3 = Vector3.ONE
@export var size_randomize:Vector3 = Vector3.ZERO

@export_group("Rotation", "rotation_")
@export var rotation_base:Vector3 = Vector3.ZERO
@export var rotation_randomize:Vector3 = Vector3.ZERO

var current_action:Action
