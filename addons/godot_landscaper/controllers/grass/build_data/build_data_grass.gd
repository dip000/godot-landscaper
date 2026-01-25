## DATA GRASS: Interface members for all data classes
##

@tool
extends GLBuildData
class_name GLBuildDataGrass


@export_group("Resources")
## Use your custom mesh as simple 3D grass without textures.
## Or use one QuadMesh and different textures each grass.
@export var mesh:Mesh

## Use the same shader globally for performance (recomended).
## You can use your own shader as long as it has the same uniforms.
@export var shader:Shader

## Use the same material globally for performance (recomended).
## Or use different materials for different biomas or to separate textured and non-textured meshes.
@export var material:ShaderMaterial

## Use the same GLTextureAtlasLayer globally for performance (recomended).
## Dynamic and performant array of textures for multiple grass textures. One Texture2DArray should exist per material.
@export var texture_array_layer:GLTextureAtlasLayer


@export_group("Raw Data")
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
