@tool
extends Resource
class_name TBrush
# Base class for all brushes like "TBrushGrassColor"
# Needs to be hosted and setted up from a TerraBrush node instance
# Every export property needs to call "update()" to apply any change in the terrain

signal on_active()

const SURFACE_SIZE_DEFAULT:Vector2i = Vector2(1024, 1024)
const BRUSH_SIZE:Vector2i = Vector2(512, 512)
const BRUSH_RECT:Rect2i = Rect2i(Vector2i.ZERO, BRUSH_SIZE)
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
		update()

var t_color:Color
var terrain:TerraBrush


# Called from "TerraBrush._ready()"
func setup():
	pass

# Called from "TerraBrush.paint()"
func paint(_scale:float, _pos:Vector3, _primary_action:bool):
	pass

# Called after modifying something that needs to apply changes like setting a new "surface_texture"
func update():
	pass

# Paints "TBrush.surface_texture" with BRUSH_MASK, previously colored with "TBrush.t_color"
func _bake_brush_into_surface(scale:float, pos:Vector3):
	if not terrain:
		return
	
	# Transforms
	var surface_size:Vector2i = surface_texture.get_size()
	var surface_full_rect := Rect2i(Vector2i.ZERO, surface_size)
	var size:Vector2i = surface_size * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/terrain.terrain_mesh.size #in [0,1] range
	pos_absolute *= Vector2(surface_size) #move in pixel size
	pos_absolute += (surface_size/2.0) * (1.0-scale) #move from center
	
	# Get images to process
	var brush_mask:Image = BRUSH_MASK.get_image().duplicate()
	var surface:Image = surface_texture.get_image()
	var brush_img:Image = _create_empty_img(t_color, size.x, size.y)
	
	# Blend brush over surface
	brush_mask.resize(size.x, size.y)
	surface.blend_rect_mask( brush_img, brush_mask, surface_full_rect, pos_absolute)
	surface_texture.update(surface)


func _create_empty_img(color:Color, size_x:int=SURFACE_SIZE_DEFAULT.x, size_y:int=SURFACE_SIZE_DEFAULT.y) -> Image:
	var img := Image.create(size_x, size_y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return img

