## CONTROLLER: Base orchestrator for all controller classes
## Hosts:
##   * Controller-specific GLBrush, GLEffect, GLBuilder and GLSetting resource classes
##   * Buttons for handy procedures or updates
##   * Global debug settings
## 
## Routes control down to:
##   * GLBrush classes. For adding/deleting new BuildData using a stroke-like interface
##   * GLEffect classes. For mutating the source BuildData into processed data
##   * GLBuilder classes. For applying the processed BuildData visually

@tool
@abstract
@icon("res://addons/godot_landscaper/scene_element/grass/grass_icon.svg")
extends Node
class_name GLController


## Controller-specific resources.
@export var resources:GLResources

## Controller-specific settings.
@export var settings:GLSettings

@export_category("Postprocess Effects")
## Mutates the data in stack order.
## Uses GLResources.source and mutates an output into GLResources.processed
##
## Note: Run the Chunkifier at the end so all of the previous effects are passed to the chunks
@export var effects:Array[GLEffect]


@export_category("APIs")
## Various Access Point Interfaces for use while playing.
##
## Warning: Only APIs are guaranteed to work stably while playing.
## Editor tools are only for the editor!
@export var apis:Array[GLAPI]


## Controller-specific builder.
## Actually builds the resulting data.
var builder:GLBuilder

## Tab configs managed EXCLUSIVELY by InspectorManager.
var brush_tabs:Array[InspectorTab]
## InspectorManager will update this. No need to do anything else here
var current_brush_tab:InspectorTab
## The brush selected in brush_tabs
var current_brush:GLBrush

## Lifehack to avoid clickthrough while adding a node from the "Add Children Node" window
var is_ready:bool


@export_category("Debugging")
## Global class for dobugging.
## The amount of messages printed from Godot Landscaper
@export var level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.level = v
	get: return GLDebug.level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.1) var brush_size:float = SceneBrush.default_scale:
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_scale_ratio(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_scale_ratio()
		return SceneBrush.default_scale


## Color of the 3D brush shpere
@export var brush_color:Color = SceneBrush.default_color:
	set(v):
		if Landscaper.running():
			Landscaper.scene.brush.set_color(v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_color()
		return SceneBrush.default_color



## This avoids clicktrhough
func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	is_ready = true


@abstract
func select_brush(brush:GLBrush) -> void

@abstract
func stroke_start(hit_info:Dictionary) -> void

@abstract
func stroke_primary(hit_info:Dictionary) -> void

@abstract
func stroke_secondary(hit_info:Dictionary) -> void

@abstract
func stroke_end() -> void
