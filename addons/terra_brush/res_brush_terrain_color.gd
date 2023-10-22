@tool
extends TBrush
class_name TBrushTerrainColor

const TEXTURE:Texture2D = preload("res://addons/terra_brush/textures/terrain_color.tres")


## Modulates the brush texture. Use alpha to set the stroke strenght
## Modifying this will set it as the active brush
@export var color:Color = Color.WHITE:
	set(v):
		color = v
		on_active.emit()
		active = true


func paint(scale:float, pos:Vector3, primary_action:bool):
	if active:
		if not surface_texture:
			print("New texture")
			surface_texture = load("res://addons/terra_brush/textures/terrain_color.tres")
		
		# The grass roots need to be colored as well so it is also sent to grass shader
		t_color = color if primary_action else Color(color, 0.1)
		TerraBrush.GRASS_MAT.set_shader_parameter("terrain_color", surface_texture)
		TerraBrush.TERRAIN_MAT.set_shader_parameter("terrain_color", surface_texture)
		_bake_brush_into_surface(scale, pos)

