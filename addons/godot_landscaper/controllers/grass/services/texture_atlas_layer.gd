## Wrapper for a single Texture2DArray layer.
##
## This class acts like AtlasTexture in the way that it represents one
## single layer of a given 'texture_array'.
## Also has helpers to bake, clear and crop the Texture2DArray.

@tool
extends Resource
class_name GLTextureAtlasLayer

## Atlas for this texture layer.
## Keeps native resource Texture2DArray separated from plugin resources.
@export var texture_array:Texture2DArray

## The layer this instance is tied to.
## This value is read-only. To change it go to:
## Grass Controller Inspector > Texture Layers > Save Layer Into Array
@export_custom(PROPERTY_HINT_NONE, "", PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY ) var layer:int = -1



## Performs 'texture_array[texture_layer] = texture_texture' but with a Texture2DArray.
## Gap layers will be filled with empty images
func bake_layer(texture_layer:int, requested_texture:Texture2D, texture_size:Vector2i):
	layer = texture_layer
	var baked_layers:int = texture_array.get_layers()
	var target_layers:int = maxi( baked_layers, layer + 1 )
	var images:Array[Image] = []
	images.resize( target_layers )
	
	# re-format all images again since it can be resized at any moment
	# Also beacuse get_layer_data() might return a differently formated image for some reason
	for target_layer in range( target_layers ):
		var img:Image
		if target_layer == layer:
			img = requested_texture.get_image()
			GLDebug.state( "Layer Set: %s, Data array format: %s, Size: (%s,%s), Total layers: %s" %[layer, img.get_format(), img.get_width(), img.get_height(), target_layers] )
		elif target_layer < baked_layers:
			img = texture_array.get_layer_data( target_layer )
			GLDebug.internal( "Layer colected and reformated: %s" %target_layer )
		else:
			img = _make_empty_image( texture_size )
			GLDebug.warning( "Gap layer created: %s. Gap layers will be black, move other non-empty textures to these gaps for performance" %layer )
		
		img = _format_img( img, texture_size )
		images[target_layer] = img
	
	texture_array.create_from_images( images )


## Performs 'texture_array[texture_layer] = null' but with a Texture2DArray.
## Also truncates if requested_layer is the last layer
func clear_layer(texture_size:Vector2i):
	var total_layers:int = texture_array.get_layers()
	var last_layer:int = total_layers - 1
	var images:Array[Image] = []
	
	# Truncate if it is the last layer
	if layer == last_layer:
		GLDebug.state("Array Layer Removed: %s, Total layers: %s (array was truncated)" %[layer, images.size()])
		total_layers -= 1
	
	for baked_layer in range( total_layers ):
		var img:Image
		
		if layer == baked_layer:
			img = _make_empty_image( texture_size )
			GLDebug.warning("Array Gap Layer Created Instead: %s. Gap layers will be black, move other non-empty textures to these gaps for performance" %layer)
		
		else:
			img = texture_array.get_layer_data( baked_layer )
			GLDebug.internal( "Layer colected and reformated: %s" %layer )
		
		img = _format_img( img, texture_size )
		images.append( img )
	
	if images:
		texture_array.create_from_images( images )
	else:
		texture_array = null
	
	layer = -1


func get_layer() -> Image:
	return texture_array.get_layer_data( layer )


func _format_img(img:Image, texture_size:Vector2i) -> Image:
	if img.is_compressed():
		if img.decompress() != OK:
			GLDebug.error("Decompression error on texture array. An empty image will be used meanwhile")
			return _make_empty_image( texture_size )
	
	if img.get_format() != Image.FORMAT_RG8:
		img.convert( Image.FORMAT_RG8 )
	
	if img.get_size() != texture_size:
		img.resize( texture_size.x, texture_size.y, Image.INTERPOLATE_LANCZOS )
	
	if not img.has_mipmaps():
		img.generate_mipmaps()
	return img


func _make_empty_image(texture_size:Vector2i) -> Image:
	return Image.create_empty( texture_size.x, texture_size.y, true, Image.FORMAT_RG8 )
