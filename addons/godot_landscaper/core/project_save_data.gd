## Individual Landscaper nodes' save data
## 1. Modular, avoids single-point failure
## 2. Simpler for the developer to manage
## 3. Follows Godot's best practices for project file management

extends Resource
class_name ProjectSaveData

@export var mesh:QuadMesh
@export var material:ShaderMaterial
@export var shader:Shader
@export var grass_instances:Array[ConfigsBakedQuadGrass]

@export_storage var top_colors:Array[Color]
@export_storage var bottom_colors:Array[Color]
@export_storage var transforms:Array[Transform3D]


#@export_group("BakedVertexGround", "bvg_")
#@export_group("TextureHeightdGround", "thg_")
#@export_group("BakedQuadGrass", "bqg_")
#@export_group("Baked3DGrass", "b3g_")
#@export_group("Textured3DGrass", "t3g_")
