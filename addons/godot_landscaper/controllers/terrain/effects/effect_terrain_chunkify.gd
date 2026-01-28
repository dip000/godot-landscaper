@tool
extends GLEffect
class_name GLTerrainChunkify

## The size squared to split the terrain
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)

## The chunks holder.
@export var root_parent_path:NodePath = "."


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Chunkifying failed: This effect is only valid for GLControllerTerrain controller types")
		return false
		
	controller = controller as GLControllerTerrain
	var processed:GLBuildDataTerrain = controller.processed
	var original_terrain:MeshInstance3D = controller.terrain
	var root_parent:Node = controller.get_node_or_null( root_parent_path )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = processed.vertices_map
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_mesh( original_terrain )
	
	# Organize a map of chunks.
	var chunks:Dictionary[Vector2i, GLBuildDataTerrain]
	for cell in vertices_map:
		var chunk:Vector2i = ( cell/float(chunk_size) ).floor()
		var vertices:PackedVector3Array = vertices_map[cell]
		
		# Collect UVs
		var uvs:PackedVector2Array
		for vertex in vertices:
			var vertex_xz:Vector2 = Vector2( vertex.x, vertex.z )
			uvs.append( (vertex_xz - bounds.position) / bounds.size )
		
		# Create or find chunk_data for this chunk.
		var chunk_data:GLBuildDataTerrain = chunks[chunk] if chunks.has( chunk ) else GLBuildDataTerrain.new()
		
		# UVs stay where they are, chunked mesh just renders its own part.
		chunk_data.min = chunk_data.min.min( vertices[0] )
		chunk_data.max = chunk_data.max.max( vertices[5] )
		chunk_data.vertices_map[cell] = vertices
		chunk_data.uvs_map[cell] = uvs
		chunks[chunk] = chunk_data
	
	
	# Build terrain chunks
	for chunk in chunks:
		var chunk_data:GLBuildDataTerrain = chunks[chunk]
		var chunk_folder:Node = SceneManager.find_or_create_node( Node, root_parent, _format_chunk(chunk) )
		var chunk_terrain:MeshInstance3D = SceneManager.find_or_create_node( MeshInstance3D, chunk_folder, original_terrain.name )
		
		# Move to its center, the builder makes sure it builds around its center
		chunk_terrain.global_position = chunk_data.min + (chunk_data.max - chunk_data.min) / 2.0
		
		# Same material with the same texture (same draw call), and new mesh
		chunk_terrain.material_override = original_terrain.material_override
		chunk_terrain.visibility_range_end = original_terrain.visibility_range_end
		chunk_terrain.visibility_range_end_margin = original_terrain.visibility_range_end_margin
		chunk_terrain.mesh = ArrayMesh.new()
		
		# Fill with the source texture since it is the same UV mapping
		chunk_data.texture = controller.source.texture
		
		GLBuilderTerrain.build_headless( chunk_data, chunk_terrain )
		chunk_terrain.set_display_folded( true )
		
	original_terrain.hide()
	GLDebug.state("Chunkified Terrain %s: Total Chunks: %s, Total Cells: %s" %[original_terrain.name, chunks.size(), vertices_map.size()])
	return true


func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Chunkifying failed: This effect is only valid for GLControllerTerrain controller types")
		return false
		
	controller = controller as GLControllerTerrain
	var processed:GLBuildDataTerrain = controller.processed
	var original_terrain:MeshInstance3D = controller.terrain
	var root_parent:Node = controller.get_node_or_null( root_parent_path )
	
	if not root_parent:
		GLDebug.error("Root parent path '%s' is invalid. Select a valid Node")
		return false
	
	original_terrain.show()
	
	# Delete MultiMeshInstance3D chunk by name if it's inside
	for chunk in root_parent.get_children():
		for node in chunk.get_children():
			if node is MeshInstance3D and node.name == original_terrain.name:
				node.free()
	
	# Clean up empty "folders"
	for node in root_parent.get_children():
		var is_chunk_parent:bool = node.name.begins_with( "Chunk" )
		var is_empty:bool = (node.get_child_count() <= 0)
		if is_chunk_parent and is_empty:
			node.queue_free()
	
	return true
