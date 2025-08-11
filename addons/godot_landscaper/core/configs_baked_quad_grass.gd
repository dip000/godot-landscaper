@tool
extends ConfigsInstance
class_name ConfigsBakedQuadGrass

@export var grass_texture:Texture2D

@export_group("Grass Detail")
@export var detail_enable:bool = false
@export var detail_color:Color = Color.DARK_SLATE_GRAY


var spawn_action := ActionMMISpawn.new()
var color_action := ActionMMIColor.new()
