@tool
extends Resource
class_name GLImageCleaner


## Removes mipmaps and compression, gives format and optionally resizes.
## Usefull for image processing or for appying more comprex formats withouth the extra bagage.
static func soft_clean_image(image:Image, format:Image.Format, size:Vector2i=Vector2i.ZERO, interpolation:Image.Interpolation=Image.INTERPOLATE_BILINEAR):
	if not image:
		return
	
	if image.has_mipmaps():
		image.clear_mipmaps()
	
	if image.is_compressed():
		image.decompress()
	
	if image.get_size() != size and size > Vector2i.ZERO:
		image.resize( size.x, size.y, interpolation )
	
	if not image.get_format() == format:
		image.convert( format )


static func hard_clean_image(image:Image, format:Image.Format, size:Vector2i=Vector2i.ZERO, color:Color=Color.TRANSPARENT, interpolation:Image.Interpolation=Image.INTERPOLATE_BILINEAR) -> Image:
	if not image:
		return filled_image( size, format, color )
	soft_clean_image( image, format, size )
	return image


static func soft_clean_texture(texture:Texture2D, format:Image.Format, size:Vector2i=Vector2i.ZERO):
	if not texture is ImageTexture:
		return
	
	var image:Image = texture.get_image()
	if not image:
		return
	
	soft_clean_image( image, format, size )
	texture.set_image( image )


static func hard_clean_texture(texture:Texture2D, format:Image.Format, size:Vector2i, color:Color=Color.TRANSPARENT) -> ImageTexture:
	var image:Image
	if not texture is ImageTexture:
		image = filled_image( size, format, color )
		texture = ImageTexture.create_from_image( image )
		return texture
	
	image = hard_clean_image( texture.get_image(), format, size )
	texture.set_image( image )
	return texture


static func filled_image(size:Vector2i, format:Image.Format, color:Color) -> Image:
	var image:Image = Image.create_empty( size.x, size.y, false, format )
	image.fill( color )
	return image


static func filled_texture(size:Vector2i, format:Image.Format, color:Color) -> ImageTexture:
	var image:Image = filled_image( size, format, color )
	return ImageTexture.create_from_image( image )






	
