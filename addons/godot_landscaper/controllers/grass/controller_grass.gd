## CONTROLLER GRASS: 
##

@tool
@icon("uid://ckbdbf7cotire")
extends GLController
class_name GLControllerGrass


@export_category("Brushes")
## How many grass instances coincides to hit over the surface per editor frame
@export_range(1.0, 10.0, 1.0, "or_greater") var spawn_ratio:float = 1.0

## How many grass instances attempt to erase per editor frame
@export_range(0.1, 1.0, 0.1) var erase_ratio:float = 1.0

## Grass color with left button mouse
@export var primary_color:Color = Color.PALE_GOLDENROD

## Grass color with right button mouse
@export var secondary_color:Color = Color.PALE_VIOLET_RED

## The transition between the bottom terrain color and the top hand-painted color.
@export_range(-1.0, 1.0, 0.01) var splash_height:float = 0.0:
	get: return _get_shader("splash_height", 0.0)
	set(v): _set_shader("splash_height", v)

## Uses the secondary color to manually paint the bottom of the grass instead of the top.
## Note that the scanning mechanics will auto detect the bottom colors.
@export var paint_bottom_with_sencondary_color:bool = false

## The source MultiMeshInstance3D tied to this controller.
## It will be auto-generated and placed under the brusshing surface if not provided.
@export var multimesh_instance:MultiMeshInstance3D


@export_group("Resources")
## Use your custom mesh as simple 3D grass without textures.
## Or use one QuadMesh and different textures each grass.
@export var mesh:Mesh

## Use the same shader globally for performance.
## You can use your own shader as long as it has the same uniforms.
@export var shader:Shader

## Use the same material globally for performance (recomended).
## Or use different materials for different biomas or to separate textured and non-textured meshes.
@export var material:ShaderMaterial


@export_subgroup("Texture", "texture_")
## Used for having multiple texture configurations with the same material.
## For performance, one single Texture2DArray will be made for all layers of the same material.
## Avoid leaving empty layer gaps.
@export var texture_layer:int = -1:
	get: return _get_shader_instance("texture_layer", -1)
	set(v): _set_shader_instance("texture_layer", v)

@export var texture_detail_color:Color = Color.TRANSPARENT:
	get: return _get_shader_index("detail_color", Color.TRANSPARENT)
	set(v): _set_shader_index( "detail_color", v )

## The formated size after baking the texture into the array
@export var texture_size_array:Vector2i = Vector2i(255, 255)

## Select a texture_layer, a texture_instance and press "Bake Instance Into Array" to apply textures. It will be formated to fit inside a Texture2DArray
@export var texture_instance:Texture2D

## Dynamic and performant array of textures for multiple grass textures. One Texture2DArray will be created per material.
@export var texture_array:Texture2DArray:
	get: return _get_shader("texture_array")
	set(v): _set_shader("texture_array", v)

@export_tool_button(" Bake Instance Into Array ") var texture_bake_btn:Callable = texture_bake
@export_tool_button("  Clear Instance Of Array  ") var texture_clear_btn:Callable = texture_clear


@export_group("Color Scanning")
@export_subgroup("Scan Physics Bodies")
## The collision_layer to scan for any developer-made PhysicsBody3D 
@export_flags_3d_physics var scan_layer:int = 0xFFFFFFFF

## The collision_layer for internal PhysicsBody3D. Set one that you're not using anywhere else
@export_flags_3d_physics var scan_layer_internal:int = (1<<31)
@export_subgroup("Scan Meshes")

## Attempts to find the mesh of the scanned PhysicsBody3D in its parent
@export var parent_of_physics_body:bool = true

## NodePath from the scanned PhysicsBody3D to its mesh
@export var relative_path_from_physics_body:StringName = ""

@export_subgroup("Scan Color Sources")
## Property path from the scanned standar material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_standar_materials:Array[String] = ["albedo_texture", "albedo_color"]

## Property path from the scanned shader material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_shader_materials:Array[String] = ["texture", "color"]

## Color when the scanner couldn't find any color source
@export var fallback_color:Color = Color.MAGENTA


@export_group("Randomizers")
@export_subgroup("Size", "size_")
## Original size of the instance to spawn
@export var size_base:Vector3 = Vector3.ONE
## How much will the base size be modified randomly
@export var size_randomize:Vector3 = Vector3(0, 0.25, 0)

@export_subgroup("Rotation", "rotation_")
## Original rotation of the instance to spawn
@export var rotation_base:Vector3 = Vector3.ZERO
## How much will the base rotation be modified randomly
@export var rotation_randomize:Vector3 = Vector3(0, PI, 0)

@export_subgroup("Position offset", "offset_")
## [NOT-IMPLEMENTED] Original position offset of the instance to spawn.
## Usefull for aligning the grass origin with the ground 
@export var offset_base:Vector3 = Vector3.ZERO

var texture_baker:GLTextureBaker


func texture_bake():
	if validator.validate_texture_bake():
		texture_baker.bake_layer()
		builder.build()

func texture_clear():
	if validator.validate_texture_clear():
		texture_baker.clear_layer()
		builder.build()


func _setup_controller():
	texture_baker = GLTextureBaker.new( self )
	validator = GLValidatorGrass.new( self )
	builder = GLBuilderGrass.new( self )
	brush_tabs = AssetsManager.load_controller_tabs( "grass" )


func _get_shader(parameter:String, default:Variant=null) -> Variant:
	if material and "shader_parameter/%s"%parameter in material:
		return material["shader_parameter/%s"%parameter]
	return default

func _set_shader(parameter:String, value:Variant):
	if material:
		material["shader_parameter/%s"%parameter] = value

func _get_shader_index(parameter:String, default:Variant=null) -> Variant:
	if material and "shader_parameter/%s"%parameter in material and texture_layer >= 0:
		return material["shader_parameter/%s"%parameter][texture_layer]
	return default

func _set_shader_index(parameter:String, value:Variant):
	if material and texture_layer >= 0:
		material["shader_parameter/%s"%parameter][texture_layer] = value

func _get_shader_instance(parameter:String, default:Variant=null) -> Variant:
	if multimesh_instance and multimesh_instance.multimesh and "instance_shader_parameters/%s"%parameter in multimesh_instance:
		return multimesh_instance.get_instance_shader_parameter(parameter)
	return default

func _set_shader_instance(parameter:String, value:Variant):
	if multimesh_instance and "instance_shader_parameters/%s"%parameter in multimesh_instance:
		multimesh_instance.set_instance_shader_parameter( parameter, value )
