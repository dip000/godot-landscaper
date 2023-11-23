@tool
extends PropertyUI
class_name CustomColorPicker
# 

@export var enable_button:bool = false
@onready var _property:Label = $HBoxContainer/PropertyName
@onready var _picker:ColorPickerButton = $ColorPickerButton
@onready var _checkbox:CheckBox = $HBoxContainer/CheckBox

var enabled:bool:
	set(v):
		_checkbox.set_pressed_no_signal( v )
		_property.add_theme_color_override( "font_color", Color.WHITE if v else Color(1,1,1, 0.3) )
	get:
		return _checkbox.is_pressed()


func _ready():
	_property.text = property_name
	_picker.color_changed.connect( _on_color_changed )
	_checkbox.toggled.connect( _on_ckeckbox_toggled )
	
	_on_color_changed( _picker.color )
	if not enable_button:
		enabled = true
		_checkbox.hide()

func _on_color_changed(color:Color):
	enabled = true
	on_change.emit( color, enabled )

func _on_ckeckbox_toggled(pressed:bool):
	enabled = pressed
	on_change.emit( _picker.color, pressed )

# PropertyUI implementations
func set_value(value):
	_picker.color = value

func get_value():
	return _picker.color
