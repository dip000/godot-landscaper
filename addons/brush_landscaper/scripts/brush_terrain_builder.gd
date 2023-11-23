@tool
extends Brush
class_name TerrainBuilder
# Brush that generates new mesh when you paint over the terrain
# Paints colors over the "_texture" depending if is built or not

const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(1,0), Vector2i(0,1), Vector2i(0,0), #triangle in fourth quadrant
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #triangle in second quadrant
]

var _mesh_arrays:Array = []
var bounds_size:Vector2:
	get:
		return _texture.get_size()


func _ready():
	_mesh_arrays.resize(Mesh.ARRAY_MAX)


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
		
		# How many squares will be drawn if i were to paint here
		var world_reach_min:Vector2i = (texture_pos - brush_radius).round()
		var world_reach_max:Vector2i = (texture_pos + brush_radius).round()
		
		# New bounding box
		var min_pos := Vector2i( mini(world_reach_min.x, 0), mini(world_reach_min.y, 0) )
		var max_pos := Vector2i( maxi(world_reach_max.x, bounds_size.x), maxi(world_reach_max.y, bounds_size.y) )
		
		# Make room for possible strokes inside the new bounding box
		_extend_all_textures( min_pos, max_pos )
	
	pos = pos.ceil()
	out_color = Color.WHITE if primary_action else Color.BLACK
	_bake_out_color_into_texture(pos)
	rebuild_terrain()

# Respawning grass is a heavy process, it is better to do so at the end of the stroke
func paint_end():
	_ui.grass_spawn.rebuild_terrain()
	

func rebuild_terrain():
	# Cashes
	var build_map:Image = _texture.get_image()
	var height_map:Image = _raw.th_texture.get_image()
	var vertices := PackedVector3Array()
	var offset:Vector2i = _raw.world_offset
	var buildmap_size:Vector2i = bounds_size
	var max_height:float = _ui.terrain_height.max_height.value
	var min_bound:Vector2i = bounds_size
	var max_bound:Vector2i = Vector2i.ZERO
	var uv := PackedVector2Array()
	
	# Find the actual min and max built points
	for x in buildmap_size.x:
		for z in buildmap_size.y:
			if not is_zero_approx( build_map.get_pixel(x, z).r ):
				if x < min_bound.x:
					min_bound.x = x
				if x > max_bound.x:
					max_bound.x = x
				if z < min_bound.y:
					min_bound.y = z
				if z > max_bound.y:
					max_bound.y = z
	
	# Crop textures if possible
	# Add one to convert from index to size 
	_extend_all_textures( min_bound, max_bound+Vector2i.ONE )
	var bounds:Vector2 = bounds_size
	
	# Generate vertex and UV data
	for x in bounds.x:
		for z in bounds.y:
			if not is_zero_approx( build_map.get_pixel(x, z).r ):
				var texture := Vector2i(x, z)
				var world := texture + offset
				
				for offset_shape in SQUARE_SHAPE:
					var texture_pos:Vector2 = offset_shape + texture
					var world_pos:Vector2 = offset_shape + world
					var y:float = height_map.get_pixelv( texture_pos ).r * max_height
					
					uv.push_back( texture_pos / bounds )
					vertices.push_back( Vector3(world_pos.x, y, world_pos.y) )
					
	
	# Update ArrayMesh
	_mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	_mesh_arrays[Mesh.ARRAY_TEX_UV] = uv
	_scene.terrain_mesh.clear_surfaces()
	_scene.terrain_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, _mesh_arrays )
	_ui.terrain_height.update_collider()


# Every brush may override the base function for specific behaviors like updating shaders
# Updates distance from world center to top-left corner of the bounding box terrain
func _extend_all_textures(min:Vector2i, max:Vector2i):
	_raw.world_offset += min
	for brush in _ui.brushes:
		brush.extend_texture( min, max, Color.BLACK )
