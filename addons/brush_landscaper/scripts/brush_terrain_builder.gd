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

var bounds_size:Vector2i:
	get:
		return _texture.get_size()



func save_ui():
	_raw.tb_texture = _texture
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_raw = raw
	_ui = ui
	_scene = scene
	_texture = _raw.tb_texture
	_preview_texture()


func template(_size:Vector2i, raw:RawLandscaper):
	raw.world_center = _size * 0.5
	raw.tb_texture = _create_texture( Color.WHITE, _size, Image.FORMAT_L8 )


func paint(pos:Vector3, primary_action:bool):
#	if primary_action:
#		var pos_v2 := Vector2(pos.x, pos.z)
#		var brush_radius:Vector2 = _ui.brush_size.value/200.0 * Vector2(bounds_size)
#		var world_reach:Vector2 = brush_radius + pos_v2.abs()
#		var world_bound:Vector2 = bounds_size - _raw.world_center
#		print( world_reach, world_bound )
#
#		var resize_by:Vector2i
#		if world_reach.x > world_bound.x:
#			resize_by.x = ceili( world_reach.x - world_bound.x )
#		if world_reach.y > world_bound.y:
#			resize_by.y = ceili( world_reach.y - world_bound.y )
#		if resize_by != Vector2i.ZERO:
#			var new_size:Vector2i = resize_by + bounds_size
#			print("Resize by: ", resize_by)
#			print("New size: ", new_size)
#			extend_texture( new_size, Color.BLACK )
	
	pos = pos.ceil()
	out_color = Color.WHITE if primary_action else Color.BLACK
	_bake_out_color_into_texture(pos)
	rebuild_terrain()



# Crops the _texture on smaller sizes, expands on bigger ones. But always keeps pixels where they were
func extend_texture(new_size:Vector2i, fill_color:Color):
	var prev_size:Vector2i = _texture.get_size()
	var prev_img:Image = _texture.get_image()
	var prev_format:int = prev_img.get_format()
	var new_img:Image = _create_img( fill_color, new_size, prev_format )
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var center_px:Vector2 = (new_size - prev_size) / 2.0
	
	new_img.blit_rect( prev_img, prev_img_full_rect, center_px )
	_texture.set_image( new_img )


func rebuild_terrain():
	var img:Image = _texture.get_image()
	var vertices_terrain := PackedVector3Array()
	var center:Vector2i = _raw.world_center
	
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x, y).r > BUILD_FROM_PIXEL_UMBRAL:
				create_square(vertices_terrain, x-center.x, y-center.y)
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
	_scene.terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_scene.terrain_collider.shape.set_faces( vertices )


func recalculate_uv(vertices:PackedVector3Array) -> PackedVector2Array:
	var uv := PackedVector2Array()
	var uv_min := Vector2.INF
	var uv_max := Vector2.ZERO
	
	# Find bounding box positions so all vertex can fit inside a rectangle _texture
	var img:Image = _texture.get_image()
	for x in img.get_width():
		for y in img.get_height():
			if x > uv_max.x:
				uv_max.x = x
			if y > uv_max.y:
				uv_max.y = y
			if x < uv_min.x:
				uv_min.x = x
			if y < uv_min.y:
				uv_min.y = y
	
	# Offset the max by one to compensate the fact that positions are taken from upper-left corner
	var size:Vector2 = (uv_max+Vector2.ONE) - uv_min
	for vertex in vertices:
		# From world coordinates to [0,1] range
		uv.push_back( (Vector2(vertex.x, vertex.z) - uv_min) / size )
	
	return uv

