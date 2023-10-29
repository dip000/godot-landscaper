@tool
extends Resource
class_name TBrush
# BASE CLASS FOR ALL BRUSHES
# Needs to be hosted and setted up from a TerraBrush node instance.
# Every export property should apply any change that it has done onto shaders, colliders, etc..


# Notifies its TerraBrush host node that this brush is active and all other brushes must be closed
signal on_active()

const BRUSH_SIZE:Vector2i = Vector2(512, 512)
const BRUSH_RECT:Rect2i = Rect2i(Vector2i.ZERO, BRUSH_SIZE)


## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var active:bool=false:
	set(v):
		#[WARNING] Do not call active=true from outside!
		if v: on_active.emit()
		active = v

@export_group("Advanced")
## The texture you'll be drawing with this brush. Set your own texture!
@export var texture:Texture2D:
	set(v):
		if v:
			# Format for internal use:
			#  Cannot process compressed or mipmapped images and we need alpha for smooth brushing
			var img:Image = v.get_image()
			if img.has_mipmaps():
				img.clear_mipmaps()
			if img.is_compressed():
				img.decompress()
			if img.get_format() != Image.FORMAT_RGBA8:
				img.convert( Image.FORMAT_RGBA8 )
			texture = ImageTexture.create_from_image( img )
			
			# Update resolution to keep the original image, the user can set it back at their own risk
			texture_resolution = img.get_width() / tb.map_size.x
			on_texture_update()

## How many pixel a square meter has. The more the heavier to process
## Some brushes don't need great resolution. Like terrain_height, 2 px/m is enough
@export_range(2, 100, 0.01, "or_greater", "suffix:px/m") var texture_resolution:float:
	set(v):
		texture_resolution = v
		if tb and texture:
			var img:Image = texture.get_image()
			img.resize( tb.map_size.x*v, tb.map_size.y*v )
			texture.set_image( img )
		

var tb:TerraBrush # Host node in scene


# Used to initialize internal logic on every load
func setup():
	pass

# Used to initialize a template for the first time
func template(size:Vector2i):
	pass

# Implements the paint action lile heightmapping or coloring
func paint(_scale:float, _pos:Vector3, _primary_action:bool):
	pass

# Applies whatever process any brush might want to perform every time its texture is updated
func on_texture_update():
	pass

func get_textured_color(primary_action:bool) -> Color:
	return Color.WHITE


# Paints "TBrush.texture" with BRUSH_MASK, previously colored with "TBrush.t_color"
func _bake_brush_into_surface(t_color:Color, scale:float, pos:Vector3):
	if not tb:
		return
	
	# Transforms
	var surface_size:Vector2i = texture.get_size()
	var surface_full_rect := Rect2i(Vector2i.ZERO, surface_size)
	var size:Vector2i = surface_size * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/tb.terrain_mesh.size #in [0,1] range
	pos_absolute *= Vector2(surface_size) #move in pixel size
	pos_absolute += (surface_size/2.0) * (1.0-scale) #move from center
	
	# Get images to process
	var brush_mask:Image = AssetsManager.DEFAULT_BRUSH.get_image().duplicate()
	var surface:Image = texture.get_image()
	var brush_img:Image = _create_empty_img(t_color, size)
	
	# Blend brush over surface
	brush_mask.resize(size.x, size.y)
	surface.blend_rect_mask( brush_img, brush_mask, surface_full_rect, pos_absolute)
	texture.update(surface)

# Crops the texture on smaller sizes, expands on bigger ones. But always keeps it where it was
func resize_texture(size:Vector2i):
	if not texture:
		return
	
	var new_size:Vector2 = size * texture_resolution
	var prev_size:Vector2 = texture.get_size()
	var new_img:Image = _create_empty_img( Color.BLACK, new_size )
	var prev_img:Image = texture.get_image()
	var prev_img_full_rect := Rect2i( Vector2i.ZERO, prev_size )
	var center_px:Vector2 = (new_size - prev_size) / 2.0
	
	new_img.blit_rect( prev_img, prev_img_full_rect, center_px )
	texture.set_image( new_img )


# Handy wrappers
func update_grass_shader(property:String, value:Variant):
	if tb and tb.grass_mesh:
		tb.grass_mesh.material.set_shader_parameter(property, value)

# Both terrain shaders are almost the same
func update_terrain_shader(property:String, value:Variant):
	if tb and tb.grass_mesh:
		tb.terrain_mesh.material.set_shader_parameter(property, value)
		tb.overlay_mesh.material.set_shader_parameter(property, value)


func _create_empty_img(color:Color, img_size:Vector2i) -> Image:
	var img := Image.create(img_size.x, img_size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img

