@tool
extends InstanceData
class_name SceneInstanceData
## Persistent storage for any amount of instance spawning
## Create it from the [Landscaper] tab in the right dock

@export_group("Instances") 
@export var scene:PackedScene

@export_storage var spawn := ActionSceneSpawn.new()
@export_storage var color := ActionSceneColor.new()
