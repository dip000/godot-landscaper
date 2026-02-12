@tool
extends GLEffect
class_name GLGrassOptimize

@export_custom(PROPERTY_HINT_SAVE_FILE, "*.mesh,*.tres,*.res") var output_mesh_file_path:String = "res://mesh.res"
@export_group("Mesh LoD")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Mesh LoD", PROPERTY_USAGE_EDITOR) var mesh_lods:bool = true
@export var normal_merge_angle:float = 40

@export_group("Vertex Data")
@export_flags(
	"Vertex", "Normals", "Tangents", "Colors", "UV", "UV2", "Custom0", "Custom1", "Custom2", "Custom3", "Bones", "Weights", "Indices"
) var enable_data:int = 0b1000000010001


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Color Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	
	var processed:GLBuildDataGrass = controller.processed
	var mesh:Mesh = processed.mesh
	var arrays:Array = mesh.surface_get_arrays( 0 )
	var lods:int = 0
	var new_arrays:Array
	new_arrays.resize( Mesh.ARRAY_MAX )
	
	# Cleanup arrays. Vertices are a must
	var enable_mask:GLBitMask = GLBitMask.new( enable_data, Mesh.ARRAY_MAX )
	enable_mask.set_bit( Mesh.ARRAY_VERTEX )
	
	for bit in enable_mask:
		if enable_mask.is_set( bit ):
			new_arrays[bit] = arrays[bit]
	
	# Apply vertex welding if requested and not already indexed
	if enable_mask.is_set(Mesh.ARRAY_INDEX) and arrays[Mesh.ARRAY_INDEX].is_empty():
		_weld_vertex( new_arrays )
	
	# Apply LoD
	if mesh_lods:
		var importer:ImporterMesh = ImporterMesh.new()
		importer.add_surface( Mesh.PRIMITIVE_TRIANGLES, new_arrays )
		importer.generate_lods( normal_merge_angle, 0, [] )
		lods = importer.get_surface_lod_count( 0 )
		mesh = importer.get_mesh()
	else:
		mesh = ArrayMesh.new()
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays( Mesh.PRIMITIVE_TRIANGLES, new_arrays )
	
	# Save mesh
	var err:int = ResourceSaver.save( mesh, output_mesh_file_path )
	if err != OK:
		GLDebug.error( "Grass Mesh Optimized Failed: Save Error. %s" %error_string(err) )
		return false
	
	await _frame()
	processed.mesh = load( output_mesh_file_path )
	
	# Statistics
	var prev_total_vertices:int = arrays[Mesh.ARRAY_VERTEX].size()
	var new_total_vertices:int = new_arrays[Mesh.ARRAY_VERTEX].size()
	var prev_mesh_size:int = _array_bytes( arrays )
	var new_mesh_size:int = _array_bytes( mesh.surface_get_arrays(0) )
	GLDebug.state(
		"Grass Mesh Optimized Success. Total Vertices: %s -> %s, Data Bytes: %s -> %s, Mesh LoDs Created: %s"
		%[prev_total_vertices, new_total_vertices, prev_mesh_size, new_mesh_size, lods]
	)
	return true


func _array_bytes(arrays:Array) -> int:
	var bits:int = 0
	for array in arrays:
		if not array or array.is_empty():
			continue
		
		var type_size:int = 0
		match typeof( array ):
			TYPE_PACKED_BYTE_ARRAY: type_size = 8
			TYPE_PACKED_INT32_ARRAY: type_size = 32
			TYPE_PACKED_FLOAT32_ARRAY: type_size = 32
			TYPE_PACKED_VECTOR2_ARRAY: type_size = 32 * 2
			TYPE_PACKED_VECTOR3_ARRAY: type_size = 32 * 3
			TYPE_PACKED_COLOR_ARRAY: type_size = 32 * 4
		bits += array.size() * type_size
	return bits / 8.0


func _weld_vertex(arrays:Array) -> Array:
	var vertices:PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var new_indices:PackedInt32Array
	var vertex_index:Dictionary[Vector3, int]
	var indexed_arrays:Array
	
	for i in vertices.size():
		var index:int
		var vertex:Vector3 = vertices[i]
		
		if vertex_index.has( vertex ):
			index = vertex_index[vertex]
		
		else:
			index = arrays[Mesh.ARRAY_VERTEX].size()
			vertex_index[vertex] = index
			
			for array_type in arrays.size():
				if arrays[array_type]:
					indexed_arrays.append( arrays[array_type][i] )
		
		new_indices.append( index )
	indexed_arrays[Mesh.ARRAY_INDEX] = new_indices
	return indexed_arrays


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Color Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	return true
