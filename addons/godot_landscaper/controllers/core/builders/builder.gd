## BUILDER: Interface members for all builder classes
##

@tool
@abstract
extends Resource
class_name GLBuilder

var _controller:GLController


func _init(controller:GLController):
	_controller = controller

@abstract
func build() -> bool
