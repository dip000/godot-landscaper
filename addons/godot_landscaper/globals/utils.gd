extends Resource
class_name Utils


static func format_texture(texture:Texture2D, resize:=Vector2i.ZERO) -> ImageTexture:
	var img:Image = texture.get_image()
	if img.is_compressed():
		img.decompress()
	if img.has_mipmaps():
		img.clear_mipmaps()
	if resize != Vector2i.ZERO:
		img.resize( resize.x, resize.y )
	return ImageTexture.create_from_image( img )
