@tool
extends Resource
class_name InstanceData
## Persistent storage for any amount of instance spawning
## Create it from the [Landscaper] tab in the right dock

@export var enable:bool = true

@export_group("Size", "size_")
@export var size_base:Vector3 = Vector3.ONE
@export var size_randomize:Vector3 = Vector3.ZERO

@export_group("Rotation", "rotation_")
@export var rotation_base:Vector3 = Vector3.ZERO
@export var rotation_randomize:Vector3 = Vector3.ZERO

## Stroke results
var transforms:Array[Transform3D]
var bottom_colors:Array[Color]
var top_colors:Array[Color]

## Stroke-constant references
var root_node:EcoInstancer
var surface_position:Vector3
var instance_index:int
var radius:float

## Stroke-constant action-specific
var add_ratio:float
var remove_ratio:float
var primary_color:Color
var secondary_color:Color

## Stroke point. Updated every frame
var cursor_position:Vector3
var face_index:int
