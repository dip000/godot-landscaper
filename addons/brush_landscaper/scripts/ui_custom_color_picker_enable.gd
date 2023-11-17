@tool
extends CustomColorPicker
class_name CustomColorPickerEnable
# Saves and shows the "enable" state. Doesn't really enable anything
# Auto-enables when the color was changed

@onready var _enable:CheckBox = $HBoxContainer/CheckBox
var enabled:bool:
	set(v):
		_enable.set_pressed( v )
	get:
		return _enable.is_pressed()


func _on_color_changed(c:Color):
	super(c)
	enabled = true
