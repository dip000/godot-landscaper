@tool
@icon("uid://dkeyetdoidrwn")
extends GLController
class_name GLControllerPackedScene


## How many instances coincides to hit over the surface per editor frame
@export_range(1.0, 10.0, 1.0, "or_greater", "suffix:instances/frame") var spawn_ratio:float = 1.0

## Controls how strongly instances rotate to match the surface they are placed on.[br]
## - 0% for standing up as the scene defaults. For "stable" scenes like houses.[br]
## - 100% for fully aligned. For small props like stones
@export_range(0, 100, 1.0, "suffix:%") var align_with_normal:float = 50

## Node to place the instances under
@export var holder:Node


@export_group("Primary Action", "primary_")
@export var primary_action:GLBrushSceneInstancer.Behavior = GLBrushSceneInstancer.Behavior.INSTANTIATE

@export_group("Secondary Action", "secondary_")
@export var secondary_action:GLBrushSceneInstancer.Behavior = GLBrushSceneInstancer.Behavior.ERASE 


@export_group("Randomizers")
@export_subgroup("Size", "size_")
## Original size of the instance to spawn
@export var size_base:Vector3 = Vector3.ONE
## How much will the base size be modified randomly
@export var size_randomize:Vector3 = Vector3(0, 0.25, 0)

@export_subgroup("Rotation", "rotation_")
## Original rotation of the instance to spawn
@export var rotation_base:Vector3 = Vector3.ZERO
## How much will the base rotation be modified randomly
@export var rotation_randomize:Vector3 = Vector3(0, TAU, 0)

@export_subgroup("Position offset", "offset_")
## [NOT-IMPLEMENTED] Original position offset of the instance to spawn.
## Usefull for aligning the grass origin with the ground 
@export var offset_position:Vector3 = Vector3.ZERO


func _setup_controller() -> void:
	validator = GLValidatorPackedScene.new( self )
	builder = GLBuilderPackedScene.new( self )
	brushes = GLAssetsManager.load_controller_brushes( "packed_scene" )
	use_grid = false
