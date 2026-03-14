@tool
extends GLEffect
class_name GLTerrainChunkify

## The size squared to split the terrain
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)

## The chunks holder.
@export var root_parent_path:NodePath = "."

## Creates all [Node3D] in path if they don't exists.
## This let's you organize the scene as you like.[br]
## - [code]{x}[/code] Will be replaced for the X coordinate of the world chunk.[br]
## - [code]{y}[/code] Will be replaced for the Y coordinate of the world chunk.
@export var root_to_instance:String = "Chunk_{x}_{y}/Terrains"


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
		
	root_to_instance = root_to_instance.simplify_path()
	if not root_to_instance.contains("{x}") or not root_to_instance.contains("{y}"):
		GLDebug.error("Chunkifying failed: root_to_instance does not contain '{x}' or '{y}'. Please add the placeholder text required")
		return false
	
	var vertex_colors_map:Dictionary[Vector2i, PackedColorArray] = processed.vertex_colors_map
	var uses_vertex_colors:bool = not vertex_colors_map.is_empty()
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
		chunk_data.uvs_map[cell] = uvs
		
		chunk_data.vertices_map[cell] = vertices
		chunk_data.min = chunk_data.min.min( vertices[0] )
		chunk_data.max = chunk_data.max.max( vertices[vertices.size()-1] )
		
		if uses_vertex_colors:
			chunk_data.vertex_colors_map[cell] = vertex_colors_map[cell]
		chunks[chunk] = chunk_data
	
	await _frame()
	
	# Build terrain chunks
	for chunk in chunks:
		var chunk_data:GLBuildDataTerrain = chunks[chunk]
		
		# Find or create all folder nodes. The terrain is not part of root_to_instance
		var last_parent:Node = root_parent
		var root_to_instance_formated:String = root_to_instance.format( {x=chunk.x, y=chunk.y} )
		for node_name in root_to_instance_formated.split( "/" ):
			last_parent = GLSceneManager.find_or_create_node( Node3D, last_parent, node_name )
		
		var chunk_terrain:MeshInstance3D = GLSceneManager.find_or_create_node( MeshInstance3D, last_parent, original_terrain.name )
		
		# Copy the same properties
		for property in original_terrain.get_property_list():
			chunk_terrain.set( property.name, original_terrain.get(property.name) )
		
		# Move to its center, the builder makes sure it builds around its center
		chunk_terrain.global_position = chunk_data.min + (chunk_data.max - chunk_data.min) / 2.0
		chunk_terrain.mesh = ArrayMesh.new()
		
		# Fill with the source layers since it is the same UV mapping
		chunk_data.layers = controller.source.layers
		
		GLBuilderTerrain.build_headless( chunk_data, chunk_terrain )
		chunk_terrain.set_display_folded( true )
		await _frame()
	
	#processed.vertices_map.clear()
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
	delete_children( root_parent, original_terrain )
	return true
	

func delete_children(parent:Node, original:MeshInstance3D):
	for node in parent.get_children():
		if node is MeshInstance3D and node.name == original.name and node != original:
			node.queue_free()
		else:
			delete_children( node, original )
