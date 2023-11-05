extends Brush
class_name TerrainBuilder
# Brush that generates new mesh when you paint over the terrain
# Paints colors over the "texture" depending if is built or not

const BUILD_FROM_PIXEL_UMBRAL:int = 0.2
const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(1,0), Vector2i(0,1), Vector2i(0,0), #triangle in fourth quadrant
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #triangle in second quadrant
]

var pivot:Vector2i
var bounds_size:Vector2i:
	set(v):
		return
	get:
		return texture.get_size()



func setup():
	resource_name = "terrain_builder"

func template(size:Vector2i):
	pivot = size * 0.5
	texture = _create_texture( Color.WHITE, size, Image.FORMAT_L8 )
	update_texture()

func paint(pos:Vector3, primary_action:bool):
	var brush_size:float = DockUI.brush_size.value/100
	pos = pos.ceil()
	out_color = Color.WHITE if primary_action else Color.BLACK
	_bake_out_color_into_texture(brush_size, pos)
	update_texture()
	update_shaders()

func update_texture():
	var img:Image = texture.get_image()
	var vertices := PackedVector3Array()
	
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x, y).r > BUILD_FROM_PIXEL_UMBRAL:
				create_square(vertices, x-pivot.x, y-pivot.y)
	update_mesh( vertices )



func create_square(vertices:PackedVector3Array, x:int, z:int):
	for offsets in SQUARE_SHAPE:
		vertices.push_back( Vector3(x+offsets.x, 0, z+offsets.y) )

func update_mesh(vertices:PackedVector3Array):
	# Clear mesh and colliders if no vertices
	if vertices.is_empty():
		print("Empty :P")
		landscaper.terrain.mesh.clear_surfaces()
		landscaper.terrain_shape.set_faces( PackedVector3Array() )
		return
	
	# Setup the ArrayMesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = recalculate_uv( vertices )
	landscaper.terrain_mesh.clear_surfaces()
	landscaper.terrain_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	landscaper.terrain_collider.shape.set_faces( vertices )


func recalculate_uv(vertices:PackedVector3Array) -> PackedVector2Array:
	var uv := PackedVector2Array()
	var uv_min := Vector2.INF
	var uv_max := Vector2.ZERO
	
	# Find bounding box positions so all vertex can fit inside a rectangle texture
	var img:Image = texture.get_image()
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

