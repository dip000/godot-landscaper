@tool
extends Resource
class_name GLStencilMaker

const DEFAULT_FORMAT:Image.Format = Image.FORMAT_RGBA8

## An image to make your own stencil shape. Try using a tileable texture
@export var input_reference:Texture2D = GLAssetsManager.load_controller_resource("terrain", "paving_stones.svg")

## Result after pressing "Mix". You can link the result with the [member GLControllerTerrain.brush_shape]
@export var output:ImageTexture

@export var timeout_sec:float = 5

@export_tool_button("                Mix                ", "Blend") var blend_btn:Callable = _blend

@export_group("Transform")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Transform", PROPERTY_USAGE_EDITOR) var enable_transforms:bool = true
@export_range(0.1, 10.0, 0.01, "or_greater", "exp") var scale:float = 1.0
@export var slide:Vector2i = Vector2i.ZERO


@export_group("Luminance-Based Threshold")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Alpha Threshold", PROPERTY_USAGE_EDITOR) var enable_threshold:bool = true
## Transparents any pixel with luminance lesser that this value.
## Min and Max can be inverted
@export_range(0.0, 1.0, 0.01) var min_threshold:float = 0.3

## Transparents any pixel with luminance greater that this value
## Min and Max can be inverted
@export_range(0.0, 1.0, 0.01) var max_threshold:float = 0.7


@export_group("Whitening")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Whitening", PROPERTY_USAGE_EDITOR) var enable_whitening:bool = true
## How white you want the output.[br]
## - 0% Keeps the same colors.[br]
## - 100% Only color white and transparency. For modulable stencils
@export_range(0.0, 100.0, 1.0, "suffix:%") var whitening:float = 50


@export_group("Distortion")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Effects", PROPERTY_USAGE_EDITOR) var enable_distortion:bool = false
## Shifts the pixels based on a noise generator
@export var distortion_map:NoiseTexture2D = NoiseTexture2D.new()

## How much to shift the result
@export_range(0.0, 100, 1.0, "or_less", "or_greater", "suffix:%") var distortion_strenght:float = 10


@export_group("Masking")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "Masking", PROPERTY_USAGE_EDITOR) var enable_masking:bool = false
## The input image pixels will be multiplied by this mask. Alpha 
@export var mask:Texture2D = GLAssetsManager.load_controller_resource("terrain", "brush_shape.tres").duplicate(true)


func _blend():
	if not input_reference:
		GLDebug.error("Stencil Mixer Failed: 'input_stencil' is null. Set a reference image to make a stencil")
		return
	
	var img_reference:Image = input_reference.get_image().duplicate()
	var size_reference:Vector2i = img_reference.get_size()
	var whitening_factor:float = whitening * 0.01
	var start_msec:float = Time.get_ticks_msec()
	var timeout:float = timeout_sec * 1000
	
	# Setup transforms
	if enable_transforms:
		size_reference *= scale
	
	# Setup distortion
	if distortion_map.height != size_reference.y or distortion_map.width != size_reference.x:
		distortion_map.height = size_reference.y
		distortion_map.width = size_reference.x
		await Engine.get_main_loop().create_timer(0.5).timeout
	if not distortion_map.noise:
		distortion_map.noise = FastNoiseLite.new()
		await Engine.get_main_loop().create_timer(0.5).timeout
	
	var distortion:Image = distortion_map.get_image()
	var distortion_factor:float = distortion_strenght * 0.01 * size_reference.x
	
	# Setup mask
	var mask_image:Image
	if enable_masking:
		mask_image = GLImageCleaner.hard_clean_image( mask.get_image(), DEFAULT_FORMAT, size_reference )
	
	GLImageCleaner.soft_clean_image( img_reference, DEFAULT_FORMAT, size_reference )
	
	for x in size_reference.x:
		for y in size_reference.y:
			
			# Input
			var paint_position:Vector2i = Vector2i( x, y )
			
			# Transform
			var uv:Vector2 = paint_position
			if enable_transforms:
				uv += Vector2(slide)
			
			# Distortion
			if enable_distortion:
				uv.x += distortion.get_pixelv( paint_position ).r * distortion_factor
				uv.y += distortion.get_pixelv( paint_position ).r * distortion_factor
			
			# Repeat by default
			uv.x = wrapi( uv.x, 0, size_reference.x )
			uv.y = wrapi( uv.y, 0, size_reference.y )
			
			var color:Color = img_reference.get_pixelv( uv )
			
			if enable_threshold:
				var lum:float = color.get_luminance()
				var threshold:float = smoothstep( min_threshold, max_threshold, lum )
				color *= threshold
			
			if enable_masking:
				var mask_color:Color = mask_image.get_pixelv( paint_position )
				color *= mask_color
			
			if enable_whitening:
				color.r = lerpf( color.r, 1.0, whitening_factor )
				color.g = lerpf( color.g, 1.0, whitening_factor )
				color.b = lerpf( color.b, 1.0, whitening_factor )
			
			img_reference.set_pixelv( paint_position, color )
			
			# Handle timeouts
			var time:int = Time.get_ticks_msec() - start_msec
			if time >= timeout:
				GLDebug.error("Stencil Mixer Failed: Timed out. Set 'timeout_sec' to a greater value")
				break
	
	if output:
		output.set_image( img_reference )
	else:
		output = ImageTexture.create_from_image( img_reference )
	













	
