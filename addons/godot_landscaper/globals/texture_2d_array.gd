@tool
extends Texture2DArray
class_name GLTexture2DArray

@export var size:Vector2i = Vector2i(255, 255)
@export var format:Image.Format = Image.FORMAT_LA8
@export var compression:Image.CompressMode = Image.COMPRESS_ETC2
@export var resize_interpolation:Image.Interpolation = Image.INTERPOLATE_BILINEAR


func configure(size:Vector2i, format:Image.Format, compression:Image.CompressMode, resize_interpolation:Image.Interpolation):
	self.resize_interpolation = resize_interpolation
	self.compression = compression
	self.format = format
	self.size = size


## Safely inserts 'new_texture' into Texture2DArray[layer].
## Fills with placeholders if any error happens or if 'layer' is higher than Texture2DArray.get_layers()
func set_layer(new_texture:Texture2D, layer_index:int):
	# Re-collect layers beacuse..
	# 1. Texture configs may change
	# 2. get_layer_data() may return a different format, for some reason
	var images:Array[Image] = _collect()
	
	# Get new
	var img:Image = new_texture.get_image()
	var total_images:int = images.size()
	img = _format_img( img )
	
	# Just replace index if already existed
	if layer_index < total_images:
		images[layer_index] = img
		GLDebug.internal("Layer Replaced: %s, Data array format: %s, Size: (%s,%s), Layers: %s" %[layer_index, get_format(), get_width(), get_height(), get_layers()])
	
	# Append with placeholders until the new layer_index is reached 
	else:
		for i in range(total_images, layer_index+1):
			if total_images == layer_index:
				images.append( img )
				GLDebug.internal("Layer Appended: %s, Data array format: %s, Size: (%s,%s), Layers: %s" %[layer_index, get_format(), get_width(), get_height(), get_layers()])
			else:
				images.append( _get_placeholder_image() )
				GLDebug.internal("Placeholder Layer Appended: %s, Data array format: %s, Size: (%s,%s), Layers: %s" %[layer_index, get_format(), get_width(), get_height(), get_layers()])
	
	# Apply changes
	create_from_images( images )


## Fills with placeholders if the slot was not at the end of the array.
## Otherwise truncate array layers
func clear_layer(layer_to_clear:int):
	var any_placeholder:bool = false
	
	for layer in get_layers():
		var img:Image = get_layer_data( layer )
		
		if img.is_invisible():
			any_placeholder = true
		
		if layer == layer_to_clear:
			update_layer( _get_placeholder_image(), layer_to_clear )
			GLDebug.internal("GLArrayTexture layer '%s' is not at the end of the array. A placeholder will be added" %layer_to_clear)
		else:
			update_layer( _format_img(img), layer )
			GLDebug.internal("GLArrayTexture layer '%s' is not at the end of the array. A placeholder will be added" %layer_to_clear)
	

## Updates formating configurations for each layer.
## NOTE: TextureLayered.get_format() might not be trustfull as of 4.4.x
func reformat():
	for layer in get_layers():
		var img:Image = get_layer_data( layer )
		update_layer( _format_img(img), layer )


func _collect() -> Array[Image]:
	var images:Array[Image]
	for layer in get_layers():
		var img:Image = get_layer_data( layer )
		if img.is_invisible():
			pass
		images.append( _format_img(img) )
	return images


func _format_img(img:Image) -> Image:
	if img.is_compressed():
		# Supports DXT, RGTC, BPTC. Formats ETC1 and ETC2 are not supported.
		var err:int = img.decompress()
		if err == ERR_UNAVAILABLE:
			GLDebug.error("Unavailable decompression format: %s. Only supports DXT, RGTC and BPTC. The placeholder image will be used meanwhile" %img.get_format())
			return _get_placeholder_image()
		elif err != OK:
			GLDebug.error("Undocumented decompression format error on texture array. The placeholder image will be used meanwhile")
			return _get_placeholder_image()
	
	if img.get_size() != size:
		img.resize(size.x, size.y, resize_interpolation)
	
	if not img.has_mipmaps():
		img.generate_mipmaps()
	
	var err:int = img.compress(compression)
	if err != OK:
		GLDebug.error("Unavailable compression format: %s. Only supports DXT, RGTC and BPTC. The placeholder image will be used meanwhile" %img.get_format())
		return _get_placeholder_image()
	
	GLDebug.spam("Formated texture array to: %s" %img.get_format())
	return img


func _get_placeholder_image() -> Image:
	var img:Image = Image.create_empty(size.x, size.y, true, format)
	img.fill(Color.TRANSPARENT)
	return img
