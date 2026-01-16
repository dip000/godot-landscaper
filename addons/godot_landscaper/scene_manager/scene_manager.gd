@tool
extends Node3D
class_name SceneManager

@onready var raycaster:SceneRaycaster = $Raycaster
@onready var brush:SceneBrush = $SceneBrush


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
func select_brush(icon:AtlasIcon.Icon):
	brush.set_icon( icon )


# ========= Called from main plugin Landscaper =========
func selected(controller:GLController):
	# Set full scan mode on select
	raycaster.set_collision_mask( controller.scan_layer_internal | controller.scan_layer )

func over_surface(pos:Vector3):
	brush.over_surface( pos )

func not_over_surface():
	brush.not_over_surface()

func stroke_start(controller:GLController, hit_info:Dictionary):
	# Scan only internal shapes (created on GLSurfaceScanner.create_shapes)
	# This allows to "brush" over perfect surfaces instead of developer-made colliders
	raycaster.set_collision_mask( controller.scan_layer_internal | controller.scan_layer )

func stroke_end(controller:GLController):
	# Return to full scan mode at brush's end
	raycaster.set_collision_mask( controller.scan_layer_internal | controller.scan_layer )

func scale_by(sca:float):
	brush.scale_by( sca )
