@tool
extends Node3D
class_name GLSceneManager

@onready var raycaster:GLSceneRaycaster = $Raycaster
@onready var brush:GLSceneBrush = $Brush
@onready var pools:Node = $Pools


static func find_or_create_node(type, parent:Node, child_name:String, ghost:bool=false) -> Node:
	if parent.has_node( child_name ):
		return parent.get_node( child_name )
	return create_node( type, parent, child_name, ghost )


static func create_node(type, parent:Node, child_name:String, ghost:bool=false) -> Node:
	var child:Node = type.new()
	var root:Node = EditorInterface.get_edited_scene_root()
	parent.add_child( child )
	if child_name:
		child.name = child_name
	if not ghost:
		child.owner = root
	GLDebug.spam( "Created node %s" %root.get_path_to(child) ) 
	return child


# ========= Called from GLInspectorManager ===== ===========
func select_brush(brush_to_select:GLBrush):
	brush.select_brush( brush_to_select )


# ========= Called from main plugin GLandscaper =========
func selected(controller:GLController):
	raycaster.update_collision_mask( controller.scan_layer )
	brush.selected( controller )

func deselected(controller:GLController):
	raycaster.update_collision_mask( controller.scan_layer )
	brush.deselected( controller )
	GLSurfaceScanner.clear_all_surfaces()

func over_surface(controller:GLController, scan_data:GLScanData):
	brush.over_surface( controller, scan_data )


func stroke_start(action:GLandscaper.Action, controller:GLController, scan_data:GLScanData):
	raycaster.update_collision_mask( controller.scan_layer )

func stroke_end(action:GLandscaper.Action, controller:GLController):
	raycaster.update_collision_mask( controller.scan_layer )

func scale_down(controller:GLController):
	brush.scale_down( controller )

func scale_up(controller:GLController):
	brush.scale_up( controller )
