extends Resource
class_name RawLandscaper
# Saves all configurations for any number of landscaping projects.
# Hosted inside a 'SceneLandscaper' node by default.
# Save or load it from the "Landscaper" UI Dock

@export var saved_external:bool = false

@export_group("Terrain Builder", "tb_")
@export var tb_texture:Texture2D
@export var tb_resolution:int
@export var world_offset:Vector2i

@export_group("Terrain Color", "tc_")
@export var tc_texture:Texture2D
@export var tc_resolution:int
@export var tc_color:Color

@export_group("Terrain Height", "th_")
@export var th_texture:Texture2D
@export var th_resolution:int
@export var th_strenght:int
@export var th_max_height:float

@export_group("Grass Color", "gc_")
@export var gc_texture:Texture2D
@export var gc_resolution:int
@export var gc_color:Color

@export_group("Grass Spawn", "gs_")
@export var gs_texture:Texture2D
@export var gs_resolution:int
@export var gs_spawn_variant:int
@export var gs_density:int
@export var gs_billboard:int
@export var gs_enable_details:bool
@export var gs_detail_color:Color
@export var gs_quality:int
@export var gs_size:Vector2
@export var gs_gradient_mask:Texture
@export var gs_variants:Array[Texture]


# Should not be setted until users actually saves them from the UI Dock
# Otherwise, they might not be updated correctly
@export_group("External Resources")
@export var terrain_mesh:ArrayMesh
@export var terrain_material:StandardMaterial3D
@export var grass_mesh:QuadMesh
@export var grass_material:ShaderMaterial
@export var grass_shader:Shader

