@tool
extends Resource
class_name OptimizationQuadGrass

const META_MIN_INDEX:int = 0
const META_MAX_INDEX:int = 1
const META_COUNT:int = 2

static var _tool:QuadGrassTool
static var _chunks_parent:Node
static var _anchor_node:Node3D


static func _check_refs() -> bool:
	if not Landscaper.running():
		return false
	
	_tool = Landscaper.tool
	if not _tool:
		return false
	
	_anchor_node = _tool.anchor_node
	if not _anchor_node:
		GLDebug.error("Gruond mesh is null")
		return false
	
	return true
	

static func _for_each_base_mmi(callback:Callable):
	for instance in _anchor_node.get_children():
		if instance is MultiMeshInstance3D:
			callback.call( instance )


static func _for_each_chunk_mmi(callback:Callable):
	var chunks_parent:Node = _anchor_node.get_node_or_null( _tool.chunk_parent_name )
	
	if not chunks_parent:
		return
	
	for chunk in chunks_parent.get_children():
		for instance in chunk.get_children():
			if instance is MultiMeshInstance3D:
				callback.call( instance )


static func is_chunkified() -> bool:
	if not _check_refs():
		return false
	
	var chunks_parent:Node = _tool.anchor_node.get_node_or_null( _tool.chunk_parent_name )
	if not chunks_parent:
		return false
	
	return (chunks_parent.get_child_count() > 0)


static func chunkify():
	if not _check_refs():
		return
	
	if _tool.chunk_size < 4:
		GLDebug.error("Cannot chunkify below 4 meters!")
		return
	
	# Find or create chunks' parent
	SceneManager.find_or_create_node( Node3D, _tool.anchor_node, _tool.chunk_parent_name )
	
	_for_each_base_mmi(
		func(instance):
			# According to very trustfull sources (ChatGPT), hiding visuals will stop shaders and rendering loads
			instance.hide()
			_chunkify_variant( instance )
	)
	
	GLDebug.state("Chunkified MultiMeshInstance3D")


static func reset_chunks():
	if not _check_refs():
		return
	
	# Show original instances.
	_for_each_base_mmi( func(instance):
		instance.show()
	)
	
	# Delete chunkified instances
	var chunks_parent:Node = _anchor_node.get_node_or_null( _tool.chunk_parent_name )
	if chunks_parent:
		chunks_parent.queue_free()
	
	GLDebug.state("Chunks Reseted")


static func update_visiblity():
	if not _check_refs():
		return
	
	_for_each_base_mmi( func(instance):
		instance.multimesh.visible_instance_count = instance.multimesh.instance_count*_tool.visible_instances
		instance.visibility_range_end = _tool.custom_lod_meters
		instance.visibility_range_end_margin = 2.0
	)
	_for_each_chunk_mmi(func(instance):
		instance.multimesh.visible_instance_count = instance.multimesh.instance_count*_tool.visible_instances
		instance.visibility_range_end = _tool.custom_lod_meters
		instance.visibility_range_end_margin = 2.0
	)
	
	GLDebug.state("Visibility Updated")


static func reset_visible():
	if not _check_refs():
		return
	
	_for_each_base_mmi( func(instance):
		instance.multimesh.visible_instance_count = -1
		instance.visibility_range_end = 0
		instance.visibility_range_end_margin = 0
	)
	_for_each_chunk_mmi(func(instance):
		instance.multimesh.visible_instance_count = -1
		instance.visibility_range_end = 0
		instance.visibility_range_end_margin = 0
	)
	
	GLDebug.state("Visibility Reseted")


