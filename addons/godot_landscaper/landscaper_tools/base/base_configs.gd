## Per-instance configuration file for Action classes
## Managed by LandscaperTool classes
@tool
extends Resource
class_name InstanceConfigs

## Landscaping tools will only apply enabled configs
@export var enable:bool = true


@export_group("Size", "size_")
## Original size of the instance to spawn
@export var size_base:Vector3 = Vector3.ONE
## How much will the base size be modified randomly
@export var size_randomize:Vector3 = Vector3.ZERO

#[TODO] apply inmmediate on setters
@export_group("Rotation", "rotation_")
## Original rotation of the instance to spawn
@export var rotation_base:Vector3 = Vector3.ZERO
## How much will the base rotation be modified randomly
@export var rotation_randomize:Vector3 = Vector3.ZERO

# This is where the actual landscaping happens. See:
# ActionMMIColor, ActionMMISpawn, ActionSceneSpawn, etc..
var current_action:Action
