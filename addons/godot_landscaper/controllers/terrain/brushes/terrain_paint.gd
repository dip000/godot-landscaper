@tool
extends GLBrush
class_name GLBrushTerrainPaint

const PIXELS_PER_SQARED_METER:Vector2 = Vector2(10,10)


func start(scan_data:GLScanData, controller:GLController):
	pass


func primary(scan_data:GLScanData, controller:GLController):
	_bake_brush_into_texture( scan_data, controller, controller.primary_color )


func secondary(scan_data:GLScanData, controller:GLController):
	_bake_brush_into_texture( scan_data, controller, controller.secondary_color )


func end():
	pass



func _bake_brush_into_texture(scan_data:GLScanData, controller:GLController, color:Color):
	controller = controller as GLControllerTerrain
	var source:GLBuildDataTerrain = controller.source
	var world_brush_size:float = controller.brush_size
	var world_brush_position:Vector3 = scan_data.position
	var texture:ImageTexture = controller.texture
	var image:Image = texture.get_image()
	var world_brush_position_xz:Vector2 = Vector2(world_brush_position.x, world_brush_position.z)
	var world_bounds:Rect2i = Rect2i( Vector2i.ZERO, Vector2i(INF,INF) )
	
	for cell in source.vertices_map:
		world_bounds.position = cell.min( world_bounds.position )
		world_bounds.end = cell.max( world_bounds.end )
	world_bounds.end += Vector2i.ONE
	
	# TODO: Check if world_bounds.size is negative, it shouldn't
	var texture_size:Vector2i = meters_to_pixels( world_bounds.size )
	var texture_rect:Rect2i = Rect2i( Vector2i.ZERO, texture_size )
	var texture_brush_size:Vector2i = meters_to_pixels( Vector2.ONE * world_brush_size )
	var texture_brush_position:Vector2i = meters_to_pixels( world_brush_position_xz - Vector2(world_bounds.position) )
	texture_brush_position -= Vector2i((texture_brush_size*0.5).round())
	
	var texture_brush_color:Image = create_image( texture_brush_size, color )
	var texture_brush_shape:Image = controller.brush_shape.duplicate().get_image()
	texture_brush_shape.resize( texture_brush_size.x, texture_brush_size.y )
	
	if not image:
		image = create_image( texture_size, Color.WHITE )
	image.blend_rect_mask( texture_brush_color, texture_brush_shape, texture_rect, texture_brush_position )
	texture.update( image )


static func meters_to_pixels(squared_meters:Vector2) -> Vector2i:
	return (PIXELS_PER_SQARED_METER * squared_meters).round()

static func pixels_to_meters(pixels:Vector2) -> Vector2:
	return pixels / PIXELS_PER_SQARED_METER

static func create_image(size:Vector2i, color:Color) -> Image:
	var img:Image = Image.create( size.x, size.y, false, Image.FORMAT_RGBA8 )
	img.fill( color )
	return img

static func resize_texture(texture:ImageTexture, prev_rect:Rect2i, new_rect:Rect2i):
	if prev_rect.size == new_rect.size:
		return texture
	
	GLDebug.internal("Resizing texture %s -> %s" %[prev_rect.size, new_rect.size])
	
	# 1. Create base image
	var new_size := meters_to_pixels(new_rect.size)
	var new_img := create_image(new_size, Color.WHITE)

	# 2. Compute destination for old image
	var texture_position:Vector2i = meters_to_pixels(prev_rect.position - new_rect.position)

	# 3. Paste old image
	var image:Image = texture.get_image()
	new_img.blit_rect( image, Rect2i(Vector2i.ZERO, image.get_size()), texture_position )
	texture.set_image( new_img )
