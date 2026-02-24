## Texture2DArray To CompressedTexture2DArray with VRAM Compression
## 
## By default, the landscaper will use a Texture2DArray to process images,
## but only Godot's native importer has the ability to compress textures.

@tool
extends GLEffect
class_name GLGrassTextureCompressor

#@export_custom(PROPERTY_HINT_SAVE_FILE, "*.png") var save_path:String = "res://grass_texture_atlas.png"
@export var formater:GLImageFormater = GLImageFormater.from_save_path( "res://grass_texture_atlas.png" )


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass VRAM Compression Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	
	controller = controller as GLControllerGrass
	
	if not formater:
		formater = GLImageFormater.from_save_path( "res://grass_texture_atlas.png" )
	
	var save_path:String = formater.save_file
	if save_path.is_empty():
		GLDebug.error("Grass VRAM Compression Failed: Invalid 'save_path=%s'" %save_path)
		return false
	
	var processed:GLBuildDataGrass = controller.processed
	var texture_array:Texture2DArray = processed.texture_array_layer.texture_array
	
	if not texture_array:
		GLDebug.error("Grass VRAM Compression Failed: There are no textures to compress")
		return false
	
	# Create Atlas
	var layers:int = texture_array.get_layers()
	var tile_w:int = texture_array.get_width()
	var tile_h:int = texture_array.get_height()
	
	var atlas:Image = Image.create_empty(
		tile_w * layers,
		tile_h,
		false,
		texture_array.get_format()
	)
	
	for layer in range( layers ):
		atlas.blit_rect(
			texture_array.get_layer_data( layer ),
			Rect2i(0, 0, tile_w, tile_h),
			Vector2i(layer * tile_w, 0)
		)
	
	# Save file with GLImageFormater class
	atlas = formater.format( atlas )
	if not atlas:
		GLDebug.error("Grass VRAM Compression Failed: Formater format error")
		return false
	
	if not formater.save( atlas ):
		GLDebug.error("Grass VRAM Compression Failed: Formater save error")
		return false
	
	await _frame()
	
	# Delete import file if exists
	var import_path:String = save_path + ".import"
	var import:ConfigFile = ConfigFile.new()
	if FileAccess.file_exists(import_path):
		DirAccess.remove_absolute(import_path)
		await _frame()
	
	# Make a custom import file
	import.set_value("remap", "importer", "2d_array_texture")
	import.set_value("remap", "type", "CompressedTexture2DArray")
	import.set_value("params", "compress/mode", 2) # VRAM compressed
	import.set_value("params", "compress/high_quality", false)
	import.set_value("params", "compress/channel_pack", 2) # RG Channels
	import.set_value("params", "mipmaps/generate", true)
	import.set_value("params", "mipmaps/limit", -1)
	import.set_value("params", "slices/horizontal", layers)
	import.set_value("params", "slices/vertical", 1)
	import.save( import_path )
	
	await _frame()
	EditorInterface.get_resource_filesystem().scan_sources()
	await _timeout(1)
	
	# Reload resources
	var texture:Texture = load( save_path )
	
	if not texture is CompressedTexture2DArray:
		GLDebug.error("Grass VRAM Compression Failed. The exported texture is not a CompressedTexture2DArray but a '%s'" %texture)
		return false
	
	controller.source.material.set_shader_parameter( "texture_array", texture )
	
	GLDebug.state("Grass VRAM Compression Succesfull: Saved in: %s. Total layers: %s" %[save_path, layers])
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerGrass:
		GLDebug.error("Grass VRAM Compression Failed: This effect is only valid for GLControllerGrass controller types")
		return false
	
	controller = controller as GLControllerGrass
	var source:GLBuildDataGrass = controller.source
	source.material.set_shader_parameter( "texture_array", source.texture_array_layer.texture_array )
	return true
	
	
