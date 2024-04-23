@tool
extends MeshInstance3D
class_name TerrainOverlay

@onready var body:StaticBody3D = %Body
@onready var collider:CollisionShape3D = %Collider
@onready var brush_sprite:Sprite3D = %Sprite


func _ready():
	global_position.y = 0.13
	body.set_collision_layer_value( PluginLandscaper.COLLISION_LAYER_OVERLAY, true )
	
	material_override = ShaderMaterial.new()
	material_override.shader = AssetsManager.TERRAIN_OVERLAY_SHADER
	material_override.set_shader_parameter( "brush_texture", AssetsManager.DEFAULT_BRUSH )


func enable():
	process_mode = Node.PROCESS_MODE_INHERIT
	show()

func disable():
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func resize(x:int, z:int):
	collider.shape.size.x = x
	collider.shape.size.y = 0.1
	collider.shape.size.z = z
	mesh = _create_mesh_overlay( Vector2(x, z) )


func _create_mesh_overlay(size:Vector2) -> ArrayMesh:
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
	return overlay_mesh


