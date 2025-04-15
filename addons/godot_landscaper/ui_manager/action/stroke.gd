extends Resource
class_name Stroke
## Packed parameters that are sent to the specific action implementation
## Gets created on UIAction.action_start() and lives throughout the stroke

## Stroke-constant references
var instance:InstanceData
var root_node:Node3D
var parent_node:Node3D
var mm:MultiMesh
var surface_position:Vector3
var radius:float

## Stroke-constant action-specific
var add_ratio:float
var remove_ratio:float
var primary_color:Color
var secondary_color:Color

## Stroke point updated every frame
var cursor_position:Vector3
var face_index:int
