extends Resource
class_name Brush
# BASE CLASS FOR ALL BRUSHES
#  Saves terrain-specific settings in a Landscaper node instance.

# List of all brushes.
# Implementations of this class shall get whichever property they need using this
# Example: DockUI.get_property(GRASS_SPAWN, DENSITY)
# Where 'DENSITY' should be declared inside GrassSpawn class
enum {TERRAIN_BUILDER, TERRAIN_COLOR, TERRAIN_HEIGHT, GRASS_COLOR, GRASS_SPAWN}

var texture:Texture2D
var out_color:Color
var landscaper:Landscaper


func enter():
	pass

func setup():
	pass

func paint(pos:Vector3, primary_action:bool):
	pass

func template(size:Vector2i):
	pass

func update_texture():
	pass

func update_shaders():
	pass

func exit():
	pass



func change_texture_resolution(new_resolution:Vector2i):
	var img:Image = texture.get_image()
	var bounds_size:Vector2i = landscaper.brushes[TERRAIN_BUILDER].bounds_size
	
	img.resize( bounds_size.x * new_resolution.x, bounds_size.y * new_resolution.y )
	texture.set_image( img )


# Paints "texture" with "out_color"
func _bake_out_color_into_texture(scale:float, pos:Vector3):
	# Transforms
	var texture_size:Vector2i = texture.get_size()
	var surface_full_rect := Rect2i(Vector2i.ZERO, texture_size)
	var size:Vector2i = texture_size * scale #size in pixels
	var bound_size_m:Vector2 = landscaper.brushes[TERRAIN_BUILDER].bounds_size
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z) / bound_size_m #in [0,1] range
	pos_absolute *= Vector2(texture_size) #move in pixel size
	pos_absolute += (texture_size/2.0) * (1.0-scale) #move from center
	
	# Duplicate to keep original resolution
	# 'texture_image' and 'brush_color' formats must match. 
	var brush_mask:Image = load("res://addons/brush_landscaper/textures/default_brush.tres").get_image().duplicate()
	var texture_image:Image = texture.get_image()
	var texture_format:int = texture_image.get_format()
	var brush_color:Image = _create_img(out_color, size, texture_format)
	
	# Blend brush over surface
	# 'brush_color' and 'brush_mask' sizes must match
	brush_mask.resize(size.x, size.y)
	texture_image.blend_rect_mask( brush_color, brush_mask, surface_full_rect, pos_absolute)
	texture.update(texture_image)


# Handy wrappers
func _update_grass_shader(property:String, value:Variant):
	landscaper.grass_mesh.material.set_shader_parameter(property, value)
func _update_terrain_shader(property:String, value:Variant):
	landscaper.terrain_overlay.material_override.set_shader_parameter(property, value)

func _create_texture(color:Color, img_size:Vector2i, format:int) -> Texture2D:
	return ImageTexture.create_from_image( _create_img(color, img_size, format) )

func _create_img(color:Color, img_size:Vector2i, format:int) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, format)
	img.fill(color)
	return img
