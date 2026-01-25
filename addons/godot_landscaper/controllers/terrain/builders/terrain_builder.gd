@tool
extends GLBuilder
class_name GLBuilderTerrain


func build_from_source() -> bool:
	return build_headless( _controller.source, _controller.terrain, _controller.source.texture, true )

func build_from_processed() -> bool:
	return build_headless( _controller.processed, _controller.terrain, _controller.source.texture, true )


static func build_headless(build_data:GLBuildDataTerrain, terrain:MeshInstance3D, texture:Texture2D, renormalize_uvs:bool) -> bool:
	var mesh:ArrayMesh = terrain.mesh
	
	if not build_data.vertices_map:
		mesh.clear_surfaces()
		return true
	
	# Fill vertex raw data for mesh_arrays (many cheap iterations)
	# Welds vertices by default (vertex indexing)
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = build_data.vertices_map
	var uvs_map:Dictionary[Vector2i, PackedVector2Array] = build_data.uvs_map
	var vertex_index:Dictionary[Vector3, int]
	var indices:PackedInt32Array
	var vertices:PackedVector3Array
	var uvs:PackedVector2Array
	
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	var terrain_offset:Vector3 = terrain.global_position
	
	for cell in vertices_map:
		var cell_vertices:PackedVector3Array = vertices_map[cell]
		var cell_uvs:PackedVector2Array = uvs_map[cell]
		
		for i in cell_vertices.size():
			var vertex:Vector3 = cell_vertices[i]
			var uv:Vector2 = cell_uvs[i]
			var index:int
			if vertex_index.has( vertex ):
				index = vertex_index[vertex]
			else:
				index = vertices.size()
				vertex_index[vertex] = index
				vertices.append( vertex-terrain_offset )
				if renormalize_uvs:
					uvs.append(Vector2(
						(vertex.x - bounds.position.x) / (bounds.size.x),
						(vertex.z - bounds.position.y) / (bounds.size.y)
					))
				else:
					uvs.append( uv )
			indices.append( index )
	
	# Create and apply mesh arrays
	var mesh_arrays:Array
	mesh_arrays.resize( Mesh.ARRAY_MAX )
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, mesh_arrays )
	
	 #Update collider
	var terrain_body:StaticBody3D = SceneManager.find_or_create_node( StaticBody3D, terrain, "TerrainBody" )
	var terrain_collider:CollisionShape3D = SceneManager.find_or_create_node( CollisionShape3D, terrain_body, "TerrainCollider" )
	terrain_collider.debug_color = Color( Color.PALE_VIOLET_RED, 0.5 )
	terrain_body.process_mode = Node.PROCESS_MODE_DISABLED
	terrain_collider.shape = mesh.create_trimesh_shape()
	terrain_body.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Update texture
	terrain.material_override.set_shader_parameter("albedo_texture", texture)
	return true
	
