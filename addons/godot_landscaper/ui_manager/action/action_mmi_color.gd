@tool
extends Action
class_name ActionMMIColor


func start(stroke:Stroke):
	# Find Multimesh
	var mmi:MultiMeshInstance3D = stroke.root_node.get_node_or_null( stroke.instance.name )
	if mmi:
		stroke.mm = mmi.multimesh
	

func primary(stroke:Stroke):
	if stroke.mm:
		_spawn( stroke, stroke.primary_color )

func secondary(stroke:Stroke):
	if stroke.mm:
		_spawn( stroke, stroke.secondary_color )


# Re-Colors the grass from the current transforms
func _spawn(stroke:Stroke, color:Color):
	for i in range(stroke.mm.instance_count):
		var transf:Transform3D = stroke.mm.get_instance_transform( i )
		var world_pos:Vector3 = transf.origin + stroke.surface_position
		var dist:float = stroke.cursor_position.distance_to( world_pos )
		if dist < stroke.radius:
			stroke.mm.set_instance_custom_data( i, color )
