@tool
extends Node3D
class_name SceneManager

@onready var raycaster:SceneRaycaster = $Raycaster
@onready var brush:SceneBrush = $Brush


static func find_or_create_node(type, parent:Node, child_name:String, ghost:bool=false) -> Node:
	if parent.has_node( child_name ):
		GLDebug.spam("Found node %s" %child_name)
		return parent.get_node( child_name )
	return create_node( type, parent, child_name, ghost )


static func create_node(type, parent:Node, child_name:String, ghost:bool=false) -> Node:
	var child:Node = type.new()
	parent.add_child( child )
	child.name = child_name
	if not ghost:
		child.owner = parent.owner
	GLDebug.spam("Created node %s" %child_name)
	return child


# ========= Called from GLInspectorManager ===== ===========
func select_brush(brush_to_select:GLBrush):
	brush.select_brush( brush_to_select )


# ========= Called from main plugin Landscaper =========
func selected(controller:GLController):
	# Set full cache_scan_all mode on select
	raycaster.set_collision_mask( controller.scan_layer )
	raycaster.set_collision_mask( controller.scan_layer )
	brush.selected( controller )

func deselected(controller:GLController):
	brush.deselected( controller )

func over_surface(controller:GLController, scan_data:GLScanData):
	brush.over_surface( controller, scan_data )


func stroke_start(controller:GLController, scan_data:GLScanData):
	raycaster.set_collision_mask( controller.scan_layer )

func stroke_end(controller:GLController):
	raycaster.set_collision_mask( controller.scan_layer )


func scale_down(controller:GLController):
	brush.scale_down( controller )

func scale_up(controller:GLController):
	brush.scale_up( controller )
