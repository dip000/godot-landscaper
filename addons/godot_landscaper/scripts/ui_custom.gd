extends Control
class_name PropertyUI
## Interface for custom dock properties.
## Managing each 'UILandscaper' property would not have scaled well otherwise

@export var property_name:String = ""
signal on_change(value)

var value:
	set=set_value,
	get=get_value


func get_value() -> Variant:
	return null

func set_value(value):
	pass