## Welp, this function took a toll on me ngl
static func _chunkify_variant(original_mmi:MultiMeshInstance3D):
	var original_mm:MultiMesh = original_mmi.multimesh
	var chunk_size:int = _tool.chunk_size
	var root_parent:Node = _tool.anchor_node.get_node( _tool.chunk_parent_name )
	
	var aabb:AABB = original_mmi.get_aabb()
	var size:Vector3 = aabb.size
	var pos:Vector3 = aabb.position
	var lower_bound:Vector3 = pos + original_mmi.global_position
	var upper_bound:Vector3 = pos + size + original_mmi.global_position
	var lower_chunk:Vector2i = (Vector2(lower_bound.x, lower_bound.z) / float(chunk_size)).floor()
	var upper_chunk:Vector2i = (Vector2(upper_bound.x, upper_bound.z) / float(chunk_size)).floor()
	var total_chunks:Vector2i = upper_chunk - lower_chunk + Vector2i.ONE
	
	GLDebug.internal("------------------------------")
	GLDebug.internal("LowerBound: %s, UpperBound: %s" %[lower_bound, upper_bound])
	GLDebug.internal("LowerChunk: %s, UpperChunk: %s" %[lower_chunk, upper_chunk])
	GLDebug.internal("TotalChunks: %s" %total_chunks)
	
	# Every original index mapped as chunks
	# This avoids making and managing arrays of ChunkX[ChunkY[Transforms[],Colors[],Colors[],Min,Max]]
	# Instead just ChunkX[ChunkY[raw[min,max,indexes]]]
	var chunked_index_map:Array[Array]
	chunked_index_map.resize(total_chunks.x)
	
	# Fill map for performance, i guess
	for x in total_chunks.x:
		chunked_index_map[x].resize(total_chunks.y)
		for y in total_chunks.y:
			# Add min, max space for later
			var raw:Array
			raw.resize(META_COUNT)
			raw[META_MIN_INDEX] = Vector3.INF
			raw[META_MAX_INDEX] = -Vector3.INF
			chunked_index_map[x][y] = raw
	
	
	# Remaps MultiMesh data into chunk indexes
	for original_index in original_mm.instance_count:
		var original_local_transf:Transform3D = original_mm.get_instance_transform( original_index )
		var original_global_pos:Vector3 = original_mmi.to_global( original_local_transf.origin )
		var original_global_h_pos:Vector2 = Vector2(original_global_pos.x, original_global_pos.z)
		var global_chunk_coords:Vector2i = ( original_global_h_pos / float(chunk_size)).floor()
		
		# Make sure to index with positive numbers
		var positive:Vector2i = global_chunk_coords - lower_chunk
		var raw:Array = chunked_index_map[positive.x][positive.y]
		
		# Find Min/Max positions and store them as metadata
		# This creates a bounding box for each MultiMeshInstance3D
		raw[META_MIN_INDEX] = raw[META_MIN_INDEX].min( original_global_pos )
		raw[META_MAX_INDEX] = raw[META_MAX_INDEX].max( original_global_pos )
		raw.append( original_index )
		
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row_index in chunked_index_map.size():
		var row:Array = chunked_index_map[row_index]
		
		for col_index in row.size():
			# Separate Raw with indexes
			var raw:Array = row[col_index]
			var original_indexes:Array = raw.slice( META_COUNT )
			
			if original_indexes.size() <= 0:
				continue
			
			# Return to global (possible) negative chunks
			var global_chunk:Vector2i = Vector2i( row_index, col_index ) + lower_chunk
			
			# Find center of the chunk instances (not to confuse with center of chunk)
			var global_min:Vector3 = raw[META_MIN_INDEX]
			var global_max:Vector3 = raw[META_MAX_INDEX]
			var global_center:Vector3 = global_min + 0.5*(global_max - global_min)
			
			# Place slot holders right in the middle of the chunk
			var slot_parent:Node3D = SceneManager.find_or_create_node(Node3D, root_parent, "Chunk_%s_%s" %[global_chunk.x, global_chunk.y])
			var instance_mmi:MultiMeshInstance3D = SceneManager.find_or_create_node(MultiMeshInstance3D, slot_parent, "%s_%s_%s" %[original_mmi.name, global_chunk.x, global_chunk.y])
			slot_parent.global_position = Vector3(global_chunk.x+0.5, 0 , global_chunk.y+0.5)
			slot_parent.global_position *= chunk_size
			
			# Place individual multimeshes in their global center position
			instance_mmi.global_position = global_center
			
			# Setup MultiMesh
			_fill_mmi(instance_mmi, original_mmi)
			var instance_mm:MultiMesh = instance_mmi.multimesh
			instance_mm.instance_count = original_indexes.size()
			GLDebug.spam("Chunk[row,col](%s,%s) = Raw[min,max,indexes.size()]%s" %[row_index, col_index, raw.size()])
			
			# Find the mapped instance data and dump it into the new Multi Meshes
			var instance_index:int = 0
			for original_index in original_indexes:
				
				# Compenzate moving the origin of the MMI Node by moving back each instance
				# By doing the whole local-global-local switcheroo, we include any rotation the referenced nodes might have
				var local_transform:Transform3D = original_mm.get_instance_transform( original_index )
				var world_pos: Vector3 = original_mmi.to_global(local_transform.origin)
				var local_pos: Vector3 = instance_mmi.to_local(world_pos)
				local_transform = Transform3D(local_transform.basis, local_pos)
				
				var colors_top:Color = original_mm.get_instance_custom_data( original_index )
				var colors_bottom:Color = original_mm.get_instance_color( original_index )
				
				instance_mm.set_instance_transform( instance_index, local_transform )
				instance_mm.set_instance_custom_data( instance_index, colors_top )
				instance_mm.set_instance_color( instance_index, colors_bottom )
				
				instance_index += 1
	
	

static func _fill_mmi(new_mmi:MultiMeshInstance3D, original_mmi:MultiMeshInstance3D):
	new_mmi["instance_shader_parameters/variant_index"] = original_mmi["instance_shader_parameters/variant_index"]
	new_mmi.multimesh = MultiMesh.new()
	new_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_mmi.multimesh.mesh = original_mmi.multimesh.mesh
	new_mmi.multimesh.use_custom_data = true
	new_mmi.multimesh.use_colors = true
	
