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
	var point := Vector3( randf_range(-1,1), randf_range(-1,1), randf_range(-1,1) )
	point = point.normalized()
	return point * radius
