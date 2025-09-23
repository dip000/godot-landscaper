@tool
extends Brush
class_name ActionMMIColor

# Should be injected before calling start()
var mmi:MultiMeshInstance3D
var grass:Grass3D
var save_data:GLSaveData


func start(hit_info:Dictionary):
	if save_data.transforms.size() != mmi.multimesh.instance_count:
		GLDebug.warning("Stored project data values are different from multimesh values. Multimesh values will be replaced")
		rebuild()
	Scanner.clear_cache()

func primary(hit_info:Dictionary):
	_paint( hit_info, grass.primary_color, false )

func secondary(hit_info:Dictionary):
	_paint( hit_info, grass.secondary_color, true )

func end():
	Scanner.clear_cache()


func rebuild():
	var mm:MultiMesh = mmi.multimesh
	mm.instance_count = save_data.transforms.size()
	for i in range(mm.instance_count):
		mm.set_instance_transform( i, save_data.transforms[i] )
		mm.set_instance_color( i, save_data.bottom_colors[i] )
		mm.set_instance_custom_data( i, save_data.top_colors[i] )
	

func _paint(hit_info:Dictionary, color:Color, secondary:bool):
	var brush_size_sqr:float = pow( Landscaper.scene.brush.get_scale_ratio()*0.5, 2)
	var mouse_world_pos:Vector3 = hit_info.position
	var mm:MultiMesh = mmi.multimesh
	
	# Re-Colors the grass from the current transforms
	for i in mm.instance_count:
		var transf:Transform3D = mm.get_instance_transform( i )
		var instance_world_pos:Vector3 = mmi.to_global( transf.origin )
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		if dist_sqr < brush_size_sqr:
			if secondary and grass.paint_with_sencondary_color:
				mm.set_instance_color( i, color )
				save_data.bottom_colors[i] = color
			else:
				mm.set_instance_custom_data( i, color )
				save_data.top_colors[i] = color
