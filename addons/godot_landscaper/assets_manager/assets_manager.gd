## Hosts static resources
@tool
extends Node
class_name AssetsManager

# =========== GENERAL STATICS ===============================
const ASSETS_ROOT:String = "res://addons/godot_landscaper/assets_manager/"
const CONTROLLER_ROOT:String = "res://addons/godot_landscaper/controllers/"

# Resources
const ICONS:Texture2D = preload("uid://b0vixk6g6mb0o")

# Scenes
const INFO_BOX:PackedScene = preload("uid://cc22twy7o43pp")
const INSPECTOR_TAB:PackedScene = preload("uid://bjulr1lyuv2wc")
const SCENE_MANAGER:PackedScene = preload("uid://dkv66uttcirw3")
const ASSETS_MANAGER:PackedScene = preload("uid://cdpkwy3lagls0")


# =========== DATABASES ===============================
static var brush:Dictionary[String,Resource]
static var grass:Dictionary[String,Resource]
static var models:Dictionary[String,Resource]


func _enter_tree():
	# These template assets should not be exported
	if Engine.is_editor_hint():
		brush = load_assets_folder( "brush" )
		grass = load_assets_folder( "grass" )
		models = load_assets_folder( "models" )


static func load_controller_tabs(controller:String) -> Array[GLInspectorTab]:
	var path:String = CONTROLLER_ROOT.path_join(controller).path_join( "tabs" )
	var tabs:Array[GLInspectorTab]
	tabs.assign( load_resources(path).values() )
	return tabs


static func load_assets_folder(folder:String) -> Dictionary[String, Resource]:
	var path:String = ASSETS_ROOT.path_join( folder )
	return load_resources( path )


# Resources with the dictionary key equal to their filenames
# Returns a custom dictionary for folder files
static func load_resources(resource_folder:String) -> Dictionary[String, Resource]:
	var file_names := ResourceLoader.list_directory( resource_folder )
	var result:Dictionary[String, Resource]
	for file_name in file_names:
		if file_name.get_extension() in ["tscn", "scn", "tres", "res", "svg", "glb", "gdshader"]:
			var file_path:String = resource_folder.path_join( file_name )
			var file_res := load( file_path )
			result[ file_name.get_basename() ] = file_res
	return result
	
