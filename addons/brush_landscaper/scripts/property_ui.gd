extends Control
class_name PropertyUI
# Interface for custom dock properties. See 'DockUI.get_property()'
#
# This is made like this because we need many global properties from DockUI
# and routing every one of them (signals, getters, setters,..) does not scale well


var value:
	set=set_value,
	get=get_value


func get_value():
	return null

func set_value(value):
	pass
