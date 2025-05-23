@tool
extends Node
class_name AssetsManager
## Hosts static resources
## Saves/loads

# Scenes
const UI_MANAGER:PackedScene = preload("res://addons/godot_landscaper/ui_manager/ui_manager.tscn")
const SCENE_MANAGER:PackedScene = preload("res://addons/godot_landscaper/scene_manager/scene_manager.tscn")
const ASSETS_MANAGER:PackedScene = preload("res://addons/godot_landscaper/assets_manager/assets_manager.tscn")

# File System Resources
const ASSETS_FOLDER:StringName = "res://addons/godot_landscaper/assets_manager/"

const SHARP:GradientTexture2D = preload( ASSETS_FOLDER + "/sharp.tres" )
const SOFT:GradientTexture2D = preload( ASSETS_FOLDER + "/soft.tres" )
const SMOOTH:GradientTexture2D = preload( ASSETS_FOLDER + "/smooth.tres" )
const ICONS:Texture2D = preload( ASSETS_FOLDER + "/icons.svg" )

const MATERIAL:ShaderMaterial = preload( ASSETS_FOLDER + "/material.tres" )
const STONE:PackedScene = preload( ASSETS_FOLDER + "/stone.glb" )
const GRASS_3D:Mesh = preload( ASSETS_FOLDER + "/grass_3d.res" )

# Dialogs
@onready var _accept_dialog:AcceptDialog = $AcceptDialog
@onready var _confirm_save:ConfirmationDialog = $ConfirmationSaveDialog
@onready var _confirm_load:ConfirmationDialog = $ConfirmationLoadDialog
