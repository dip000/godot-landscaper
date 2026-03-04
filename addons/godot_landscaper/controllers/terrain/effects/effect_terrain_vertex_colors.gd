## 

@tool
extends GLEffect
class_name GLTerrainVertexColor

## The pixels to average relative to the vertex.[br]
## Biger window means a more precise, expensive and disperse color.[br]
@export var sampling_window:Rect2i = Rect2i(-1, -1, 1, 1)

## Optionally, a shader replacement with vertex color enabled.
## Leave empty for using the same shader as the original.
@export var replace_with_shader:Shader = GLAssetsManager.load_controller_resource( "terrain", "terrain_vertex_color_shader.gdshader" )

## Target channel to paint the vertex with
@export var target_channel:String = "terrain_texture"



func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var processed:GLBuildDataTerrain = controller.processed
	var source:GLBuildDataTerrain = controller.source
	var target_layer:GLPaintLayer = GLPaintLayer.get_channel( target_channel, processed.layers )
	
	if not target_layer or not target_layer.texture:
		GLDebug.error("Terrain Texture Formater Failed: Channel '%s' does not exist in any terrain layer. Make a layer named as such" %target_channel)
		return false
	
	#var texture:Texture2D = terget_layer.texture
	var image:Image = target_layer.get_image()
	var vertices_map:Dictionary[Vector2i, PackedVector3Array] = processed.vertices_map
	var vertex_colors_map:Dictionary[Vector2i, PackedColorArray]
	var bounds:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_coordinates( vertices_map.keys() )
	var square_shape:Array[Vector2i] = GLBrushTerrainBuider.SQUARE_SHAPE
	var square_size:int = square_shape.size()
	var img_max_index:Vector2i = image.get_size() - Vector2i.ONE
	var sampled_windows:Dictionary[Vector2i, Color]
	
	for cell in vertices_map:
		var world_position:Vector2 = Vector2(cell) - bounds.position
		var cell_vertex_colors:PackedColorArray
		cell_vertex_colors.resize( square_size )
		
		for i in square_size:
			var corner_offset:Vector2 = square_shape[i]
			var corner_pixel:Vector2i = target_layer.meters_to_pixels( world_position + corner_offset )
			
			# Avoid repeating expensive windows.
			# Like the top-right corner of a square and the top-left of the next, it's the same corner 
			if corner_pixel in sampled_windows:
				cell_vertex_colors[i] = sampled_windows[corner_pixel]
				continue
			
			# Window sampling
			var accumulated:Color = Color(0, 0, 0, 0)
			var count:int = 0
			for cell_sample in GLRect2iter.from( sampling_window ):
				var target_pixel:Vector2i = (cell_sample + corner_pixel).clamp( Vector2i.ZERO, img_max_index )
				accumulated += image.get_pixelv( target_pixel )
				count += 1
			
			var cell_color:Color = accumulated / count
			sampled_windows[corner_pixel] = cell_color
			cell_vertex_colors[i] = cell_color
		
		vertex_colors_map[cell] = cell_vertex_colors
		await  _10_index( cell.x )
	
	processed.vertex_colors_map = vertex_colors_map
	if replace_with_shader:
		processed.shader = replace_with_shader
		processed.material.shader = replace_with_shader
		controller.terrain.material_override = processed.material
	GLDebug.state("Terrain Vertex Color Succesfull")
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Vertex Color Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var source:GLBuildDataTerrain = controller.source
	source.material.shader = source.shader
	controller.terrain.material_override = source.material
	return true
	








	
