@tool
extends GLBrush
class_name GLBrushTerrainHeight

enum Behavior {
	RAISE, ## Raises the vertex vertical positions.
	LOWER, ## Lowers the vertex vertical positions.
}


func start(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	pass


## Heighten/Lower terrain level
func action(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerTerrain
	var behavior:Behavior
	
	# Resolve
	match action:
		GLandscaper.Action.PRIMARY:
			behavior = controller.primary_height_behavior
		GLandscaper.Action.SECONDARY:
			behavior = controller.secondary_height_behavior
	
	# Execute
	match behavior:
		Behavior.RAISE:
			_height( controller.strenght, controller.ease_curve, controller.level, scan_data.position, controller.brush_size, controller.source.vertices_map )
		Behavior.LOWER:
			_height( -controller.strenght, controller.ease_curve, controller.level, scan_data.position, controller.brush_size, controller.source.vertices_map )


func end(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	pass


func _height(full_strength:float, ease_curve:float, level:bool, center:Vector3, radius:float, vertices_map:Dictionary[Vector2i, PackedVector3Array]):
	var center_xz:Vector2 = Vector2(center.x, center.z)
	var world_brush_rect:Rect2 = GLandscaper.scene.brush.get_rect()
	var world_rect:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	var brush_area:Rect2 = world_rect.intersection( world_brush_rect )
	var square_shape:Array[Vector2i] = GLBrushTerrainBuider.SQUARE_SHAPE
	
	if brush_area.size.is_zero_approx():
		return
	
	var min_height:float
	var max_height:float
	if level:
		min_height = INF
		max_height = - INF
		for cell in GLRect2iter.from( brush_area ):
			var vertices:PackedVector3Array = vertices_map.get(cell, [])
			for vertex in vertices:
				min_height = min(vertex.y, min_height)
				max_height = max(vertex.y, max_height)
	
		if not is_finite(min_height):
			min_height = 0
		
		if not is_finite(max_height):
			min_height = 0
	
	brush_area.size += Vector2.ONE
	for cell in GLRect2iter.from( brush_area ):
		var distance:float = center_xz.distance_to(cell)
		var distance_norm:float = 1.0 - distance / radius
		var falloff:float = ease(distance_norm, ease_curve)
		var current_strenght:float = full_strength * falloff
		
		#GLDebug.spam("cell=%s, distance=%s, current_height=%s" %[cell, distance, current_strenght])
		
		# Raise pivot corner of every overlapping cell
		for cell_corner in square_shape.size():
			var shape_offset:Vector2i = square_shape[cell_corner]
			var affected_cell:Vector2i = cell - shape_offset
			
			if vertices_map.has( affected_cell ):
				var vertices:PackedVector3Array = vertices_map[affected_cell]
				var vertex_height:float = vertices[cell_corner].y
				var target:float = vertex_height + current_strenght
				
				if level:
					if full_strength < 0:
						var delta:float = (min_height - vertex_height)*0.1
						target = max(target+delta, min_height)
					else:
						var delta:float = (max_height - vertex_height)*0.1
						target = min(target+delta, max_height)
				
				vertices[cell_corner].y = target
			
			
			
			
			
			
			
			
			
	
