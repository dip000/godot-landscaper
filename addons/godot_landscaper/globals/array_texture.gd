@tool
extends Texture2DArray
class_name GLArrayTexture

@export var texture_size:Vector2i = Vector2i(255, 255)
@export var texture_format:Image.Format = Image.FORMAT_LA8
@export var texture_compression:Image.CompressMode = Image.COMPRESS_ETC2
@export_storage var _weak_mms:Array[WeakRef]


## Finds a spot to place a new image and returns the index
## MultiMesh resources are unique per variant, so when it's deleted, the WeakRef will be deleted too
func request_layer(new_texture:Texture2D, mm:MultiMesh) -> int:
	var new_image:Image = new_texture.get_image()
	var err:int = _format_img( new_image )
	if err != OK: return return_err(err)
	
	# Garbage collect
	var current_images:Array[Image]
	var weak_mms:Array[WeakRef] = _weak_mms.duplicate(true)
	var freed_layer:int = -1
	print(weak_mms)
	
	for layer in weak_mms.size():
		var weak_mm:WeakRef = weak_mms[layer]
		var weak_mm_ref:MultiMesh = weak_mm.get_ref()
		if not weak_mm_ref:
			_weak_mms.erase(weak_mm)
			freed_layer = current_images.size()-1
			GLDebug.internal("GLArrayTexture garbage collected '%s'. Weak layer '%s' reference" %[weak_mm, layer] )

	# Return previously assgned layer
	for i in _weak_mms.size():
		if _weak_mms[i].get_ref() == mm:
			update_layer(new_image, i)
			GLDebug.internal("GLArrayTexture assigned layer '%s' from previous state" %i )
			return i
	
	# Return any freed layer if possible
	if freed_layer >= 0:
		update_layer(new_image, freed_layer)
		GLDebug.internal("GLArrayTexture assigned layer '%s' from another freed instance" %freed_layer )
		return freed_layer
	
	# Re-collect layers. get_layer_data() might return a different format for some reason
	for layer in get_layers():
		var img:Image = get_layer_data(layer)
		err = _format_img( img )
		if err != OK: return return_err(err)
		current_images.append( img )
	
	# Add new layer
	current_images.append( new_image )
	err = create_from_images(current_images)
	if err != OK: return return_err(err)
	
	_weak_mms.append( weakref(mm) )
	var layer:int = _weak_mms.size()-1
	GLDebug.internal("Slot requested: %s, Data array format: %s, Size: (%s,%s), Layers: %s" %[layer, get_format(), get_width(), get_height(), get_layers()])
	return layer


func free_slot(index:int):
	GLDebug.internal("Slot freed: %s, Data array format: %s, Size: (%s,%s), Layers: %s" %[get_layers()-1, get_format(), get_width(), get_height(), get_layers()])


func return_err(err) -> int:
	GLDebug.error("Image layer could not be added to the shader's Texture2DArray. Error code: %s" %err)
	return -1


## Generates a dynamic, compatibility-friendly, and performant array of textures
func _add_texture(instance_index:int, new_texture:Texture2D):
	var layers:int = get_layers()
	var layer_max_index:int = layers-1
	var variant_img:Image = new_texture.get_image()
	
	# Make room for new texture
	if instance_index > layer_max_index:
		var new_max_length:int = instance_index+1
		var current_images:Array[Image]
		current_images.resize(new_max_length)
		for layer in new_max_length:
			if layer < layers:
				# [WARNING] This might return on format Image.FORMAT_RGBA8 unexpectedly
				current_images[layer] = get_layer_data(layer)
				GLDebug.spam("Current layer data array format: %s, img format: %s" %[get_format(), current_images[layer].get_format()])
			elif layer == instance_index:
				GLDebug.spam("Selected variant on layer: %s of format: %s" %[layer, variant_img.get_format()])
				current_images[layer] = variant_img
			else: #fill empty slots
				GLDebug.spam("Filled layer: %s with format: %s" %[layer, texture_format])
				current_images[layer] = Image.create_empty(texture_size.x, texture_size.y, true, texture_format)
				current_images[layer].fill(Color.BLACK)
			_format_img( current_images[layer] )
		create_from_images(current_images)
		GLDebug.internal("Updated tex_array: %s. new_max_length: %s" %[self, new_max_length])
	
	else: # If it fits, it sits
		GLDebug.internal("variant_img format: %s, tex_array format: %s" %[variant_img.get_format(), get_format()])
		update_layer(variant_img, instance_index)
		

func _format_img(img:Image) -> int:
	if img.is_compressed():
		var err:int = img.decompress()
		if err != OK: return err
	if img.get_size() != texture_size:
		img.resize(texture_size.x, texture_size.y)
	if not img.has_mipmaps():
		img.generate_mipmaps()
	return img.compress(texture_compression)
	
