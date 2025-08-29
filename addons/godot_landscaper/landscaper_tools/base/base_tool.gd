@tool
extends Node
class_name LandscaperTool

## The amount of messages printed from Godot Landscaper
@export var level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.level = v
	get: return GLDebug.level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.1) var brush_size:float = 2.0:
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_scale_ratio(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_scale_ratio()
		return 0.1

## Color of the 3D brush shpere
@export var brush_color:Color = Color(1.0, 0.0, 1.0, 0.3):
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_color(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_color()
		return Color.MAGENTA


# This avoids clicktrhough
var is_ready:bool
func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	is_ready = true

func selected() -> void:
	pass

func deselected() -> void:
	pass

func action_start(hit_info:Dictionary) -> void:
	pass

func action_primary(hit_info:Dictionary) -> void:
	pass

func action_secondary(hit_info:Dictionary) -> void:
	pass

func action_end() -> void:
	pass

func scale_by(value:float):
	pass
