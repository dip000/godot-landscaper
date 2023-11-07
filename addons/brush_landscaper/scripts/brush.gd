@tool
extends VBoxContainer
class_name Brush
# BASE CLASS FOR ALL BRUSHES
#  Every brush implements a different functionality based of painting or
#  brushing over a terrain.
#  
#  Note that brushes use 'PropertyUI' to store their specific values like
#  'CustomColorPicker' for color brushes.


# The texture you'll painting over; color, heightmap, etc..
var texture:Texture2D
# The output color. Usually black or white for non-color brushes
var out_color:Color
# Hub for node references in scene
var scene:SceneLandscaper
# Hub for control references
var ui:UILandscaper


# On select brush
func enter():
	show()
func exit():
	hide()

# On new landscape start
func setup():
	pass

# Called while creating a stroke over the 3D scene's terrain
func paint(pos:Vector3, primary_action:bool):
	pass

# Create a custom template for a new terrains
func template(size:Vector2i):
	pass

# May be called any time the the textures were updated, like creating them or loading them
func update_texture():
	pass


# Change texture resolution
func resize_texture(new_resolution:Vector2i):
	var img:Image = texture.get_image()
	img.resize( new_resolution.x, new_resolution.y )
	texture.set_image( img )


# Paints "texture" with "out_color"
func _bake_out_color_into_texture(pos:Vector3):
	# Transforms
	var _scale:float = ui.brush_size.value/100
	var texture_size:Vector2i = texture.get_size()
	var surface_full_rect := Rect2i(Vector2i.ZERO, texture_size)
	var _size:Vector2i = texture_size * _scale #size in pixels
	_size.x = max(1, _size.x)
	_size.y = max(1, _size.y)
	
	var bound_size_m:Vector2 = ui.terrain_builder.bounds_size
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z) / bound_size_m #in [0,1] range
	pos_absolute *= Vector2(texture_size) #move in pixel size
	pos_absolute += (texture_size/2.0) * (1.0-_scale) #move from center
	
	# Duplicate to keep original resolution
	# 'texture_image' and 'brush_color' formats must match. 
	var brush_mask:Image = load("res://addons/brush_landscaper/textures/default_brush.tres").get_image().duplicate()
	var texture_image:Image = texture.get_image()
	var texture_format:int = texture_image.get_format()
	var brush_color:Image = _create_img(out_color, _size, texture_format)
	
	# Blend brush over surface
	# 'brush_color' and 'brush_mask' sizes must match
	brush_mask.resize(_size.x, _size.y)
	texture_image.blend_rect_mask( brush_color, brush_mask, surface_full_rect, pos_absolute)
	texture.update(texture_image)


# Handy wrappers
func _update_grass_shader(property:String, value:Variant):
	scene.grass_mesh.material.set_shader_parameter(property, value)
func _update_terrain_shader(property:String, value:Variant):
	scene.terrain_overlay.material_override.set_shader_parameter(property, value)

func _create_texture(color:Color, img_size:Vector2i, format:int) -> Texture2D:
	return ImageTexture.create_from_image( _create_img(color, img_size, format) )

func _create_img(color:Color, img_size:Vector2i, format:int) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, format)
	img.fill(color)
	return img
