@tool
extends UIBrush
class_name BrushTexture

# Hub for control references. There's only one UI
static var ui:UIManager
# Hub for node references in scene
var _scene:SceneLandscaper
# Instance-specific properties from current scene
var _project:ProjectLandscaper
# How many pixels has the texture per meter squared
var _resolution:float
# The texture you'll painting over; color, heightmap, etc..
var texture:ImageTexture
# Cached texture image. For faster image processing
var img:Image


# Usefull for color textures
func __change_resolution(new_resolution:float):
	var world_resolution:Vector2 = _project.world.size * new_resolution
	img.resize( world_resolution.x, world_resolution.y )
	texture.set_image( img )
	_resolution = new_resolution


func __get_brush_size_px(pos:Vector3, world_offset:Vector2) -> Vector2:
	var max_size:Vector2i = _project.canvas.size
	var brush_scale:float = ui.brush_size.value
	var src_size:Vector2i = max_size * brush_scale * _resolution
	var full_rect := Rect2i(Vector2i.ZERO, img.get_size())
	src_size = Vector2i( max(src_size.x, 1), max(src_size.y, 1) )
	return src_size
	
func __get_texture_position_px(pos:Vector3, world_offset:Vector2) -> Vector2:
	var max_size:Vector2i = _project.canvas.size
	var brush_scale:float = ui.brush_size.value
	var src_size:Vector2i = max_size * brush_scale * _resolution
	var full_rect := Rect2i(Vector2i.ZERO, img.get_size())
	src_size = Vector2i( max(src_size.x, 1), max(src_size.y, 1) )
	
	var node:Vector3 = _scene.terrain.global_position
	var dst := Vector2( pos.x, pos.z)
	dst -= world_offset + Vector2(node.x, node.z)# To texture space (positive indexes)
	dst *= _resolution # Relative to this texture resolition
	dst -= src_size*0.5 # Draw from texture center
	return dst.round()


# Bakes the current texture using the parameters given
func __blend_color_into_texture(brush_shape_index:int, brush_color:Color, brush_size_px:Vector2, texture_position_px:Vector2):
	var brush_shape:Image = ui.brush_texture.tabs[brush_shape_index].get_image()
	var src:Image = __create_img( brush_color, brush_size_px, brush_shape.get_format() )
	var src_rect := Rect2i(Vector2i.ZERO, img.get_size())
	
	brush_shape.resize( brush_size_px.x, brush_size_px.y )
	img.blend_rect_mask( src, brush_shape, src_rect, texture_position_px )
	texture.update( img )


# Crops texture on smaller sizes, expands on bigger ones. But always keeps pixels where they were
func __resize_texture(rect:Rect2i, fill_color:Color):  ## virtual
	var prev_size:Vector2i = img.get_size()
	var prev_format:int = img.get_format()
	
	var new_size:Vector2i = rect.size * _resolution
	var new_img:Image = __create_img( fill_color, new_size, prev_format )
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var dst:Vector2 = rect.position * _resolution
	
	new_img.blit_rect( img, prev_img_full_rect, dst )
	texture.set_image( new_img )
	img = new_img


# Handy wrappers
func __update_grass_shader(property:String, value:Variant):
	_scene.grass_mesh.material.set_shader_parameter(property, value)
	_scene.grass_mesh.emit_changed()

func __update_overlay_shader(property:String, value:Variant):
	_scene.overlay.material_override.set_shader_parameter(property, value)
	_scene.overlay.material_override.emit_changed()

func __input_texture(tex:Texture2D):
	# Caché the image as well for preformance
	texture = tex
	img = texture.get_image()
	

func __create_img(color:Color, img_size:Vector2i, format:int) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, format)
	img.fill(color)
	return img
