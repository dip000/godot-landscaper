@tool
extends Action
class_name ActionMMIColor

var mmi:MultiMeshInstance3D


func start(instance:InstanceData):
	mmi = instance.root_node.get_node_or_null( instance.resource_name )


func primary(instance:InstanceData):
	if mmi:
		_spawn( instance, instance.primary_color )


func secondary(instance:InstanceData):
	if mmi:
		_spawn( instance, instance.secondary_color )


func redo(instance:InstanceData):
	if mmi:
		for i in range(mmi.multimesh.instance_count):
			mmi.mm.set_instance_custom_data( i, instance.top_colors[i] )


# Re-Colors the grass from the current transforms
func _spawn(instance:InstanceData, color:Color):
	if mmi:
		for i in range(mmi.multimesh.instance_count):
			var transf:Transform3D = mmi.multimesh.get_instance_transform( i )
			var world_pos:Vector3 = transf.origin + instance.surface_position
			var dist:float = instance.cursor_position.distance_to( world_pos )
			if dist < instance.radius:
				mmi.multimesh.set_instance_custom_data( i, color )
				instance.top_colors.append( color )
