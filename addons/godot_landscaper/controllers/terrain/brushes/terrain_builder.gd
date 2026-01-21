@tool
extends GLBrush
class_name GLBrushTerrainBuider

# Each corner of a square has a list of 3 closest neighbors that share the same vertex
# These const define their mapping of {relative_index_in_square_shape: neighbor_corner_offset}
# For example. Looking from the TOP_LEFT corner:
#   You have the neighbors left-up, left, and up with their respective indexes of the shared vertex 5,1,2
const TOP_LEFT:Dictionary[int, Vector2i] = {5:Vector2i(-1,-1), 1:Vector2i(-1,0), 2:Vector2i(0,-1)}
const TOP_RIGHT:Dictionary[int, Vector2i] = {5:Vector2i(0,-1), 2:Vector2i(-1,-1), 0:Vector2i(0,1)}
const BOTTOM_LEFT:Dictionary[int, Vector2i] = {5:Vector2i(-1,0), 1:Vector2i(-1,1), 0:Vector2i(0,1)}
const BOTTOM_RIGHT:Dictionary[int, Vector2i] = {2:Vector2i(1,0), 1:Vector2i(0,1), 0:Vector2i(1,1)}

const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), #top-left triangle
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #bottom-right triangle
]


func start(scan_data:GLScanData, controller:GLController):
	pass


func primary(scan_data:GLScanData, controller:GLController):
	_update( scan_data, controller, true )
	

func secondary(scan_data:GLScanData, controller:GLController):
	_update( scan_data, controller, false )


func end():
	pass


func _update(scan_data:GLScanData, controller:GLControllerTerrain, build:bool):
	var brush_pos:Vector3 = scan_data.position
	var brush_size:float = controller.brush_size
	var brush_radius:float = brush_size * 0.5
	var cell_size:float = controller.cell_size
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
				
				for corner_index in SQUARE_SHAPE.size():
					var offset:Vector2i = SQUARE_SHAPE[corner_index]
					var corner_height:float = 0
					
					if controller.sew_seams_on_build:
						match corner_index:
							0: corner_height = _get_corner_height(TOP_LEFT, vertices_map, cell)
							1, 4: corner_height = _get_corner_height(TOP_RIGHT, vertices_map, cell)
							2, 3: corner_height = _get_corner_height(BOTTOM_LEFT, vertices_map, cell)
							5: corner_height = _get_corner_height(BOTTOM_RIGHT, vertices_map, cell)
					
					vertices.append(Vector3(
						origin_x + offset.x * cell_size,
						corner_height,
						origin_z + offset.y * cell_size
					))
				
				vertices_map[cell] = vertices
			
			elif not build and vertices_map.has( cell ):
				GLDebug.spam("Erasd Cell: %s" %cell)
				vertices_map.erase( cell )



func _get_corner_height(corner_map:Dictionary[int, Vector2i], vertices_map:Dictionary[Vector2i, PackedVector3Array], pivot:Vector2i) -> float:
	for cell_corner in corner_map:
		var cell:Vector2i = pivot + corner_map[cell_corner]
		if vertices_map.has( cell ):
			return vertices_map[cell][cell_corner].y
	return 0
	
	
