@tool
extends GLBrush
class_name GLBrushTerrainHeight


func start(scan_data:GLScanData, controller:GLController):
	pass


## Heighten terrain level
func primary(scan_data:GLScanData, controller:GLController):
	_update( scan_data, controller, true )


## Lower terrain level
func secondary(scan_data:GLScanData, controller:GLController):
	_update( scan_data, controller, false )


func end():
	pass


func _update(scan_data:GLScanData, controller:GLControllerTerrain, heighten:bool):
	var brush_pos:Vector3 = scan_data.position
	var brush_size:float = controller.brush_size
	var brush_radius:float = brush_size * 0.5
	var cell_size:float = controller.cell_size
	var source:GLBuildDataTerrain = controller.source
	var height_strength:float = controller.strenght
	var ease_curve:float = controller.ease_curve
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = source.vertices_map
	var square_shape:Array[Vector2i] = GLBrushTerrainBuider.SQUARE_SHAPE
	
	# Find the affected area
	# Even and odd sizes behave differently in a 2D grid
	var is_even:bool = (roundi( brush_size ) % 2 == 0.0)
	var brush_pos_xz:Vector2 = Vector2(brush_pos.x, brush_pos.z)
	brush_pos_xz = brush_pos_xz.round() if is_even else brush_pos_xz.floor() + Vector2(0.5,0.5) 
	
	var brush_area:Rect2 = Rect2(brush_pos_xz, Vector2.ZERO)
	brush_area = brush_area.grow( brush_radius )
	
	# Loop thrugh each offset around radius
	for x in range(-brush_radius, brush_radius+1):
		for y in range(-brush_radius, brush_radius+1):
			
			# Pivot around the origin
			var pivot:Vector2i = Vector2i(brush_pos_xz) + Vector2i(x, y)
			
			# Calculate fall-off
			var distance:float = maxf(absf(x), absf(y))
			distance /= brush_radius
			distance = clampf(distance, 0.0, 1.0)
			var t:float = 1.0 - distance
			var falloff:float = ease(t, ease_curve)
			var height:float = height_strength if heighten else -height_strength
			var falloff_height:float = height * falloff
			
			GLDebug.spam("pivot=%s, falloff_height=%s" %[pivot, falloff_height])
			
			# Raise pivot corner of every overlapping cell
			for cell_corner in square_shape.size():
				var shape_offset:Vector2i = square_shape[cell_corner]
				var cell:Vector2i = pivot - shape_offset
				if vertices_map.has( cell ):
					var vertices:PackedVector3Array = vertices_map[cell]
					vertices[cell_corner].y += falloff_height
	
