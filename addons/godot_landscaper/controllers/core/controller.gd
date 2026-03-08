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


## Raw MultiMesh data from brushing over surfaces.[br]
## Press "Clear All Effects" or "Apply All Effects" to rebuild.[br]
## You can store this data in the filesystem for safekeeping backups or versions,
@export var source:GLBuildData
## The result of processing the MultiMesh source data after applying all effects.
@export var processed:GLBuildData

## Mutates the source data in stack order.[br]
## Note: Run the Chunkifier at the end so all of the previous effects are passed to the chunks
@export var effects:Array[GLEffect]

@export_tool_button(" Rebuild From Source", "PlayScene") var _rebuild_from_source_btn:Callable = rebuild_from_source
@export_tool_button("     Apply All Effects     ", "BoneMapperHandleSelected") var _apply_effects_btn:Callable = apply_effects
@export_tool_button("     Clear All Effects     ", "Clear") var _clear_effects_btn:Callable = clear_effects


@export_category("Scan Configs")
@export_tool_button("    Clear Scan Data    ", "Clear") var _clear_all_surfaces_btn:Callable = GLSurfaceScanner.clear_all_surfaces

@export_group("Layers")
## Layers to detect your surfaces
@export_flags_3d_physics var scan_layer:int = GLSceneRaycaster.LAYER_ALL_NOT_INTERNAL

@export_group("Meshes")
## Attempts to find the mesh of the scanned PhysicsBody3D in its parent.[br]
## Last layer is kept disabled by default to avoid internal layers.
@export var parent_of_physics_body:bool = true

## Attempts to find the mesh of the scanned PhysicsBody3D in any of its children.
@export var child_of_physics_body:bool = false

## NodePath from the scanned PhysicsBody3D to its mesh
@export var relative_path_from_physics_body:String = ""


@export_group("Color Sources")
## Attempts to find the material of the scanned MeshInstance3D, in priority order,[br]
## under any of the selected active surfaces (zero includes override and overlay)
@export var active_materials:Array[int] = [0, 1, 2, 3, 4, 5]

## Property path from the scanned material to the source of color, can be a texture, vec3, or a vec4.[br]
## Prefix 'shader_parameter/' for shader materials
@export var paths_in_material:Array[String] = ["albedo_texture", "albedo_color", "shader_parameter/terrain_texture", "shader_parameter/albedo_texture", "shader_parameter/texture", "shader_parameter/color", "shader_parameter/albedo_color"]

## Color if the scanner can't find any color source
@export var fallback_color:Color = Color.MAGENTA


## Controller-specific builder.
## Actually builds the resulting data. Set in _setup_controller()
var builder:GLBuilder

## Helper for validating stuff. Set in _setup_controller()
var validator:GLValidator

## Tab configs with UI info. Set in _setup_controller()[br]
## GLInspectorManager listens for the brushes[clicked_tab]
var brushes:Array[GLBrush]
## The current active brush from brushes
var current_brush:GLBrush

var use_grid:bool

## Lifehack to avoid clickthrough while adding a node from the "Add Children Node" window
var is_ready:bool


@export_category("Globals")
## Global class for dobugging.[br]
## The amount of messages printed from Godot GLandscaper
@export var debug_level:GLDebug.Level=GLDebug.Level.STATES:
	set(v): GLDebug.level = v
	get: return GLDebug.level


## Diameter of the 3D brush sphere. Keybind is [Shift] + [MouseWheel]
@export_range(0.1, 20, 0.001, "or_greater") var brush_size:float = 4.0:
	set(v):
		brush_size = v
		if GLandscaper.running():
			GLandscaper.scene.brush.set_size(use_grid, v)
	get:
		if GLandscaper.running():
			return GLandscaper.scene.brush.get_size()
		return 4.0


func _enter_tree():
	if Engine.is_editor_hint():
		## Delay avoids clickthrough and waits for scene resources to be loaded
		await Engine.get_main_loop().process_frame
		await Engine.get_main_loop().process_frame
		_setup_controller()
		if GLValidator.validate_initialization( validator ):
			is_ready = true
			return


## Connect external resources like validators, builders, tabs, etc..
@abstract
func _setup_controller() -> void


## Called from GLInspectorManager on tab click
func select_brush(brush:GLBrush):
	if GLValidator.validate_select_brush( validator, brush ):
		current_brush = brush
		GLDebug.internal("Selected: %s/%s" %[name, brush.title])


## Start landscaping according to the current brush.
func stroke_start(action:GLandscaper.Action, scan_data:GLScanData):
	if GLValidator.validate_stroke_start( validator, action, scan_data ):
		current_brush.start( action, scan_data, self )
		builder.quick_start( source )


func stroking(action:GLandscaper.Action, scan_data:GLScanData):
	if GLValidator.validate_stroking( validator, action, scan_data ):
		current_brush.action( action, scan_data, self )
		builder.quick_build( source )


func stroke_end(action:GLandscaper.Action, scan_data:GLScanData):
	if GLValidator.validate_stroke_end( validator, action ):
		current_brush.end( action, scan_data, self )
		builder.quick_end( source )


func rebuild_from_source():
	if GLValidator.validate_rebuild_from_source( validator ):
		if not builder.build( source ):
			GLDebug.error("Unexpected Rebuild From Source Error")


func clear_effects():
	if GLValidator.validate_clear_effects( validator ):
		if await GLEffect.clear_all( effects, self ):
			builder.build( source )
			processed = null


func apply_effects():
	if GLValidator.validate_apply_effects( validator ):
		processed = source.duplicate( true )
		if await GLEffect.apply_all( effects, self ):
			builder.build( processed )
	
