@tool
extends GLBuilder
class_name GLBuilderTerrain


func build_from_source() -> bool:
	_controller = _controller as GLControllerTerrain
	var source:GLBuildDataTerrain = _controller.source
	var terrain:MeshInstance3D = _controller.terrain
	var mesh:ArrayMesh = terrain.mesh
	
	if not source.vertices_map:
		mesh.clear_surfaces()
		return true
	
	# Find bounds with the mesh instance
	var bounds:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( terrain )
	
	# Fill vertex raw data for mesh_arrays (many cheap iterations)
	# Welds vertices by default (vertex indexing)
	var vertices_values:Array[PackedVector3Array] = source.vertices_map.values()
	var vertex_index:Dictionary[Vector3, int]
	var indices:PackedInt32Array
	var vertices:PackedVector3Array
	var uvs:PackedVector2Array
	
	for cell_vertices in vertices_values:
		for vertex in cell_vertices:
			var index:int
			if vertex_index.has( vertex ):
				index = vertex_index[vertex]
			else:
				index = vertices.size()
				vertex_index[vertex] = index
				vertices.append( vertex )
				uvs.append(Vector2(
					(vertex.x - bounds.position.x) / (bounds.size.x),
					(vertex.z - bounds.position.y) / (bounds.size.y)
				))
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
	_controller.texture.set_image( source.image )
	return true
	

func build_from_processed() -> bool:
	return true
