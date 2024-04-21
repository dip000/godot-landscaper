@tool
extends Brush
class_name TerrainBuilder
# Brush that generates new mesh when you paint over the terrain
# Paints white or black over the "texture" depending if is built or not

const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), #top-left triangle
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #bottom-right triangle
]

var _mesh_arrays:Array = []


func _ready():
	_mesh_arrays.resize(Mesh.ARRAY_MAX)


func save_ui():
	_raw.tb_resolution = _resolution

func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_format_texture( raw.tb_texture )
	super (ui, scene, raw )
	_resolution = raw.tb_resolution

func paint(pos:Vector3, primary_action:bool):
	out_color = Color.WHITE if primary_action else Color(0,0,0,0)
	
	# Builder uses the max texture size instead of the minimum size given by '_raw.world'
	var world_offset:Vector2 = -_raw.MAX_BUILD_REACH*0.5
	_bake_out_color_into_texture( pos, false, world_offset )
	rebuild_terrain()

# Respawning grass is a heavy process, it is better to do so at the end of the stroke
func paint_end():
	_ui.grass_spawn.rebuild_terrain()


func rebuild_terrain():
	# Caches
	var build_rect:Rect2i = img.get_used_rect()
	var build_map:Image = img.get_region( build_rect )
	var overlay_mesh:ArrayMesh = _scene.terrain_overlay.mesh
	var terrain_mesh:ArrayMesh = _scene.terrain_mesh
	var overlay_mesh_array:Array = overlay_mesh.surface_get_arrays( 0 )
	var overlay_vertices:PackedVector3Array = overlay_mesh_array[Mesh.ARRAY_VERTEX]
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var max_height:float = _ui.terrain_height.max_height.value
	var max_size:Vector2i = img.get_size()
	var shape_size:int = SQUARE_SHAPE.size()
	
	if build_rect.size != _raw.world.size:
		var new_position:Vector2i = build_rect.position - RawLandscaper.MAX_BUILD_REACH/2
		var resize_rect := Rect2i( _raw.world.position - new_position, build_rect.size )
		_raw.world.position = new_position
		_raw.world.size = build_rect.size
		for brush in _ui.brushes:
			brush.resize_texture( resize_rect, Color.BLACK )
	
	var world_position:Vector2i = _raw.world.position
	var world_size:Vector2 = _raw.world.size
	var height_map:Image = _ui.terrain_height.img
	var world_position_inv:Vector2i = max_size/2 + world_position
	
	# Generate vertex and UV data
	for x in world_size.x:
		for z in world_size.y:
			if not is_zero_approx( build_map.get_pixel(x, z).a ):
				var texture := Vector2i(x, z)
				var world := texture + world_position
				var world_index := texture + world_position_inv
				
				for i in range( shape_size ):
					var offset_shape:Vector2i = SQUARE_SHAPE[i]
					var texture_pos:Vector2 = offset_shape + texture
					var world_pos:Vector2 = offset_shape + world
					var y:float = height_map.get_pixelv( texture_pos ).r * max_height
					
					uv.push_back( texture_pos / world_size )
					vertices.push_back( Vector3(world_pos.x, y, world_pos.y) )
					
					# Update the overlay mesh. Overlay is a constant size so only update its height
					var square_indx:int = world_index.y + max_size.y * world_index.x
					var vertex_indx:int = i + shape_size*square_indx
					overlay_vertices[vertex_indx].y = y
	
	# Update ArrayMesh
	terrain_mesh.clear_surfaces()
	_mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	_mesh_arrays[Mesh.ARRAY_TEX_UV] = uv
	terrain_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, _mesh_arrays )
	
	overlay_mesh.clear_surfaces()
	overlay_mesh_array[Mesh.ARRAY_VERTEX] = overlay_vertices
	overlay_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, overlay_mesh_array )
	
	_ui.terrain_height.update_collider()


# Builder brush should not be resized
func resize_texture(rect:Rect2i, fill_color:Color):
	return
