## Hosts static resources
@tool
extends Node
class_name GLAssetsManager

# =========== GENERAL STATICS ===============================
const CONTROLLER_ROOT:String = "res://addons/godot_landscaper/controllers/"

# Scenes
const INFO_BOX:PackedScene = preload("uid://cc22twy7o43pp")
const UI_LAYER:PackedScene = preload("uid://b00d8qhvcb6t1")
const UI_LAYERS:PackedScene = preload("uid://qn18mgxarljs")
const INSPECTOR_TAB:PackedScene = preload("uid://bjulr1lyuv2wc")
const SCENE_MANAGER:PackedScene = preload("uid://dkv66uttcirw3")
const ASSETS_MANAGER:PackedScene = preload("uid://cdpkwy3lagls0")


## Runtime load a list of resources in a given controller_name inside the folder CONTROLLER_ROOT
static func load_controller_brushes(controller_name:String) -> Array[GLBrush]:
	var resource_folder:String = CONTROLLER_ROOT.path_join(controller_name).path_join("brushes")
	var brushes:Array[GLBrush]
	var file_names := ResourceLoader.list_directory( resource_folder )
	for file_name in file_names:
		if file_name.get_extension() in ["tres", "res"]:
			var file_path:String = resource_folder.path_join( file_name )
			GLDebug.spam("Loading Brush: %s.." %file_path)
			var file_res := load( file_path )
			brushes.append( file_res )
	return brushes


## Runtime load a resource given a controller_name inside the folder CONTROLLER_ROOT, and the specific resource_filename
static func load_controller_resource(controller_name:String, resource_filename:String) -> Resource:
	var resource_file:String = CONTROLLER_ROOT.path_join(controller_name).path_join("resources").path_join( resource_filename )
	GLDebug.spam("Loading Controller Resource: %s.." %resource_file)
	return load( resource_file )
	
	
