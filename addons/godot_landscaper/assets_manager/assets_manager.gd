## Hosts static resources
@tool
extends Node
class_name AssetsManager

# =========== GENERAL STATICS ===============================
const ASSETS_ROOT:String = "res://addons/godot_landscaper/_editor_only_assets/"
const INSPECTOR_TOOLS_ROOT:String = "res://addons/godot_landscaper/inspector_tools/"

# Resources
const ICONS:Texture2D = preload(INSPECTOR_TOOLS_ROOT+"icons.svg")

# Tabs for InspectorTools
const PAINT_TAB:String = INSPECTOR_TOOLS_ROOT+"tabs/paint.tres"
const SPAWN_TAB:String = INSPECTOR_TOOLS_ROOT+"tabs/spawn.tres"

# Scenes
const INFO_BOX:PackedScene = preload(INSPECTOR_TOOLS_ROOT+"info_box.tscn")
const INSPECTOR_TAB:PackedScene = preload(INSPECTOR_TOOLS_ROOT+"inspector_tab.tscn")
const SCENE_MANAGER:PackedScene = preload("res://addons/godot_landscaper/scene_manager/scene_manager.tscn")
const ASSETS_MANAGER:PackedScene = preload("res://addons/godot_landscaper/assets_manager/assets_manager.tscn")


# =========== DATABASES ===============================
static var brush:Dictionary[String,Object]
static var grass:Dictionary[String,Object]
static var models:Dictionary[String,Object]


func _enter_tree():
	# These teamplate assets should not be exported
	if Engine.is_editor_hint():
		brush = filename_as_key(ASSETS_ROOT+"brush")
		grass = filename_as_key(ASSETS_ROOT+"grass")
		models = filename_as_key(ASSETS_ROOT+"models")

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
