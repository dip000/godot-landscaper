@tool
extends Resource
class_name GLStencilMaker

const DEFAULT_FORMAT:Image.Format = Image.FORMAT_RGBA8

## The base shape of the stencil. Try using a radial [GradientTexture2D]
@export var input_mask:Texture2D = GLAssetsManager.load_controller_resource("terrain", "brush_shape.tres").duplicate()

## An image to make your own stencil shape. Try using a tileable texture
@export var input_stencil:Texture2D = GLAssetsManager.load_controller_resource("terrain", "paving_stones.png")

## Result after pressing "Mix". You can link the result with the [member GLControllerTerrain.brush_shape]
@export var output:ImageTexture

@export_tool_button("                Mix                ", "Blend") var blend_btn:Callable = _blend

@export_group("Settings")
@export_range(0.0, 100.0, 1.0, "or_less", "or_greater") var distortion:float = 0.0
@export_range(0.0, 1.0, 0.01) var min_threshold:float = 0.4
@export_range(0.0, 1.0, 0.01) var max_threshold:float = 0.6
@export_range(0.1, 10.0, 0.01, "or_less", "or_greater", "exp") var stencil_scale:float = 0.5
@export var stencil_offset:Vector2i = Vector2i.ZERO

func _blend():
	if not input_mask or not input_stencil:
		GLDebug.error("Stencil Mixer Failed: An input is invalid. Create or add an input")
		return
	
	var img_mask:Image = input_mask.get_image().duplicate()
	var img_stencil:Image = input_stencil.get_image().duplicate()
	var size_mask:Vector2i = img_mask.get_size()
	var size_stencil:Vector2i = img_stencil.get_size()
	var half_size_stencil:Vector2 = size_stencil * 0.5
	var half_size_mask:Vector2i = size_mask * 0.5
	
	sanitize( img_mask, size_mask )
	sanitize( img_stencil, size_stencil )
	
	var mask_rect:Rect2i = Rect2i(Vector2i.ZERO, size_mask)
	var stencil_rect:Rect2i = Rect2i(Vector2i.ZERO, size_stencil)
	var effect_rect:Rect2i = mask_rect.intersection( stencil_rect )
	var noise:FastNoiseLite = FastNoiseLite.new()

	for paint_position in GLRect2iter.from( mask_rect ):
		var mask:Color = img_mask.get_pixelv( paint_position )
		if is_zero_approx( mask.a ):
			continue
		
		var centered_and_scaled:Vector2 = paint_position - half_size_mask + stencil_offset
		centered_and_scaled /= stencil_scale
		centered_and_scaled += half_size_stencil
		
		if centered_and_scaled.x < 0 or centered_and_scaled.y < 0 \
		or centered_and_scaled.x >= size_stencil.x \
		or centered_and_scaled.y >= size_stencil.y:
			continue
		
		if distortion > 0:
			centered_and_scaled.x += noise.get_noise_2dv( paint_position ) * distortion
			centered_and_scaled.y += noise.get_noise_2dv( (paint_position + Vector2i(1000,1000)) ) * distortion
			centered_and_scaled = centered_and_scaled.clamp( Vector2i.ZERO, size_stencil - Vector2i.ONE )
		
		var stencil_color:Color = img_stencil.get_pixelv( centered_and_scaled )
		var mask_result:Color = Color.TRANSPARENT
		var lum:float = stencil_color.get_luminance()
		var threshold:float = smoothstep( min_threshold, max_threshold, lum )
		var result:Color = Color.WHITE
		result.a = clamp(mask.a * threshold, 0.0, 1.0)
		img_mask.set_pixelv( paint_position, result )
	
	if output:
		output.set_image( img_mask )
	else:
		output = ImageTexture.create_from_image( img_mask )
	

func sanitize(image:Image, size:Vector2i):
	if image.has_mipmaps():
		image.clear_mipmaps()
	if image.is_compressed():
		image.decompress()
	if image.get_format() != DEFAULT_FORMAT:
		image.convert( DEFAULT_FORMAT )
	if image.get_size() != size:
		image.resize( size.x, size.y )















	
