@tool
extends GLBrush
class_name GLBrushTerrainHeight


func start(hit_info:Dictionary, controller:GLController):
	pass


## Heighten terrain level
func primary(hit_info:Dictionary, controller:GLController):
	_update( hit_info, controller, true )


## Lower terrain level
func secondary(hit_info:Dictionary, controller:GLController):
	_update( hit_info, controller, false )


func end():
	pass


func _update(hit_info:Dictionary, controller:GLControllerTerrain, height:bool):
	var brush_pos:Vector3 = hit_info.position
	var brush_size:float = controller.brush_size
	var brush_radius:float = brush_size * 0.5
	var cell_size:float = controller.cell_size
	var source:GLBuildDataTerrain = controller.source
	var height_strenght:float = controller.strenght
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = source.vertices_map
	
	# Find the affected area
	# Even and odd sizes behave differently in a 2D grid
	var is_even:bool = (roundi( brush_size ) % 2 == 0.0)
	var brush_pos_xz:Vector2 = Vector2(brush_pos.x, brush_pos.z)
	brush_pos_xz = brush_pos_xz.round() if is_even else brush_pos_xz.floor() + Vector2(0.5,0.5) 
	
	var brush_area:Rect2 = Rect2(brush_pos_xz, Vector2.ZERO)
	brush_area = brush_area.grow( brush_radius )
	
	# Update the affected area
	for cx in range(brush_area.position.x, brush_area.end.x):
		for cz in range(brush_area.position.y, brush_area.end.y):
			var cell:Vector2i = Vector2i(cx, cz)
			
			if vertices_map.has( cell ):
				var vertices:PackedVector3Array = vertices_map[cell]
				for index in vertices.size():
					if height:
						vertices[index].y += height_strenght
					else:
						vertices[index].y -= height_strenght
						
	
