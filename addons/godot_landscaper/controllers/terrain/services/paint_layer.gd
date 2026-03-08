## First class object for GLBrushTerrainPaint
##
## The [member sampler] is the same as the uniform sampler2D from a [Shader]
## 
 
@tool
extends Resource
class_name GLPaintLayer

const DEFAULT_FORMAT:Image.Format = Image.FORMAT_RGBA8
const DEFAULT_COLOR:Color = Color(0, 0, 0, 0)

enum SizeMode {
	CROP_AND_EXPAND, ## Crops or expands the texture with the terrain size keeping the same pixels spatially where they were.
	ABSOLUTE, ## Makes the texture size immutable. Usefull for tiling smaller textures in the shader.
}

## Only the first active layer found will be edited, the rest will be locked.[br]
## Use with the Paint Layers panel, a.k.a [GLUILayers].
@export var active:bool = true

## This layer's texture. Will be converted to [ImageTexture] for image processing.[br]
## Note: All texture layers will be blended into a single output texture in [member GLBuildDataTerrain.texture]
@export var texture:Texture2D

## Name of the shader parameter this layer feeds (albedo, roughness, ao..).[br][br]
## Layers sharing the same channel are composited into a single texture during build. For example:[br]
## [code]Base albedo + sea floor + grass patch = "terrain_texture"[/code][br][br]
## Painting with alpha will reveal the bottom layers.
@export var sampler:String = "terrain_texture"

@export_tool_button("       Clear       ", "Clear") var clear_btn:Callable = clear

@export_group("Size")
## Size behavior
@export var size_mode:SizeMode = SizeMode.CROP_AND_EXPAND

## If [member size_mode] is [member SizeMode.CROP_AND_EXPAND]. The texture's pixel density in pixels per meter.
@export_range(1.0, 1024, 1.0, "or_greater", "exp", "suffix:pixels/meter") var texel_size:float = 32

## If [member size_mode] is [member SizeMode.ABSOLUTE]. The absolute size of the texture
@export var absolute_size:Vector2i = Vector2i(1024, 1024)



static func get_active(layers:Array[GLPaintLayer]) -> GLPaintLayer:
	for layer in layers:
		if layer and layer.active:
			return layer
	return null


static func get_channel(channel_name:String, layers:Array[GLPaintLayer]) -> GLPaintLayer:
	for layer in layers:
		if layer.sampler == channel_name:
			return layer
	return null


## Generates new layers. Alpha blends the ones with the same name
static func compose_sampler_outputs(layers:Array[GLPaintLayer]) -> Array[GLPaintLayer]:
	var result:Array[GLPaintLayer] = []
	var base_layer:GLPaintLayer
	var input_names:PackedStringArray
	var output_names:PackedStringArray
	
	for layer in layers:
		if not layer:
			continue
		
		input_names.append( layer.sampler )
		if base_layer and layer.sampler == base_layer.sampler:
			base_layer.overlay_with( layer )
			base_layer.active = base_layer.active or layer.active
		else:
			base_layer = layer.duplicate( true )
			result.append( base_layer )
			output_names.append( base_layer.sampler )
	
	GLDebug.internal( "Composition Results: Input%s, Output%s" %[input_names, output_names])
	return result


func clear():
	if texture:
		texture = GLImageCleaner.hard_clean_texture( texture, DEFAULT_FORMAT, texture.get_size(), DEFAULT_COLOR )


func overlay_with(other_layer:GLPaintLayer):
	var image:Image = GLImageCleaner.hard_clean_image( texture.get_image(), DEFAULT_FORMAT, texture.get_size(), DEFAULT_COLOR )
	var other_image:Image = other_layer.get_image()
	var rect:Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
	image.blend_rect( other_image, rect, Vector2i.ZERO )
	texture.update( image )


func get_image() -> Image:
	var image:Image = texture.get_image()
	GLImageCleaner.soft_clean_image( image, DEFAULT_FORMAT )
	return image


func get_image_resize(world_size:Vector2i) -> Image:
	var image:Image = texture.get_image()
	var relative_size:Vector2i = meters_to_pixels( world_size )
	var current_size:Vector2i = image.get_size()
	
	if size_mode == SizeMode.ABSOLUTE and current_size != absolute_size:
		image.resize( absolute_size.x, absolute_size.y )
		texture.set_image( image )
	elif size_mode == SizeMode.CROP_AND_EXPAND and current_size != relative_size:
		image.resize( relative_size.x, relative_size.y )
		texture.set_image( image )
	
	return image


func update_image(image:Image):
	texture.update( image )


## Crops or expands the texture to fit the new_rect.
## [GLBrushTerrainBuider] will shrink or expand this layer's texture with the terrain.
func crop_expand(prev_rect:Rect2i, new_rect:Rect2i):
	if size_mode != SizeMode.CROP_AND_EXPAND:
		return
	
	if prev_rect.size == new_rect.size or new_rect.size <= Vector2i.ZERO:
		return
	
	# 1. Create base image
	var new_size:Vector2i = meters_to_pixels( new_rect.size )
	var new_img:Image = Image.create( new_size.x, new_size.y, false, DEFAULT_FORMAT )
	var image:Image = texture.get_image()
	if not image:
		texture.set_image( new_img )
		return
	
	GLDebug.internal(
		"Shrink/Expand Texture. Texel Size: %s, Meters: %s -> %s, Pixels: %s -> %s"
		%[texel_size, prev_rect.size, new_rect.size, image.get_size(), new_size]
	)
	
	# 2. Compute destination for old image
	var texture_position:Vector2i = meters_to_pixels( prev_rect.position - new_rect.position )
	
	# 3. Paste old image
	new_img.blit_rect( image, Rect2i(Vector2i.ZERO, image.get_size()), texture_position )
	texture.set_image( new_img )


## Converts px/m2 * m2 = px
func meters_to_pixels(squared_meters:Vector2) -> Vector2:
	return (texel_size * squared_meters).round()










	
