@tool
extends Resource
class_name Action


func start(stroke:Stroke):
	pass

func primary(stroke:Stroke):
	pass

func secondary(stroke:Stroke):
	pass

func end():
	pass


# Not really evenly distributed but whatever
func _get_surface_point(radius:float) -> Vector3:
	var point:Vector3 = _randv(-1, +1).normalized()
	return point * radius

# Not really evenly distributed but whatever
func _randv(min:float, max:float) -> Vector3:
	return Vector3( randf_range(min,max), randf_range(min,max), randf_range(min,max) )
