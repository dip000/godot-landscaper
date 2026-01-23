## Base framework for all controller classes
## Hosts:
##   * Controller-specific editor properties and buttons
##   * Controller-specific GLBrush, GLEffect and GLBuilder resource classes
##   * Global debug settings
## 
## Routes control down to:
##   * GLBrush classes. For adding/deleting new BuildData using a stroke-like interface
##   * GLEffect classes. For mutating the source BuildData
##   * GLBuilder classes. For applying BuildData

@tool
@abstract
@icon("res://addons/godot_landscaper/scene_element/core/base_icon.svg")
extends Node
class_name GLController


## Raw MultiMesh data from brushing over surfaces.
## Press "Clear All Effects" or "Apply All Effects" to rebuild.
## You can store this data in the filesystem for safekeeping backups or versions,
@export var source:GLBuildData
## The result of processing the MultiMesh source data after applying all effects.
@export var processed:GLBuildData

## Mutates the source data in stack order.
## Note: Run the Chunkifier at the end so all of the previous effects are passed to the chunks
@export var effects:Array[GLEffect]

@export_tool_button("    Apply All Effects   ", "BoneMapperHandleSelected") var _apply_effects_btn:Callable = apply_effects
@export_tool_button("    Clear All Effects   ", "InstanceOptions") var _clear_effects_btn:Callable = clear_effects


@export_category("Scan Configs")
@export_group("Layers")
## Layers to detect your surfaces
@export_flags_3d_physics var scan_layer:int = 0xFFFF_FFFF

@export_group("Meshes")
## Attempts to find the mesh of the scanned PhysicsBody3D in its parent
@export var parent_of_physics_body:bool = true

## NodePath from the scanned PhysicsBody3D to its mesh
@export var relative_path_from_physics_body:String = ""


@export_group("Color Sources")
## Attempts to find the material of the scanned MeshInstance3D under any of the selected active surfaces (includes override and overlay)
@export var active_materials:Array[int] = [0,1,2,3]

## Property path from the scanned standar material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_standar_materials:Array[String] = ["albedo_texture", "albedo_color"]

## Property path from the scanned shader material to the source of color, can be a texture, vec3, or a vec4 
@export var paths_in_shader_materials:Array[String] = ["albedo_texture", "texture", "color", "albedo"]

## Color when the scanner couldn't find any color source
@export var fallback_color:Color = Color.MAGENTA


## Controller-specific builder.
## Actually builds the resulting data. Set in _setup_controller()
var builder:GLBuilder

## Helper for validating stuff. Set in _setup_controller()
var validator:GLValidator

## Tab configs with UI info. Set in _setup_controller()
## GLInspectorManager listens for the brushes[clicked_tab]
var brushes:Array[GLBrush]
## The current active brush from brushes
var current_brush:GLBrush

var use_grid:bool

## Lifehack to avoid clickthrough while adding a node from the "Add Children Node" window
var is_ready:bool


@export_category("Globals")
## Global class for dobugging.
## The amount of messages printed from Godot Landscaper
@export var debug_level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.level = v
	get: return GLDebug.level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.001, "or_greater") var brush_size:float = 2.0:
	set(v):
		brush_size = v
		if Landscaper.running():
			Landscaper.scene.brush.set_size(use_grid, v)
	get:
		if Landscaper.running():
			return Landscaper.scene.brush.get_size()
		return 2.0


func _ready():
	if Engine.is_editor_hint():
		_setup_controller()
		process_mode = Node.PROCESS_MODE_INHERIT
		if GLValidator.validate_ready( validator ):
			## Delay avoids clickthrough 
			await get_tree().process_frame
			await get_tree().process_frame
			is_ready = true
	else:
		process_mode = Node.PROCESS_MODE_DISABLED


## Connect external resources like validators, builders, tabs, etc..
@abstract
func _setup_controller() -> void


## Called from GLInspectorManager on tab click
func select_brush(brush:GLBrush):
	if GLValidator.validate_select_brush( validator, brush ):
		current_brush = brush
		GLDebug.internal("Selected: %s/%s" %[name, brush.title])



## Start landscaping according to the current brush
func stroke_start(scan_data:GLScanData):
	if GLValidator.validate_stroke_start( validator, scan_data ):
		current_brush.start( scan_data, self )


func stroke_primary(scan_data:GLScanData):
	if GLValidator.validate_stroke_primary( validator, scan_data ):
		current_brush.primary( scan_data, self )
		builder.build_from_source()


func stroke_secondary(scan_data:GLScanData):
	if GLValidator.validate_stroke_secondary( validator, scan_data ):
		current_brush.secondary( scan_data, self )
		builder.build_from_source()


func stroke_end():
	if GLValidator.validate_stroke_end( validator ):
		current_brush.end()


func clear_effects():
	if GLValidator.validate_clear_effects( validator ):
		for effect in effects:
			await effect.clear( self )
		builder.build_from_source()


func apply_effects():
	if GLValidator.validate_apply_effects( validator ):
		processed = source.duplicate( true )
		for effect in effects:
			await effect.apply( self )
		builder.build_from_processed()
	
	
	
