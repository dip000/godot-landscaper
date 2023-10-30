@tool
extends TBrush
class_name TBrushTerrainColor
# Brush that paints the terrain as well as the bottom of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"


## Use alpha to set the stroke strenght.
## Paint with right-click to smooth selected color
@export var color:Color = Color.WHITE:
	set(v):
		color = v
		out_color = v
		set_active( true )


func setup():
	resource_name = "terrain_color"
	set_active( true )

func template(size:Vector2i):
	set_texture_resolution( 20 )
	color = Color.SEA_GREEN
	texture = set_texture( _create_texture(Color.WHITE, size*texture_resolution) )
	

func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# The grass roots need to be colored as well so it is also sent to grass shader
	out_color = color if primary_action else Color(color, 0.1)
	_bake_brush_into_surface(scale, pos)
	on_texture_update()

func on_texture_update():
	_update_grass_shader("terrain_color", texture)
	_update_terrain_shader("terrain_color", texture)
