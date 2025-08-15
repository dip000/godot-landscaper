@tool
extends Resource
class_name OptimizationQuadGrass

static var chunkified:bool


static func chunkify():
	if not Landscaper.running():
		return
	
	var tool:QuadGrassTool = Landscaper.tool
	var parent:Node = tool.chunks_parent
	if not parent:
		tool.chunks_parent = tool
		parent = tool
	
	if tool.chunk_size < 4:
		GLDebug.error("Cannot chunkify below 4 meters!")
		return
	
	for instance in tool.parent_node.get_children():
		if instance is MultiMeshInstance3D:
			instance.hide()
			_apply_to_instance( parent, instance )
	
	chunkified = true
	GLDebug.state("Chunkified MultiMeshInstance3D")


static func reset_chunks():
	if not Landscaper.running():
		return
	
	var tool:QuadGrassTool = Landscaper.tool
	var parent:Node = tool.chunks_parent
	if not parent:
		tool.chunks_parent = tool
		parent = tool
	
	# Show original instances
	for node in tool.parent_node.get_children():
		if node is MultiMeshInstance3D:
			node.show()
	
	# Delete chunkified instances
	for grass_type in parent.get_children():
		if grass_type is MultiMeshInstance3D:
			continue
		if grass_type.name.contains("Chunk"):
			grass_type.queue_free()
	
	chunkified = false
	GLDebug.state("Chunks Reseted")


static func update_visiblity():
	if not Landscaper.running():
		return
	
	var tool:QuadGrassTool = Landscaper.tool
	var holder:Node = tool.chunks_parent
	if not holder:
		tool.chunks_parent = tool
		holder = tool
	
	# Original instances
	for node in tool.parent_node.get_children():
		if node is MultiMeshInstance3D:
			node.multimesh.visible_instance_count = node.multimesh.instance_count*tool.visible_instances
			node.visibility_range_end = tool.custom_lod_meters
			node.visibility_range_end_margin = 2.0
	
	# Chunkified instances
	for row in holder.get_children():
		for col in row.get_children():
			for variant in col.get_children():
				if variant is MultiMeshInstance3D:
					variant.multimesh.visible_instance_count = variant.multimesh.instance_count*tool.visible_instances
					variant.visibility_range_end = tool.custom_lod_meters
					variant.visibility_range_end_margin = 2.0

	GLDebug.state("Visibility Updated")


static func reset_visible():
	if not Landscaper.running():
		return
	
	var tool:QuadGrassTool = Landscaper.tool
	var holder:Node = tool.chunks_parent
	if not holder:
		tool.chunks_parent = tool
		holder = tool
	
	# Original instances
	for node in tool.parent_node.get_children():
		if node is MultiMeshInstance3D:
			node.multimesh.visible_instance_count = -1
			node.visibility_range_end = 0
			node.visibility_range_end_margin = 0
	
	# Chunkified instances
	for row in holder.get_children():
		for col in row.get_children():
			for variant in col.get_children():
				if variant is MultiMeshInstance3D:
					variant.multimesh.visible_instance_count = -1
					variant.visibility_range_end = 0
					variant.visibility_range_end_margin = 0

	GLDebug.state("Visibility Reseted")




const META_MIN_INDEX:int = 0
const META_MAX_INDEX:int = 1
const META_COUNT:int = 2

