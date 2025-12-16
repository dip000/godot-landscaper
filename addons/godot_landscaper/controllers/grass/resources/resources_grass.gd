## DATA GRASS: Interface members for all data classes
##

@tool
extends GLResources
class_name GLResourcesGrass

## One material can be used for multiple grass instance variants.
## You can set any GrassTextured variants per material, just avoid leaving empty indexes.
@export var instance_index:int = -1

## Use your custom shader per grass or use the same shader on each grass for performance
@export var shader:Shader

## Use your custom material per grass or use the same material on each grass for performance
@export var material:ShaderMaterial

## Use your custom mesh per grass or use textured grass to be able to use the same mesh on each grass for performance
@export var mesh:Mesh

## Use your custom texture for each grass variant. It will be formated to fit inside a sampler2DArray
@export var texture:Texture2D


func fix_references(settings:GLSettings) -> bool:
	# Fill with templates if any resource is missing
	if not texture:
		texture = AssetsManager.grass.texture_polyquad
	if not shader:
		shader = AssetsManager.grass.shader
	if not material:
		material = AssetsManager.grass.material
	if not mesh:
		mesh = AssetsManager.grass.mesh_textured_polyquad
	
	# Create Textures
	var grass_texture_array:GLTexture2DArray = material.get_shader_parameter("grass_texture_array")
	if not grass_texture_array:
		grass_texture_array = GLTexture2DArray.new()
	
	grass_texture_array.configure(settings.texture_size, settings.texture_format, settings.texture_compression, settings.texture_resize_interpolation)
	
	# Complain about texture configuration missmatches
	if settings.enable_texture and instance_index < 0:
		GLDebug.warning("You've set enable_texture but the instance index is invalid and textures will not be show. Set instance_index>=0")
		grass_texture_array.clear_layer(instance_index)

	# Fix texture array
	elif instance_index >= 0:
		grass_texture_array.set_layer(texture, instance_index)
		material.set_shader_parameter("grass_texture_array", grass_texture_array)
	
	# Force set references
	material.shader = shader
	mesh.surface_set_material(0, material)
	
	material["shader_parameter/enable_textures"][instance_index] = settings.enable_texture as int
	material["shader_parameter/details_enable"][instance_index] = settings.enable_texture_details as int
	material["shader_parameter/detail_colors"][instance_index] = settings.texture_detail_color
	return true
