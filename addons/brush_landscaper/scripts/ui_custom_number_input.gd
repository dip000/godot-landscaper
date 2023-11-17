@tool
extends PropertyUI
class_name CustomNumberInput

@export var suffix:String = ""
@onready var _input:LineEdit = $HBoxContainer/LineEdit
@onready var _suffix:Label = $HBoxContainer/Suffix
var _prev_text:String


func _ready():
	$Label.text = property_name
	_input.text_changed.connect( _on_text_changed )

func _on_text_changed(new_text:String):
	if new_text.is_valid_float():
		_prev_text = new_text
		on_change.emit( float(new_text) )
	elif new_text.is_empty():
		_prev_text = "0"
		on_change.emit( 0 )
	else:
		_input.text = _prev_text

func set_value(value):
	_input.text = str(value)
	if suffix.is_empty():
		_suffix.hide()
	_suffix.text = suffix

func get_value():
	return float( _input.text )

