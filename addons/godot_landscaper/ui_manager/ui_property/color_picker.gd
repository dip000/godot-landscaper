@tool
extends UIProperty
class_name UIColorPicker
## Same as an inspector color property with enable.
## Use as 'my_color_picker.value'

@export var _enable_button:bool = false
@onready var _property:Label = $HBoxContainer/PropertyName
@onready var _picker:ColorPickerButton = $ColorPickerButton
@onready var _checkbox:CheckBox = $HBoxContainer/CheckBox

var color:Color:
	get: return _picker.color

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
	
	_on_color_changed( color )
	if not _enable_button:
		enabled = true
		_checkbox.hide()

func _on_color_changed(_color:Color):
	enabled = true
	change()

func _on_ckeckbox_toggled(pressed:bool):
	enabled = pressed
	change()
