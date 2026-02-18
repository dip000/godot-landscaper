## Builder For Terrain Controllers
##
## A bit of a jaggernaut builder, it seems

@tool
extends GLBuilder
class_name GLBuilderTerrain


func build_from_dirty() -> bool:
	return build_headless( _controller.source, _controller.terrain )

func build_from_source() -> bool:
	return build_headless( _controller.source, _controller.terrain )

func build_from_processed() -> bool:
	return build_headless( _controller.processed, _controller.terrain )


## Builds from 'build_data'.
## if uvs_map is not provided, renormalizes them to scale with the bounds.
static func build_headless(build_data:GLBuildDataTerrain, terrain:MeshInstance3D) -> bool:
	var terrain_body:StaticBody3D = GLSceneManager.find_or_create_node( StaticBody3D, terrain, "TerrainBody" )
	var terrain_collider:CollisionShape3D = GLSceneManager.find_or_create_node( CollisionShape3D, terrain_body, "TerrainCollider" )
	
	if build_data.vertices_map.is_empty():
		terrain.mesh.clear_surfaces()
		terrain_collider.shape = null
		return true
	
	# Fill vertex raw data for mesh_arrays (many cheap iterations)
	# Welds vertices by default (vertex indexing)
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = build_data.vertices_map
	var uvs_map:Dictionary[Vector2i, PackedVector2Array] = build_data.uvs_map
	var vertex_colors_map:Dictionary[Vector2i, PackedColorArray] = build_data.vertex_colors_map
	var paint_vertices:bool = not vertex_colors_map.is_empty()
	var renormalize_uvs:bool = uvs_map.is_empty()
	var vertex_index:Dictionary[Vector3, int]
	var indices:PackedInt32Array
	var vertices:PackedVector3Array
	var vertex_colors:PackedColorArray
	var uvs:PackedVector2Array
	var terrain_offset:Vector3 = terrain.global_position
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	
	for cell in vertices_map:
		var cell_vertices:PackedVector3Array = vertices_map[cell]
		var cell_uvs:PackedVector2Array
		var cell_colors:PackedColorArray
		
		if not renormalize_uvs:
			cell_uvs = uvs_map[cell]
		
		if paint_vertices:
			cell_colors = vertex_colors_map[cell]
		
		for i in cell_vertices.size():
			var index:int
			var vertex:Vector3 = cell_vertices[i]
			
			if vertex_index.has( vertex ):
				index = vertex_index[vertex]
			
			else:
				index = vertices.size()
				vertex_index[vertex] = index
				vertices.append( vertex-terrain_offset )
				
				if paint_vertices:
					vertex_colors.append( cell_colors[i] )
				
				if renormalize_uvs:
					var vertex_xz:Vector2 = Vector2( vertex.x, vertex.z )
					uvs.append( (vertex_xz - bounds.position) / bounds.size )
				else:
					uvs.append( cell_uvs[i] )
			
			indices.append( index )
	
	# Create and apply mesh arrays
	var mesh_arrays:Array
	mesh_arrays.resize( Mesh.ARRAY_MAX )
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX] = indices
	if paint_vertices:
		mesh_arrays[Mesh.ARRAY_COLOR] = vertex_colors
	
	var importer:ImporterMesh = ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	importer.generate_lods(60, 0, [])
	terrain.mesh = importer.get_mesh()
	
	#var lods:Dictionary[float, PackedInt32Array]
	#for lod_index in importer.get_surface_lod_count(0):
		#var size:float = importer.get_surface_lod_size(0, lod_index)
		#lods[size] = importer.get_surface_lod_indices(0, lod_index)
	#
	## Shadow mesh
	#var shadow_mesh:ArrayMesh = ArrayMesh.new()
	#var shadow_arrays:Array
	#shadow_arrays.resize( Mesh.ARRAY_MAX )
	#shadow_arrays[Mesh.ARRAY_VERTEX] = vertices
	#shadow_arrays[Mesh.ARRAY_INDEX] = indices
	#shadow_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, shadow_arrays, [], lods )
	#terrain.mesh.shadow_mesh = shadow_mesh
	
	 #Update collider
	terrain_collider.debug_color = Color( Color.PALE_VIOLET_RED, 0.5 )
	terrain_body.process_mode = Node.PROCESS_MODE_DISABLED
	terrain_collider.shape = terrain.mesh.create_trimesh_shape()
	terrain_body.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Update textures
	for layer in build_data.layers:
		terrain.material_override.set_shader_parameter( layer.material_channel, layer.texture )
	return true







	
