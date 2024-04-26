@tool
extends VBoxContainer
class_name Brush
## BASE CLASS FOR ALL BRUSHES
## Every brush implements a different functionality based of brush-painting over a terrain.
## Brush-specific properties inherit from 'PropertyUI'
## Only override functions labeled as 'virtual'
## [TODO] For lagging problems: Implement a "preview stroke" handler, then, apply stroke on 'paint_end()'

# Every brush has a texture preview property to give users a better intuition of how everithing works
@onready var texture_preview:CustomToggleContent = $ToggleContent

# Hub for control references. There's only one UI
static var ui:UIControl
# Hub for node references in scene
var _scene:SceneLandscaper
# Instance-specific properties from current scene
var _project:ProjectLandscaper

# The texture you'll painting over; color, heightmap, etc..
var texture:ImageTexture
# Cached texture image. For faster image processing
var img:Image
# How many pixels has the texture per meter squared
var _resolution:float


# Unpack properties from new "scene"
# Rebuilds are disabled on save/load UI. This avoids lagspikes secondary effects and stack overflows
func load_ui(scene:SceneLandscaper):
	_scene = scene
	_project = scene.project
	_rebuild_enabled = false
	_on_load_ui( scene )
	_rebuild_enabled = true
func _on_load_ui(scene:SceneLandscaper): ## virtual
	pass

# Pack properties to new "scene"
func save_ui():
	_rebuild_enabled = false
	_on_save_ui()
	_rebuild_enabled = true
func _on_save_ui(): ## virtual
	pass


# Called while paint-brushing over the 3D scene's terrain
func paint_start(pos:Vector3): ## virtual
	pass
func paint_primary(pos:Vector3): ## virtual
	pass
func paint_secondary(pos:Vector3): ## virtual
	pass
func paint_end(): ## virtual
	pass

# Called when user selects/deselects a brush from the Landscaper Dock
func selected_brush(): ## virtual
	pass
func deselected_brush(): ## virtual
	pass

# Called when user changed its selection to another node in the scene
func deselected_scene(): ## virtual
	_project = null
	_scene = null
	texture = null
	img = null

# Any logic needed to rebuild the scene terrain; update textures, colliders, shaders, scatteres, ect..
var _rebuild_enabled:bool = true
func rebuild():
	if _rebuild_enabled:
		_on_rebuild()
func _on_rebuild():  ## virtual
	pass

# Usefull for color textures
func _change_resolution(new_resolution:float):  ## virtual
	var world_resolution:Vector2 = _project.world.size * new_resolution
	img.resize( world_resolution.x, world_resolution.y )
	texture.set_image( img )
	_resolution = new_resolution


# Paints "texture" with "color" at given "pos" with the global brush size
func _bake_color_into_texture(color:Color, pos:Vector3, blend:=true, world_offset:Vector2=_project.world.position):
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
	dst = dst.round()
	
	# Create copies so the original doesn't get distorted
	# 'get_image()' returns a copy unless the texture is constant
	var src:Image = _create_img( color, src_size, img.get_format() )
	var brush_mask:Image = AssetsManager.DEFAULT_BRUSH.get_image().duplicate()
	brush_mask.resize( src_size.x, src_size.y )
	
	if blend:
		img.blend_rect_mask( src, brush_mask, full_rect, dst )
	else:
		img.blit_rect_mask( src, brush_mask, full_rect, dst )
	
	texture.update( img )


# Crops texture on smaller sizes, expands on bigger ones. But always keeps pixels where they were
func resize_texture(rect:Rect2i, fill_color:Color):  ## virtual
	var prev_size:Vector2i = img.get_size()
	var prev_format:int = img.get_format()
	
	var new_size:Vector2i = rect.size * _resolution
	var new_img:Image = _create_img( fill_color, new_size, prev_format )
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var dst:Vector2 = rect.position * _resolution
	
	new_img.blit_rect( img, prev_img_full_rect, dst )
	texture.set_image( new_img )
	img = new_img


# Handy wrappers
func _update_grass_shader(property:String, value:Variant):
	_scene.grass_mesh.material.set_shader_parameter(property, value)
	_scene.grass_mesh.emit_changed()

func _update_overlay_shader(property:String, value:Variant):
	_scene.overlay.material_override.set_shader_parameter(property, value)
	_scene.overlay.material_override.emit_changed()

func _input_texture(tex:Texture2D):
	# Caché the image as well for preformance
	texture = tex
	img = texture.get_image()
	
	# Preview
	var tex_rec := TextureRect.new()
	tex_rec.texture = texture
	tex_rec.custom_minimum_size = Vector2(100, 100)
	tex_rec.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rec.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_preview.value = [tex_rec]

func _create_img(color:Color, img_size:Vector2i, format:int) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, format)
	img.fill(color)
	return img

