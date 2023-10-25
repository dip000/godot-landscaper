@tool
extends TBrush
class_name TBrushGrassColor
# Brush that paints the top of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"


## Modulates the brush texture. Use alpha to set the stroke strenght
## Modifying this will set it as the active brush
@export var color:Color = Color.WHITE:
	set(v):
		color = v
		on_active.emit()
		active = true


func setup():
	resource_name = "grass_color"
	color = Color.FOREST_GREEN
	texture = ImageTexture.create_from_image( _create_empty_img(Color.WHITE) )


func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# Paint alpha with secondary to smooth the texture
	t_color = color if primary_action else Color(color, 0.1)
	update_grass_shader("grass_color", texture)
	_bake_brush_into_surface(scale, pos)


func on_texture_update():
	update_grass_shader("grass_color", texture)

