## EFFECT GRASS: Interface members for all effect classes
##

@tool
extends GLEffect
class_name GLEffectGrassChunkify

enum Meta {MIN_INDEX, MAX_INDEX, COUNT}

@export var chunks_parent:NodePath
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)
@export var organize_by_chunk_parents:bool = true


func _apply(controller:GLController) -> bool:
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	if not original_mmi:
		GLDebug.error("GLController does not have a 'MultiMeshInstance3D' to chunkify")
		return false
	
	var root_parent:Node = controller.get_node_or_null( chunks_parent )
	if not root_parent:
		GLDebug.warning("Chunks Parent is invalid '%s'. Placed as a sibling of the multimesh_instance instead, select another parent node if this is not your intention." %chunks_parent)
		root_parent = original_mmi.get_parent()
		chunks_parent = controller.get_path_to( root_parent )
	
	if not _clear( controller ):
		return false
	
	var original_mm:MultiMesh = original_mmi.multimesh
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
	
	# Every original index mapped as chunks
	# This avoids making and managing arrays of ChunkX[ChunkY[Transforms[],Colors[],Colors[],Min,Max]]
	# Instead just ChunkX[ChunkY[raw[min,max,indexes]]]
	var chunked_index_map:Array[Array]
	chunked_index_map.resize( total_chunks.x )
	
	# Fill map for performance, i guess
	for x in total_chunks.x:
		chunked_index_map[x].resize( total_chunks.y )
		for y in total_chunks.y:
			# Add min, max space for later
			var raw:Array
			raw.resize( Meta.COUNT )
			raw[Meta.MIN_INDEX] = Vector3.INF
			raw[Meta.MAX_INDEX] = -Vector3.INF
			chunked_index_map[x][y] = raw
	
	
	# Remaps MultiMesh data into chunk indexes
	for original_index in original_mm.instance_count:
		var original_local_transf:Transform3D = original_mm.get_instance_transform( original_index )
		var original_global_pos:Vector3 = original_mmi.to_global( original_local_transf.origin )
		var original_global_h_pos:Vector2 = Vector2( original_global_pos.x, original_global_pos.z )
		var global_chunk_coords:Vector2i = ( original_global_h_pos / float(chunk_size) ).floor()
		
		# Make sure to index with positive numbers
		var positive:Vector2i = global_chunk_coords - lower_chunk
		var raw:Array = chunked_index_map[positive.x][positive.y]
		
		# Find Min/Max positions and store them as metadata
		# This creates a bounding box for each MultiMeshInstance3D
		raw[Meta.MIN_INDEX] = raw[Meta.MIN_INDEX].min( original_global_pos )
		raw[Meta.MAX_INDEX] = raw[Meta.MAX_INDEX].max( original_global_pos )
		raw.append( original_index )
		
		await _index(original_index)
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row_index in chunked_index_map.size():
		var row:Array = chunked_index_map[row_index]
		
		for col_index in row.size():
			# Separate Raw with indexes
			var raw:Array = row[col_index]
			var original_indexes:Array = raw.slice( Meta.COUNT )
			
			if original_indexes.size() <= 0:
				continue
			
			# Return to global; (possible) negative chunks
			var global_chunk:Vector2i = Vector2i( row_index, col_index ) + lower_chunk
			
			# Place instance either inside a slot_parent or just directly under its root_parent
			var parent:Node3D = root_parent
			if organize_by_chunk_parents:
				parent = SceneManager.find_or_create_node(Node3D, root_parent, "Chunk_%s_%s" %[global_chunk.x, global_chunk.y])
				parent.global_position = Vector3( global_chunk.x+0.5, 0 , global_chunk.y+0.5 )
				parent.global_position *= chunk_size
			
			# Place individual multimeshes in their global center position
			# Find center of the individual chunk instances (not to confuse with center of chunk)
			var local_min:Vector3 = raw[Meta.MIN_INDEX]
			var local_max:Vector3 = raw[Meta.MAX_INDEX]
			var local_center:Vector3 = local_min + 0.5*(local_max - local_min)
			var instance_mmi:MultiMeshInstance3D = SceneManager.find_or_create_node( MultiMeshInstance3D, parent, "%s_%s_%s" %[original_mmi.name, global_chunk.x, global_chunk.y] )
			instance_mmi.global_position = local_center
			
			
			# Setup MultiMesh
			_fill_mmi( instance_mmi, original_mmi )
			var instance_mm:MultiMesh = instance_mmi.multimesh
			instance_mm.instance_count = original_indexes.size()
			GLDebug.spam("Chunk[%s, %s] -> min=%s, max=%s, count=%s" %[row_index, col_index, local_min, local_max, original_indexes.size()])
			
			# Find the mapped instance data and dump it into the new Multi Meshes
			var instance_index:int = 0
			for original_index in original_indexes:
				
				# Compenzate moving the origin of the MMI Node by moving back each instance
				# By doing the whole local-global-local switcheroo, we include any rotation the referenced nodes might have
				var local_transform:Transform3D = original_mm.get_instance_transform( original_index )
				var world_pos: Vector3 = original_mmi.to_global( local_transform.origin )
				var local_pos: Vector3 = instance_mmi.to_local( world_pos )
				local_transform = Transform3D( local_transform.basis, local_pos )
				
				var colors_top:Color = original_mm.get_instance_custom_data( original_index )
				var colors_bottom:Color = original_mm.get_instance_color( original_index )
				
				instance_mm.set_instance_transform( instance_index, local_transform )
				instance_mm.set_instance_custom_data( instance_index, colors_top )
				instance_mm.set_instance_color( instance_index, colors_bottom )
				
				instance_index += 1
				await _index( instance_index )
	
	original_mmi.hide()
	GLDebug.state("Chunkified. Total chunks = %s, Total grass instances = %s" %[total_chunks, original_mm.instance_count])
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
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	if not original_mmi:
		return true
	
	var root_parent:Node = controller.get_node_or_null( chunks_parent )
	if not root_parent:
		return true
	
	original_mmi.show()
	for node in root_parent.get_children():
		var is_as_chunk_parent:bool = node.name.begins_with( "Chunk" )
		var is_as_original:bool = node.name.begins_with( original_mmi.name )
		var is_original:bool = (node.name == original_mmi.name)
		
		if is_as_chunk_parent or (is_as_original and not is_original):
			node.queue_free()
	
	return true
	
