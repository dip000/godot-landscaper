@tool
extends GLEffect
class_name GLTerrainChunkify

## The size squared to split the terrain
@export var chunk_size:int = 32:
	set(v): chunk_size = max(1, v)


func _apply(controller:GLController) -> bool:
	controller = controller as GLControllerTerrain
	var processed:GLBuildDataTerrain = controller.processed
	var original_terrain:MeshInstance3D = controller.terrain
	var root_parent:Node = original_terrain.get_parent()
	var aabb:AABB = original_terrain.get_aabb()
	var size:Vector3 = aabb.size
	var pos:Vector3 = aabb.position
	var lower_bound:Vector3 = pos + original_terrain.global_position
	var upper_bound:Vector3 = pos + size + original_terrain.global_position
	var lower_chunk:Vector2i = (Vector2(lower_bound.x, lower_bound.z) / float(chunk_size)).floor()
	var upper_chunk:Vector2i = (Vector2(upper_bound.x, upper_bound.z) / float(chunk_size)).floor()
	var total_chunks:Vector2i = upper_chunk - lower_chunk + Vector2i.ONE
	
	GLDebug.internal("LowerBound: %s, UpperBound: %s" %[lower_bound, upper_bound])
	GLDebug.internal("LowerChunk: %s, UpperChunk: %s" %[lower_chunk, upper_chunk])
	GLDebug.internal("TotalChunks: %s" %total_chunks)
	
	# Organized map of chunks, example: chunks[x][y].image
	var chunks:Array[Array]
	chunks.resize( total_chunks.x )
	
	# Fill map for performance, i guess
	for x in total_chunks.x:
		chunks[x].resize( total_chunks.y )
		for y in total_chunks.y:
			chunks[x][y] = GLBuildDataTerrain.new()
	
	return true


func _clear(controller:GLController) -> bool:
	return true
