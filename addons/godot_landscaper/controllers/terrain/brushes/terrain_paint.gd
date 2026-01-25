@tool
extends GLBrush
class_name GLBrushTerrainPaint

const PIXELS_PER_SQUARED_METER:Vector2 = Vector2(10,10)

var brush_shape:Image
var brush_color:Image
var target_image:Image


## Cache and pre-process images for performance.
## Use with stroke_paint(..) and end()
func start(scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerTerrain
	var wold_brush_size:Vector2 = Vector2.ONE * controller.brush_size
	var texture_brush_size:Vector2i = meters_to_pixels( wold_brush_size )
	
	target_image = controller.source.texture.get_image()
	brush_shape = controller.brush_shape.get_image().duplicate()
	brush_shape.resize( texture_brush_size.x, texture_brush_size.y )
	brush_color = Image.create( texture_brush_size.x, texture_brush_size.y, false, Image.FORMAT_RGBA8 )


func primary(scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerTerrain
	var world_rect:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( controller.terrain )
	var world_brush_rect:Rect2 = Rect2( scan_data.position.x, scan_data.position.z, 0, 0 )
	world_brush_rect = world_brush_rect.grow( controller.brush_size*0.5 )
	stroke_paint( controller.primary_color, controller.source.texture, world_brush_rect, world_rect )
	

func secondary(scan_data:GLScanData, controller:GLController):
	controller = controller as GLControllerTerrain
	var world_rect:Rect2i = GLBrushTerrainBuider.get_bounding_box_from_mesh( controller.terrain )
	var world_brush_rect:Rect2 = Rect2( scan_data.position.x, scan_data.position.z, 0, 0 )
	world_brush_rect = world_brush_rect.grow( controller.brush_size*0.5 )
	stroke_paint( controller.secondary_color, controller.source.texture, world_brush_rect, world_rect )


func end():
	brush_shape = null
	brush_color = null
	target_image = null


## First call from start(), then you can call this function repeatedly with minimum cost.
## 'world_brush_rect' and 'world_rect' should be in world space
func stroke_paint(paint_color:Color, target_texture:ImageTexture, world_brush_rect:Rect2, world_rect:Rect2):
	var texture_rect:Rect2i = Rect2i(
		Vector2i.ZERO,
		target_image.get_size()
	)
	var texture_brush_rect:Rect2i = Rect2i(
		meters_to_pixels(world_brush_rect.position - world_rect.position),
		brush_shape.get_size()
	)
	var paint_rect:Rect2i = texture_brush_rect.intersection( texture_rect )
	
	# Hey, there are pros of manual loops for image processing:
	# - Full control, no workarounds
	# - Terrain no longer needs alpha, like Image.blend_rect_mask(..) does
	for paint_position in Rect2iter.new( paint_rect ):
		var shape:Color = brush_shape.get_pixelv( paint_position - texture_brush_rect.position )
		var alpha:float = shape.a * paint_color.a
		
		if alpha <= 0.0:
			continue
		
		# paint_rect makes sure indices are always inside the texture scope
		var target_color:Color = target_image.get_pixelv( paint_position )
		var shape_color:Color = paint_color * shape
		var alpha_blend:Color = alpha * shape_color + (1 - alpha) * target_color
		target_image.set_pixelv( paint_position, Color(alpha_blend, 1.0) )
	
	target_texture.update( target_image )


static func meters_to_pixels(squared_meters:Vector2) -> Vector2:
	return (PIXELS_PER_SQUARED_METER * squared_meters).round()

static func pixels_to_meters(pixels:Vector2) -> Vector2:
	return pixels / PIXELS_PER_SQUARED_METER

static func create_image(size:Vector2i, color:Color) -> Image:
	if size <= Vector2i.ZERO:
		size = Vector2i.ONE
	var img:Image = Image.create( size.x, size.y, false, Image.FORMAT_RGBA8 )
	img.fill( color )
	return img

static func resize_texture(texture:ImageTexture, prev_rect:Rect2i, new_rect:Rect2i):
	if prev_rect.size == new_rect.size or new_rect.size <= Vector2i.ZERO:
		return
	# 1. Create base image
	var new_size:Vector2i = meters_to_pixels( new_rect.size )
	var new_img:Image = create_image( new_size, Color.WHITE )
	
	var image:Image = texture.get_image()
	if not image:
		texture.set_image( new_img )
		return
	
	GLDebug.internal("Resizing texture %s -> %s" %[prev_rect.size, new_rect.size])
	
	# 2. Compute destination for old image
	var texture_position:Vector2i = meters_to_pixels( prev_rect.position - new_rect.position )
	
	# 3. Paste old image
	new_img.blit_rect( image, Rect2i(Vector2i.ZERO, image.get_size()), texture_position )
	texture.set_image( new_img )
