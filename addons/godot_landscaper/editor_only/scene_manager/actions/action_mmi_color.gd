@tool
extends Action
class_name ActionMMIColor

var _mmi:MultiMeshInstance3D


func start(instancer:BaseInstancer, project:ProjectSaveData, configs:ConfigsInstance):
	super(instancer, project, configs)
	var parent_holder:Node = instancer.get_node( instancer.parent_node )
	_mmi = parent_holder.get_node( configs.resource_name )
	Landscaper.undo_redo.add_undo_method( self, "restore", _project.top_colors.duplicate() )



func primary(hit_info:Dictionary):
	_spawn( hit_info, _instancer.primary_color )


func secondary(hit_info:Dictionary):
	_spawn( hit_info, _instancer.secondary_color )


func end():
	Landscaper.undo_redo.add_do_method( self, "restore", _project.top_colors.duplicate() )
	super()


func restore(colors:Array[Color]):
	for i in _mmi.multimesh.instance_count:
		_mmi.multimesh.set_instance_custom_data( i, colors[i] )
		


# Re-Colors the grass from the current transforms
func _spawn(hit_info:Dictionary, color:Color):
	var brush_size_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var object_world_position:Vector3 = hit_info.collider.global_position
	
	for i in _mmi.multimesh.instance_count:
		var transf:Transform3D = _mmi.multimesh.get_instance_transform( i )
		var instance_world_pos:Vector3 = transf.origin + object_world_position
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		if dist_sqr < brush_size_sqr:
			_mmi.multimesh.set_instance_custom_data( i, color )
			_project.top_colors[i] = color
		
