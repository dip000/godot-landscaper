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
	var enable_mask:GLBitMask = GLBitMask.new( enable_data, Mesh.ARRAY_MAX )
	var arrays:Array = mesh.surface_get_arrays( 0 )
	var new_arrays:Array = arrays.duplicate( true )
	new_arrays.resize( Mesh.ARRAY_MAX )
	
	# Cleanup arrays
	enable_mask.set_bit( Mesh.ARRAY_VERTEX )
	for bit in enable_mask:
		if enable_mask.is_clear( bit ):
			new_arrays[bit] = null
	 
	var st:SurfaceTool = SurfaceTool.new()
	st.create_from_arrays( new_arrays, Mesh.PRIMITIVE_TRIANGLES )
	
	# Regenerate Normals
	if enable_mask.is_set( Mesh.ARRAY_NORMAL ):
		st.generate_normals()
	
	# Regenerate Tangents
	if enable_mask.is_set( Mesh.ARRAY_TANGENT ):
		st.generate_tangents()
	
	# Regenerate Indices
	if enable_mask.is_set( Mesh.ARRAY_INDEX ):
		st.index()
		st.optimize_indices_for_cache()
	
	# Mesh Level Of Detail
	var lods:int = 0
	new_arrays = st.commit_to_arrays()
	if mesh_lods:
		var importer:ImporterMesh = ImporterMesh.new()
		importer.add_surface( Mesh.PRIMITIVE_TRIANGLES, new_arrays )
		importer.generate_lods( normal_merge_angle, 0, [] )
		lods = importer.get_surface_lod_count( 0 )
		mesh = importer.get_mesh()
	else:
		mesh = st.commit()
	
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
	var new_mesh_size:int = _array_bytes( new_arrays )
	GLDebug.state(
		"Grass Mesh Optimize Success. Total Vertices: %s -> %s, Data Bytes: %s -> %s, Mesh LoDs Created: %s"
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


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass Rescan Color Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	return true
