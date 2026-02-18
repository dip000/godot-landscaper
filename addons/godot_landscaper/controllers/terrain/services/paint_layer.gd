@tool
extends Resource
class_name GLPaintLayer

const DEFAULT_FORMAT:Image.Format = Image.FORMAT_RGBA8
const DEFAULT_COLOR:Color = Color(0, 0, 0, 0)

## Only the first active layer will be edited, the rest will be locked.
@export var active:bool = true

## This layer's texture.
## All texture layers will be blended into a single output texture in [member GLBuildDataTerrain.texture]
@export var texture:ImageTexture

## Name of the shader parameter this layer feeds (albedo, roughness, ao..).[br][br]
## Layers sharing the same channel are composited into a single texture during build. For example:[br]
## [code]Base albedo + sea floor + grass patch = "terrain_texture"[/code][br][br]
## Painting with alpha will reveal the bottom layers.
@export var material_channel:String = "terrain_texture"

@export_tool_button("       Clear       ", "Clear") var clear_btn:Callable = clear


static func get_active(layers:Array[GLPaintLayer]) -> GLPaintLayer:
	for layer in layers:
		if layer and layer.active:
			return layer
	return null


static func get_channel(channel_name:String, layers:Array[GLPaintLayer]) -> GLPaintLayer:
	for layer in layers:
		if layer.material_channel == channel_name:
			return layer
	return null


static func compose_sampler_outputs(layers:Array[GLPaintLayer]) -> Array[GLPaintLayer]:
	var result:Array[GLPaintLayer] = []
	var base_layer:GLPaintLayer
	var input_names:PackedStringArray
	var output_names:PackedStringArray
	
	for layer in layers:
		if not layer:
			continue
		
		input_names.append( layer.material_channel )
		if base_layer and layer.material_channel == base_layer.material_channel:
			base_layer.overlay_with( layer )
			base_layer.active = base_layer.active or layer.active
		else:
			base_layer = layer.duplicate( true )
			result.append( base_layer )
			output_names.append( base_layer.material_channel )
	
	GLDebug.internal( "Composition Results: Input=%s, Output=%s" %[input_names, output_names])
	return result


func clear():
	if texture:
		var size:Vector2i = texture.get_size()
		var image:Image = Image.create_empty( size.x, size.y, false, DEFAULT_FORMAT )
		image.fill( DEFAULT_COLOR )
		texture = ImageTexture.create_from_image( image )


func overlay_with(other_layer:GLPaintLayer):
	var image:Image = get_image()
	var other_image:Image = other_layer.get_image()
	var rect:Rect2i = Rect2i(Vector2i.ZERO, image.get_size())
	image.blend_rect( other_image, rect, Vector2i.ZERO )
	texture.update( image )


func update_image(image:Image):
	#TODO: Check for new size
	texture.update( image )


func get_image() -> Image:
	var image:Image = texture.get_image()
	
	if image.has_mipmaps():
		image.clear_mipmaps()
	
	if image.is_compressed():
		image.decompress()
	
	if image.get_format() != DEFAULT_FORMAT:
		image.convert( DEFAULT_FORMAT )
	
	return image
	

func new_image(color:Color, size:Vector2i) -> Image:
	var image:Image = Image.create_empty( size.x, size.y, false, DEFAULT_FORMAT )
	image.fill( color )
	return image






	
