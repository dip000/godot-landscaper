## Builder For Terrain Controllers
##

@tool
extends GLBuilder
class_name GLBuilderTerrain


func build(from_data:GLBuildData) -> bool:
	return build_headless( from_data, _controller.terrain )


func quick_start(from_data:GLBuildData):
	from_data = from_data as GLBuildDataTerrain
	_controller = _controller as GLControllerTerrain
	var terrain:MeshInstance3D = _controller.terrain
	
	# Build nodes
	if not terrain:
		terrain = GLSceneManager.find_or_create_node(MeshInstance3D, _controller, _controller.name)
	if not terrain.mesh:
		terrain.mesh = ArrayMesh.new()
	
	var terrain_offset:Vector3 = terrain.global_position
	var terrain_body:StaticBody3D = GLSceneManager.find_or_create_node( StaticBody3D, terrain, "TerrainBody" )
	var terrain_collider:CollisionShape3D = GLSceneManager.find_or_create_node( CollisionShape3D, terrain_body, "TerrainCollider" )
	
	# Update textures
	for layer in from_data.layers:
		terrain.material_override.set_shader_parameter( layer.sampler, layer.texture )
	
	# Update shape
	if from_data.vertices_map.is_empty():
		terrain.mesh.clear_surfaces()
		terrain_collider.shape = null
	
	# Make sure to have everything wired correctly
	_controller.terrain = terrain
	from_data.material.shader = from_data.shader
	terrain.material_override = from_data.material


func quick_build(from_data:GLBuildData) -> bool:
	from_data = from_data as GLBuildDataTerrain
	_controller = _controller as GLControllerTerrain
	var terrain:MeshInstance3D = _controller.terrain
	var terrain_offset:Vector3 = terrain.global_position
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = from_data.vertices_map
	var vertices:PackedVector3Array
	var uvs:PackedVector2Array
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	
	for cell_vertices in vertices_map.values():
		for vertex in cell_vertices:
			vertices.append( vertex-terrain_offset )
			var vertex_xz:Vector2 = Vector2( vertex.x, vertex.z )
			uvs.append( (vertex_xz - bounds.position) / bounds.size )
	
	# Create and apply mesh arrays
	terrain.mesh.clear_surfaces()
	if vertices:
		var mesh_arrays:Array
		mesh_arrays.resize( Mesh.ARRAY_MAX )
		mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
		mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
		terrain.mesh.clear_surfaces()
		terrain.mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, mesh_arrays )
	return true


func quick_end(from_data:GLBuildData) -> bool:
	return build_headless( from_data, _controller.terrain )


## Generates Shadow Mesh, vertex indexing, LoDs, normals, tangents, and colliders.
## Generates 'uvs_map' if not provided. Adds 'vertex_colors_map' if provided.
static func build_headless(build_data:GLBuildDataTerrain, terrain:MeshInstance3D) -> bool:
	var terrain_body:StaticBody3D = GLSceneManager.find_or_create_node( StaticBody3D, terrain, "TerrainBody" )
	var terrain_collider:CollisionShape3D = GLSceneManager.find_or_create_node( CollisionShape3D, terrain_body, "TerrainCollider" )
	
	if build_data.vertices_map.is_empty():
		terrain.mesh.clear_surfaces()
		terrain_collider.shape = null
		return true
	
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = build_data.vertices_map
	var uvs_map:Dictionary[Vector2i, PackedVector2Array] = build_data.uvs_map
	var vertex_colors_map:Dictionary[Vector2i, PackedColorArray] = build_data.vertex_colors_map
	var paint_vertices:bool = not vertex_colors_map.is_empty()
	var renormalize_uvs:bool = uvs_map.is_empty()
	var terrain_offset:Vector3 = terrain.global_position
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	var st:SurfaceTool = SurfaceTool.new()
	st.begin( Mesh.PRIMITIVE_TRIANGLES )
	
	for cell in vertices_map:
		var cell_vertices:PackedVector3Array = vertices_map[cell]
		
		for i in cell_vertices.size():
			var vertex:Vector3 = cell_vertices[i]
			
			if renormalize_uvs:
				var vertex_xz:Vector2 = Vector2( vertex.x, vertex.z )
				st.set_uv( (vertex_xz - bounds.position) / bounds.size )
			else:
				st.set_uv( uvs_map[cell][i] )
			
			if paint_vertices:
				st.set_color( vertex_colors_map[cell][i] )
			
			st.add_vertex( vertex-terrain_offset )
	
	# Optimizaions from SurfaceTool
	st.generate_normals()
	st.generate_tangents()
	st.index()
	st.optimize_indices_for_cache()
	var mesh_arrays:Array = st.commit_to_arrays()
	
	# Generate LoD from ImporterMesh
	var importer:ImporterMesh = ImporterMesh.new()
	importer.add_surface( Mesh.PRIMITIVE_TRIANGLES, mesh_arrays )
	importer.generate_lods( 60, 0, [] )
	terrain.mesh = importer.get_mesh()
	
	var lods:Dictionary[float, PackedInt32Array]
	for lod_index in importer.get_surface_lod_count(0):
		var size:float = importer.get_surface_lod_size(0, lod_index)
		lods[size] = importer.get_surface_lod_indices(0, lod_index)
	
	# Shadow mesh
	var shadow_mesh:ArrayMesh = ArrayMesh.new()
	var shadow_arrays:Array
	shadow_arrays.resize( Mesh.ARRAY_MAX )
	shadow_arrays[Mesh.ARRAY_VERTEX] = mesh_arrays[Mesh.ARRAY_VERTEX]
	shadow_arrays[Mesh.ARRAY_INDEX] = mesh_arrays[Mesh.ARRAY_INDEX]
	shadow_mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, shadow_arrays, [], lods )
	terrain.mesh.shadow_mesh = shadow_mesh
	
	# Update collider
	terrain_collider.debug_color = Color( Color.PALE_VIOLET_RED, 0.5 )
	terrain_body.process_mode = Node.PROCESS_MODE_DISABLED
	terrain_collider.shape = terrain.mesh.create_trimesh_shape()
	terrain_body.process_mode = Node.PROCESS_MODE_INHERIT
	
	# Update textures
	for layer in build_data.layers:
		terrain.material_override.set_shader_parameter( layer.sampler, layer.texture )
	return true






	
