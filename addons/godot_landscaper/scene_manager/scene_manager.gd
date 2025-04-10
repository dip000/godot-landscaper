@tool
extends Node3D
class_name SceneManager

@onready var raycaster:SceneRaycaster = $Raycaster
@onready var brush:SceneBrush = $SceneBrush


static func find_or_create_node(type, parent:Node, child_name:String):
	if parent.has_node( child_name ):
		Debug.other("Found node %s" %child_name)
		return parent.get_node( child_name )
	
	var child:Node = type.new()
	parent.add_child( child )
	child.name = child_name
	child.owner = parent.owner
	Debug.other("Created node %s" %child_name)
	return child

func over_surface(pos:Vector3):
	brush.over_surface( pos )

func not_over_surface():
	brush.not_over_surface()

func scale_by(sca:float):
	brush.scale_by( sca )
