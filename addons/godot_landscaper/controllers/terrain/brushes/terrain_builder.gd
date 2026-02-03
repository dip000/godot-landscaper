@tool
extends GLBrush
class_name GLBrushTerrainBuider

# Each corner of a square has a list of 3 closest neighbors that share the same vertex
# These const define their mapping of {relative_index_in_square_shape: neighbor_corner_offset}
# For example. Looking from the TOP_LEFT_MAP corner:
#   You have the neighbors left-up, left, and up with their respective indexes of the shared vertex 5,1,2
const TOP_LEFT_MAP:Dictionary[int, Vector2i] = {5:Vector2i(-1,-1), 1:Vector2i(-1,0), 2:Vector2i(0,-1)}
const TOP_RIGHT_MAP:Dictionary[int, Vector2i] = {5:Vector2i(0,-1), 2:Vector2i(1,-1), 0:Vector2i(1,0)}
const BOTTOM_LEFT_MAP:Dictionary[int, Vector2i] = {5:Vector2i(-1,0), 1:Vector2i(-1,1), 0:Vector2i(0,1)}
const BOTTOM_RIGHT_MAP:Dictionary[int, Vector2i] = {2:Vector2i(1,0), 1:Vector2i(0,1), 0:Vector2i(1,1)}

const TOP_LEFT:Vector2i = Vector2i(0, 0)
const TOP_RIGHT:Vector2i = Vector2i(1, 0)
const BOTTOM_LEFT:Vector2i = Vector2i(0, 1)
const BOTTOM_RIGHT:Vector2i = Vector2i(1, 1)

const TOP_LEFT_TRI:Array[Vector2i] = [TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT]
const TOP_RIGHT_TRI:Array[Vector2i] = [TOP_LEFT, TOP_RIGHT, BOTTOM_RIGHT]
const BOTTOM_LEFT_TRI:Array[Vector2i] = [TOP_LEFT, BOTTOM_RIGHT, BOTTOM_LEFT]
const BOTTOM_RIGHT_TRI:Array[Vector2i] = [BOTTOM_LEFT, TOP_RIGHT, BOTTOM_RIGHT]

const SQUARE_SHAPE:Array[Vector2i] = [
	TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT,
	BOTTOM_LEFT, TOP_RIGHT, BOTTOM_RIGHT
]


func start(scan_data:GLScanData, controller:GLController):
	pass


func primary(scan_data:GLScanData, controller:GLController):
	var source:GLBuildDataTerrain = controller.source
	var brush_rect:Rect2 = GLandscaper.scene.brush.get_rect()
	headless_build( brush_rect, source.vertices_map, source.texture, controller.sew_seams_on_build )


func secondary(scan_data:GLScanData, controller:GLController):
	var source:GLBuildDataTerrain = controller.source
	var brush_rect:Rect2 = GLandscaper.scene.brush.get_rect()
	headless_erase( brush_rect, source.vertices_map, source.texture )


func end(scan_data:GLScanData, controller:GLController):
	pass


static func headless_erase(erase_rect:Rect2i, vertices_map:Dictionary[Vector2i, PackedVector3Array], texture:ImageTexture):
	var prev_bounds:Rect2i = get_bounding_box_from_coordinates( vertices_map.keys() )
	
	for cell in Rect2iter.new(erase_rect):
		if vertices_map.has( cell ):
			GLDebug.spam("Erasd Cell: %s" %cell)
			vertices_map.erase( cell )
	
	var new_bounds:Rect2i = get_bounding_box_from_coordinates( vertices_map.keys() )
	GLBrushTerrainPaint.resize_texture( texture, prev_bounds, new_bounds )
	


static func headless_build(build_rect:Rect2i, vertices_map:Dictionary[Vector2i, PackedVector3Array], texture:ImageTexture, sew_seams_on_build:bool):
	var prev_bounds:Rect2i = get_bounding_box_from_coordinates( vertices_map.keys() )
	var new_bounds:Rect2 = prev_bounds.merge( build_rect )
	
	for cell in Rect2iter.new(build_rect):
		if vertices_map.has( cell ):
			continue
		
		var vertices:PackedVector3Array
		GLDebug.spam("Added Cell: %s" %[cell])
		
		for corner_index in SQUARE_SHAPE.size():
			var offset:Vector2i = SQUARE_SHAPE[corner_index]
			var corner_height:float = 0
			
			if sew_seams_on_build:
				match corner_index:
					0: corner_height = get_corner_height(TOP_LEFT_MAP, vertices_map, cell)
					1, 4: corner_height = get_corner_height(TOP_RIGHT_MAP, vertices_map, cell)
					2, 3: corner_height = get_corner_height(BOTTOM_LEFT_MAP, vertices_map, cell)
					5: corner_height = get_corner_height(BOTTOM_RIGHT_MAP, vertices_map, cell)
			
			var world_pos:Vector2 = cell + offset
			vertices.append( Vector3( world_pos.x, corner_height, world_pos.y ) )
		
		vertices_map[cell] = vertices
	
	return GLBrushTerrainPaint.resize_texture( texture, prev_bounds, new_bounds )



## Returns any vertex in the same corner position shared by all 3 adjacent cells of 'corner_map'.
## I know is weid but it works ok!
static func get_corner_height(corner_map:Dictionary[int, Vector2i], vertices_map:Dictionary[Vector2i, PackedVector3Array], pivot:Vector2i, default:float=0.0) -> float:
	for cell_corner in corner_map:
		var cell:Vector2i = pivot + corner_map[cell_corner]
		if vertices_map.has( cell ):
			return vertices_map[cell][cell_corner].y
	return default
	

static func get_bounding_box_from_mesh(mesh_instance:MeshInstance3D) -> Rect2i:
	if not mesh_instance or not mesh_instance.mesh:
		return Rect2i()
	var aabb:AABB = mesh_instance.get_aabb()
	return Rect2i(aabb.position.x, aabb.position.z, aabb.size.x, aabb.size.z)


static func get_bounding_box_from_coordinates(map:Array[Vector2i]) -> Rect2i:
	if map.is_empty():
		return Rect2i()
	var min:Vector2i = map[0]
	var max:Vector2i = map[0]
	for cell in map:
		max = max.max( cell )
		min = min.min( cell )
	return Rect2i(min, max - min + Vector2i.ONE)
