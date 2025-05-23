@tool
extends Resource
class_name Action
## Interface members for every action and general utilities
## Due this resource being dynamically assigned, it should not store values


func start(instance:Instancer):
	pass

func primary(instance:Instancer):
	pass

func secondary(instance:Instancer):
	pass

func end(instance:Instancer):
	pass

func redo(instance:Instancer):
	pass


# Not really evenly distributed but whatever
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
