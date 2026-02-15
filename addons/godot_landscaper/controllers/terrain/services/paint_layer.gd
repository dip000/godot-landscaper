@tool
extends Resource
class_name GLPaintLayer

const DEFAULT_FORMAT:Image.Format = Image.FORMAT_RGBA8
const DEFAULT_COLOR:Color = Color(0, 0, 0, 0)

## Only the first active layer will be edited, the rest will be locked.
@export var active:bool = true

## This layer's texture.
## All texture layers will be blended into a single output texture in [member GLBuildDataTerrain.texture]
@export var texture:ImageTexture

@export_tool_button("       Clear       ", "Clear") var clear_btn:Callable = clear


static func get_active(layers:Array[GLPaintLayer]) -> GLPaintLayer:
	for layer in layers:
		if layer and layer.active:
			return layer
	return null


static func merge_layers(layers:Array[GLPaintLayer], size:Vector2i) -> Image:
	var layers_affected:int = 0
	var texture_rect:Rect2i = Rect2i( Vector2i.ZERO, size )
	var result:Image = Image.create_empty( size.x, size.y, false, DEFAULT_FORMAT )
	result.fill( DEFAULT_COLOR )
	
	for i in layers.size():
		var layer:GLPaintLayer = layers[i]
		if layer:
			var image:Image = layer.get_image( size )
			result.blend_rect( image, texture_rect, Vector2i.ZERO )
			layers_affected += 1
	
	GLDebug.internal("Blended '%s' layer images" %layers_affected)
	return result


func clear():
	if texture:
		var size:Vector2i = texture.get_size()
		var image:Image = Image.create_empty( size.x, size.y, false, DEFAULT_FORMAT )
		image.fill( DEFAULT_COLOR )
		texture = ImageTexture.create_from_image( image )


func update_image(image:Image):
	#TODO: Check for new size
	texture.update( image )


func get_image(size:Vector2i) -> Image:
	var image:Image
	if not texture:
		image = new_image( DEFAULT_COLOR, size )
		texture = ImageTexture.create_from_image( image )
		return image
	
	image = texture.get_image()
	if not image:
		image = new_image( DEFAULT_COLOR, size )
		texture = ImageTexture.create_from_image( image )
		return image
	
	if image.has_mipmaps():
		image.clear_mipmaps()
	
	if image.is_compressed():
		image.decompress()
	
	if image.get_format() != DEFAULT_FORMAT:
		image.convert( DEFAULT_FORMAT )
	
	return image
	

func new_image(color:Color, size:Vector2i) -> Image:
	var image:Image = Image.create_empty( size.x, size.y, false, DEFAULT_FORMAT )
	image.fill( color )
	return image






	
