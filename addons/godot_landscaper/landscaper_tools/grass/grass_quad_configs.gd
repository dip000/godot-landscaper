## Per-instance configuration file for Brush classes
## Managed by LandscaperTool classes
@tool
@icon("res://addons/godot_landscaper/config_icon.svg")
extends InstanceConfigs
class_name GrassQuadConfigs

const CAP:int = 4

@export var grass_texture:Texture2D:
	set(v): set_shader_parameter("grass_textures", v, true)
	get: return get_shader_parameter("grass_textures", null, true)

@export_group("Grass Detail")
@export var detail_enable:bool = false:
	set(v): set_shader_parameter("details_enable", v as int, true)
	get: return get_shader_parameter("details_enable", false, true) as bool

@export var detail_color:Color = Color.DARK_SLATE_GRAY:
	set(v): set_shader_parameter("detail_colors", v, true)
	get: return get_shader_parameter("detail_colors", Color.BLACK, true)


func load_template():
	grass_texture = AssetsManager.grass.texture_quad.duplicate()
	detail_enable = true
	detail_color = Color(0.184, 0.31, 0.31)
	rotation_randomize.y = PI

func fix_dependencies():
	if not shader:
		shader = AssetsManager.grass.shader_quad.duplicate()
	if not material:
		material = AssetsManager.grass.material_quad.duplicate()
	material.shader = shader
	if not mesh:
		mesh = AssetsManager.grass.mesh_quad.duplicate()
	mesh.material = material
