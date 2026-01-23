## EFFECT GRASS: Interface members for all effect classes
##

## MultiMeshInstance3D Chunkifyier
##
## The chunks are split in absolute world coordinates, including negatives

@tool
extends GLEffect
class_name GLEffectGrassChunkify

## The size squared to split the grass instances.
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)

## The chunks holder.
@export var root_parent_path:NodePath = "."


func _apply(controller:GLController) -> bool:
	if not _clear( controller ):
		GLDebug.error("Chunkifying is not possible: Clearing chunks failed")
		return false
		
	controller = controller as GLControllerGrass
	var processed:GLBuildDataGrass = controller.processed
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var root_parent:Node = controller.get_node_or_null( root_parent_path )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	var aabb:AABB = original_mmi.get_aabb()
	var size:Vector3 = aabb.size
	var pos:Vector3 = aabb.position
	var lower_bound:Vector3 = pos + original_mmi.global_position
	var upper_bound:Vector3 = pos + size + original_mmi.global_position
	var lower_chunk:Vector2i = (Vector2(lower_bound.x, lower_bound.z) / float(chunk_size)).floor()
	var upper_chunk:Vector2i = (Vector2(upper_bound.x, upper_bound.z) / float(chunk_size)).floor()
	var total_chunks:Vector2i = upper_chunk - lower_chunk + Vector2i.ONE
	
	GLDebug.internal("LowerBound: %s, UpperBound: %s" %[lower_bound, upper_bound])
	GLDebug.internal("LowerChunk: %s, UpperChunk: %s" %[lower_chunk, upper_chunk])
	GLDebug.internal("TotalChunks: %s" %total_chunks)
	
	# Organized map of chunks, example: chunks[x][y].transforms[i]
	var chunks:Array[Array]
	chunks.resize( total_chunks.x )
	
	# Fill map for performance, i guess
	for x in total_chunks.x:
		chunks[x].resize( total_chunks.y )
		for y in total_chunks.y:
			chunks[x][y] = GLBuildDataGrass.new()
	
	# Remaps MultiMesh data into chunk indexes
	for original_index in processed.size():
		var original_local_transf:Transform3D = processed.transforms[original_index]
		var original_global_pos:Vector3 = original_mmi.to_global( original_local_transf.origin )
		var original_global_h_pos:Vector2 = Vector2( original_global_pos.x, original_global_pos.z )
		var global_chunk_coords:Vector2i = ( original_global_h_pos / float(chunk_size) ).floor()
		
		# Make sure to index with positive numbers
		var positive:Vector2i = global_chunk_coords - lower_chunk
		var chunk:GLBuildDataGrass = chunks[positive.x][positive.y]
		
		# Find Min/Max positions creating a bounding box for each MultiMeshInstance3D
		chunk.min = chunk.min.min( original_global_pos )
		chunk.max = chunk.max.max( original_global_pos )
		chunk.transforms.append( original_local_transf )
		chunk.top_colors.append( processed.top_colors[original_index] )
		chunk.bottom_colors.append( processed.bottom_colors[original_index] )
		
		await _index(original_index)
	
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row_index in chunks.size():
		var chunk_rows:Array[GLBuildDataGrass] = chunks[row_index]
		
		for col_index in chunk_rows.size():
			var chunk:GLBuildDataGrass = chunk_rows[col_index]
			
			# Return to global; (possible) negative chunks
			var global_chunk:Vector2i = Vector2i( row_index, col_index ) + lower_chunk
			
			# Place instance inside a chunk folder
			var parent:Node = SceneManager.find_or_create_node( Node, root_parent, _format_chunk(global_chunk) )
			
			# Place individual multimeshes in their global center position
			# Find center of the individual chunk instances (not to confuse with center of chunk)
			var local_min:Vector3 = chunk.min
			var local_max:Vector3 = chunk.max
			var local_center:Vector3 = local_min + 0.5*(local_max - local_min)
			var instance_mmi:MultiMeshInstance3D = SceneManager.find_or_create_node( MultiMeshInstance3D, parent, original_mmi.name )
			instance_mmi.global_position = local_center
			
			# Setup MultiMesh
			_fill_mmi( instance_mmi, original_mmi )
			var instance_mm:MultiMesh = instance_mmi.multimesh
			instance_mm.instance_count = chunk.size()
			GLDebug.spam("Chunk[%s, %s] -> min=%s, max=%s, count=%s" %[row_index, col_index, local_min, local_max, instance_mm.instance_count])
			
			# Move the instance data from the original_mmi to the chunked instance_mmi
			for instance_index in instance_mm.instance_count:
				
				# Compenzate moving the origin of the MMI Node by moving back each instance
				# By doing the whole local-global-local switcheroo, we include any rotation the referenced nodes might have
				var local_transform:Transform3D = chunk.transforms[instance_index]
				var world_pos: Vector3 = original_mmi.to_global( local_transform.origin )
				var local_pos: Vector3 = instance_mmi.to_local( world_pos )
				local_transform = Transform3D( local_transform.basis, local_pos )
				
				instance_mm.set_instance_transform( instance_index, local_transform )
				instance_mm.set_instance_color( instance_index, chunk.top_colors[instance_index] )
				instance_mm.set_instance_custom_data( instance_index, chunk.bottom_colors[instance_index] )
				
				await _index( instance_index )
	
	original_mmi.hide()
	GLDebug.state("Chunkified. Total chunks = %s, Total grass instances = %s" %[total_chunks, processed.size()])
	return true


func _fill_mmi(new_mmi:MultiMeshInstance3D, original_mmi:MultiMeshInstance3D):
	new_mmi["instance_shader_parameters/texture_layer"] = original_mmi["instance_shader_parameters/texture_layer"]
	new_mmi.visibility_range_end = original_mmi.visibility_range_end
	new_mmi.visibility_range_end_margin = original_mmi.visibility_range_end_margin
	new_mmi.multimesh = MultiMesh.new()
	new_mmi.multimesh.visible_instance_count = original_mmi.multimesh.visible_instance_count
	new_mmi.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	new_mmi.multimesh.mesh = original_mmi.multimesh.mesh
	new_mmi.multimesh.use_custom_data = true
	new_mmi.multimesh.use_colors = true
	

func _clear(controller:GLController) -> bool:
	controller = controller as GLControllerGrass
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var root_parent:Node = controller.get_node_or_null( root_parent_path )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	original_mmi.show()
	
	# Delete MultiMeshInstance3D chunk by name if it's inside
	for chunk in root_parent.get_children():
		for node in chunk.get_children():
			if node is MultiMeshInstance3D and node.name == original_mmi.name:
				node.free()
	
	# Clean up empty "folders"
	for node in root_parent.get_children():
		var is_chunk_parent:bool = node.name.begins_with( "Chunk" )
		var is_empty:bool = (node.get_child_count() <= 0)
		if is_chunk_parent and is_empty:
			node.queue_free()
	
	return true
	
