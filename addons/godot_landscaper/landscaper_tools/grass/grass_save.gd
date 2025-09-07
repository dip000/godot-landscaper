@tool
extends Resource
class_name SaveGrass

@export var grass_quad_configs:Array[GrassQuadConfigs]
@export var grass_3d_configs:Array[Grass3DConfigs]


func set_shader_parameter(param:String, value:Variant, indexed:bool):
	_for_each_enabled_config(func(config:InstanceConfigs):
		config.set_shader_parameter( param, value, indexed )
	)

func get_shader_parameter(param:String, default:Variant, indexed:bool) -> Variant:
	if grass_quad_configs[0]:
		return grass_quad_configs[0].get_shader_parameter( param, default, indexed )
	elif grass_3d_configs[0]:
		return grass_3d_configs[0].get_shader_parameter( param, default, indexed )
	return default

func fix_dependencies():
	_for_each_config(func(config:InstanceConfigs):
		config.fix_dependencies()
	)

func load_template():
	_for_each_config(func(config:InstanceConfigs):
		config.load_template()
	)


func load_project_data():
	_for_each_config(func(config:InstanceConfigs):
		config.current_brush.rebuild()
	)

func select_brush(tab:String):
	Callable(self, tab).call()

func select_spawn_action():
	_for_each_config(func(config:InstanceConfigs):
		config.select_spawn_action()
	)

func select_color_action():
	_for_each_config(func(config:InstanceConfigs):
		config.select_color_action()
	)

func action_start():
	_for_each_config(func(config:InstanceConfigs):
		config.action_start()
	)

func _for_each_config(callback:Callable):
	for config in grass_quad_configs:
		if config:
			callback.call( config )
	for config in grass_3d_configs:
		if config:
			callback.call( config )

func _for_each_enabled_config(callback:Callable):
	for config in grass_quad_configs:
		if config and config.enable:
			callback.call( config )
	for config in grass_3d_configs:
		if config and config.enable:
			callback.call( config )
