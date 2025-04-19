@tool
extends Resource
class_name Action


func start(instance:InstanceData):
	pass

func primary(instance:InstanceData):
	pass

func secondary(instance:InstanceData):
	pass

func end(instance:InstanceData):
	pass

func redo(instance:InstanceData):
	pass


# Not really evenly distributed but whatever
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

# Not really evenly distributed but whatever
func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
