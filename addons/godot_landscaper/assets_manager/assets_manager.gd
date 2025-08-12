@tool
extends Node
class_name AssetsManager
## Hosts static resources
## Saves/loads

# Scenes
const SCENE_MANAGER:PackedScene = preload("res://addons/godot_landscaper/scene_manager/scene_manager.tscn")
const ASSETS_MANAGER:PackedScene = preload("res://addons/godot_landscaper/assets_manager/assets_manager.tscn")

const ICONS:Texture2D = preload("res://addons/godot_landscaper/assets_manager/ui/icons.svg")

# Databases
const ASSETS_ROOT:String = "res://addons/godot_landscaper/assets_manager/"
static var brush:Dictionary[String,Variant]
static var grass:Dictionary[String,Variant]
static var models:Dictionary[String,Variant]
static var ui:Dictionary[String,Variant]


func _enter_tree():
	brush = filename_as_key(ASSETS_ROOT+"brush")
	grass = filename_as_key(ASSETS_ROOT+"grass")
	models = filename_as_key(ASSETS_ROOT+"models")
	ui = filename_as_key(ASSETS_ROOT+"ui")


# Resources with the dictionary key equal to their filenames
func filename_as_key(resource_folder:String) -> Dictionary[String, Variant]:
	return load_callback(resource_folder,
		func(result:Dictionary[String, Variant], file_name:String, file_path:String):
			var file_res := load(file_path)
			result[ file_name ] = file_res
	)

# Doesn't load the resource itself. Load them on-demand
func only_paths(resource_folder:String) -> Dictionary[String, Variant]:
	var paths:Dictionary[String, Variant] = load_callback(resource_folder,
		func(result:Dictionary[String, Variant], file_name:String, file_path:String):
			result[ file_name ] = file_path
	)
	return paths


# Returns a custom dictionary for folder files
# Call this externally to filter or format the output resource more custom-made. Or use the functions provided
func load_callback(resource_folder:String, callback:Callable) -> Dictionary[String, Variant]:
	if resource_folder.is_empty():
		push_error("Unassigned directory")
		return {}
	
	var file_names := ResourceLoader.list_directory( resource_folder )
	var result:Dictionary[String, Variant]
	
	for file_name in file_names:
		if file_name.get_extension() in ["tscn", "scn", "tres", "res", "svg", "glb", "gdshader"]:
			var file_path:String = resource_folder.path_join(file_name)
			callback.call( result, file_name.get_basename(), file_path )
	
	return result
