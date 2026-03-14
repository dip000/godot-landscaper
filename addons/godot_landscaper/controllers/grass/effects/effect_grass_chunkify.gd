## MultiMeshInstance3D Chunkifyier
##
## The chunks are split in absolute world coordinates, including negatives

@tool
extends GLEffect
class_name GLGrassChunkify

## The size squared to split the grass instances.
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)

## The chunks holder root. Can be the scene root
@export var root_node:NodePath = "."

## Creates all [Node3D] in path if they don't exists.
## This let's you organize the scene as you like.[br]
## - [code]{x}[/code] Will be replaced for the X coordinate of the world chunk.[br]
## - [code]{y}[/code] Will be replaced for the Y coordinate of the world chunk.
@export var root_to_instance:String = "Chunk_{x}_{y}/Grass"


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Chunkifying failed: This effect is only valid for GLControllerGrass controller types")
		return false
		
	if not _clear( controller ):
		GLDebug.error("Chunkifying failed: Clearing chunks failed")
		return false
	
	root_to_instance = root_to_instance.simplify_path()
	if not root_to_instance.contains("{x}") or not root_to_instance.contains("{y}"):
		GLDebug.error("Chunkifying failed: root_to_instance does not contain '{x}' or '{y}'. Please add the placeholder text required")
		return false
	
	controller = controller as GLControllerGrass
	var processed:GLBuildDataGrass = controller.processed
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var root_parent:Node = controller.get_node_or_null( root_node )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	var original_mm:MultiMesh = original_mmi.multimesh
	var original_ratio:float = float(original_mm.visible_instance_count) / original_mm.instance_count
	
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
		
		await _100_index(original_index)
	
	
	# Rebuilds MultiMeshInstance3D knowing the chunked indexes
	for row_index in chunks.size():
		var chunk_rows:Array = chunks[row_index]
		
		for col_index in chunk_rows.size():
			var chunk:GLBuildDataGrass = chunk_rows[col_index]
			if chunk.size() <= 0:
				continue
			
			# Return to global; (possible) negative chunks
			var global_chunk:Vector2i = Vector2i( row_index, col_index ) + lower_chunk
			
			# Find or create all folder nodes. The MMI is not part of root_to_instance
			var last_parent:Node = root_parent
			var root_to_instance_formated:String = root_to_instance.format( {x=global_chunk.x, y=global_chunk.y} )
			for node_name in root_to_instance_formated.split( "/" ):
				last_parent = GLSceneManager.find_or_create_node( Node3D, last_parent, node_name )
			
			# Find center of the individual chunk instances (not to confuse with center of chunk)
			var local_min:Vector3 = chunk.min
			var local_max:Vector3 = chunk.max
			var local_center:Vector3 = local_min + 0.5*(local_max - local_min)
			var instance_mmi:MultiMeshInstance3D = GLSceneManager.find_or_create_node( MultiMeshInstance3D, last_parent, original_mmi.name )
			
			# Copy the same properties
			for property in original_mmi.get_property_list():
				instance_mmi.set( property.name, original_mmi.get(property.name) )
			
			# Setup MultiMesh
			var instance_mm:MultiMesh = MultiMesh.new()
			instance_mm.transform_format = MultiMesh.TRANSFORM_3D
			instance_mm.mesh = processed.mesh
			instance_mm.use_custom_data = true
			instance_mm.use_colors = true
			instance_mm.instance_count = chunk.size()
			if original_mm.visible_instance_count >= 0:
				instance_mm.visible_instance_count = instance_mm.instance_count * original_ratio
			
			# Set unique properties
			instance_mmi.multimesh = instance_mm
			instance_mmi.global_position = local_center
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
				
				await _100_index( instance_index )
	
	original_mmi.hide()
	#processed.clear()
	GLDebug.state("Chunkified. Total chunks = %s, Total grass instances = %s" %[total_chunks, processed.size()])
	return true



func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Chunkifying failed: This effect is only valid for GLControllerGrass controller types")
		return false
		
	controller = controller as GLControllerGrass
	var original_mmi:MultiMeshInstance3D = controller.multimesh_instance
	var root_parent:Node = controller.get_node_or_null( root_node )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	original_mmi.show()
	delete_children( root_parent, original_mmi )
	return true
	

func delete_children(parent:Node, original:Node):
	for node in parent.get_children():
		if node is MultiMeshInstance3D and node.name == original.name and not node == original:
			node.queue_free()
		else:
			delete_children( node, original )








	
