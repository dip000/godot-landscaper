@tool
extends Brush
class_name TerrainBuilder
# Brush that generates new mesh when you paint over the terrain
# Paints colors over the "_texture" depending if is built or not

const BUILD_FROM_PIXEL_UMBRAL:int = 0.2
const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(1,0), Vector2i(0,1), Vector2i(0,0), #triangle in fourth quadrant
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #triangle in second quadrant
]

var bounds_size:Vector2:
	get:
		return _texture.get_size()



func save_ui():
	_raw.tb_texture = _texture
	_raw.tb_resolution = _resolution
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_raw = raw
	_ui = ui
	_scene = scene
	_texture = _raw.tb_texture
	_resolution = _raw.tb_resolution
	_preview_texture()


func template(_size:Vector2i, raw:RawLandscaper):
	raw.world_offset = Vector2i.ZERO
	raw.tb_resolution = 1
	raw.tb_texture = _create_texture( Color.WHITE, _size, Image.FORMAT_L8 )


func paint(pos:Vector3, primary_action:bool):
	if primary_action:
		var pos_v2 := Vector2(pos.x, pos.z)
		var bounds_i := Vector2i(bounds_size)
		
		var brush_radius:Vector2 = _ui.brush_size.value/200.0 * bounds_size
		var world_reach_max:Vector2i = (pos_v2 + brush_radius).ceil()
		var world_reach_min:Vector2 = (pos_v2 - brush_radius).floor()
		var world_bound_lower:Vector2i = _raw.world_offset
		
		world_reach_max -= _raw.world_offset
		var max_pos := Vector2i( maxi(world_reach_max.x, bounds_i.x), maxi(world_reach_max.y, bounds_i.y) )
		var min_pos:Vector2i
		
		if world_reach_min.x < world_bound_lower.x:
			min_pos.x = floori( world_reach_min.x - world_bound_lower.x )
			_raw.world_offset.x += min_pos.x

		if world_reach_min.y < world_bound_lower.y:
			min_pos.y = floori( world_reach_min.y - world_bound_lower.y )
			_raw.world_offset.y += min_pos.y
		
		out_color = Color.BLACK
		_ui.terrain_clor.extend_texture( min_pos, max_pos )
		extend_texture( min_pos, max_pos )
#	else:
#		var img:Image = _texture.get_image()
#		var min:Vector2i = img.get_size()
#		var max:Vector2i = Vector2i.ZERO
#		for x in img.get_width():
#			for y in img.get_height():
#				if img.get_pixel( x, y ).r > BUILD_FROM_PIXEL_UMBRAL:
#					if x < min.x:
#						min.x = x
#					if x > max.x:
#						max.x = x
#					if y < min.y:
#						min.y = y
#					if y > max.y:
#						max.y = y
#		extend_texture( min, max+Vector2i.ONE )
	
	pos = pos.ceil()
	out_color = Color.WHITE if primary_action else Color.BLACK
	_bake_out_color_into_texture(pos)
	rebuild_terrain()


func rebuild_terrain():
	var img:Image = _texture.get_image()
	var vertices_terrain := PackedVector3Array()
	var uv := PackedVector2Array()
	var offset:Vector2i = _raw.world_offset
	var min:Vector2i = img.get_size()
	var max:Vector2i = Vector2i.ZERO
	
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel( x, y ).r > BUILD_FROM_PIXEL_UMBRAL:
				create_square( vertices_terrain, x+offset.x, y+offset.y )
	update_mesh( vertices_terrain )


func create_square(vertices:PackedVector3Array, x:int, z:int):
	for offsets in SQUARE_SHAPE:
		vertices.push_back( Vector3(x+offsets.x, 0, z+offsets.y) )
		

func update_mesh(vertices:PackedVector3Array):
	# Clear mesh and colliders if no vertices
	if vertices.is_empty():
		print("Empty :P")
		_scene.terrain.mesh.clear_surfaces()
		_scene.terrain_collider.shape.set_faces( PackedVector3Array() )
		return
	
	# Setup the ArrayMesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = recalculate_uv( vertices )
	_scene.terrain_mesh.clear_surfaces()
	_scene.terrain_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
	
	_scene.terrain_collider.shape.map_width = bounds_size.x + 1
	_scene.terrain_collider.shape.map_depth = bounds_size.y + 1
	_scene.terrain_collider.global_position.x = bounds_size.x * 0.5 + _raw.world_offset.x
	_scene.terrain_collider.global_position.z = bounds_size.y * 0.5 + _raw.world_offset.y


func recalculate_uv(vertices:PackedVector3Array) -> PackedVector2Array:
	# From world coordinates to [0,1] range
	var uv := PackedVector2Array()
	for vertex in vertices:
		uv.push_back( (Vector2(vertex.x, vertex.z) - Vector2(_raw.world_offset)) / bounds_size)
	return uv

