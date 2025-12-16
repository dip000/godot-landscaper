## DATA GRASS: Interface members for all data classes
##

@tool
extends GLBuildData
class_name GLBuildDataGrass

@export var top_colors:Array[Color]
@export var bottom_colors:Array[Color]
@export var transforms:Array[Transform3D]


func append(data:GLBuildData):
	top_colors.append_array(data.top_colors)
	bottom_colors.append_array(data.bottom_colors)
	transforms.append_array(data.transforms)
