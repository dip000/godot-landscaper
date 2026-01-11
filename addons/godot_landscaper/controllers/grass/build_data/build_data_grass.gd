## DATA GRASS: Interface members for all data classes
##

@tool
extends GLBuildData
class_name GLBuildDataGrass

## MultiMesh.instance_colors
@export var top_colors:PackedColorArray

## MultiMesh.instance_custom_data
@export var bottom_colors:PackedColorArray

## MultiMesh does not store these directly
@export var transforms:Array[Transform3D]


func append(data:GLBuildData):
	top_colors.append_array(data.top_colors)
	bottom_colors.append_array(data.bottom_colors)
	transforms.append_array(data.transforms)

func clear():
	top_colors.clear()
	bottom_colors.clear()
	transforms.clear()

func size() -> int:
	return transforms.size()
