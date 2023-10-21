@tool
extends Resource
class_name TBrush

signal on_active()

const BRUSH_SIZE:Vector2i = Vector2(512, 512)
const BRUSH_FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, BRUSH_SIZE)
const SURFACE_SIZE:Vector2i = Vector2(1024, 1024)
const SURFACE_HALF_SIZE:Vector2i = SURFACE_SIZE/2
const SURFACE_FULL_RECT:Rect2i = Rect2i(Vector2i.ZERO, SURFACE_SIZE)

## Check to draw with this brush. Note that this will unckeck every other brush so only one can be active at a time
@export var active:bool=false:
	set(v):
		if v: on_active.emit() #ok i admit this is a hack. But sould work as long as no one calls active=true from outside
		active = v

@export_group("Advanced")
@export var surface_texture:Texture2D ## The texture you'll be drawing with this brush. A new texture will be provided if you dont set your own
@export var brush_texture:Texture2D ## Leave empty to use a simple round texture. Or use a grass texture for "grass_color" brush for example

var t_color:Color
var texture_updated:bool
var terrain:MeshInstance3D


func paint(_scale:float, _pos:Vector3, _primary_action:bool):
	pass

func _bake_brush_into_surface(scale:float, pos:Vector3):
	if not terrain:
		return
	
	# Transforms
	var size:Vector2i = SURFACE_SIZE * scale #size in pixels
	var pos_absolute:Vector2 = Vector2(pos.x, pos.z)/terrain.mesh.size #in [0,1] range
	pos_absolute *= Vector2(SURFACE_SIZE) #move in pixel size
	pos_absolute += SURFACE_HALF_SIZE * (1.0-scale) #move from center
	
	# Create color
	var brush_img:Image = Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	brush_img.fill( t_color )
	
	# Recolor brush texture if it was provided
	if brush_texture:
		brush_img.blend_rect(brush_texture.get_image(), BRUSH_FULL_RECT, Vector2i.ZERO)
	
	# Blend brush over surface
	var surface:Image = surface_texture.get_image()
	var brush_mask:Image = TerraBrush.BRUSH_MASK.get_image().duplicate()
	brush_mask.resize(size.x, size.y)
	surface.blend_rect_mask( brush_img, brush_mask, SURFACE_FULL_RECT, pos_absolute)
	surface_texture.update(surface)
	texture_updated = true


