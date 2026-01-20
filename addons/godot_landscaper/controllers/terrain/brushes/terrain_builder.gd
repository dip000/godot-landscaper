@tool
extends GLBrush
class_name GLBrushTerrainBuider

const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), #top-left triangle
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #bottom-right triangle
]


func start(hit_info:Dictionary, controller:GLController):
	pass


func primary(hit_info:Dictionary, controller:GLController):
	_update( hit_info, controller, true )
	

func secondary(hit_info:Dictionary, controller:GLController):
	_update( hit_info, controller, false )


func end():
	pass


func _update(hit_info:Dictionary, controller:GLControllerTerrain, build:bool):
	var brush_pos:Vector3 = hit_info.position
	var brush_size:float = controller.brush_size
	var brush_radius:float = brush_size * 0.5
	var cell_size:float = controller.cell_size
	var height:float = controller.base_height
	var source:GLBuildDataTerrain = controller.source
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
			
			if build and not vertices_map.has( cell ):
				var origin_x := cx * cell_size
				var origin_z := cz * cell_size
				var vertices:PackedVector3Array
				GLDebug.spam("Added Cell: %s" %[cell])
				
				# TODO: Make an "auto-sew seams if close enough"
				for offset_shape in SQUARE_SHAPE:
					vertices.append(Vector3(
						origin_x + offset_shape.x * cell_size,
						height,
						origin_z + offset_shape.y * cell_size
					))
				vertices_map[cell] = vertices
			
			elif not build and vertices_map.has( cell ):
				GLDebug.spam("Erasd Cell: %s" %cell)
				vertices_map.erase( cell )
			
