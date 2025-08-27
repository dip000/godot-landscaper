@tool
extends Node3D
class_name SceneManager

@onready var raycaster:SceneRaycaster = $Raycaster
@onready var brush:SceneBrush = $SceneBrush


static func find_or_create_node(type, parent:Node, child_name:String):
	if parent.has_node( child_name ):
		GLDebug.internal("Found node %s" %child_name)
		return parent.get_node( child_name )
	return create_node( type, parent, child_name )


static func find_or_create_ownerless(type, parent:Node, child_name:String):
	if parent.has_node( child_name ):
		GLDebug.internal("Found node %s" %child_name)
		return parent.get_node( child_name )
	return create_ownerless( type, parent, child_name )


static func create_node(type, parent:Node, child_name:String) -> Node:
	var child:Node = type.new()
	parent.add_child( child )
	child.name = child_name
	child.owner = parent.owner
	GLDebug.internal("Created node %s" %child_name)
	return child

static func create_ownerless(type, parent:Node, child_name:String) -> Node:
	var child:Node = type.new()
	parent.add_child( child )
	child.name = child_name
	GLDebug.internal("Created node %s" %child_name)
	return child


# ========= Called from InspectorTools ===== ===========
func select_action(tool:LandscaperTool, tab:InspectorTab):
	brush.set_icon( tab.icon )


# ========= Called from main plugin Landscaper =========
func selected(tool:LandscaperTool):
	# Set full scan mode on select
	raycaster.set_collision_mask( tool.scan_layer_internal | tool.scan_layer )

func deselected(tool:LandscaperTool):
	pass

func over_surface(pos:Vector3):
	brush.over_surface( pos )

func not_over_surface():
	brush.not_over_surface()

func action_start(tool:LandscaperTool, hit_info:Dictionary):
	# Scan only internal shapes (created on Scanner.create_shapes)
	# This allows to "brush" over perfect surfaces instead of developer-made colliders
	raycaster.set_collision_mask( tool.scan_layer_internal | tool.scan_layer )

func action_end(tool:LandscaperTool):
	# Return to full scan mode at stroke's end
	raycaster.set_collision_mask( tool.scan_layer_internal | tool.scan_layer )

func scale_by(sca:float):
	brush.scale_by( sca )
