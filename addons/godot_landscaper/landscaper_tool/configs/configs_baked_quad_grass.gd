## Per-instance configuration file for Action classes
## Managed by LandscaperTool classes
@tool
extends ConfigsInstance
class_name ConfigsBakedQuadGrass

@export var grass_texture:Texture2D

@export_group("Grass Detail")
@export var detail_enable:bool = false
@export var detail_color:Color = Color.DARK_SLATE_GRAY


var spawn_action := ActionMMISpawn.new()
var color_action := ActionMMIColor.new()


# Rebuild data. Shared between config actions.
# [NOT-IMPLEMENTED] Rebuilding from projects is not supported yet, this is for shared storage only :P
@export_storage var top_colors:Array[Color]
@export_storage var bottom_colors:Array[Color]
@export_storage var transforms:Array[Transform3D]
