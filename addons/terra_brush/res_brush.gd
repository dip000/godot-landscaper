@tool
extends Resource
class_name TBrush

signal on_active()

const BRUSH_SIZE:Vector2i = Vector2(512, 512)
const BRUSH_FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, BRUSH_SIZE)
const SURFACE_SIZE:Vector2i = Vector2(1024, 1024)
const SURFACE_HALF_SIZE:Vector2i = SURFACE_SIZE/2
const SURFACE_FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SURFACE_SIZE)

const BRUSH_MASK:Texture2D = preload("res://addons/terra_brush/textures/default_brush.tres")


## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var active:bool=false:
	set(v):
		#[WARNING] Do not call active=true from outside!
		if v: on_active.emit()
		active = v

@export_group("Advanced")
## The texture you'll be drawing with this brush. A new texture will be provided if it is not set
@export var surface_texture:Texture2D:
	set(v):
		surface_texture = v
		on_active.emit()
		active = true
		update()

## Leave empty to use a simple round texture. Or use a grass texture for "grass_color" brush for example
#@export var brush_texture:Texture2D

var t_color:Color
var _terrain:TerraBrush


func setup(terrain:TerraBrush):
	_terrain = terrain
	active = false

func paint(_scale:float, _pos:Vector3, _primary_action:bool):
	pass
	
func update():
	pass

func _create_empty_img(color:Color) -> Image:
	var img := Image.create(1024, 1024, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img

func _bake_brush_into_surface(scale:float, pos:Vector3):
	if not _terrain:
		return
	
	# Transforms
	var size:Vector2i = SURFACE_SIZE * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/_terrain.mesh.size #in [0,1] range
	pos_absolute *= Vector2(SURFACE_SIZE) #move in pixel size
	pos_absolute += SURFACE_HALF_SIZE * (1.0-scale) #move from center
	
	# Create color
	var brush_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	brush_img.fill( t_color )
	
	# Recolor brush texture if it was provided
#	if brush_texture:
#		brush_img.blend_rect(brush_texture.get_image(), BRUSH_FULL_RECT, Vector2i.ZERO)
	
	# Blend brush over surface
	var surface:Image = surface_texture.get_image()
	var brush_mask:Image = BRUSH_MASK.get_image().duplicate()
	brush_mask.resize(size.x, size.y)
	surface.blend_rect_mask( brush_img, brush_mask, SURFACE_FULL_RECT, pos_absolute)
	surface_texture.update(surface)


