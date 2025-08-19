## Per-instance configuration file for Action classes
## Managed by LandscaperTool classes
@tool
@icon("res://addons/godot_landscaper/config_icon.svg")
extends InstanceConfigs
class_name Grass3DConfigs

@export var mesh:Mesh

var spawn_action := ActionMMISpawn.new()
var color_action := ActionMMIColor.new()

# Rebuild data. Shared between config actions.
# Tools might override scene instances for these in case there's a missmatch
@export_storage var top_colors:Array[Color]
@export_storage var bottom_colors:Array[Color]
@export_storage var transforms:Array[Transform3D]
