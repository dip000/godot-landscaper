## Hosts static resources
@tool
extends Node
class_name AssetsManager

# =========== GENERAL STATICS ===============================
const ASSETS_ROOT:String = "res://addons/godot_landscaper/_editor_only_assets/"

# Resources
const ICONS:Texture2D = preload("uid://b0vixk6g6mb0o")

# Scenes
const INFO_BOX:PackedScene = preload("uid://cc22twy7o43pp")
const INSPECTOR_TAB:PackedScene = preload("uid://bjulr1lyuv2wc")
const SCENE_MANAGER:PackedScene = preload("uid://dkv66uttcirw3")
const ASSETS_MANAGER:PackedScene = preload("uid://cdpkwy3lagls0")


# =========== DATABASES ===============================
static var brush:Dictionary[String,Object]
static var grass:Dictionary[String,Object]
static var models:Dictionary[String,Object]
static var execs:Dictionary[String,Object]

func _enter_tree():
	# These template assets should not be exported
	if Engine.is_editor_hint():
		brush = filename_as_key(ASSETS_ROOT + "brush")
		grass = filename_as_key(ASSETS_ROOT + "grass")
		models = filename_as_key(ASSETS_ROOT + "models")

# Resources with the dictionary key equal to their filenames
# Returns a custom dictionary for folder files
func filename_as_key(resource_folder:String) -> Dictionary[String, Object]:
	var file_names := ResourceLoader.list_directory( resource_folder )
	var result:Dictionary[String, Object]
	for file_name in file_names:
		if file_name.get_extension() in ["tscn", "scn", "tres", "res", "svg", "glb", "gdshader"]:
			var file_path:String = resource_folder.path_join(file_name)
			var file_res := load(file_path)
			result[ file_name.get_basename() ] = file_res
	return result
