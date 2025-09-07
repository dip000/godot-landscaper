## Saved data for QuadGrassTool Tool.
@icon("res://addons/godot_landscaper/save_icon.svg")
extends SaveData
class_name Grass3DSave

# Resources
# Please save resources externally.
@export var grass_configs:Array[Grass3DConfigs]


func load_project_data(tool:GrassTool):
	for config in grass_configs:
		config.current_brush.unpack( tool, self, config )
		config.current_brush.rebuild()

func select_spawn_action():
	for config in grass_configs:
		config.current_brush = config.spawn_action

func select_color_action():
	for config in grass_configs:
		config.current_brush = config.color_action
