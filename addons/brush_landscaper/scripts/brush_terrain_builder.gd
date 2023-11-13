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
		# Position to texture-space
		var texture_pos := Vector2(pos.x, pos.z) - Vector2(_raw.world_offset)
		var brush_radius:Vector2 = _ui.brush_size.value/200.0 * bounds_size
		var bounds_i := Vector2i(bounds_size)
		
		# How many squares will be drawn if i were to paint here
		var world_reach_max:Vector2i = (texture_pos + brush_radius).ceil()
		var world_reach_min:Vector2i = (texture_pos - brush_radius).floor()
		
		# New bounding box
		var max_pos := Vector2i( maxi(world_reach_max.x, bounds_i.x), maxi(world_reach_max.y, bounds_i.y) )
		var min_pos := Vector2i( mini(world_reach_min.x, 0), mini(world_reach_min.y, 0) )
		
		# Update distance from world center to top-left corner of the bounding box terrain
		_raw.world_offset += min_pos
		
		# Extend every texture to new bounding box if bounds are different
		if min_pos != Vector2i.ZERO or max_pos != bounds_i:
			out_color = Color.BLACK
			_ui.terrain_clor.extend_texture( min_pos, max_pos )
			extend_texture( min_pos, max_pos )
	
	pos = pos.ceil()
	out_color = Color.WHITE if primary_action else Color.BLACK
	_bake_out_color_into_texture(pos)
	rebuild_terrain()


func rebuild_terrain():
	var img:Image = _texture.get_image()
	var vertices := PackedVector3Array()
	var offset:Vector2 = _raw.world_offset
	var img_size:Vector2i = img.get_size()
	var min_bound:Vector2i = img_size
	var max_bound:Vector2i = Vector2i.ZERO
	
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel( x, y ).r > BUILD_FROM_PIXEL_UMBRAL:
				create_square( vertices, x+offset.x, y+offset.y )
				
				# Find the actual min and max built points
				if x < min_bound.x:
					min_bound.x = x
				if x > max_bound.x:
					max_bound.x = x
				if y < min_bound.y:
					min_bound.y = y
				if y > max_bound.y:
					max_bound.y = y
				
	# Crop texture to optimize sizes if possible
	if max_bound != Vector2i.ZERO or min_bound != img_size:
		_raw.world_offset += min_bound
		_ui.terrain_clor.extend_texture( min_bound, max_bound )
		extend_texture( min_bound, max_bound+Vector2i.ONE )
	
	# Calculate UVs
	var uv := PackedVector2Array()
	var bounds:Vector2 = img.get_size()
	uv.resize( vertices.size() )
	
	for i in vertices.size():
		var vertex := Vector2(vertices[i].x, vertices[i].z)
		uv[i] = (vertex - offset) / bounds
	
	update_mesh( vertices, uv )


func create_square(vertices:PackedVector3Array, x:int, z:int):
	for offsets in SQUARE_SHAPE:
		vertices.push_back( Vector3(x+offsets.x, 0, z+offsets.y) )

func update_mesh(vertices:PackedVector3Array, uv:PackedVector2Array):
	# Clear mesh and colliders if no vertices
	if vertices.is_empty():
		print("Empty :P")
		_scene.terrain.mesh.clear_surfaces()
		_scene.terrain_collider.shape.map_width = 0
		_scene.terrain_collider.shape.map_depth = 0
		return
	
	# Setup the ArrayMesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	_scene.terrain_mesh.clear_surfaces()
	_scene.terrain_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, arrays )
	
	_scene.terrain_collider.shape.map_width = bounds_size.x + 1
	_scene.terrain_collider.shape.map_depth = bounds_size.y + 1
	_scene.terrain_collider.global_position.x = bounds_size.x * 0.5 + _raw.world_offset.x
	_scene.terrain_collider.global_position.z = bounds_size.y * 0.5 + _raw.world_offset.y

