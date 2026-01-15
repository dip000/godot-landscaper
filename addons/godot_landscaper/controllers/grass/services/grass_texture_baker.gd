## Texture Baker and formater for Texture2DArray
##
## Although this class could be extended directly from Texture2DArray,
## that would mean adding this class as a hard dependency to the exported game.

@tool
extends RefCounted
class_name GLTextureBaker

var _controller:GLController


func _init(controller:GLController):
	_controller = controller


## Performs 'texture_array[texture_layer] = texture_instance' but with a Texture2DArray.
## Gap layers will be filled with empty images
func bake_layer():
	_controller = _controller as GLControllerGrass
	var requested_layer:int = _controller.texture_layer
	var requested_texture:Texture2D = _controller.texture_instance
	var texture_array:Texture2DArray = _controller.texture_array
	if not texture_array:
		texture_array = Texture2DArray.new()
		_controller.texture_array = texture_array
	
	var texture_size:Vector2i = _controller.texture_size_array
	var baked_layers:int = texture_array.get_layers()
	var target_layers:int = maxi( baked_layers, requested_layer + 1 )
	var images:Array[Image] = []
	images.resize( target_layers )
	
	# re-format all images again since it can be resized at any moment
	# Also beacuse get_layer_data() might return a differently formated image for some reason
	for layer in range( target_layers ):
		var img:Image
		if layer == requested_layer:
			img = requested_texture.get_image()
			GLDebug.state( "Layer Set: %s, Data array format: %s, Size: (%s,%s), Total layers: %s" %[layer, texture_array.get_format(), texture_array.get_width(), texture_array.get_height(), texture_array.get_layers()] )
		elif layer < baked_layers:
			img = texture_array.get_layer_data( layer )
			GLDebug.internal( "Layer colected: %s" %layer )
		else:
			img = _make_empty_image( texture_size )
			GLDebug.warning( "Gap layer created: %s. Gap layers will be black, move other non-empty textures to these gaps for performance" %layer )
		
		img = _format_img( img, texture_size )
		images[layer] = img
	
	texture_array.create_from_images( images )


## Performs 'texture_array[texture_layer] = null' but with a Texture2DArray.
## Also truncates if requested_layer is the last layer
func clear_layer():
	var requested_layer:int = _controller.texture_layer
	if requested_layer < 0:
		GLDebug.error("Texture clear failed. texture_layer must be a positive value")
		return
	
	var requested_texture:Texture2D = _controller.texture_instance
	if not requested_texture:
		GLDebug.error("Texture clear failed. texture_instance is invalid")
		return
	
	var texture_array:Texture2DArray = _controller.texture_array
	var baked_layers := texture_array.get_layers()
	if requested_layer >= baked_layers:
		GLDebug.error("Texture clear failed. texture_array doesn't have layer %s" %requested_layer)
		return
	
	if not texture_array:
		texture_array = Texture2DArray.new()
		_controller.texture_array = texture_array
	
	var images: Array[Image] = []
	var texture_size:Vector2i = _controller.texture_size_array
	
	for layer in range( baked_layers ):
		# Truncate if it is the last layer
		if layer != requested_layer:
			var img:Image = texture_array.get_layer_data(layer)
			img = _format_img( img, texture_size )
			images.append( img )
	
	if images:
		texture_array.create_from_images(images)
	else:
		_controller.texture_array = null


func _format_img(img:Image, texture_size:Vector2i) -> Image:
	if img.is_compressed():
		if img.decompress() != OK:
			GLDebug.error("Decompression error on texture array. An empty image will be used meanwhile")
			return _make_empty_image( texture_size )
	
	if img.get_format() != Image.FORMAT_RG8:
		img.convert( Image.FORMAT_RG8 )
	
	if img.get_size() != texture_size:
		#var base:Image = _make_empty_image( texture_size )
		#var inner_size:Vector2i = texture_size - Vector2i(2,2)
		img.resize( texture_size.x, texture_size.y, Image.INTERPOLATE_LANCZOS )
		#base.blit_rect( img, Rect2i(Vector2i.ZERO, inner_size), Vector2i.ONE )
		#img = base
	
	if not img.has_mipmaps():
		img.generate_mipmaps()
	return img



func _make_empty_image(texture_size:Vector2i) -> Image:
	return Image.create_empty( texture_size.x, texture_size.y, true, Image.FORMAT_RG8 )
