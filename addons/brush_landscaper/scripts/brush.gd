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
var _texture:Texture2D
var _resolution:int


# Unpack all of its new properties from "raw"
func load_ui(ui:UILandscaper, scene:SceneLandscaper, raw:RawLandscaper):
	_ui = ui
	_scene = scene
	_raw = raw

# Pack all of its properties to "_raw" so they can be saved
func save_ui():
	pass

# Called while paint brushing over the 3D scene's terrain
func paint(pos:Vector3, primary_action:bool):
	pass

# Any logic needed to rebuild the scene terrain; update textures, colliders, shaders, scatteres, ect..
func rebuild_terrain():
	pass


# Change texture resolution
func resize_texture(new_resolution:Vector2i):
	var img:Image = _texture.get_image()
	img.resize( new_resolution.x, new_resolution.y )
	_texture.set_image( img )


# Paints "texture" with "out_color" at given "pos" with the global brush size
func _bake_out_color_into_texture(pos:Vector3):
	# Transforms
	var _scale:float = _ui.brush_size.value
	var texture_size:Vector2i = _texture.get_size()
	var surface_full_rect := Rect2i(Vector2i.ZERO, texture_size)
	var _size:Vector2i = texture_size * _scale #size in pixels
	
	# Even the brush size using the bigest axis
	if _size.x > _size.y:
		_size = Vector2i.ONE * maxi(1, _size.x)
	else:
		_size = Vector2i.ONE * maxi(1, _size.y)
	
	var pos_v2:Vector2 = Vector2(pos.x, pos.z)
	var world_offset:Vector2 = _scene.raw.world_offset
	var bounds_size:Vector2 = _ui.terrain_builder.bounds_size
	var pos_absolute:Vector2 = (pos_v2-world_offset) / bounds_size #in [0,1] range
	pos_absolute *= Vector2(texture_size) #move in pixel size
	pos_absolute -= (texture_size/2.0) * _scale #move from top-left corner
	
	# Duplicate to keep original resolution
	# 'texture_image' and 'brush_color' formats must match. 
	var brush_mask:Image = AssetsManager.DEFAULT_BRUSH.get_image().duplicate()
	var texture_image:Image = _texture.get_image()
	var texture_format:int = texture_image.get_format()
	var brush_color:Image = _create_img(out_color, _size, texture_format)
	
	# Blend brush over surface
	# 'brush_color' and 'brush_mask' sizes must match
	brush_mask.resize(_size.x, _size.y)
	texture_image.blend_rect_mask( brush_color, brush_mask, surface_full_rect, pos_absolute)
	_texture.update(texture_image)


# Crops texture on smaller sizes, expands on bigger ones. But always keeps pixels where they were
# "min" and "max" are the new bounding box corners relative to the current texture size
func extend_texture(min:Vector2i, max:Vector2i):
	var prev_size:Vector2i = _texture.get_size()
	var prev_img:Image = _texture.get_image()
	var prev_format:int = prev_img.get_format()
	
	var new_size:Vector2i = (max - min) * _resolution
	var new_img:Image = _create_img( out_color, new_size, prev_format )
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var dst:Vector2 = (-min) * _resolution
	
	new_img.blit_rect( prev_img, prev_img_full_rect, dst )
	_texture.set_image( new_img )

# "terrain_height" has to have one pixel more for the extra vertex
func _extend_all_textures(min:Vector2i, max:Vector2i):
	_ui.terrain_height.extend_texture( min, max+Vector2i.ONE )
	_ui.terrain_clor.extend_texture( min, max )
	_ui.grass_color.extend_texture( min, max )
	_ui.grass_spawn.extend_texture( min, max )
	_ui.terrain_builder.extend_texture( min, max )
	# Update distance from world center to top-left corner of the bounding box terrain
	_raw.world_offset += min


# Handy wrappers
func _update_grass_shader(property:String, value:Variant):
	_scene.grass_mesh.material.set_shader_parameter(property, value)
func _update_terrain_shader(property:String, value:Variant):
	_scene.terrain_overlay.material_override.set_shader_parameter(property, value)

func _create_texture(color:Color, img_size:Vector2i, format:int):
	return ImageTexture.create_from_image( _create_img(color, img_size, format) )

func _create_img(color:Color, img_size:Vector2i, format:int) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, format)
	img.fill(color)
	return img

func _preview_texture():
	var tex_rec := TextureRect.new()
	tex_rec.texture = _texture
	tex_rec.custom_minimum_size = Vector2(100, 100)
	tex_rec.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rec.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_preview.value = [tex_rec]