static func _apply_to_instance(root_parent:Node, original_mmi:MultiMeshInstance3D):
	var tool:QuadGrassTool = Landscaper.tool
	var aabb:AABB = original_mmi.get_aabb()
	var size:Vector3 = aabb.size
	var pos:Vector3 = aabb.position
	var lower_bound:Vector3 = pos + original_mmi.global_position
	var upper_bound:Vector3 = pos + size + original_mmi.global_position
	var lower_chunk:Vector2i = (Vector2(lower_bound.x, lower_bound.z) / float(tool.chunk_size)).floor()
	var upper_chunk:Vector2i = (Vector2(upper_bound.x, upper_bound.z) / float(tool.chunk_size)).floor()
	var total_chunks:Vector2i = upper_chunk - lower_chunk + Vector2i.ONE
	
	GLDebug.internal("LowerBound: %s, UpperBound: %s" %[lower_bound, upper_bound])
	GLDebug.internal("LowerChunk: %s, UpperChunk: %s" %[lower_chunk, upper_chunk])
	GLDebug.internal("TotalChunks: %s" %total_chunks)
	
	# Move the parent to the instance so every calculation over the children can be local
	var variant_h_position := Vector2(original_mmi.global_position.x, original_mmi.global_position.z) 
	
	# Every original index mapped as chunks
	var chunked_index_map:Array[Array]
	chunked_index_map.resize(total_chunks.x)
	
	# Fill map for performance, i guess
	for x in total_chunks.x:
		chunked_index_map[x].resize(total_chunks.y)
		for y in total_chunks.y:
			# Add metadata for later
			var raw:Array
			raw.resize(META_COUNT)
			raw[META_MIN_INDEX] = Vector3.INF
			raw[META_MAX_INDEX] = -Vector3.INF
			chunked_index_map[x][y] = raw
	
	
	# Remaps MultiMesh data in chunk indexes
	var original_mm:MultiMesh = original_mmi.multimesh
	lower_chunk = lower_chunk.abs()
	for original_index in original_mm.instance_count:
		var transf:Transform3D = original_mm.get_instance_transform( original_index )
		var original_pos:Vector3 = transf.origin
		var h_pos:Vector2 = Vector2(original_pos.x, original_pos.z)
		var chunk_coords:Vector2i = ( h_pos / float(tool.chunk_size)).floor()
		
		# Make sure to index with positive numbers
		var positive_x:int = chunk_coords.x + lower_chunk.x
		var positive_y:int = chunk_coords.y + lower_chunk.y
		var raw:Array = chunked_index_map[positive_x][positive_y]
		
		# Find Min/Max positions and store them as metadata
		# This creates a bounding box for each MultiMeshInstance3D
		raw[META_MIN_INDEX] = raw[META_MIN_INDEX].min( original_pos )
		raw[META_MAX_INDEX] = raw[META_MAX_INDEX].max( original_pos )
		raw.append( original_index )
		
	
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row_index in chunked_index_map.size():
		var row:Array = chunked_index_map[row_index]
		var row_parent:Node3D = SceneManager.find_or_create_node(Node3D, root_parent, "ChunkRow%s"%row_index)
		
		for col_index in row.size():
			# Separate Raw with indexes
			var raw:Array = row[col_index]
			var original_indexes:Array = raw.slice(META_COUNT)
			
			if original_indexes.size() <= 0:
				continue
			
			# Find center of all instances to center the MultiMeshInstance3D correctly
			var min:Vector3 = raw[META_MIN_INDEX]
			var max:Vector3 = raw[META_MAX_INDEX]
			var center:Vector3 = min + 0.5*(max - min)
			
			var col_parent:Node3D = SceneManager.find_or_create_node(Node3D, row_parent, "ChunkCol%s" %col_index)
			var instance_mmi:MultiMeshInstance3D = SceneManager.find_or_create_node(MultiMeshInstance3D, col_parent, "%s_%s_%s" %[original_mmi.name, row_index, col_index])
			_fill_mmi(instance_mmi, original_mmi)
			instance_mmi.global_position = center
			
			var instance_mm:MultiMesh = instance_mmi.multimesh
			instance_mm.instance_count = original_indexes.size()
			GLDebug.spam("Chunk[row,col](%s,%s) = Raw[min,max,indexes]%s" %[row_index, col_index, raw])
			
			# Find the mapped instance data and dump it to the new Multi Mesh Instances
			var instance_index:int = 0
			for original_index in original_indexes:
				var transform:Transform3D = original_mm.get_instance_transform( original_index )
				transform = transform.translated(-center)
				
				var colors_top:Color = original_mm.get_instance_custom_data( original_index )
				var colors_bottom:Color = original_mm.get_instance_color( original_index )
				
				instance_mm.set_instance_transform( instance_index, transform )
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
	
