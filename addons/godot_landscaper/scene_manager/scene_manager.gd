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


static func create_node(type, parent:Node, child_name:String) -> Node:
	var child:Node = type.new()
	parent.add_child( child )
	child.name = child_name
	child.owner = parent.owner
	GLDebug.internal("Created node %s" %child_name)
	return child


# Called from InspectorTools
func select_action(tool:LandscaperTool, tab:InspectorTab):
	brush.set_icon( tab.icon )
	raycaster.set_collision_mask( tool.scan_layer )

# Called from main plugin Landscaper
func over_surface(pos:Vector3):
	brush.over_surface( pos )

func not_over_surface():
	brush.not_over_surface()

func scale_by(sca:float):
	brush.scale_by( sca )
