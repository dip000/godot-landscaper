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

## Absolute world coordinate ranges where this build data exists.
## Currently only used for chunkifying
var min:Vector3 = Vector3.INF
var max:Vector3 = -Vector3.INF


func clear():
	transforms.clear()
	top_colors.clear()
	bottom_colors.clear()


## Usefull when you don't want to replace the resource reference
func fill(data:GLBuildData):
	transforms = data.transforms
	top_colors = data.top_colors
	bottom_colors = data.bottom_colors


## Minimum of all arrays, to ensure future indexing works correctly
func size() -> int:
	return min( transforms.size(), top_colors.size(), bottom_colors.size() )
