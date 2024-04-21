@tool
extends VBoxContainer
class_name Brush
# BASE CLASS FOR ALL BRUSHES
#  Every brush implements a different functionality based of brush-painting over a terrain.
#  * Use 'PropertyUI' to show their UI values like 'CustomColorPicker'
#  * Use scene-specific properties from '_raw' like '_raw.world_center'


# Every brush has a texture preview property inside a CustomToggleContent
@onready var texture_preview:CustomToggleContent = $ToggleContent


# The output color. Usually black or white for non-color brushes
var out_color:Color
# Hub for node references in scene
var _scene:SceneLandscaper
# Hub for control references
var _ui:UILandscaper
# Instance-specific properties from current scene
var _raw:RawLandscaper

# The texture you'll painting over; color, heightmap, etc..
var texture:ImageTexture

# How many pixels has the texture per meter squared
var _resolution:float

# Cached texture image. For faster image processing
var img:Image


# Unpack all of its new properties from "raw"
# "texture" should've been formated with '_format_texture()' before calling super()
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_ui = ui
	_scene = scene
	_raw = raw
	
	var tex_rec := TextureRect.new()
	tex_rec.texture = texture
	tex_rec.custom_minimum_size = Vector2(100, 100)
	tex_rec.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rec.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_preview.value = [tex_rec]

# Pack all of its properties to "_raw" so they can be saved
func save_ui():
	pass

# Called while paint brushing over the 3D scene's terrain
func paint(pos:Vector3, primary_action:bool):
	pass
func paint_end():
	pass

# Any logic needed to rebuild the scene terrain; update textures, colliders, shaders, scatteres, ect..
func rebuild_terrain():
	pass


# Usefull for color textures
func _change_resolution(new_resolution:float):
	var world_resolution:Vector2 = _raw.world.size * new_resolution
	img.resize( world_resolution.x, world_resolution.y )
	texture.set_image( img )
	_resolution = new_resolution


# Paints "texture" with "out_color" at given "pos" with the global brush size
func _bake_out_color_into_texture(pos:Vector3, blend:=true, world_offset:Vector2=_raw.world.position):
	var max_size:Vector2i = RawLandscaper.MAX_BUILD_REACH
	var brush_scale:float = _ui.brush_size.value
	var src_size:Vector2i = max_size * brush_scale * _resolution
	var full_rect := Rect2i(Vector2i.ZERO, img.get_size())
	src_size = Vector2i( max(src_size.x, 1), max(src_size.y, 1) )
	
	var dst := Vector2( pos.x, pos.z)
	dst -= world_offset # To texture space (positive indexes)
	dst *= _resolution # Relative to this texture resolition
	dst -= src_size*0.5 # Draw from texture center
	dst = dst.round()
	
	# Create copies so the original doesn't get distorted
	# 'get_image()' returns a copy unless the texture is constant
	var src:Image = _create_img( out_color, src_size, img.get_format() )
	var brush_mask:Image = AssetsManager.DEFAULT_BRUSH.get_image().duplicate()
	brush_mask.resize( src_size.x, src_size.y )
	
	if blend:
		img.blend_rect_mask( src, brush_mask, full_rect, dst )
	else:
		img.blit_rect_mask( src, brush_mask, full_rect, dst )
	
	texture.update( img )


# Crops texture on smaller sizes, expands on bigger ones. But always keeps pixels where they were
func resize_texture(rect:Rect2i, fill_color:Color):
	var prev_size:Vector2i = img.get_size()
	var prev_format:int = img.get_format()
	
	var new_size:Vector2i = rect.size * _resolution
	var new_img:Image = _create_img( fill_color, new_size, prev_format )
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var dst:Vector2 = rect.position * _resolution
	
	# Note that 'img' is being kept internally so 'get_image()' is never called, for performance
	new_img.blit_rect( img, prev_img_full_rect, dst )
	texture.set_image( new_img )
	img = new_img


# Handy wrappers
func _update_grass_shader(property:String, value:Variant):
	_scene.grass_mesh.material.set_shader_parameter(property, value)
	_scene.grass_mesh.emit_changed()
func _update_terrain_shader(property:String, value:Variant):
	_scene.terrain_overlay.material_override.set_shader_parameter(property, value)
	_scene.terrain_overlay.material_override.emit_changed()

func _format_texture(tex:Texture2D):
	texture = tex
	img = texture.get_image()

func _create_img(color:Color, img_size:Vector2i, format:int) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, format)
	img.fill(color)
	return img

