extends BoxContainer
class_name PropertyUI
# Interface for custom dock properties.
#
# This is made like this because we need many properties from 'UILandscaper' and
# managing each one individually does not scale well

@export var property_name:String = ""
signal on_change(value)

var value:
	set=set_value,
	get=get_value


func get_value():
	return null

func set_value(value):
	pass
