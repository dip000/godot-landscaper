## Grass Controller. Based on MultiMeshInstance3D
##
## Select "Spawn" tab to create grass instances over a surface.[br]
## Select "Paint" tab to paint grass instances.[br]
##
## Set your custom mesh under Resources > Shape,[br]
## and optionally, your custom grass texture under Resources > Texture.[br]
##
## You can configure the color scanning capabilities and spawn randomness.[br]
## Try the various effects like recolorings or the chunkifier and press "Apply All Effects".

@tool
@icon("uid://bayr1rdodg66t")
extends GLController
class_name GLControllerGrass

## How many grass instances coincides to hit over the surface per editor frame
@export_range(1.0, 10.0, 1.0, "or_greater", "suffix:instances/frame") var spawn_ratio:float = 1.0

## Smooths the erasing.[br]
## For decreasing the density withouth hard-cutting everything
@export_range(0.1, 1.0, 0.1, "suffix:%/frame") var erase_ratio:float = 1.0

## Controls how strongly instances rotate to match the surface they are placed on.[br]
@export_range(0, 100, 1.0, "suffix:%") var align_with_normal:float = 100


## Grass color with left button mouse.[br]
## Use transparency for smooth blending.
@export var primary_color:Color = Color(GLandscaper.LEMON_CHIFFON, 0.5)

## Grass color with right button mouse.[br]
## Use transparency for smooth blending.
@export var secondary_color:Color = Color(GLandscaper.VERDIGIRS, 0.5)

## The transition between the bottom terrain color and the top hand-painted color.
@export_range(-1.0, 1.0, 0.01) var splash_height:float = 0.0:
	get: return _get_shader("splash_height", 0.0)
	set(v): _set_shader("splash_height", v)

## The source MultiMeshInstance3D tied to this controller.[br]
## It will be auto-generated and placed under the brusshing surface if not provided.
@export var multimesh_instance:MultiMeshInstance3D


@export_group("Primary Action", "primary_")
@export var primary_spawn_behavior:GLBrushGrassSpawn.Behavior = GLBrushGrassSpawn.Behavior.SPAWN
@export var primary_paint_behavior:GLBrushGrassPaint.Behavior = GLBrushGrassPaint.Behavior.PAINT_TOP

@export_group("Secondary Action", "secondary_")
@export var secondary_spawn_behavior:GLBrushGrassSpawn.Behavior = GLBrushGrassSpawn.Behavior.ERASE
@export var secondary_paint_behavior:GLBrushGrassPaint.Behavior = GLBrushGrassPaint.Behavior.PAINT_TOP


@export_group("Texture Layers", "texture_")
## Used for having multiple texture configurations with the same material.[br]
## For performance, one single Texture2DArray will be made for all layers of the same material.[br]
## Avoid leaving empty layer gaps.
@export var texture_layer:int = -1

## The formated size after baking the texture into the array
@export var texture_size_array:Vector2i = Vector2i(255, 255):
	set(v): texture_size_array = v.max(Vector2i.ONE)

## You can add and fine-tuned cheap details with a grayscaled grass texture (instead of purely white), like contours or veins.[br]
## The grayscale will be mix-recolored to this color.[br]
## Leave transparent for disabling it (more performant).
@export var texture_detail_color:Color = Color.TRANSPARENT:
	get: return _get_shader_index("detail_color", Color.TRANSPARENT)
	set(v): _set_shader_index( "detail_color", v )

## Select a texture_layer, a texture_texture and press "Bake Instance Into Array" to apply textures. [br]
## It will be formated to fit inside a Texture2DArray
@export var texture_texture:Texture2D


@export_tool_button("  Save Layer Into Array ", "Save") var texture_bake_btn:Callable = texture_bake
@export_tool_button("Clear Layer From Array", "Clear") var texture_clear_btn:Callable = texture_clear


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
@export var rotation_randomize:Vector3 = Vector3(0, TAU, 0)

@export_subgroup("Position offset", "offset_")
## [NOT-IMPLEMENTED][br]
## Original position offset of the instance to spawn.[br]
## Usefull for aligning the grass origin with the ground 
@export var offset_base:Vector3 = Vector3.ZERO


func texture_bake():
	if GLValidatorGrass.validate_texture_bake( validator ):
		var texture_array_layer:GLTextureAtlasLayer = source.texture_array_layer
		texture_array_layer.bake_layer( texture_layer, texture_texture, texture_size_array )
		multimesh_instance.set_instance_shader_parameter("texture_layer", texture_layer)
	
	
func texture_clear():
	if GLValidatorGrass.validate_texture_clear( validator ):
		var texture_array_layer:GLTextureAtlasLayer = source.texture_array_layer
		texture_array_layer.clear_layer( texture_size_array )
		multimesh_instance.set_instance_shader_parameter("texture_layer", -1)
		

func _setup_controller():
	validator = GLValidatorGrass.new( self )
	builder = GLBuilderGrass.new( self )
	brushes = GLAssetsManager.load_controller_brushes( "grass" )
	use_grid = false


func _get_shader(parameter:String, default:Variant=null) -> Variant:
	if not is_ready or not source: return default
	var material:ShaderMaterial = source.material
	if material and "shader_parameter/%s"%parameter in material:
		return material["shader_parameter/%s"%parameter]
	return default


func _set_shader(parameter:String, value:Variant):
	if not is_ready or not source: return
	var material:ShaderMaterial = source.material
	if ready and material:
		material["shader_parameter/%s"%parameter] = value
	else:
		GLDebug.error("Cannot set shader parameter %s: Material is null. Assign a valid shader material with the corresponding shader" %parameter)


func _get_shader_index(parameter:String, default:Variant=null) -> Variant:
	if not is_ready or not source: return default
	var material:ShaderMaterial = source.material
	if material and "shader_parameter/%s"%parameter in material and texture_layer >= 0:
		return material["shader_parameter/%s"%parameter][texture_layer]
	return default


func _set_shader_index(parameter:String, value:Variant):
	if not is_ready or not source: return
	var material:ShaderMaterial = source.material
	if material and texture_layer >= 0:
		material["shader_parameter/%s"%parameter][texture_layer] = value
	else:
		GLDebug.error("Cannot set shader parameter %s: Material is null or texture_layer<0" %parameter)
