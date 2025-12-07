extends Resource
class_name GLSaveData

@export_group("Grass 3D Resources")
## Use your custom shader per grass or use the same shader on each grass for performance
@export var shader:Shader
## Use your custom material per grass or use the same material on each grass for performance
@export var material:ShaderMaterial
## Use your custom mesh per grass or use textured grass to be able to use the same mesh on each grass for performance
@export var mesh:Mesh

@export_group("Textured Grass Resources")
## In regular 3D grass you have single-material, many-meshes. But textured grass can work with
## a single-textured-material, single-quad-mesh by using shader sampler2DArray[instance_index]
## Note that the hardware limits the amount of instances, but you can chunkify them to releif that problem entirely
@export var enable_textures:bool = false
## One material can be used for multiple grass instance variants.
## You can set any GrassTextured variants per material, just avoid leaving empty indexes.
@export var instance_index:int = -1
## Use your custom texture for each grass variant. It will be formated to fit inside a sampler2DArray
@export var texture:Texture2D
@export var enable_details:bool = false
@export var detail_color:Color = Color.SEA_GREEN

@export_group("Size", "size_")
## Original size of the instance to spawn
@export var size_base:Vector3 = Vector3.ONE
## How much will the base size be modified randomly
@export var size_randomize:Vector3 = Vector3.ZERO

@export_group("Rotation", "rotation_")
## Original rotation of the instance to spawn
@export var rotation_base:Vector3 = Vector3.ZERO
## How much will the base rotation be modified randomly
@export var rotation_randomize:Vector3 = Vector3.ZERO

@export_group("Position offset", "offset_")
## [NOT-IMPLEMENTED] Original position offset of the instance to spawn.
## Usefull for aligning the grass origin with the ground 
@export var offset_base:Vector3 = Vector3.ZERO

@export_group("Reubild Data")
@export var top_colors:Array[Color]
@export var bottom_colors:Array[Color]
@export var transforms:Array[Transform3D]
