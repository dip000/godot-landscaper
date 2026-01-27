## GRASS BRUSH: Paints grass color over the stroked surface
##  

@tool
extends GLBrush
class_name GLBrushGrassPaint


func start(scan_data:GLScanData, controller:GLController):
	pass


func primary(scan_data:GLScanData, controller:GLController):
	_paint( scan_data, controller, false )


func secondary(scan_data:GLScanData, controller:GLController):
	_paint( scan_data, controller, true )


func end(scan_data:GLScanData, controller:GLController):
	pass


func _paint(scan_data:GLScanData, controller:GLControllerGrass, is_secondary:bool):
	var brush_radius_sqr:float = pow( controller.brush_size*0.5, 2)
	var mouse_world_pos:Vector3 = scan_data.position
	
	var paint_bottom:bool = (is_secondary and controller.paint_bottom_with_sencondary_color)
	var color:Color = controller.secondary_color if is_secondary else controller.primary_color
	
	var data:GLBuildDataGrass = controller.source
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	
	# Re-Colors the grass from the current transforms
	for i in data.size():
		var transf:Transform3D = data.transforms[i]
		var instance_world_pos:Vector3 = mmi.to_global( transf.origin )
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		
		# More performant than having to square root both
		if dist_sqr < brush_radius_sqr:
			if paint_bottom:
				data.bottom_colors[i] = _blend_alpha( color, data.bottom_colors[i] )
			else:
				data.top_colors[i] = _blend_alpha( color, data.top_colors[i] )


func _blend_alpha(target:Color, over:Color) -> Color:
	over = Color(over, 1.0-target.a)
	return target.blend( over )
