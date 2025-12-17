## DATA GRASS: Interface members for all data classes
##

@tool
extends GLResources
class_name GLResourcesGrass

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
	if not texture and settings.enable_texture:
		texture = AssetsManager.grass.texture_polyquad
	if not shader:
		shader = AssetsManager.grass.shader
	if not material:
		material = AssetsManager.grass.material
	if not mesh:
		mesh = AssetsManager.grass.mesh_textured_polyquad
	
	# Create Textures
	var grass_texture_array:GLTexture2DArray = get_shader("grass_texture_array")
	if not grass_texture_array:
		grass_texture_array = GLTexture2DArray.new()
	
	grass_texture_array.configure(settings.texture_size, settings.texture_format, settings.texture_compression, settings.texture_resize_interpolation)
	
	# Complain about texture configuration missmatches
	if settings.enable_texture and settings.instance_index < 0:
		GLDebug.warning("You've set enable_texture but the instance index is invalid and textures will not be show. Set instance_index>=0")
		grass_texture_array.clear_layer(settings.instance_index)

	# Fix texture array
	elif settings.enable_texture and settings.instance_index >= 0:
		grass_texture_array.set_layer(texture, settings.instance_index)
		set_shader("grass_texture_array", grass_texture_array)
	
	# Force set references
	set_shader("enable_textures", int(settings.enable_texture), settings.instance_index)
	set_shader("details_enable", int(settings.enable_texture_details), settings.instance_index)
	set_shader("detail_colors", settings.texture_detail_color, settings.instance_index)
	material.shader = shader
	mesh.surface_set_material(0, material)
	return true


func set_shader(param:String, value:Variant, index:int=-1):
	if index >= 0:
		material["shader_parameter/%s"%param][index] = value
	else:
		material.set_shader_parameter(param, value)

func get_shader(param:String, index:int=-1) -> Variant:
	if index >= 0:
		return material["shader_parameter/%s"%param][index]
	else:
		return material.get_shader_parameter(param)
