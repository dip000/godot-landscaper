@tool
extends TBrush
class_name TBrushTerrainColor
# Brush that paints the terrain as well as the bottom of the grass when you paint over the terrain
# Paints different colors over the "texture" depending on "color"


## Use alpha to set the stroke strenght. Paint with right-click to smooth selected color
@export var color:Color = Color.WHITE:
	set(v):
		color = v
		on_active.emit()
		active = true


func setup(template:bool):
	resource_name = "terrain_color"
	active = true
	if template:
		color = Color.SEA_GREEN
		texture = ImageTexture.create_from_image( _create_empty_img(Color.WHITE, 1024, 1024) )

func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# The grass roots need to be colored as well so it is also sent to grass shader
	var t_color := color if primary_action else Color(color, 0.1)
	update_grass_shader("terrain_color", texture)
	update_terrain_shader("terrain_color", texture)
	_bake_brush_into_surface(t_color, scale, pos)

func on_texture_update():
	update_grass_shader("terrain_color", texture)
	update_terrain_shader("terrain_color", texture)

func get_textured_color(primary_action:bool) -> Color:
	return color if primary_action else color.lightened(0.3)
