## Terrain Effect That Rounds Corners  
## 
## An aestetic choice instead of ending your maps in ugly squares.
## It ends in less ugly triangles.
## It also enhances performance a bit a guess.

@tool
extends GLEffect
class_name GLTerrainRoundCorners


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Round Corners Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var terrain:MeshInstance3D = controller.terrain
	var processed:GLBuildDataTerrain = controller.processed
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = processed.vertices_map
	var new_vertices_map:Dictionary[Vector2i, PackedVector3Array]
	var square_shape:Array[Vector2i] = GLBrushTerrainBuider.SQUARE_SHAPE
	var get_height:Callable = Callable(GLBrushTerrainBuider.get_corner_height)
	var i:int = 0
	
	for cell in vertices_map:
		var cell_vertices:PackedVector3Array = vertices_map[cell]
		var tri_shape:Array[Vector2i]
		
		await _100_index(i)
		i += 1
		
		# If no neighbors in TOP_LEFT, build a BOTTOM_RIGHT triangle.
		# Then repeat for every corner
		if is_inf( get_height.call(GLBrushTerrainBuider.TOP_LEFT_MAP, vertices_map, cell, INF) ):
			tri_shape = GLBrushTerrainBuider.BOTTOM_RIGHT_TRI
		elif is_inf( get_height.call(GLBrushTerrainBuider.TOP_RIGHT_MAP, vertices_map, cell, INF) ):
			tri_shape = GLBrushTerrainBuider.BOTTOM_LEFT_TRI
		elif is_inf( get_height.call(GLBrushTerrainBuider.BOTTOM_LEFT_MAP, vertices_map, cell, INF) ):
			tri_shape = GLBrushTerrainBuider.TOP_RIGHT_TRI
		elif is_inf( get_height.call(GLBrushTerrainBuider.BOTTOM_RIGHT_MAP, vertices_map, cell, INF) ):
			tri_shape = GLBrushTerrainBuider.TOP_LEFT_TRI
		
		# Not a corner, keep the same vertex data
		if not tri_shape:
			new_vertices_map[cell] = cell_vertices
			continue
		
		# A sharp corner, recreate a tri instead
		var new_cell_vertices:PackedVector3Array
		for tri_offset in tri_shape:
			var prev_pos:Vector3
			
			# Aaaand this is the point where it worked on trial and error, so don't ask me how this works..
			match tri_offset:
				GLBrushTerrainBuider.TOP_LEFT: prev_pos = cell_vertices[0]
				GLBrushTerrainBuider.TOP_RIGHT: prev_pos = cell_vertices[1]
				GLBrushTerrainBuider.BOTTOM_LEFT: prev_pos = cell_vertices[2]
				GLBrushTerrainBuider.BOTTOM_RIGHT: prev_pos = cell_vertices[5]
			
			new_cell_vertices.append( prev_pos )
		new_vertices_map[cell] = new_cell_vertices
	
	processed.vertices_map = new_vertices_map
	GLDebug.state("Effect Terrain Round Corners Applied to Terrain '%s'" %terrain.name)
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Round Corners Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	return true
	
	
