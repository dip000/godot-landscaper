## ImageTexture To CompressedTexture2D with formating options.
## 
## By default, the landscaper will use a ImageTexture to process images,
## but only Godot's native importer has the ability to compress textures.

@tool
extends GLEffect
class_name GLTerrainTextureFormater

enum CompressBy {
	SOURCE,
	CHANNELS,
}

enum SaveAs {
	JPG, PNG, WEBP
}

enum ColorSpace {
	NONE,
	SRGB_TO_LINEAR,
	RGBE_TO_SRGB,
	LINEAR_TO_SRGB,
}

enum AlphaOps {
	NONE,
	PREMULT_ALPHA,
	FIX_ALPHA_EDGES,
}


@export_dir() var save_directory:String = "res://"
@export var save_as:SaveAs = SaveAs.JPG

@export_group("Save Details")
@export var save_webp_jpg_quality:float = 0.75
@export var save_webp_lossy:bool = false
@export var save_exr_grayscale:bool = false

@export var color_space_conversion:ColorSpace
@export var alpha_operation:AlphaOps

@export_group("Resize")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var enable_resize:bool = false
@export var resize_size:Vector2i = Vector2i(1024, 1024):
	set(v): resize_size = v.max(Vector2i.ONE)
@export var resize_interpolation:Image.Interpolation = Image.INTERPOLATE_LANCZOS

@export_group("Compression")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var enable_compression:bool = false
@export var compress_by:CompressBy = CompressBy.SOURCE
@export var compress_source:Image.CompressSource = Image.COMPRESS_SOURCE_GENERIC
@export var compress_channels:Image.UsedChannels = Image.USED_CHANNELS_RGBA
@export var compress_mode:Image.CompressMode = Image.COMPRESS_ETC
@export var compress_astc_format:Image.ASTCFormat = Image.ASTC_FORMAT_4x4

@export_group("Convert")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var enable_convert:bool = false
@export var convert_format:Image.Format = Image.FORMAT_RGBA8

@export_group("Mipmaps")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var enable_mipmaps:bool = false

@export_group("Brightness, Contrast and Saturation")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var enable_bcs:bool = false
@export var bcs_brightness:float = 1.0
@export var bcs_contrast:float = 1.0
@export var bcs_saturation:float = 1.0


func _apply(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	if not DirAccess.dir_exists_absolute( save_directory ):
		GLDebug.error("Terrain Texture Formater Failed: Invalid 'save_directory=%s'" %save_directory)
		return false
	
	controller = controller as GLControllerTerrain
	
	var processed:GLBuildDataTerrain = controller.processed
	var save_paths:Array[String]
	
	for layer in processed.layers:
		var image:Image = _format_image( layer.get_image() )
		var save_path:String = save_directory.path_join( layer.material_channel )
		var err:int = OK
		
		match save_as:
			SaveAs.PNG:
				save_path += ".png"
				err = image.save_png( save_path)
			SaveAs.JPG:
				save_path += ".jpg"
				err = image.save_jpg( save_path , save_webp_jpg_quality )
			SaveAs.WEBP:
				save_path += ".webp"
				err = image.save_webp( save_path, save_webp_lossy, save_webp_jpg_quality )
		
		save_paths.append( save_path )
		if err != OK:
			GLDebug.error("Terrain Texture Save Failed. Reason: %s" %error_string(err))
			return false
	
	await _frame()
	EditorInterface.get_resource_filesystem().scan_sources()
	await _timeout( 0.5 )
	
	# Reload resources
	for i in save_paths.size():
		var save_path:String = save_paths[i]
		var layer:GLPaintLayer = processed.layers[i]
		var texture:Texture = load( save_path )
		controller.terrain.material_override.set_shader_parameter( layer.material_channel, texture )
	
	GLDebug.state("Terrain Texture Formater Succesfull: Files=%s" %save_paths)
	return true
	

func _clear(controller:GLController) -> bool:
	if not controller is GLControllerTerrain:
		GLDebug.error("Terrain Texture Formater Failed: This effect is only valid for GLControllerTerrain controller types")
		return false
	
	controller = controller as GLControllerTerrain
	var source:GLBuildDataTerrain = controller.source
	
	return true
	


func _format_image(image:Image) -> Image:
	var err:int = OK
	
	if image.has_mipmaps():
		image.clear_mipmaps()
	
	if image.is_compressed():
		image.decompress()
	
	if enable_resize:
		image.resize( resize_size.x, resize_size.y, resize_interpolation )
	
	if enable_bcs:
		image.adjust_bcs( bcs_brightness, bcs_contrast, bcs_saturation )
	
	if enable_compression:
		if compress_by == CompressBy.SOURCE:
			err = image.compress( compress_mode, compress_source, compress_astc_format )
		else:
			err = image.compress_from_channels( compress_mode, compress_channels, compress_astc_format )
	
		if err != OK:
			GLDebug.error("Terrain Texture Compression Failed. Reason: %s" %error_string(err))
			return null
	
	if enable_convert:
		image.convert( convert_format )
	
	if enable_mipmaps:
		image.generate_mipmaps()
		if err != OK:
			GLDebug.error("Terrain Texture Mipmaps Failed. Reason: %s" %error_string(err))
			return null
	
	match alpha_operation:
		AlphaOps.FIX_ALPHA_EDGES:
			image.fix_alpha_edges()
		AlphaOps.PREMULT_ALPHA:
			image.premultiply_alpha()
	
	match color_space_conversion:
		ColorSpace.RGBE_TO_SRGB:
			image = image.rgbe_to_srgb()
		ColorSpace.SRGB_TO_LINEAR:
			image.srgb_to_linear()
		ColorSpace.LINEAR_TO_SRGB:
			image.linear_to_srgb()
	
	return image










	
