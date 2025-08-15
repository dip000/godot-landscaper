## Per-instance configuration file for Action classes
## Managed by LandscaperTool classes
@tool
extends InstanceConfigs
class_name QuadGrassConfigs

@export var grass_texture:Texture2D

@export_group("Grass Detail")
@export var detail_enable:bool = false
@export var detail_color:Color = Color.DARK_SLATE_GRAY

var spawn_action := ActionMMISpawn.new()
var color_action := ActionMMIColor.new()

# Rebuild data. Shared between config actions.
# Tools might override scene instances for these in case there's a missmatch
@export_storage var top_colors:Array[Color]
@export_storage var bottom_colors:Array[Color]
@export_storage var transforms:Array[Transform3D]
