@tool
extends TBrush
class_name TBrushTerrainColor

## Modulates the brush texture. Use alpha to set the stroke strenght
## Modifying this will set it as the active brush
@export var color:Color = Color.WHITE:
	set(v):
		color = v
		on_active.emit()
		active = true


func setup(terrain:TerraBrush):
	super(terrain)
	resource_name = "terrain_color"
	color = Color.SEA_GREEN
	var tex := ImageTexture.create_from_image( _create_empty_img(Color.WHITE) )
	surface_texture = tex

func paint(scale:float, pos:Vector3, primary_action:bool):
	if not active:
		return
	
	# The grass roots need to be colored as well so it is also sent to grass shader
	t_color = color if primary_action else Color(color, 0.1)
	update()
	_bake_brush_into_surface(scale, pos)

func update():
	_terrain.grass_mesh.material.set_shader_parameter("terrain_color", surface_texture)
	_terrain.mesh.material.set_shader_parameter("terrain_color", surface_texture)
