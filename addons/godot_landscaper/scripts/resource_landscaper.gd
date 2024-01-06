extends Resource
class_name RawLandscaper
# Saves all configurations for any number of landscaping projects.
# Hosted inside a 'SceneLandscaper' node by default.
# Save or load it from the "Landscaper" UI Dock
# Creates templates for every brush on new()

const MAX_BUILD_REACH := Vector2i(100, 100)
@export var saved_external:bool = false

## Position of terrain in 3D space. Starts with size of 6x6 and centered
@export var world:Rect2i = Rect2i(-3, -3, 6, 6)

@export_group("Terrain Builder", "tb_")
@export var tb_resolution:int = 1
@export var tb_texture:Texture2D = _builder_texture()

@export_group("Terrain Color", "tc_")
@export var tc_resolution:int = 10
@export var tc_texture:Texture2D = _texture(Color(0.557, 0.655, 0.337), Image.FORMAT_RGBA8, tc_resolution*world.size)
@export var tc_color := Color(0.231, 0.482, 0.224)

# Height texture uses FORMAT_LA8 for smoothing height with alpha blend
# Also has one extra pixel for the extra vertices (total_vertices = terrain_size+1)
@export_group("Terrain Height", "th_")
@export var th_resolution:int = 1
@export var th_texture:Texture2D = _texture(Color.BLACK, Image.FORMAT_LA8, th_resolution*world.size + Vector2i.ONE)
@export var th_strength:float = 0.02
@export var th_max_height:float = 2

@export_group("Grass Color", "gc_")
@export var gc_resolution:int = 5
@export var gc_texture:Texture2D = _texture(Color(0.8, 0.792, 0.408), Image.FORMAT_RGBA8, gc_resolution*world.size)
@export var gc_color := Color(0.929, 0.925, 0.576)

@export_group("Grass Spawn", "gs_")
@export var gs_resolution:int = 5
@export var gs_texture:Texture2D = _texture(Color(0.125,0.125,0.125), Image.FORMAT_L8, gs_resolution*world.size)
@export var gs_selected_variant:int = GrassSpawn.VARIANT_0
@export var gs_density:int = 30
@export var gs_selected_billboard:int = 0
@export var gs_enable_details:bool = true
@export var gs_detail_color:Color = Color(0.29, 0.286, 0.098)
@export var gs_quality:float = 3
@export var gs_size:Vector2 = Vector2(0.3, 0.3)
@export var gs_gradient_value:float = 0.2
@export var gs_gradient_mask:Texture2D = AssetsManager.DEFAULT_GRASS_GRADIENT.duplicate()
@export var gs_variants:Array[Texture2D] = [
	AssetsManager.DEFAULT_GRASS_0.duplicate(),
	AssetsManager.DEFAULT_GRASS_1.duplicate(),
	AssetsManager.DEFAULT_GRASS_2.duplicate(),
]


# Should not be setted until users actually saves them from the UI Dock
# Otherwise, they might not be updated correctly
@export_group("External Resources")
@export var terrain_mesh:ArrayMesh
@export var terrain_material:StandardMaterial3D
@export var grass_mesh:QuadMesh
@export var grass_material:ShaderMaterial
@export var grass_shader:Shader


# Create a texture template
func _texture(color:Color, format:Image.Format, size:Vector2i) -> Texture2D:
	var img := Image.create(size.x, size.y, false, format)
	img.fill(color)
	return ImageTexture.create_from_image( img )


# Builder texture uses FORMAT_LA8 for the "Image.get_used_rect()" functionality
# Size is the maximum building reach. The actual terrain size is given by "Image.get_used_rect().size"
func _builder_texture() -> Texture2D:
	var img := Image.create(MAX_BUILD_REACH.x, MAX_BUILD_REACH.y, false, Image.FORMAT_LA8)
	var pos:Vector2i
	var build_rect:Rect2i = world
	
	build_rect.position += MAX_BUILD_REACH/2
	img.fill(Color.TRANSPARENT)
	img.fill_rect( build_rect, Color.WHITE )
	return ImageTexture.create_from_image( img )

