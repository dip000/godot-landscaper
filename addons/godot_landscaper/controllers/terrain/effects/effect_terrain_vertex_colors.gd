## 

@tool
extends GLEffect
class_name GLTerrainVertexColor

const DEFAULT_WINDOW:Rect2i = Rect2i( -GLBrushTerrainPaint.PIXELS_PER_SQUARED_METER*0.5, GLBrushTerrainPaint.PIXELS_PER_SQUARED_METER*0.5 )

## The pixels to average relative to the vertex.[br]
## Biger window means a more precise, expensive and disperse color.[br]
@export var sampling_window:Rect2i = Rect2i(-1, -1, 1, 1)


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var processed:GLBuildDataTerrain = controller.processed
	var source:GLBuildDataTerrain = controller.source
	var texture:Texture2D = processed.texture
	var image:Image = texture.get_image()
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = processed.vertices_map
	var vertex_colors_map:Dictionary[Vector2i, PackedColorArray]
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	var square_shape:Array[Vector2i] = GLBrushTerrainBuider.SQUARE_SHAPE
	var img_max_index:Vector2i = image.get_size() - Vector2i.ONE
	var sampled_windows:Dictionary[Vector2i, Color]
	
	for cell in vertices_map:
		var world_position:Vector2 = Vector2(cell) - bounds.position
		var cell_vertex_colors:PackedColorArray
		cell_vertex_colors.resize( 6 )
		
		for i in 6:
			var corner_offset:Vector2 = square_shape[i]
			var corner_pixel:Vector2i = GLBrushTerrainPaint.meters_to_pixels( world_position + corner_offset )
			
			# Avoid repeating expensive windows.
			# Like the top-right corner of a square and the top-left of the next, it's the same corner 
			if corner_pixel in sampled_windows:
				cell_vertex_colors[i] = sampled_windows[corner_pixel]
				continue
			
			# Window sampling
			var accumulated:Color = Color(0, 0, 0, 0)
			var count:int = 0
			for cell_sample in Rect2iter.new( sampling_window ):
				var target_pixel:Vector2i = (cell_sample + corner_pixel).clamp( Vector2i.ZERO, img_max_index )
				accumulated += image.get_pixelv( target_pixel )
				count += 1
			
			var cell_color:Color = accumulated / count
			sampled_windows[corner_pixel] = cell_color
			cell_vertex_colors[i] = cell_color
		
		vertex_colors_map[cell] = cell_vertex_colors
		await  _10_index( cell.x )
	
	source.material.set_shader_parameter("vertex_paint", true)
	source.material.set_shader_parameter("terrain_texture", null)
	processed.vertex_colors_map = vertex_colors_map
	GLDebug.state("Terrain Vertex Color Succesfull")
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Vertex Color Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var source:GLBuildDataTerrain = controller.source
	source.material.set_shader_parameter("vertex_paint", false)
	source.material.set_shader_parameter("terrain_texture", source.texture)
	return true
	








	
