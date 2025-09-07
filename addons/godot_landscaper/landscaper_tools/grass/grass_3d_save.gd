@tool
extends Resource
class_name GrassSave3D

@export var configs:Array[Grass3DConfigs]


func set_shader_parameter(param:String, value:Variant, indexed:bool):
	for config in configs:
		if config and config.enable:
			config.set_shader_parameter( param, value, indexed )

func get_shader_parameter(param:String, default:Variant, indexed:bool) -> Variant:
	if configs and configs[0]:
		return configs[0].get_shader_parameter( param, default, indexed )
	return default


func fix_dependencies():
	for config in configs:
		if config:
			config.fix_dependencies()

func load_template():
	for config in configs:
		if config:
			config.load_template()

func load_project_data():
	for config in configs:
		if config:
			config.current_brush.rebuild()


func select_brush(tab:String):
	Callable(self, tab).call()

func select_spawn_action():
	for config in configs:
		if config:
			config.select_spawn_action()

func select_color_action():
	for config in configs:
		if config:
			config.select_color_action()

func action_start(hit_info:Dictionary):
	for config in configs:
		if config and config.enable:
			config.action_start(hit_info)

func action_primary(hit_info:Dictionary):
	for config in configs:
		if config and config.enable:
			config.action_primary(hit_info)

func action_secondary(hit_info:Dictionary):
	for config in configs:
		if config and config.enable:
			config.action_secondary(hit_info)

func action_end():
	for config in configs:
		if config and config.enable:
			config.action_end()
