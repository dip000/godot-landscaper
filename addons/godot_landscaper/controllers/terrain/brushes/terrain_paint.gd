@tool
extends GLBrush
class_name GLBrushTerrainPaint

enum Behavior {
	SPLAT_PAINTING, ## For smudges or simple fill coloring. The brush size resizes the brush texture.
	TEXTURE_TILING, ## For continuous rocks or grass textures. The brush size resizes the brush texture.
}

const PIXELS_PER_SQUARED_METER:float = 64.0
const DEFAULT_FORMAT:Image.Format = Image.FORMAT_RGBA8

# Caches
var paint_stencil:Image
var target_image:Image
var target_layer:GLPaintLayer
var composed_image:Image
var composed_layer:GLPaintLayer

var behavior:Behavior = -1
var color:Color


func start(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerTerrain
	
	# Resolve
	match action:
		GLandscaper.Action.PRIMARY:
			paint_stencil = controller.primary_paint_stencil.get_image().duplicate()
			behavior = controller.primary_paint_behavior
			color = controller.primary_color
		GLandscaper.Action.SECONDARY:
			paint_stencil = controller.secondary_paint_stencil.get_image().duplicate()
			behavior = controller.secondary_paint_behavior
			color = controller.secondary_color
	
	# input layers (individual)
	var source:GLBuildDataTerrain = controller.source
	var bounds:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( controller.terrain )
	target_layer = GLPaintLayer.get_active( controller.layers )
	target_image = target_layer.get_image_resize( bounds.size )
	
	# output layers (composed)
	source.layers = GLPaintLayer.compose_sampler_outputs( controller.layers )
	composed_layer = GLPaintLayer.get_active( source.layers )
	composed_image = composed_layer.get_image_resize( bounds.size )

	# Brush
	var texture_brush_size:Vector2i = target_layer.meters_to_pixels( Vector2.ONE * controller.brush_size )
	GLImageCleaner.soft_clean_image( paint_stencil, DEFAULT_FORMAT )
	paint_stencil.resize( texture_brush_size.x, texture_brush_size.y )


func action(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerTerrain
	var world_brush_rect:Rect2 = Rect2( scan_data.position.x, scan_data.position.z, 0, 0 )
	world_brush_rect = world_brush_rect.grow( controller.brush_size*0.5 )

	stroke_paint( color, controller.paint_strenght*0.01, world_brush_rect, controller.terrain )
	

func end(action:GLandscaper.Action, scan_data:GLScanData, controller:GLController):
	var source:GLBuildDataTerrain = controller.source
	source.layers = GLPaintLayer.compose_sampler_outputs( controller.layers )
	for layer in source.layers:
		source.material.set_shader_parameter( layer.sampler, layer.texture )
	
	paint_stencil = null
	target_image = null
	target_layer = null
	composed_layer = null
	composed_image = null
	behavior = -1


## First call from start(), then you can call this function repeatedly with minimum cost.
## 'world_brush_rect' and 'world_rect' should be in world space
func stroke_paint(paint_color:Color, paint_strenght:float, world_brush_rect:Rect2, terrain:MeshInstance3D):
	var world_rect:Rect2 = GLBrushTerrainBuider.get_bounding_box_from_mesh( terrain )
	var world_node_reference:Vector2 = Vector2( terrain.global_position.x, terrain.global_position.z )
	var texture_rect:Rect2i = Rect2i( Vector2i.ZERO, target_image.get_size() )
	var texture_brush_rect:Rect2i = Rect2i(
		target_layer.meters_to_pixels(world_brush_rect.position - world_rect.position - world_node_reference),
		paint_stencil.get_size()
	)
	var paint_rect:Rect2i = texture_brush_rect.intersection( texture_rect )
	
	# Hey, there are pros of manual loops for image processing:
	# - Full control, no workarounds
	# - Terrain no longer needs alpha, like Image.blend_rect_mask(..) does
	for y in GLRect2iter.range_y(paint_rect):
		for x in GLRect2iter.range_x(paint_rect):
			var paint_position:Vector2i = Vector2i(x,y)
			var pixel:Vector2i = paint_position
			
			if behavior == Behavior.TEXTURE_TILING:
				pixel.x = wrapi( pixel.x, 0, texture_brush_rect.size.x )
				pixel.y = wrapi( pixel.y, 0, texture_brush_rect.size.y )
			else:
				pixel -= texture_brush_rect.position
			
			var shape:Color = paint_stencil.get_pixelv( pixel )
			var blend_factor:float = shape.a * paint_strenght
			shape.a = 1.0
			
			if blend_factor <= 0.0:
				continue
			
			var inv_blend_factor:float = 1.0 - blend_factor
			var blend_mult:Color = blend_factor * (paint_color * shape)
			
			# Current layer image that actually get saved
			var target_color:Color = target_image.get_pixelv( paint_position )
			var blend_result:Color = blend_mult + inv_blend_factor * target_color
			target_image.set_pixelv( paint_position, blend_result )
			
			# Preview composed image to show while painting
			target_color = composed_image.get_pixelv( paint_position )
			blend_result = blend_mult + inv_blend_factor * target_color
			composed_image.set_pixelv( paint_position, blend_result )
		
	target_layer.update_image( target_image )
	composed_layer.update_image( composed_image )


static func create_image(size:Vector2i, color:Color) -> Image:
	if size <= Vector2i.ZERO:
		size = Vector2i.ONE
	var img:Image = Image.create( size.x, size.y, false, DEFAULT_FORMAT )
	img.fill( color )
	return img





	
