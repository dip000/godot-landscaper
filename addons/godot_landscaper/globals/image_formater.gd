@tool
extends Resource
class_name GLImageFormater


enum CompressBy {
	SOURCE, ## As specified from method [member Image.compress]
	CHANNELS, ## As specified from method [member Image.compress_from_channels]
}

enum ColorSpace {
	NONE, ## Does not convert
	SRGB_TO_LINEAR, ## As specified in [member Image.rgbe_to_srgb]
	RGBE_TO_SRGB, ## As specified in [member Image.srgb_to_linear]
	LINEAR_TO_SRGB, ## As specified in [member Image.linear_to_srgb]
}

enum AlphaOps {
	NONE, ## Does not perform alpha operations
	PREMULT_ALPHA, ## As specified in [member Image.premultiply_alpha]
	FIX_ALPHA_EDGES, ## As specified in [member Image.fix_alpha_edges]
}


@export_group("Save Details", "save_")
## Folder, name and format of the texture.[br]
## Formats [code]jpg/webp[/code] will use the dedicated save methods from the [Image.save_webp] or [Image.save_jpg] methods and its paramenters
@export_custom(PROPERTY_HINT_SAVE_FILE, "*.png,*.jpg,*.webp", PROPERTY_USAGE_EDITOR) var save_file:String = "res://texture.png"

## Save hint as specified by [member Image.save_webp] or [member Image.save_jpg]
@export var save_webp_jpg_quality:float = 0.75

## Save hint as specified by [member Image.save_webp]
@export var save_webp_lossy:bool = false


@export_group("Resize", "resize_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var resize_enable:bool = false
## Resize size as specified by [member Image.resize]
@export var resize_size:Vector2i = Vector2i(1024, 1024):
	set(v): resize_size = v.max(Vector2i.ONE)

## Resize interpolation as specified by [member Image.resize]
@export var resize_interpolation:Image.Interpolation = Image.INTERPOLATE_LANCZOS

@export_group("Compression", "compress_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var compress_enable:bool = false
## Compression method as specified by the [Image] class
@export var compress_by:CompressBy = CompressBy.SOURCE

## Compression source as specified by [member Image.compress]
@export var compress_source:Image.CompressSource = Image.COMPRESS_SOURCE_GENERIC
## Compression channels as specified by [member Image.compress_from_channels]
@export var compress_channels:Image.UsedChannels = Image.USED_CHANNELS_RGBA
## Compression mode as specified by [member Image.compress] or [member Image.compress_from_channels]
@export var compress_mode:Image.CompressMode = Image.COMPRESS_ETC
## Compression ASTC Format as specified by [member Image.compress] or [member Image.compress_from_channels]
@export var compress_astc_format:Image.ASTCFormat = Image.ASTC_FORMAT_4x4

@export_group("Convert", "convert_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var convert_enable:bool = false
## Conversion format as specified by [member Image.convert]
@export var convert_format:Image.Format = Image.FORMAT_RGBA8

@export_group("Mipmaps")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var enable_mipmaps:bool = false

@export_group("Brightness, Contrast and Saturation", "bcs_")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "", PROPERTY_USAGE_EDITOR) var bcs_enable:bool = false
## Brightness as specified by [member Image.adjust_bcs]
@export var bcs_brightness:float = 1.0
## Contrast as specified by [member Image.adjust_bcs]
@export var bcs_contrast:float = 1.0
## Saturation as specified by [member Image.adjust_bcs]
@export var bcs_saturation:float = 1.0


@export_group("Other")
## Applies conversions in color space
@export var color_space_conversion:ColorSpace

## Applies alpha operations
@export var alpha_operation:AlphaOps


## Constructor for starting with a predefined save file path
static func from_save_path(path:String) -> GLImageFormater:
	var formater:GLImageFormater = GLImageFormater.new()
	formater.save_file = path
	return formater


## Formats with all enabled properties and
## saves image into [member save_directory] with the given name and extension [member save_as]
func format_and_save(image:Image) -> bool:
	image = format( image )
	if not image:
		return false
	return save( image )


## Formats with all enabled properties
func format(image:Image) -> Image:
	if not image:
		GLDebug.error("Image Formater Failed: Image is null")
		return null
	
	var err:int = OK
	if image.has_mipmaps():
		image.clear_mipmaps()
	
	if image.is_compressed():
		err = image.decompress()
		if err != OK:
			GLDebug.error("Image Formater Failed. Decompression error: %s" %error_string(err))
			return null
	
	if resize_enable:
		image.resize( resize_size.x, resize_size.y, resize_interpolation )
	
	if bcs_enable:
		image.adjust_bcs( bcs_brightness, bcs_contrast, bcs_saturation )
	
	if enable_mipmaps:
		image.generate_mipmaps()
		if err != OK:
			GLDebug.error("Image Formater Failed. Mipmaps error: %s" %error_string(err))
			return null
	
	if convert_enable:
		image.convert( convert_format )
	
	if compress_enable:
		if compress_by == CompressBy.SOURCE:
			err = image.compress( compress_mode, compress_source, compress_astc_format )
		else:
			err = image.compress_from_channels( compress_mode, compress_channels, compress_astc_format )
	
		if err != OK:
			GLDebug.error("Image Formater Failed. Compression error: %s" %error_string(err))
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


## Saves image into [member save_directory] with the given name and extension [member save_as]
func save(image:Image) -> bool:
	var err:int = OK
	var extension:String = save_file.get_extension()
	
	match extension:
		"png":
			err = image.save_png( save_file )
		"jpg":
			err = image.save_jpg( save_file , save_webp_jpg_quality )
		"webp":
			err = image.save_webp( save_file, save_webp_lossy, save_webp_jpg_quality )
		_:
			ResourceSaver.save( image, save_file, ResourceSaver.FLAG_COMPRESS )
	
	return err == OK



	
