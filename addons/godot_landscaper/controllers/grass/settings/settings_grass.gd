## SETTINGS: Interface members for all settings classes
##

@tool
extends GLSettings
class_name GLSettingsGrass


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
@export var size_randomize:Vector3 = Vector3.ZERO

@export_subgroup("Rotation", "rotation_")
## Original rotation of the instance to spawn
@export var rotation_base:Vector3 = Vector3.ZERO
## How much will the base rotation be modified randomly
@export var rotation_randomize:Vector3 = Vector3.ZERO

@export_subgroup("Position offset", "offset_")
## [NOT-IMPLEMENTED] Original position offset of the instance to spawn.
## Usefull for aligning the grass origin with the ground 
@export var offset_base:Vector3 = Vector3.ZERO


@export_group("Texture")
## Used for having multiple texture configurations with the same material.
## For performance, one single GLTexture2DArray will be made for all indexes of the same material.
## Avoid leaving empty index gaps.
@export var instance_index:int = -1

## By enabling it, you may set  
@export var enable_texture:bool = false
@export var enable_texture_details:bool = false
@export var texture_detail_color:Color = Color.SEA_GREEN


@export_group("Array Texture Formatting", "texture_")
@export var texture_size:Vector2i = Vector2i(255, 255)
@export var texture_format:Image.Format = Image.FORMAT_LA8
@export var texture_compression:Image.CompressMode = Image.COMPRESS_ETC2
@export var texture_resize_interpolation:Image.Interpolation = Image.INTERPOLATE_BILINEAR
