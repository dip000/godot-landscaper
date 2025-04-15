@tool
extends Node
class_name AssetsManager
## Hosts static resources
## Saves/loads

# Scenes
const UI_MANAGER:PackedScene = preload("res://addons/godot_landscaper/ui_manager/ui_manager.tscn")
const SCENE_MANAGER:PackedScene = preload("res://addons/godot_landscaper/scene_manager/scene_manager.tscn")
const ASSETS_MANAGER:PackedScene = preload("res://addons/godot_landscaper/assets_manager/assets_manager.tscn")
const INSTANCE_PREVIEW:PackedScene = preload("res://addons/godot_landscaper/ui_manager/instance/instance.tscn")

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
const QUAD_GRASS:Mesh = preload( ASSETS_FOLDER + "/quad_grass.res" )

# Dialogs
@onready var _accept_dialog:AcceptDialog = $AcceptDialog
@onready var _confirm_save:ConfirmationDialog = $ConfirmationSaveDialog
@onready var _confirm_load:ConfirmationDialog = $ConfirmationLoadDialog
