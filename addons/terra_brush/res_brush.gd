@tool
extends Resource
class_name TBrush
# BASE CLASS FOR ALL BRUSHES
#  Needs to be hosted and setted up from a TerraBrush node instance.
# 
# IMPORTANT:
#  * Export setters should apply any change that it has done onto shaders, colliders, etc..


const BRUSH_SIZE:Vector2i = Vector2(512, 512)
const BRUSH_RECT:Rect2i = Rect2i(Vector2i.ZERO, BRUSH_SIZE)

## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var active:bool=false: set=set_active
@export_group("Advanced")

## The texture you'll be drawing with this brush. Set your own texture!
@export var texture:Texture2D: set=set_texture

## How many pixels a square meter has 
@export_range(2, 100, 0.01, "or_greater", "suffix:px/m") var texture_resolution:float: set=set_texture_resolution


# The actual color that the texture will be painted with
var out_color:Color

 # Host node in scene
var tb:TerraBrush


func set_active(v):
	active = v
	if not active or not tb:
		return
	
	tb.active_brush = self
	for brush in [tb.grass_color, tb.grass_spawn, tb.terrain_color, tb.terrain_height]:
		if self != brush:
			brush.active = false

func set_texture(v):
	# Cannot reset the texture, only replace it
	if not v or not tb:
		return
	
	# Format for internal use:
	#  Cannot process compressed or mipmapped images and we need alpha for smooth brushing
	var img:Image = v.get_image()
	if img.has_mipmaps():
		img.clear_mipmaps()
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert( Image.FORMAT_RGBA8 )
	
	# Note that this generates a copy of the original texture unlinked to the file
	# This means that loading assets will increase their size due duplications. But saving again will fix it
	texture = ImageTexture.create_from_image( img )
	
	# Update resolution to keep the original quality, the user can set it back
	set_texture_resolution( float(img.get_width()) / tb.map_size.x )
	on_texture_update()

func set_texture_resolution(v):
	texture_resolution = v
	if not texture:
		return
	
	var img:Image = texture.get_image()
	img.resize( tb.map_size.x * v, tb.map_size.y * v )
	texture.set_image( img )
	on_texture_update()


# Used to initialize internal logic on every load
func setup():
	pass

# Used to initialize a template for the first time
func template(_size:Vector2i):
	pass

# Implements the paint action lile heightmapping or coloring
func paint(_scale:float, _pos:Vector3, _primary_action:bool):
	pass

# Applies whatever process any brush might want to perform every time its texture is updated
func on_texture_update():
	pass


# Paints "texture" with "out_color"
func _bake_brush_into_surface(scale:float, pos:Vector3):
	# Transforms
	var texture_size:Vector2i = texture.get_size()
	var surface_full_rect := Rect2i(Vector2i.ZERO, texture_size)
	var size:Vector2i = texture_size * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/tb.terrain_mesh.size #in [0,1] range
	pos_absolute *= Vector2(texture_size) #move in pixel size
	pos_absolute += (texture_size/2.0) * (1.0-scale) #move from center
	
	# Get images to process
	var brush_mask:Image = AssetsManager.DEFAULT_BRUSH.get_image().duplicate()
	var texture_image:Image = texture.get_image()
	var brush_img:Image = _create_img(out_color, size)
	
	# Blend brush over surface
	brush_mask.resize(size.x, size.y)
	texture_image.blend_rect_mask( brush_img, brush_mask, surface_full_rect, pos_absolute)
	texture.update(texture_image)

# Crops the texture on smaller sizes, expands on bigger ones. But always keeps pixels where they were
func resize_texture(size:Vector2i):
	if not texture:
		return
	
	var new_size:Vector2 = size * texture_resolution
	var prev_size:Vector2 = texture.get_size()
	var new_img:Image = _create_img( out_color, new_size )
	var prev_img:Image = texture.get_image()
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var center_px:Vector2 = (new_size - prev_size) / 2.0
	
	new_img.blit_rect( prev_img, prev_img_full_rect, center_px )
	texture.set_image( new_img )


# Handy wrappers
func _update_grass_shader(property:String, value:Variant):
	if tb:
		tb.grass_mesh.material.set_shader_parameter(property, value)

# Both terrain shaders are almost the same
func _update_terrain_shader(property:String, value:Variant):
	if tb:
		tb.terrain_mesh.material.set_shader_parameter(property, value)
		tb.overlay_mesh.material.set_shader_parameter(property, value)

func _create_texture(color:Color, img_size:Vector2i) -> Texture2D:
	return ImageTexture.create_from_image( _create_img(color, img_size) )

func _create_img(color:Color, img_size:Vector2i) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img

