@tool
extends GLBuilder
class_name GLBuilderTerrain


func build_from_source() -> bool:
	_controller = _controller as GLControllerTerrain
	var source:GLBuildDataTerrain = _controller.source
	var mesh:ArrayMesh = _controller.terrain.mesh
	
	if not source.vertices_map:
		mesh.clear_surfaces()
		return true
	
	var vertices:PackedVector3Array
	var uvs:PackedVector2Array
	var vertices_values:Array[PackedVector3Array] = source.vertices_map.values()
	
	var min_x:float = INF
	var max_x:float = -INF
	var min_z:float = INF
	var max_z:float = -INF
	
	for cell_vertices in vertices_values:
		for v in cell_vertices:
			min_x = min(min_x, v.x)
			max_x = max(max_x, v.x)
			min_z = min(min_z, v.z)
			max_z = max(max_z, v.z)
	
	var size_x:float = max_x - min_x
	var size_z:float = max_z - min_z
	
	for cell_vertices in vertices_values:
		vertices.append_array( cell_vertices )
		for vertex in cell_vertices:
			uvs.append(Vector2(
				(vertex.x - min_x) / size_x,
				(vertex.z - min_z) / size_z
			))
	
	var mesh_arrays:Array
	mesh_arrays.resize( Mesh.ARRAY_MAX )
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, mesh_arrays )
	return true
	

func build_from_processed() -> bool:
	return true
