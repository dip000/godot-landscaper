@tool
extends Node
class_name AssetsManager
## Hosts static resources
## Saves/loads

# Instantiables
const UI_MANAGER:StringName = "res://addons/godot_landscaper/ui_manager/ui_manager.tscn"
const SCENE_MANAGER:StringName = "res://addons/godot_landscaper/scene_manager/scene_manager.tscn"
const ASSETS_MANAGER:StringName = "res://addons/godot_landscaper/assets_manager/assets_manager.tscn"

# File System Resources
const ASSETS_FOLDER:StringName = "res://addons/godot_landscaper/assets_manager/"

const SHARP:GradientTexture2D = preload( ASSETS_FOLDER + "/sharp.tres" )
const SOFT:GradientTexture2D = preload( ASSETS_FOLDER + "/soft.tres" )
const SMOOTH:GradientTexture2D = preload( ASSETS_FOLDER + "/smooth.tres" )
const ICONS:Texture2D = preload( ASSETS_FOLDER + "/icons.svg" )

const GRASS_GRADIENT:Texture2D = preload( ASSETS_FOLDER + "/grass_gradient.tres" )
const GRASS_SHADER:Shader = preload( ASSETS_FOLDER + "/grass_shader.gdshader" )
const GRASS_TALL:Texture2D = preload( ASSETS_FOLDER + "/tall.svg" )
const GRASS_SHORT:Texture2D = preload( ASSETS_FOLDER + "/short.svg" )
const GRASS_SUNFLOWER:Texture2D = preload( ASSETS_FOLDER + "/sunflower.svg" )

const STONE:PackedScene = preload( ASSETS_FOLDER + "/stone.glb" )
const TREE:PackedScene = preload( ASSETS_FOLDER + "/tree.glb" )
const PREVIEW:Mesh = preload( ASSETS_FOLDER + "/preview.res" )
const QUAD_GRASS:Mesh = preload( ASSETS_FOLDER + "/quad_grass.res" )

# Dialogs
@onready var _accept_dialog:AcceptDialog = $AcceptDialog
@onready var _confirm_save:ConfirmationDialog = $ConfirmationSaveDialog
@onready var _confirm_load:ConfirmationDialog = $ConfirmationLoadDialog


func setup():
	Landscaper.ui.save.pressed.connect( _on_save_pressed )
	Landscaper.ui.load.pressed.connect( _on_load_pressed )
	_confirm_save.confirmed.connect( _save_confirmed )
	_confirm_load.confirmed.connect( _load_confirmed )


func _load_ui():
	Debug.other("Saved UI parameters")
	for brush in Landscaper.ui.brushes:
		brush._load_ui()

func save_ui():
	Debug.other("Saved UI parameters")
	for brush in Landscaper.ui.brushes:
		brush._save_ui()


func _on_load_pressed():
	Debug.state("Loading project at '%s'.." %Landscaper.ui.settings.save_folder.path)

func _load_confirmed():
	Debug.state("Loaded project at '%s'" %Landscaper.ui.settings.save_folder.path)


func _on_save_pressed():
	Debug.state("Saving project at '%s'.." %Landscaper.ui.settings.save_folder.path)

func _save_confirmed():
	Debug.state("Saved project at '%s'" %Landscaper.ui.settings.save_folder.path)

func _save_resource(file:CustomFileInput, res:Resource):
	if file.value and res:
		await get_tree().process_frame # Avoid freezing the computer
		res.take_over_path( file.path ) # This saves the references as well
		ResourceSaver.save( res )

func _load_resource(file:CustomFileInput, res:Resource) -> Resource:
	if file.path != res.resource_path:
		return load(file.path)
	return res


func set_unsaved_changes(unsaved:bool):
	Landscaper.ui.save.text = "Save Project *" if unsaved else "Save Project"
