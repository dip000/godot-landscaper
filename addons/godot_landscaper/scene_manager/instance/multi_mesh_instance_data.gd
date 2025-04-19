@tool
extends InstanceData
class_name MultiMeshInstanceData
## Persistent storage for any amount of instance spawning
## Create it from the [Landscaper] tab in the right dock

@export_group("Instances") 
@export var mesh:Mesh ## Examples: QuadMesh for texturing, 3D grass mesh
@export var texture:Texture2D ## Optional, most usefull with quad multimesh meshes

@export_storage var spawn := ActionMMISpawn.new()
@export_storage var color := ActionMMIColor.new()
