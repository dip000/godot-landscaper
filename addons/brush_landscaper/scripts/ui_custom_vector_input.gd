@tool
extends PropertyUI
class_name CustomVectorInput

@onready var _input_x:LineEdit = $HBoxContainer/LineEdit
@onready var _input_y:LineEdit = $HBoxContainer/LineEditY
var _prev_text_x:String
var _prev_text_y:String


func _ready():
	$Label.text = property_name
	_input_x.text_changed.connect( _on_text_x_changed )
	_input_y.text_changed.connect( _on_text_y_changed )


func _on_text_x_changed(new_text:String):
	if new_text.is_valid_float():
		_prev_text_x = new_text
		on_change.emit( Vector2(float(new_text), float(_input_y.text)) )
	elif new_text.is_empty():
		_prev_text_x = "0"
		on_change.emit( Vector2(0, float(_input_y.text)) )
	else:
		_input_x.text = _prev_text_x

func _on_text_y_changed(new_text:String):
	if new_text.is_valid_float():
		_prev_text_y = new_text
		on_change.emit( Vector2(float(_input_x.text), float(new_text)) )
	elif new_text.is_empty():
		_prev_text_y = "0"
		on_change.emit( Vector2(float(_input_x.text), 0) )
	else:
		_input_y.text = _prev_text_y


func set_value(value:Vector2):
	_input_x.text = String.num( value.x, 2 )
	_input_y.text = String.num( value.y, 2 )

func get_value():
	return Vector2( float(_input_x.text), float(_input_y.text) )

