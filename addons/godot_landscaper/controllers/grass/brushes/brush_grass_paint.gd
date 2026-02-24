## GRASS BRUSH: Paints grass color over the stroked surface
##  

@tool
extends GLBrush
class_name GLBrushGrassPaint

enum Behavior {
	PAINT_TOP, ## Paints the top color of the grass instances. 
	PAINT_BOTTOM, ## Paints the bottom color of the grass instances. Note that the [GLSurfaceScanner] already paints this color by default
}

var behavior:Behavior
var color:Color


func start(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerGrass 
	# Resolve
	match action:
		GLandscaper.Action.PRIMARY:
			behavior = controller.primary_paint_behavior
			color = controller.primary_color
		GLandscaper.Action.SECONDARY:
			behavior = controller.secondary_paint_behavior
			color = controller.secondary_color


func action(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	_paint( scan_data, controller )


func end(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	pass


func _paint(scan_data:GLScanData, controller:GLControllerGrass):
	var brush_radius_sqr:float = pow( controller.brush_size*0.5, 2)
	var mouse_world_pos:Vector3 = scan_data.position
	
	var data:GLBuildDataGrass = controller.source
	var mmi:MultiMeshInstance3D = controller.multimesh_instance
	
	# Re-Colors the grass from the current transforms
	for i in data.size():
		var transf:Transform3D = data.transforms[i]
		var instance_world_pos:Vector3 = mmi.to_global( transf.origin )
		var dist_sqr:float = mouse_world_pos.distance_squared_to( instance_world_pos )
		
		# More performant than having to square root both
		if dist_sqr < brush_radius_sqr:
			if behavior == Behavior.PAINT_BOTTOM:
				data.bottom_colors[i] = _blend_alpha( color, data.bottom_colors[i] )
			else:
				data.top_colors[i] = _blend_alpha( color, data.top_colors[i] )


func _blend_alpha(target:Color, over:Color) -> Color:
	over = Color(over, 1.0-target.a)
	return target.blend( over )
