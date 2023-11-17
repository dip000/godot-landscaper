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
	super(ui, scene, raw)
	_texture = _raw.tb_texture
	_resolution = _raw.tb_resolution
	_preview_texture()

func paint(pos:Vector3, primary_action:bool):
	if primary_action:
		# Position to texture-space
		var texture_pos := Vector2(pos.x, pos.z) - Vector2(_raw.world_offset)
		var brush_radius:Vector2 = _ui.brush_size.value/2.0 * bounds_size
		var bounds_i := Vector2i(bounds_size)
		
		# How many squares will be drawn if i were to paint here
		var world_reach_max:Vector2i = (texture_pos + brush_radius).ceil()
		var world_reach_min:Vector2i = (texture_pos - brush_radius).floor()
		
		# New bounding box
		var max_pos := Vector2i( maxi(world_reach_max.x, bounds_i.x), maxi(world_reach_max.y, bounds_i.y) )
		var min_pos := Vector2i( mini(world_reach_min.x, 0), mini(world_reach_min.y, 0) )
		
		# Extend every texture to new bounding box if bounds are different
		if min_pos != Vector2i.ZERO or max_pos != bounds_i:
			out_color = Color.BLACK
			_extend_all_textures( min_pos, max_pos )
	
	pos = pos.ceil()
	out_color = Color.WHITE if primary_action else Color.BLACK
	_bake_out_color_into_texture(pos)
	rebuild_terrain()
	_ui.terrain_height.update_collider()


func rebuild_terrain():
	var build_map:Image = _texture.get_image()
	var height_map:Image = _raw.th_texture.get_image()
	var vertices := PackedVector3Array()
	var offset:Vector2i = _raw.world_offset
	var buildmap_size:Vector2i = build_map.get_size()
	var max_height:float = _ui.terrain_height.max_height.value
	var min_bound:Vector2i = buildmap_size
	var max_bound:Vector2i = Vector2i.ZERO
	
	for x in buildmap_size.x:
		for z in buildmap_size.y:
			
			if build_map.get_pixel(x, z).r > BUILD_FROM_PIXEL_UMBRAL:
				var texture := Vector2i(x, z)
				var world := texture + offset
				
				for shape in SQUARE_SHAPE:
					var uv:Vector2i = shape + texture
					var world_pos:Vector2i = shape + world
					var y:float = height_map.get_pixelv( uv ).r * max_height
					vertices.push_back( Vector3(world_pos.x, y, world_pos.y) )
				
				# Find the actual min and max built points
				if x < min_bound.x:
					min_bound.x = x
				if x > max_bound.x:
					max_bound.x = x
				if z < min_bound.y:
					min_bound.y = z
				if z > max_bound.y:
					max_bound.y = z
	
	if vertices.is_empty():
		return
	
	# Crop texture to optimize sizes if possible
	if max_bound != Vector2i.ZERO or min_bound != buildmap_size:
		max_bound += Vector2i.ONE
		_extend_all_textures( min_bound, max_bound )
	
	# Calculate UVs
	var uv := PackedVector2Array()
	var bounds:Vector2 = build_map.get_size()
	uv.resize( vertices.size() )
	
	for i in vertices.size():
		var vertex := Vector2i(vertices[i].x, vertices[i].z)
		uv[i] = Vector2(vertex - offset) / bounds
	
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


