extends Resource
class_name InstanceData
## Persistent storage for any amount of instance spawning
## Create it from the [Landscaper] tab in the right dock

@export var name:String

@export_group("Execution Logic For Each Action") 
@export var spawn:Action
@export var color:Action

@export_group("Instances") 
@export var packed_scene:PackedScene ## Set either a packed scene or a multimesh to instantiate
@export var multimesh_mesh:Mesh ## Examples: QuadMesh for texturing, 3D grass mesh
@export var texture:Texture2D ## Optional, most usefull with quad multimesh meshes

@export_group("Size", "size_")
@export var size_base:Vector3 = Vector3.ONE
@export var size_randomize:Vector3 = Vector3.ZERO

@export_group("Rotation", "rotation_")
@export var rotation_base:Vector3 = Vector3.ZERO
@export var rotation_randomize:Vector3 = Vector3.ZERO
