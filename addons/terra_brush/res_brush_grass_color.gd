@tool
extends TBrush
class_name TBrushGrassColor
# Brush that paints the top of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"


## Use alpha to set the stroke strenght
@export var color:Color = Color.WHITE:
	set(v):
		color = v
		out_color = v
		set_active( true )


func setup():
	resource_name = "grass_color"

func template(size:Vector2i):
	set_texture_resolution( 10 )
	color = Color.LIGHT_YELLOW
	set_texture( _create_texture(Color.PALE_GREEN, size*texture_resolution) )
	

func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# Paint alpha with secondary to smooth the texture
	out_color = color if primary_action else Color(color, 0.1)
	on_texture_update()
	_bake_brush_into_surface(scale, pos)
	

func on_texture_update():
	_update_grass_shader("grass_color", texture)
