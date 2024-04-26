@tool
extends MeshInstance3D
class_name TerrainOverlay
## This is the hover surface when you hover over the terrain and the brush follows the mouse pointer

@onready var body:StaticBody3D = %Body
@onready var collider:CollisionShape3D = %Collider
@onready var brush_sprite:Sprite3D = %Sprite


func _ready():
	body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_OVERLAY, true )
	material_override = ShaderMaterial.new()
	material_override.shader = AssetsManager.TERRAIN_OVERLAY_SHADER
	material_override.set_shader_parameter( "brush_texture", AssetsManager.DEFAULT_BRUSH )
	material_override.set_shader_parameter( "brush_scale", 0.05 )


func enable():
	process_mode = Node.PROCESS_MODE_INHERIT
	show()

func disable():
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func snap(snap:Vector3):
	global_position = snap
	global_position.y += 0.10

func paint_start():
	global_position.y -= 0.05

func paint_brushing():
	pass

func paint_end():
	global_position.y += 0.05

func hover_terrain(pos:Vector3):
	var x:float = (pos.x - global_position.x) / collider.shape.size.x
	var z:float = (pos.z - global_position.z) / collider.shape.size.z
	var brush_position := Vector2( x, z )
	material_override.set_shader_parameter("brush_position", brush_position)
	
	pos.y += 1
	brush_sprite.global_position = pos

func set_brush_index(index:int):
	brush_sprite.frame = index

func set_brush_scale(value:float):
	material_override.set_shader_parameter("brush_scale", value)


func resize(x:int, z:int):
	# In case is called too soon
	if not is_node_ready():
		await get_tree().process_frame
	
	collider.shape.size.x = x
	collider.shape.size.y = 0.1
	collider.shape.size.z = z
	generate_mesh_base_overlay( Vector2(x, z) )


func generate_mesh_base_overlay(size:Vector2):
	# Caches
	var overlay_mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var uv := PackedVector2Array()
	var square_shape:Array[Vector2i] = TerrainBuilder.SQUARE_SHAPE
	var mesh_arrays:Array = []
	mesh_arrays.resize( Mesh.ARRAY_MAX )
	
	var world_position:Vector2i = -size*0.5
	var y:int = 0
	
	# Generate vertex and UV data
	for x in size.x:
		for z in size.y:
			var texture := Vector2i(x, z)
			var world := texture + world_position
			
			for offset_shape in square_shape:
				var texture_pos:Vector2 = offset_shape + texture
				var world_pos:Vector2 = offset_shape + world
				
				uv.push_back( texture_pos / size )
				vertices.push_back( Vector3(world_pos.x, y, world_pos.y) )
	
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uv
	overlay_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, mesh_arrays )
	mesh = overlay_mesh


