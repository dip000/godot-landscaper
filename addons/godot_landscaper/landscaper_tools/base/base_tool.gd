@tool
extends Node
class_name LandscaperTool

## The amount of messages printed from Godot Landscaper
@export var debug_level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.debug_level = v
	get: return GLDebug.debug_level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.1) var brush_size:float = 2.0:
	set(v):
		brush_size = v
		if Landscaper.is_enabled:
			Landscaper.scene.brush.set_scale_ratio(v)
	get:
		if Landscaper.is_enabled:
			return Landscaper.scene.brush.get_scale_ratio()
		return brush_size

## Color of the 3D brush shpere
@export var brush_color:Color = Color(1.0, 0.4, 0.4, 0.3):
	set(v):
		brush_color = v
		if Landscaper.running():
			Landscaper.scene.brush.set_color(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_color()
		return brush_color


func selected():
	pass

func deselected():
	pass

func action_start(hit_info:Dictionary):
	pass

func action_primary(hit_info:Dictionary):
	pass

func action_secondary(hit_info:Dictionary):
	pass

func action_end():
	pass

func scale_by(value:float):
	pass
