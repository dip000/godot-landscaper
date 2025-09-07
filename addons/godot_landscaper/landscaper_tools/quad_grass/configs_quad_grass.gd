## Per-instance configuration file for Brush classes
## Managed by LandscaperTool classes
@tool
@icon("res://addons/godot_landscaper/config_icon.svg")
extends InstanceConfigs
class_name QuadGrassConfigs

@export var grass_texture:Texture2D:
	set(v): _set_shader_param("grass_textures", v)
	get: return _get_shader_param("grass_textures", null)

@export_group("Grass Detail")
@export var detail_enable:bool = false:
	set(v): _set_shader_param("details_enable", v as int)
	get: return _get_shader_param("details_enable", false) as bool

@export var detail_color:Color = Color.DARK_SLATE_GRAY:
	set(v): _set_shader_param("detail_colors", v)
	get: return _get_shader_param("detail_colors", Color.BLACK)

func _get_shader_param(param:String, default:Variant) -> Variant:
	if Landscaper.running() and Landscaper.tool:
		var project:QuadGrassSave = Landscaper.tool.project
		if project and project.material and project.material.shader:
			var index:int = project.grass_configs.find( self )
			return project.material["shader_parameter/"+param][index]
	return default

func _set_shader_param(param:String, value:Variant):
	if Landscaper.running() and Landscaper.tool:
		var project:QuadGrassSave = Landscaper.tool.project
		if project and project.material and project.material.shader:
			var index:int = project.grass_configs.find( self )
			project.material["shader_parameter/"+param][index] = value
			project.notify_property_list_changed()
			project.material.shader = project.shader
