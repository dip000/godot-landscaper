@tool
extends Brush
class_name TerrainBuilder
## Brush that generates new mesh when you paint_brushing over the terrain
## Paints white or black over the "texture" depending if is built or not


const DESCRIPTION := "Left click to build, right click to erase terrain"
const SQUARE_SHAPE:Array[Vector2i] = [
	Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), #top-left triangle
	Vector2i(0,1), Vector2i(1,0), Vector2i(1,1), #bottom-right triangle
]

@onready var canvas_size:CustomNumberInput = $CustomNumberInput
var _mesh_arrays:Array = []

func _ready():
	_mesh_arrays.resize(Mesh.ARRAY_MAX)
	canvas_size.on_change.connect( _on_canvas_size_changed )

func _on_canvas_size_changed(new_size:float):
	if new_size < 2:
		canvas_size.value = 2
		return
	
	var size_vector := Vector2i(new_size, new_size)
	var image_pos:Vector2i = (size_vector*0.5 - _project.canvas.size*0.5).round()
	_scene.overlay.resize( new_size, new_size )
	resize_texture( Rect2(image_pos, size_vector), Color.TRANSPARENT )
	_project.canvas.size = size_vector
	_project.canvas.position = -size_vector/2

func selected_brush():
	_update_overlay_shader("brush_color",  Color.GRAY)

func _on_save_ui():
	_project.tb_texture = texture
	_project.tb_resolution = _resolution
	_project.tb_canvas_size = canvas_size.value

func _on_load_ui(scene:SceneLandscaper):
	_input_texture( _project.tb_texture )
	_resolution = _project.tb_resolution
	canvas_size.value = _project.tb_canvas_size

func paint_primary(pos:Vector3):
	# Build terrain
	# Builder uses the canvas size instead of the minimum size given by '_project.world'
	var world_offset:Vector2 = -_project.canvas.size*0.5
	_update_overlay_shader("brush_color", Color.WHITE)
	_bake_color_into_texture( Color.WHITE, pos, false, world_offset )
	rebuild()

func paint_secondary(pos:Vector3):
	# Debuild terrain
	var world_offset:Vector2 = -_project.canvas.size*0.5
	_update_overlay_shader( "brush_color", Color(0,0,0,0) )
	_bake_color_into_texture( Color(0,0,0,0), pos, false, world_offset )
	
	# Paint back the same point and return to avoid nulling
	if img.get_used_rect().size <= Vector2i.ZERO:
		push_warning("Terrain Builder: Terrain cannot be fully debuilt")
		_bake_color_into_texture( Color.WHITE, pos, false, world_offset )
		return
	rebuild()


func paint_end():
	# Cleanup base mesh overlay, then reupdate terrain overlay
	_scene.overlay.generate_mesh_base_overlay( _project.canvas.size )
	rebuild()
	# Respawning grass is a heavy process, it is better to do so at the end of the stroke
	ui.grass_spawn.rebuild()


func _on_rebuild():
	# Caches
	var build_rect:Rect2i = img.get_used_rect()
	var build_map:Image = img.get_region( build_rect )
	var overlay_mesh:ArrayMesh = _scene.overlay.mesh
	var terrain_mesh:ArrayMesh = _scene.terrain_mesh
	var overlay_mesh_array:Array = overlay_mesh.surface_get_arrays( 0 )
	var overlay_vertices:PackedVector3Array = overlay_mesh_array[Mesh.ARRAY_VERTEX]
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var max_height:float = ui.terrain_height.max_height.value
	var max_size:Vector2i = img.get_size()
	var shape_size:int = SQUARE_SHAPE.size()
	
	if build_rect.size != _project.world.size:
		var new_position:Vector2i = build_rect.position - _project.canvas.size/2
		var resize_rect := Rect2i( _project.world.position - new_position, build_rect.size )
		_project.world.position = new_position
		_project.world.size = build_rect.size
		for brush in ui.brushes:
			if brush != self:
				brush.resize_texture( resize_rect, Color.BLACK )
		ui.assets_manager.set_unsaved_changes( true ) # Notify unsaved internal textures
	
	var world_position:Vector2i = _project.world.position
	var world_size:Vector2 = _project.world.size
	var height_map:Image = ui.terrain_height.img
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
	
	ui.terrain_height.update_collider()
